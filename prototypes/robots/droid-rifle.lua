local droidscale = 0.8
local c = require("meta")
local droidRifleTint = { r = 0.8, g = 1, b = 0.8, a = 1 }
local droidMapColour = { r = .05, g = .70, b = .29 }

local function make_rifle_gunshot_sounds()
	return {
		{
			filename = "__base__/sound/fight/light-gunshot-1.ogg",
			volume = 1
		},
		{
			filename = "__base__/sound/fight/light-gunshot-2.ogg",
			volume = 1
		},
		{
			filename = "__base__/sound/fight/light-gunshot-3.ogg",
			volume = 1
		}
	}
end

return {
	{
		type = "recipe",
		name = "droid-rifle",
		enabled = false,
		category = "advanced-crafting",
		energy_required = c.classes["droid-rifle"].craft,
		ingredients = {
			{ "copper-plate", 20 },
			{ "electronic-circuit", 5 },
			{ "iron-gear-wheel", 10 },
		},
		result = "droid-rifle"
	},
	{
		type = "unit",
		name = "droid-rifle",
		icon = "__base__/graphics/icons/player.png",
		flags = { "placeable-player", "player-creation", "placeable-off-grid" },
		subgroup = "creatures",
		order = "e-a-b-d",
		max_health = 40 * c.config.HEALTH_SCALAR,
		alert_when_damaged = false,
		healing_per_tick = 0.01, -- XXX upgraded this from 0 so that task-heal can work for everyone
		collision_box = { { -0.8*droidscale, -0.8*droidscale }, { 0.8*droidscale, 0.8*droidscale } },
		selection_box = { { -0.8*droidscale, -0.8*droidscale }, { 0.8*droidscale, 0.8*droidscale } },
		sticker_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		vision_distance = 30,
		movement_speed = 0.08,
		friendly_map_color = droidMapColour,
		minable = { hardness = 0.1, mining_time = 0.1, result = "droid-rifle" },
		pollution_to_join_attack = 0,
		distraction_cooldown = 0,
		distance_per_frame = 0.05,
		dying_explosion = "medium-explosion",
		resistances = {
			{
				type = "physical",
				decrease = 1,
				percent = 30
			},
			{
				type = "explosion",
				decrease = 5,
				percent = 50
			},
			{
				type = "acid",
				decrease = 1,
				percent = 25
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
			type = "projectile",
			ammo_category = "bullet",
			shell_particle = {
				name = "shell-particle",
				direction_deviation = 0.1,
				speed = 0.1,
				speed_deviation = 0.03,
				center = { 0, 0.1 },
				creation_distance = -0.5,
				starting_frame_speed = 0.4,
				starting_frame_speed_deviation = 0.1
			},
			cooldown = 120,
			projectile_center = { -0.6, 1 },
			projectile_creation_distance = 0.8,
			range = 15,
			sound = make_rifle_gunshot_sounds(),
			animation = {
				filename = "__robotarmy__/graphics/entity/rifle_idle.png",
				priority = "high",
				scale = droidscale,
				width = 80,
				height = 80,
				tint = droidRifleTint,
				direction_count = 8,
				frame_count = 1,
				animation_speed = 0.3,
				shift = { 0, 0 }
			},
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
								damage = { amount = 10 * c.config.DAMAGE_SCALAR , type = "physical" }
							}
						}
					}
				}
			}
		},
		idle = {
			filename = "__robotarmy__/graphics/entity/rifle_run.png",
			priority = "high",
			width = 80,
			height = 80,
			scale = droidscale,
			tint = droidRifleTint,
			direction_count = 22,
			frame_count = 1,
			animation_speed = 0.3,
			shift = { 0, 0 }
		},
		run_animation = {
			filename = "__robotarmy__/graphics/entity/rifle_run.png",
			priority = "high",
			width = 80,
			height = 80,
			tint = droidRifleTint,
			direction_count = 22,
			scale = droidscale,
			frame_count = 1,
			animation_speed = 0.3,
			shift = { 0, 0 }
		},
	},
}
