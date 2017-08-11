local droidscale = 0.8
local droidMapColour = { r = .05, g = .70, b = .29 }
local c = require("meta")

local function make_laser_sounds()
	return {
		{
			filename = "__base__/sound/fight/laser-1.ogg",
			volume = 0.7
		},
		{
			filename = "__base__/sound/fight/laser-2.ogg",
			volume = 0.7
		},
		{
			filename = "__base__/sound/fight/laser-3.ogg",
			volume = 0.7
		}
	}
end

return {
	{
		type = "recipe",
		name = "terminator",
		enabled = false,
		category = "advanced-crafting",
		energy_required = c.classes.terminator.craft,
		ingredients = {
			{ "steel-plate", 10 },
			{ "laser-turret", 2 },
			{ "processing-unit", 10 },
			{ "modular-armor", 1 }
		},
		result = "terminator"
	},
	{
		type = "unit",
		name = "terminator",
		icon = "__robotarmy__/graphics/icons/terminator.png",
		flags = { "placeable-player", "player-creation", "placeable-off-grid" },
		subgroup = "creatures",
		order = "e-a-b-d",
		max_health = 300 * c.config.HEALTH_SCALAR,
		alert_when_damaged = false,
		healing_per_tick = 0.02,
		friendly_map_color = droidMapColour,
		collision_box = { { -0.8*droidscale, -0.8*droidscale }, { 0.8*droidscale, 0.8*droidscale } },
		selection_box = { { -0.8*droidscale, -0.8*droidscale }, { 0.8, 0.8*droidscale } },
		sticker_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		vision_distance = 30,
		movement_speed = 0.18,
		minable = { hardness = 0.1, mining_time = 0.1, result = "terminator" },
		pollution_to_join_attack = 0,
		distraction_cooldown = 0,
		distance_per_frame = 0.05,
		dying_explosion = "medium-explosion",
		resistances = {
			{
				type = "physical",
				decrease = 1,
				percent = 80
			},
			{
				type = "explosion",
				decrease = 20,
				percent = 90
			},
			{
				type = "acid",
				decrease = 5,
				percent = 85
			},
			{
				type = "laser",
				decrease = 5,
				percent = 35
			},
			{
				type = "fire",
				decrease = 5,
				percent = 95
			}
		},
		destroy_action = {
			type = "direct",
			action_delivery = {
				type = "instant",
				source_effects = {
					{
						type = "create-entity",
						entity_name = "explosion"
					},
					{
						type = "nested-result",
						action = {
							type = "area",
							perimeter = 50,
							action_delivery = {
								type = "instant",
								target_effects = {
									{
										type = "damage",
										damage = { amount = 100, type = "explosion" }
									},
									{
										type = "create-entity",
										entity_name = "explosion"
									},
									{
										type = "create-entity",
										entity_name = "small-scorchmark",
										check_buildability = true
									}
								}
							}
						}
					},
				}
			}
		},
		attack_parameters = {
			type = "projectile",
			ammo_category = "combat-robot-laser",
			cooldown = 10,
			projectile_center = { 0, 0.4 },
			projectile_creation_distance = 1.5,
			range = 15,
			sound = make_laser_sounds(),
			animation = {
				filename = "__robotarmy__/graphics/entity/terminator_idle.png",
				priority = "high",
				width = 80,
				height = 80,
				direction_count = 8,
				frame_count = 1,
				animation_speed = 0.15,
				shift = { 0, 0 }
			},
			ammo_type = {
				type = "projectile",
				category = "combat-robot-laser",
				energy_consumption = "0W",
				projectile = "laser-dual",
				speed = 2,
				action = {
					{
						type = "direct",
						action_delivery = {
							{
								type = "projectile",
								projectile = "laser-dual",
								starting_speed = 1
							}
						}
					}
				}
			}
		},
		idle = {
			filename = "__robotarmy__/graphics/entity/terminator_run.png",
			priority = "very-low",
			width = 80,
			height = 80,
			direction_count = 22,
			frame_count = 1,
			animation_speed = 0.5,
			shift = { 0, 0 }
		},
		run_animation = {
			filename = "__robotarmy__/graphics/entity/terminator_run.png",
			priority = "high",
			width = 80,
			height = 80,
			direction_count = 22,
			frame_count = 1,
			animation_speed = 0.5,
			shift = { 0, 0 }
		},
	},
}
