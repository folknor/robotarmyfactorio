local droidMapColour = { r = .05, g = .70, b = .29 }
local droidFlameTint = { r = 1.0, g = 0.5, b = 0.5, a = 1 }
local droidscale = 0.8
-- potential names: https://en.wikipedia.org/wiki/Flame_tank#World_War_II_Allied
local c = require("meta")

return {
	{
		type = "recipe",
		name = "droid-flame",
		enabled = false,
		category = "advanced-crafting",
		energy_required = c.classes["droid-flame"].craft,
		ingredients = {
			{ "steel-plate", 5 },
			{ "electronic-circuit", 25 },
			{ "flamethrower", 1 },
			{ "light-armor", 2 }

		},
		result = "droid-flame",
	},
	{
		type = "unit",
		name = "droid-flame",
		icon = "__base__/graphics/icons/player.png",
		flags = { "placeable-player", "player-creation", "placeable-off-grid" },
		subgroup = "creatures",
		order = "e-a-b-d",
		max_health = 200 * c.config.HEALTH_SCALAR,
		alert_when_damaged = false,
		healing_per_tick = 0.01,
		collision_box = { { -0.8*droidscale, -0.8*droidscale }, { 0.8*droidscale, 0.8*droidscale } },
		selection_box = { { -0.8*droidscale, -0.8*droidscale }, { 0.8, 0.8*droidscale } },
		sticker_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		vision_distance = 30,
		movement_speed = 0.09,
		minable = { hardness = 0.1, mining_time = 0.1, result = "droid-flame" },
		pollution_to_join_attack = 0,
		distraction_cooldown = 0,
		distance_per_frame = 0.05,
		friendly_map_color = droidMapColour,
		dying_explosion = "medium-explosion",
		resistances = {
			{
				type = "physical",
				decrease = 5,
				percent = 40
			},
			{
				type = "explosion",
				decrease = 5,
				percent = 70
			},
			{
				type = "acid",
				decrease = 1,
				percent = 30
			},
			{
				type = "fire",
				percent = 100
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
									damage = { amount = 40, type = "explosion" }
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
			type = "stream",
			ammo_category = "flamethrower",
			movement_slow_down_factor = 0.6,
			cooldown = 30,
			projectile_creation_distance = 0.6,
			range = 10,
			min_range = 0,
			projectile_center = { -0.17, 0.2 },
			animation = {
				filename = "__robotarmy__/graphics/entity/flame_run.png",
				priority = "high",
				width = 80,
				height = 80,
				tint = droidFlameTint,
				direction_count = 22,
				frame_count = 1,
				animation_speed = 0.3,
				shift = { 0, 0 }
			},
			cyclic_sound = {
				begin_sound = {
					{
						filename = "__base__/sound/fight/flamethrower-start.ogg",
						volume = 0.7
					}
				},
				middle_sound = {
					{
						filename = "__base__/sound/fight/flamethrower-mid.ogg",
						volume = 0.7
					}
				},
				end_sound = {
					{
						filename = "__base__/sound/fight/flamethrower-end.ogg",
						volume = 0.7
					}
				}
			},
			ammo_type = {
				category = "flamethrower",
				action = {
					type = "direct",
					action_delivery = {
						type = "stream",
						stream = "flamethrower-fire-stream",
						duration = 60,
						source_offset = { 0.15, -0.5 },
					}
				}
			}
		},
		idle = {
			filename = "__robotarmy__/graphics/entity/flame_run.png",
			priority = "high",
			width = 80,
			height = 80,
			tint = droidFlameTint,
			direction_count = 22,
			frame_count = 1,
			animation_speed = 0.3,
			shift = { 0, 0 }
		},
		run_animation = {
			filename = "__robotarmy__/graphics/entity/flame_run.png",
			priority = "high",
			width = 80,
			height = 80,
			tint = droidFlameTint,
			direction_count = 22,
			frame_count = 1,
			animation_speed = 0.3,
			shift = { 0, 0 }
		},
	},
}
