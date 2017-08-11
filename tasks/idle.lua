local _meta = require("meta")

local idleWander = {
	type = defines.command.compound,
	structure_type = defines.compound_command.return_last,
	commands = {
		{ type = defines.command.go_to_location, },
		{ type = defines.command.wander, }
	}
}

local function process(squad)
	idleWander.commands[1].destination = squad.position
	squad:Order(idleWander)
	return 20, _meta.errors.notFull
end

local function shouldweretask(squad)
	if squad:IsFull() then return true end
end

return {
	process = process,
	shouldRetask = shouldweretask,
	shouldReinforce = function() return true end,
}
