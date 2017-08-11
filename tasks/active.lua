local _meta = require("meta")

-- _TASK_ACTIVE_COMMAND is only used while a squad has an active
-- explicit command set by a player.

local function process()
	return 4, _meta.errors.retasking
end

local function shouldweretask(squad)
	-- self.taskData is the tick on which we should process again
	if type(squad.taskData) == "number" and squad.taskData > game.tick then return true end
end

return {
	process = process,
	shouldRetask = shouldweretask,
	shouldReinforce = function() return true end,
}
