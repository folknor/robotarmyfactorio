local _log = require("util.logger")
local _util = require("util.utility")
local _meta = require("meta")

-- If we are retreating;
-- 1. Find the closest assembler
-- 2. Move towards it until we are close
-- 3. Retask to _TASK_IDLE

local function getRetreatingSquadPosition(squad)
	for i = 1, #squad do
		local m = squad(i)
		if m and m.valid and squad.taskData.retreating[m.unit_number] then
			return m.position
		end
	end
end

local function process(squad)
	if not squad.taskData then
		-- Initial process
		_log(squad, _log.RETREATING)
		local closest = _util.findClosestAssembler(squad)
		if not closest then return 20, _meta.errors.assembler end
		squad.position = closest.position
		squad.taskData = {
			assembler = closest,
			retreating = {},
		}
		-- Store the current squad members in case we get reinforced "somehow".
		-- Even though shouldReinforce always returns false for this task.
		for i = 1, #squad do
			local m = squad(i)
			if m and m.valid then
				squad.taskData.retreating[m.unit_number] = true
			end
		end
	end

	local retreatingFrom = getRetreatingSquadPosition(squad)
	if not retreatingFrom then
		-- This probably means all retreating squad members have been killed, so retask to idle
		return squad:Task(_meta.tasks.idle)
	end

	local distance = (((retreatingFrom.x - squad.position.x) ^ 2) + ((retreatingFrom.y - squad.position.y) ^ 2)) ^ 0.5
	if distance < _meta.config.HOLD_SPAWNS_RANGE then
		-- We are close to the assembler.
		return squad:Task(_meta.tasks.idle)
	end
	squad:Order({
		type = defines.command.go_to_location,
		destination = squad.position,
		distraction = defines.distraction.none
	}, true)
	return 15
end

return {
	process = process,
	shouldRetask = function() return false end,
	shouldReinforce = function() return false end,
}
