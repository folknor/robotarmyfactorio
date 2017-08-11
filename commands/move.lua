
local function process(squad)
	squad:Order({
		type = defines.command.go_to_location,
		destination = squad.position,
		distraction = defines.distraction.by_anything
	}, true)
end

return process
