local _meta = require("meta")

local function attack(squad)
	squad:Order({
		type = defines.command.attack_area,
		radius = _meta.config.HUNT_AREA_ATTACK_RADIUS,
		destination = squad.position,
		distraction = defines.distraction.by_anything,
	}, true)
end

return attack
