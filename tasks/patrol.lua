local _util = require("util.utility")
local _meta = require("meta")

local function process(squad)
	-- squad.position is the stored position of the next waypoint
	_util.clearInvalid(squad.taskData)
	if #squad.taskData == 0 then return 5, _meta.errors.retasking end

	local first = squad.taskData[1]
	local currentPosition = squad:GetPosition()
	local distance = (((currentPosition.x - first.position.x) ^ 2) + ((currentPosition.y - first.position.y) ^ 2)) ^ 0.5

	if distance > _meta.config.GUARD_VALIDATE_POLE_DISTANCE then
		-- We are not close enough, or we have a new target, move towards it and wait 60 seconds
		squad:Order({
			type = defines.command.go_to_location,
			destination = first.position,
			distraction = defines.distraction.by_anything,
		})
		-- If the group still considers itself finished after being given the command,
		-- forcefully move to next pole
		if squad.group and squad.group.valid and squad.group.state == defines.group_state.finished then
			-- remove pole at index 1 and add it to the end
			local f = table.remove(squad.taskData, 1)
			table.insert(squad.taskData, f)
			-- Patrol at this spot for 5 seconds, then process again
			return 5, _meta.errors.command.patrol
		end
		-- squad.position should reflect where we want to go
		squad.position = first.position
	else
		-- remove index 1 and add it to the end
		local f = table.remove(squad.taskData, 1)
		table.insert(squad.taskData, f)
		return 5, _meta.errors.command.patrol
	end
	return 10
end

local function shouldweretask(squad)
	-- As long as there are patrol poles active, we keep patrolling
	-- We can do this because a patrol command doesn't start until at least
	-- one invulnerable pole is placed
	if squad.taskData and #squad.taskData == 0 then return true end
	return false
end

return {
	process = process,
	shouldRetask = shouldweretask,
	shouldReinforce = function() return true end,
}
