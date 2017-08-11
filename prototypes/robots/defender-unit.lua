local c = require("meta")
return {
	{
		type = "recipe",
		name = "defender-unit",
		enabled = false,
		category = "advanced-crafting",
		energy_required = c.classes["defender-unit"].craft,
		ingredients = {
			{ "piercing-rounds-magazine", 1 },
			{ "electronic-circuit", 5 },
			{ "iron-gear-wheel", 5 },
		},
		result = "defender-unit"
	},
	{
		type = "unit",
		name = "defender-unit",
		icon = "__base__/graphics/icons/defender.png",
		flags = { "placeable-player", "player-creation", "placeable-off-grid" },
		subgroup = "creatures",
		max_health = 65 * c.config.HEALTH_SCALAR,
		minable = { hardness = 0.1, mining_time = 0.1, result = "defender-unit" },
		alert_when_damaged = false,
		order = "b-b-a",
		resistances = {
			{
				type = "physical",
				decrease = 4,
			}
		},
		friendly_map_color = { r = .05, g = .70, b = .29 },
		healing_per_tick = 0.01, -- XXX upgraded
		collision_box = nil,
		collision_mask = { "ghost-layer" },
		selection_box = { { -0.3, -0.3 }, { 0.3, 0.3 } },
		sticker_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
		distraction_cooldown = 300,
		attack_parameters = {
			type = "projectile",
			ammo_category = "bullet",
			cooldown = 20,
			projectile_center = { 0, 1 },
			projectile_creation_distance = 0.6,
			range = 12,
			min_attack_distance = 8,
			sound = _G.make_light_gunshot_sounds(),
			ammo_type = {
				category = "bullet",
				action = {
					type = "direct",
					action_delivery = {
						type = "instant",
						source_effects = {
							type = "create-explosion",
							entity_name = "explosion-gunshot-small"
						},
						target_effects = {
							{
								type = "create-entity",
								entity_name = "explosion-hit"
							},
							{
								type = "damage",
								damage = { amount = 5 * c.config.DAMAGE_SCALAR , type = "physical" }
							}
						}
					}
				}
			},
			animation = {
				layers = {
					{
						filename = "__base__/graphics/entity/defender-robot/defender-robot.png",
						priority = "high",
						line_length = 16,
						width = 32,
						height = 33,
						frame_count = 1,
						direction_count = 16,
						shift = { 0, 0.015625 }
					},
					{
						filename = "__base__/graphics/entity/defender-robot/defender-robot-mask.png",
						priority = "high",
						line_length = 16,
						width = 18,
						height = 16,
						frame_count = 1,
						direction_count = 16,
						shift = { 0, -0.125 },
						apply_runtime_tint = true
					},
					{
						filename = "__base__/graphics/entity/defender-robot/defender-robot-shadow.png",
						priority = "high",
						line_length = 16,
						width = 43,
						height = 23,
						frame_count = 1,
						direction_count = 16,
						shift = { 0.859375, 0.609375 }
					},
				}
			}
		},
		vision_distance = 45,
		movement_speed = 0.2,
		distance_per_frame = 0.15,
		-- in pu
		pollution_to_join_attack = 0,
		corpse = "robot-corpse",
		dying_explosion = "explosion",
		working_sound = {
			sound = {
				{ filename = "__base__/sound/flying-robot-1.ogg", volume = 0.6 },
				{ filename = "__base__/sound/flying-robot-2.ogg", volume = 0.6 },
				{ filename = "__base__/sound/flying-robot-3.ogg", volume = 0.6 },
				{ filename = "__base__/sound/flying-robot-4.ogg", volume = 0.6 },
				{ filename = "__base__/sound/flying-robot-5.ogg", volume = 0.6 }
			},
			max_sounds_per_type = 3,
			--audible_distance_modifier = 0.5,
			probability = 1 / (3 * 60) -- average pause between the sound is 3 seconds
		},
		dying_sound = {
			{
				filename = "__base__/sound/fight/small-explosion-1.ogg",
				volume = 0.5
			},
			{
				filename = "__base__/sound/fight/small-explosion-2.ogg",
				volume = 0.5
			}
		},
		run_animation = {
			layers = {
				{
					filename = "__base__/graphics/entity/defender-robot/defender-robot.png",
					priority = "high",
					line_length = 16,
					width = 32,
					height = 33,
					frame_count = 1,
					direction_count = 16,
					shift = { 0, 0.015625 }
				},
				{
					filename = "__base__/graphics/entity/defender-robot/defender-robot-mask.png",
					priority = "high",
					line_length = 16,
					width = 18,
					height = 16,
					frame_count = 1,
					direction_count = 16,
					shift = { 0, -0.125 },
					apply_runtime_tint = true
				},
				{
					filename = "__base__/graphics/entity/defender-robot/defender-robot-shadow.png",
					priority = "high",
					line_length = 16,
					width = 43,
					height = 23,
					frame_count = 1,
					direction_count = 16,
					shift = { 0.859375, 0.609375 }
				},
			},
		},
	},
}

