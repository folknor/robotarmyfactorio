local _meta = require("meta")

-- This is only used by the player squads and the active command.
-- Simply make sure we move towards the player and process again quite fast, so we keep up.
-- We might actually want to interpolate a position ahead of the player and move towards that.

-- XXX kyranzor
-- Check to see if there are any enemies within 30-40 range or so, and automatically attack those?
-- If we are set to follow a player, that might be what they expect.
--
local function process(squad)
	local player
	local force = false
	if squad.taskData then -- This means we've been set to follow from an active command
		player = game.players[squad.taskData]
		force = true
	else -- This means we're a player-specific squad
		player = game.players[squad.id]
	end
	if not player or not player.valid or not player.connected then return 30, _meta.errors.noPlayer end
	squad:Order({
		type = defines.command.go_to_location,
		destination = player.position,
		distraction = defines.distraction.by_anything,
	}, force)
	return 4 -- process often
end

return {
	process = process,
	shouldRetask = function() return false end,
	shouldReinforce = function() return true end,
}
