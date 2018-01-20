local droidscale = 0.8
local c = require("meta")
local droidRocketTint = { r = 0.8, g = 0.8, b = 1, a = 1 }
local droidMapColour = { r = .05, g = .70, b = .29 }

return {
	{
		type = "recipe",
		name = "droid-rocket",
		enabled = false,
		category = "advanced-crafting",
		energy_required = c.classes["droid-rocket"].craft,
		ingredients = {
			{ "steel-plate", 5 },
			{ "electronic-circuit", 25 },
			{ "rocket-launcher", 1 },
			{ "light-armor", 1 }
		},
		result = "droid-rocket"
	},
	{
		type = "unit",
		name = "droid-rocket",
		icon = "__base__/graphics/icons/player.png",
		icon_size = 32,
		flags = { "placeable-player", "player-creation", "placeable-off-grid" },
		subgroup = "creatures",
		has_belt_immunity = true,
		order = "e-a-b-d",
		max_health = 85 * c.config.HEALTH_SCALAR,
		alert_when_damaged = false,
		healing_per_tick = 0.01,
		collision_box = { { -0.8*droidscale, -0.8*droidscale }, { 0.8*droidscale, 0.8*droidscale } },
		selection_box = { { -0.8*droidscale, -0.8*droidscale }, { 0.8, 0.8*droidscale } },
		sticker_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		vision_distance = 30,
		friendly_map_color = droidMapColour,
		movement_speed = 0.11,
		minable = { hardness = 0.1, mining_time = 0.1, result = "droid-rocket" },
		pollution_to_join_attack = 0,
		distraction_cooldown = 0,
		distance_per_frame = 0.05,
		dying_explosion = "medium-explosion",
		resistances = {
			{
				type = "physical",
				decrease = 1,
				percent = 40
			},
			{
				type = "explosion",
				decrease = 5,
				percent = 30
			},
			{
				type = "acid",
				decrease = 1,
				percent = 30
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
						type = "nested-result",
						affects_target = true,
						action = {
							type = "area",
							perimeter = 6,
							collision_mask = { "player-layer" },
							action_delivery = {
								type = "instant",
								target_effects = {
									type = "damage",
									damage = { amount = 50, type = "explosion" }
								}
							}
						},
					},
					{
						type = "create-entity",
						entity_name = "explosion"
					},
					{
						type = "damage",
						damage = { amount = 100, type = "explosion" }
					}
				}
			}
		},
		 attack_parameters = {
			type = "projectile",
			ammo_category = "rocket",
			movement_slow_down_factor = 0.8,
			cooldown = 180,
			projectile_creation_distance = 1,
			range = 22,
			projectile_center = { 0.6, 1 },
			animation = {
				filename = "__robotarmy__/graphics/entity/rocket_idle.png",
				priority = "high",
				width = 80,
				height = 80,
				tint = droidRocketTint,
				direction_count = 8,
				frame_count = 1,
				animation_speed = 0.15,
				shift = { 0, 0 }
			},
			sound = {
				{
					filename = "__base__/sound/fight/rocket-launcher.ogg",
					volume = 0.7
				}
			},
			ammo_type = {
				category = "rocket",
				action = {
					type = "direct",
					action_delivery = {
						type = "projectile",
						projectile = "droid-explosive-rocket",
						starting_speed = 0.9,
						source_effects = {
							type = "create-entity",
							entity_name = "explosion-hit"
						}
					}
				}
			}
		},
		idle = {
			filename = "__robotarmy__/graphics/entity/rocket_idle.png",
			priority = "high",
			width = 80,
			height = 80,
			tint = droidRocketTint,
			direction_count = 8,
			frame_count = 1,
			animation_speed = 0.3,
			shift = { 0, 0 }
		},
		run_animation = {
			filename = "__robotarmy__/graphics/entity/rocket_run.png",
			priority = "high",
			width = 80,
			height = 80,
			tint = droidRocketTint,
			direction_count = 22,
			frame_count = 1,
			animation_speed = 0.3,
			shift = { 0, 0 }
		},
	},
}
