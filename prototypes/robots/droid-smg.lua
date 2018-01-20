local droidSmgTint = { r = 0.8, g = 1, b = 1, a = 1 }
local droidscale = 0.8
local droidMapColour = { r = .05, g = .70, b = .29 }

local c = require("meta")

local function make_heavy_shot_sounds()
	return {
		{
			filename = "__base__/sound/fight/heavy-gunshot-1.ogg",
			volume = 0.45
		},
		{
			filename = "__base__/sound/fight/heavy-gunshot-2.ogg",
			volume = 0.45
		},
		{
			filename = "__base__/sound/fight/heavy-gunshot-3.ogg",
			volume = 0.45
		},
		{
			filename = "__base__/sound/fight/heavy-gunshot-4.ogg",
			volume = 0.45
		}
	}
end
return {
	{
		type = "recipe",
		name = "droid-smg",
		enabled = false,
		category = "advanced-crafting",
		energy_required = c.classes["droid-smg"].craft,
		ingredients = {
			{ "steel-plate", 5 },
			{ "electronic-circuit", 15 },
			{ "submachine-gun", 1 },
			{ "light-armor", 1 }
		},
		result = "droid-smg"
	},
	{
		type = "unit",
		name = "droid-smg",
		icon = "__base__/graphics/icons/player.png",
		icon_size = 32,
		flags = { "placeable-player", "player-creation", "placeable-off-grid" },
		subgroup = "creatures",
		has_belt_immunity = true,
		order = "e-a-b-d",
		max_health = 120 * c.config.HEALTH_SCALAR,
		alert_when_damaged = false,
		healing_per_tick = 0.01,
		collision_box = { { -0.8*droidscale, -0.8*droidscale }, { 0.8*droidscale, 0.8*droidscale } },
		selection_box = { { -0.8*droidscale, -0.8*droidscale }, { 0.8, 0.8*droidscale } },
		sticker_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		vision_distance = 30,
		movement_speed = 0.11,
		minable = { hardness = 0.1, mining_time = 0.1, result = "droid-smg" },
		pollution_to_join_attack = 0,
		distraction_cooldown = 0,
		distance_per_frame = 0.05,
		friendly_map_color = droidMapColour,
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
				percent = 70
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
			cooldown = 20,
			projectile_center = { 0, 0.5 },
			projectile_creation_distance = 0.6,
			range = 13,
			sound = make_heavy_shot_sounds(1.0),
			animation = {
				filename = "__robotarmy__/graphics/entity/smg_idle.png",
				priority = "high",
				width = 80,
				height = 80,
				tint = droidSmgTint,
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
								damage = { amount = 8 * c.config.DAMAGE_SCALAR , type = "physical" }
							}
						}
					}
				}
			}
		},
		idle = {
			filename = "__robotarmy__/graphics/entity/smg_run.png",
			priority = "high",
			width = 80,
			height = 80,
			tint = droidSmgTint,
			direction_count = 22,
			frame_count = 1,
			animation_speed = 0.3,
			shift = { 0, 0 }
		},
		run_animation = {
			filename = "__robotarmy__/graphics/entity/smg_run.png",
			priority = "high",
			width = 80,
			height = 80,
			tint = droidSmgTint,
			direction_count = 22,
			frame_count = 1,
			animation_speed = 0.3,
			shift = { 0, 0 }
		},
	},
}
