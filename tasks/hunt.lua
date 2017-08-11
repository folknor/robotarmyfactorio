local _util = require("util.utility")
local _log = require("util.logger")
local _meta = require("meta")
local _TREE = "tree"

local function getTarget(squad, surface, data)
	if data.target and data.target.valid then return data.target, false end
	-- If we have zero valid targets, find new ones within the hunt radius
	local huntRadius = squad:Get(_meta.settings.huntRadius)
	local chainRadius = _meta.config.HUNT_CHAIN_RADIUS
	if huntRadius == -1 then chainRadius = _meta.config.HUNT_ROAM_RADIUS end

	local nearby = surface.find_nearest_enemy({
		position = squad:GetPosition(),
		max_distance = chainRadius,
		force = squad.force
	})
	if nearby and nearby.valid then
		data.target = nearby
		return nearby, true
	elseif squad.home then
		local fromHome = surface.find_nearest_enemy({
			position = squad.home,
			max_distance = huntRadius,
			force = squad.force,
		})
		if fromHome and fromHome.valid then
			data.target = fromHome
			return fromHome, true
		end
	end
	data.target = nil
end

local function returnToAssembler(squad)
	_log(squad, _log.RETURNING_TO_ASSEMBLER)
	local closest = _util.findClosestAssembler(squad)
	if not closest then return 30, _meta.errors.assembler end
	local retreatPos = _util.assemblerPosition(closest)
	squad.position = retreatPos
	squad:Order({
		type = defines.command.go_to_location,
		destination = retreatPos,
		distraction = defines.distraction.by_damage
	}, true)
	return 30
end

local function updateFlyingStatus(squad)
	local n = #squad
	squad.taskData.groupSize = n
	for i = 1, n do
		local member = squad(i)
		if not _meta.classes[member.name].flying then
			squad.taskData.flying = false
			return
		end
	end
	squad.taskData.flying = true
end

local function getTrees(distance, squad, put)
	for i = 1, #squad do
		local member = squad(i)
		local trees = member.surface.find_entities_filtered({
			area = {
				{ member.position.x - distance, member.position.y - distance },
				{ member.position.x + distance, member.position.y + distance }
			},
			type = _TREE
		})
		if trees and #trees ~= 0 then
			for k = 1, #trees do put[trees[k]] = true end
		end
	end
end

local busy = {
	[defines.group_state.attacking_distraction] = true,
	[defines.group_state.attacking_target] = true,
}
local function process(squad)
	-- Is this the initial process?
	local first = false
	if not squad.taskData then
		first = true
		squad.taskData = {}
		updateFlyingStatus(squad)
	end
	if squad.taskData.groupSize ~= #squad then
		updateFlyingStatus(squad)
	end

	-- If the squads group is already attacking something, GTFO
	local state = squad.group and squad.group.valid and squad.group.state
	if state and busy[state] and _meta.useGroup then return 4 end

	local data = squad.taskData
	local surface = squad:GetSurface()
	local target, changed = getTarget(squad, surface, data)

	-- If there's zero valid targets then there's nothing to kill, simply return
	if not target then
		return returnToAssembler(squad)
	end

	-- Update .position to where the squad WANTS to be
	squad.position = target.position

	local bunched, closest = squad:IsGathered()

	if not data.flying then
		-- XXX 12 is the distance ahead of the closest member we check for tree density
		-- XXX it should probably be based on the members speed and the return value from
		-- XXX this process() (which is 8).
		-- So if the squad, based on this members speed, will move 30 tiles in 8 seconds,
		-- we should probably increase the distance to 30. I don't know how fast things move.
		local sX, sY
		if squad.group and squad.group.valid and squad.group.state ~= defines.group_state.gathering then
			-- If we're not gathering, check ahead
			sX, sY = _util.interpolatedPosition(closest, 12)
		else
			-- If there is no group, or we are gathering, check around the squad
			sX, sY = closest.position.x, closest.position.y
		end
		-- XXX We probably need to adjust all 3 of the tree config variables so that tree clearing appears sane
		local modifier = math.min(#squad * _meta.config.TREE_KILL_RADIUS_PER_MEMBER, _meta.config.TREE_KILL_MAX_RADIUS)
		local trees = surface.find_entities_filtered({
			area = {
				{ sX - modifier, sY - modifier },
				{ sX + modifier, sY + modifier },
			},
			type = _TREE
		})
		if trees and #trees > (modifier * _meta.config.TREE_DENSITY_THRESHOLD) then
			-- There's a lot of trees in the area ahead
			-- Get all the trees around each member as well, and send it all to task-trees
			local map = {}
			for i = 1, #trees do map[trees[i]] = true end
			local distance = (_meta.config.TREE_KILL_RADIUS_PER_MEMBER * 2)
			getTrees(distance, squad, map)
			local actualTrees = {}
			for k in pairs(map) do actualTrees[#actualTrees + 1] = k end
			return squad:Task(_meta.tasks.trees, actualTrees)
		end
	end

	if not first then
		-- This is not the first iteration, so now we check is we are bunched
		-- Because squad.position and such will be relevant.
		if not bunched then
			-- while bunching, the squad wants to bunch at the closest member
			squad.position = closest.position
			-- We're not bunched up, so retask
			return squad:Task(_meta.tasks.gather)
		end

		-- Charts around the squad member that is closest to the target
		game.forces[squad.force].chart(surface, {
			{ closest.position.x - 32, closest.position.y - 32 },
			{ closest.position.x + 32, closest.position.y + 32 }
		})
	end

	if changed then
		local order = {
			type = defines.command.attack_area,
			radius = _meta.config.HUNT_AREA_ATTACK_RADIUS,
			destination = target.position,
			distraction = defines.distraction.by_anything,
		}
		-- force=true the order because we only do it after the target has changed
		local accepted = squad:Order(order, true)
		if accepted then
			_log(squad, _log.HUNT_TARGET, target.name)
		end
	end

	return 8
end

local function shouldweretask(squad)
	-- If we are hunting, we only stop to retreat and reinforce
	local retreat = squad:Get(_meta.settings.retreatSize)
	if #squad <= retreat then return _meta.tasks.retreat end
	return false
end

local caption = {"robotarmy-task-names.task-retreat"}
return {
	process = process,
	shouldRetask = shouldweretask,
	shouldReinforce = function() return false end,
	updateUI = function(squad)
		local retreat = squad:Get(_meta.settings.retreatSize)
		return caption, retreat
	end,
}
