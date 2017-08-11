local _meta = require("meta")

local function getCompoundKillCommand(...)
	local ret = {
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = {}
	}
	for i = 1, select("#", ...) do
		table.insert(ret.commands, {
			type = defines.command.attack,
			target = select(i, ...)
		})
	end
	return ret
end

-- XXX This and task-trees are the only ones where we individually
-- .set_command as of 0.4.1.
-- Also the hold/stop commands.

local function initialProcess(squad)
	local go = {
		type = defines.command.go_to_location,
		destination = squad.position,
		distraction = defines.distraction.by_anything,
	}

	local clear
	local distance = (_meta.config.TREE_KILL_RADIUS_PER_MEMBER * 2)
	for i = 1, #squad do
		local member = squad(i)
		if not _meta.classes[member.name].flying then
			local trees = member.surface.find_entities_filtered({
				area = {
					{ member.position.x - distance, member.position.y - distance },
					{ member.position.x + distance, member.position.y + distance }
				},
				type = "tree"
			})
			if trees and #trees ~= 0 then
				if not clear then clear = {} end
				for k = 1, #trees do clear[#clear+1] = trees[k] end
				-- Order this member to start killing his own trees immediately
				member.set_command(getCompoundKillCommand(unpack(trees)))
			else
				member.set_command(go)
			end
		end
	end
	-- XXX _meta.config.TREE_DENSITY_THRESHOLD is quite low, it's supposed to be per-member
	-- XXX but #clear contains all the trees at this point, so it could be a lot even if
	-- XXX the number of trees around each individual member might be like 0-2.
	-- We don't care. We want to kill all trees anyway :-)
	if clear and #clear > _meta.config.TREE_DENSITY_THRESHOLD then
		return squad:Task(_meta.tasks.trees, clear)
	else
		squad:Order(go, true)
	end
	return 8
end

local _WAIT = "wait"

local function randomize(pos)
	return {pos.x + math.random(-4, 4), pos.y + math.random(-4, 4)}
end

-- This task is only applied by other tasks that want the squad to gather.
-- Make sure squad.position is set to the gathering point before
-- applying this task.
-- When gathering is complete, make sure you set squad.taskData = true
-- Note that this task never changes squad.position, so that when we
-- re-task after gathering is complete, it will have the same value as
-- before task-gather.
local function process(squad)
	if not squad.taskData then
		squad.taskData = _WAIT
		return initialProcess(squad)
	end

	-- At this point we have had 8 seconds to gather up.
	if squad.group and squad.group.valid then
		if squad.group.state ~= defines.group_state.finished then
			squad.taskData = _WAIT
			return 5
		end
	end

	if squad:IsGathered() then
		squad.taskData = true
		return 3, _meta.errors.retasking
	else
		if squad.taskData == _WAIT then squad.taskData = 1
		else
			squad.taskData = squad.taskData + 1
			if squad.taskData > 2 then
				-- We've tried 3 times or more
				for i = 1, #squad do
					local m = squad(i)
					if m and m.valid then
						local dest = randomize(m.position)
						m.set_command({
							type = defines.command.go_to_location,
							destination = dest,
						})
					end
				end
				squad.taskData = _WAIT
				return 3
			end
			if squad.taskData > 1 then
				-- We've tried 2 times. Forcefully destroy the group so that
				-- the game reacts and makes the units move.
				if squad.group and squad.group.valid then squad.group.destroy() end
			end
		end
		squad:Order({
			type = defines.command.go_to_location,
			destination = squad.position,
			distraction = defines.distraction.by_anything,
		}, true)
	end
	-- No return, just process again immediately
end

local function shouldweretask(squad)
	if type(squad.taskData) == "boolean" and squad.taskData then return true end
	return false
end

local function shouldReinforce(squad, location)
	-- Check distance between given location for new spawns and squads current position
	local distance = (((location.x - squad.position.x) ^ 2) + ((location.y - squad.position.y) ^ 2)) ^ 0.5
	return distance <= _meta.config.HOLD_SPAWNS_RANGE
end

return {
	process = process,
	shouldRetask = shouldweretask,
	shouldReinforce = shouldReinforce,
}
