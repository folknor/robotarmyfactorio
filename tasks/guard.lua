local _log = require("util.logger")
local _util = require("util.utility")
local _meta = require("meta")
local select = select
local unpack = unpack
local HASH = "#"

-- We should test whether or not it would be a big improvement
-- to actually cache the entity-to-entity distances
local function findClosest(to, ...)
	local best, bestDistance
	for i = 1, select(HASH, ...) do
		local foo = (select(i, ...))
		local d = (((foo.position.x - to.x) ^ 2) + ((foo.position.y - to.y) ^ 2)) ^ 0.5
		if not bestDistance or (d < bestDistance) then
			best = i
			bestDistance = d
		end
	end
	return best
end

-- All entries in sort must be valid
-- This is horribly inefficient with all the table.ins/rm magic
-- We should implement a linked list
local function sortByDistance(origin, sort)
	if #sort < 2 then return sort end
	-- we could fast-path 2 entries as well, I guess
	local best = findClosest(origin, unpack(sort))
	table.insert(sort, 1, table.remove(sort, best)) -- This is really expensive, we should probably implement a custom linked list

	local index = 2
	while index ~= (#sort + 1) do
		local closest = findClosest(sort[index - 1].position, unpack(sort, index))
		if (closest + index - 1) ~= index then
			local entry = table.remove(sort, closest + index - 1)
			table.insert(sort, index, entry)
		end
		index = index + 1
	end
	return sort
end

-- TABLECHURN PLZ
local _VIRTUAL = "virtual"
local _GREEN = defines.wire_type.green
local function getPoles(squad)
	local ret = {}
	for i = #global.guardPoles, 1, -1 do
		local pole = global.guardPoles[i]
		if pole and pole.valid then
			local cc = pole.get_control_behavior()
			if cc and cc.valid then
				local p = cc.get_signal(1)
				if p and p.signal and p.signal.type == _VIRTUAL and _meta.squadIdSignals[p.signal.name] then
					if squad.id == _meta.squadIdSignals[p.signal.name] then
						table.insert(ret, pole)
					end
				else
					local green = cc.get_circuit_network(_GREEN)
					if green and green.valid and green.signals then
						-- Check all incoming signals to see if they are a squad ID
						for k = 1, #green.signals do
							local s = green.signals[k].signal
							if s and s.type == _VIRTUAL and _meta.squadIdSignals[s.name] and squad.id == _meta.squadIdSignals[s.name] then
								table.insert(ret, pole)
								break
							end
						end
					end
				end
			end
		else
			-- Important that we do this here, or we have to do _util.clearinvalid in :process
			table.remove(global.guardPoles, i)
		end
	end
	return ret
end

local function initialGuardSetup(squad)
	local as = _util.findClosestAssembler(squad)
	squad.taskData = {
		assembler = as,
	}
	if as and as.valid then
		local poles = getPoles(squad)
		squad.taskData.poles = sortByDistance(as.position, poles)
	end
end

-- If we are assigned to guarding;
-- 1. Find out how far we are from the next waypoint
-- 2. If we are too far away, we move towards it and wait 60 seconds
-- 3. If we are close, we check if the settings have been
-- 4. If not, see if there are any enemies within
-- 4. If not, we move towards next waypoint
local function process(squad)
	-- All pole list processing depends on the squad having a valid assembler home
	if type(squad.taskData) == "table" and (not squad.taskData.assembler or not squad.taskData.assembler.valid) then
		squad.taskData.assembler = _util.findClosestAssembler(squad)
		if not squad.taskData.assembler or not squad.taskData.assembler.valid then
			return 60, _meta.errors.assembler
		end
	end

	-- taskData is always nil after a retask
	if type(squad.taskData) ~= "table" then
		initialGuardSetup(squad)
	else
		-- This is not the first time we :process, so check if poles have changed
		-- getPoles removes invalid luaentities, so if there are any invalid ones,
		-- size ~= size will trigger, and we reprocess everything
		local newList = getPoles(squad)
		if #squad.taskData.poles ~= #newList then
			squad.taskData.poles = sortByDistance(squad.taskData.assembler.position, newList)
		end
	end

	if #squad.taskData.poles == 0 then
		return 60, _meta.errors.guardPoles
	end

	-- From here on down we can basically act like the patrol task, where we reorder the pole array
	-- every :process. And if the array updates above here, then the squad will simply have
	-- to move to one "weird" pole place before everything is sorted again

	local first = squad.taskData.poles[1]
	local currentPosition = squad:GetPosition()
	local distance = (((currentPosition.x - first.position.x) ^ 2) + ((currentPosition.y - first.position.y) ^ 2)) ^ 0.5

	if distance > _meta.config.GUARD_VALIDATE_POLE_DISTANCE then
		-- We are not close enough to our current pole, so go go!
		squad:Order({
			type = defines.command.go_to_location,
			destination = first.position,
			distraction = defines.distraction.by_anything,
		})
		-- If the group still considers itself finished after being given the command,
		-- forcefully move to next pole
		if squad.group and squad.group.valid and squad.group.state == defines.group_state.finished then
			-- remove pole at index 1 and add it to the end
			local f = table.remove(squad.taskData.poles, 1)
			table.insert(squad.taskData.poles, f)
			-- Patrol at this spot for 5 seconds, then process again
			return 5, _meta.errors.command.patrol
		end
		-- squad.position should reflect where we want to go
		squad.position = first.position
	else
		-- remove pole at index 1 and add it to the end
		local f = table.remove(squad.taskData.poles, 1)
		table.insert(squad.taskData.poles, f)

		-- Are there any enemies near us?
		local nearest = squad:GetSurface().find_nearest_enemy({
			position = currentPosition,
			max_distance = _meta.config.GUARD_ENGAGE_DISTANCE,
			force = squad.force
		})
		if nearest then
			_log(squad, _log.GUARD_FOUND_ENEMY)
			-- There is an enemy target within distance, engage!
			squad:Order({
				type = defines.command.compound,
				structure_type = defines.compound_command.return_last,
				commands = {
					{
						type = defines.command.attack,
						target = nearest,
						distraction = defines.distraction.by_anything,
					},
					{
						type = defines.command.go_to_location,
						destination = currentPosition,
						distraction = defines.distraction.by_enemy
					},
				}
			})
			return 30
		else
			-- Patrol at this spot for 5 seconds, then process again
			return 5, _meta.errors.command.patrol
		end
	end
	return 10
end

local function shouldweretask() return false end

return {
	process = process,
	shouldRetask = shouldweretask,
	shouldReinforce = function() return true end,
}
