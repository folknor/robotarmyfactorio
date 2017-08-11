do
	local data = _G.data

	local counter = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
	counter.name = "droid-counter"
	counter.icon = "__robotarmy__/graphics/icons/droid-counter.png"
	counter.minable.result = "droid-counter"
	counter.item_slot_count = 20
	counter.sprites = {
		north = {
			filename = "__robotarmy__/graphics/entity/droid-counter.png",
			width = 53,
			height = 44,
			frame_count = 1,
			shift = { 0.0, 0 },
		},
		east = {
			filename = "__robotarmy__/graphics/entity/droid-counter.png",
			width = 53,
			height = 44,
			frame_count = 1,
			shift = { 0.0, 0 },
		},
		south = {
			filename = "__robotarmy__/graphics/entity/droid-counter.png",
			width = 53,
			height = 44,
			frame_count = 1,
			shift = { 0.0, 0 },
		},
		west = {
			filename = "__robotarmy__/graphics/entity/droid-counter.png",
			width = 53,
			height = 44,
			frame_count = 1,
			shift = { 0.0, 0 },
		}
	}

	local droidSettings = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
	droidSettings.name = "droid-settings"
	droidSettings.icon = "__robotarmy__/graphics/icons/droid-settings.png"
	droidSettings.minable.result = "droid-settings"
	droidSettings.item_slot_count = 6
	droidSettings.sprites = {
		north = {
			filename = "__robotarmy__/graphics/entity/droid-settings.png",
			width = 53,
			height = 44,
			frame_count = 1,
			shift = { 0.0, 0 },
		},
		east = {
			filename = "__robotarmy__/graphics/entity/droid-settings.png",
			width = 53,
			height = 44,
			frame_count = 1,
			shift = { 0.0, 0 },
		},
		south = {
			filename = "__robotarmy__/graphics/entity/droid-settings.png",
			width = 53,
			height = 44,
			frame_count = 1,
			shift = { 0.0, 0 },
		},
		west = {
			filename = "__robotarmy__/graphics/entity/droid-settings.png",
			width = 53,
			height = 44,
			frame_count = 1,
			shift = { 0.0, 0 },
		}
	}

	local selectionSticker = {
		type = "sticker",
		name = "selection-sticker",
		flags = { "not-on-map" },
		icon = "__robotarmy__/graphics/icons/unit-selection.png",
		animation = {
			filename = "__robotarmy__/graphics/icons/unit-selection.png",
			priority = "extra-high",
			width = 32,
			height = 32,
			frame_count = 1,
			animation_speed = 1
		},
		duration_in_ticks = 3000 * 60,
		target_movement_modifier = 0.9999
	}

	local assembly = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
	assembly.name = "droid-assembling-machine"
	assembly.icon = "__robotarmy__/graphics/icons/droid-assembling-machine.png"
	assembly.minable.result = "droid-assembling-machine"
	assembly.fluid_boxes = {
		{
			production_type = "output",
			pipe_picture = _G.assembler2pipepictures(),
			pipe_covers = _G.pipecoverspictures(),
			base_area = 10,
			base_level = 1,
			pipe_connections = {{ type="output", position = {0, -2} }},
			--secondary_draw_orders = { north = -1 }
		},
		off_when_no_fluid_recipe = false
	}
	--assembly.fluid_boxes.off_when_no_fluid_recipe = false
	assembly.fast_replaceable_group = nil
	assembly.animation = {
		filename = "__robotarmy__/graphics/entity/droid-assembler.png",
		priority = "high",
		width = 111,
		height = 99,
		frame_count = 1,
		line_length = 1,
		shift = { 0.4, -0.06 }
	}
	assembly.crafting_categories = { "droids" }
	assembly.crafting_speed = 1
	assembly.energy_usage = "300kW"
	assembly.ingredient_count = 1
	assembly.result_inventory_size = 1

	local patrolPole = table.deepcopy(data.raw["electric-pole"]["small-electric-pole"])
	patrolPole.name = "patrol-pole"
	patrolPole.minable = { hardness = 0.2, mining_time = 3 } -- no result
	patrolPole.icon = "__robotarmy__/graphics/icons/guard-pole.png"
	patrolPole.maximum_wire_distance = 0
	patrolPole.supply_area_distance = 0
	patrolPole.track_coverage_during_build_by_moving = nil
	patrolPole.order = "z"
	patrolPole.pictures = {
		filename = "__robotarmy__/graphics/entity/rally-pole.png",
		priority = "extra-high",
		width = 120,
		height = 124,
		direction_count = 1,
		shift = {0.9, -1}
	}
	patrolPole.connection_points = {
		{
			shadow = {
				copper = {2.7, 0},
				red = {2.3, 0},
				green = {3.1, 0}
			},
			wire = {
				copper = {0, -2.7},
				red = {-0.375, -2.625},
				green = {0.40625, -2.625}
			}
		},
	}

	local plop = {
		type = "explosion",
		name = "pole-plop",
		flags = { "not-on-map" },
		animations = { {
			filename = "__base__/graphics/terrain/blank.png",
			priority = "low",
			width = 32,
			height = 128,
			frame_count = 1,
			line_length = 1,
			animation_speed = 1
		} },
		light = { intensity = 0, size = 0 },
		sound = { {
			filename = "__core__/sound/build-small.ogg",
			volume = 0.7
		} },
	}

	local guardPole = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
	guardPole.name = "guard-pole"
	guardPole.icon = "__robotarmy__/graphics/icons/guard-pole.png"
	guardPole.minable.result = "guard-pole"
	guardPole.max_health = 1000
	guardPole.item_slot_count = 1
	local sprite = {
		filename = "__robotarmy__/graphics/entity/guard-pole.png",
		width = 136,
		height = 122,
		shift = { 1.4, -1.0 }
	}
	guardPole.sprites.north = sprite
	guardPole.sprites.east = sprite
	guardPole.sprites.south = sprite
	guardPole.sprites.west = sprite
	local connection = {
		shadow = {
			copper = {2.55, 0.4},
			green = {2.0, 0.4},
			red = {3.05, 0.4}
		},
		wire = {
			copper = {-0.03125, -2.46875},
			green = {-0.34375, -2.46875},
			red = {0.25, -2.46875}
		}
	}
	guardPole.circuit_wire_connection_points = { connection, connection, connection, connection }
	guardPole.circuit_wire_max_distance = 10

	data:extend({ assembly, patrolPole, plop, guardPole, counter, droidSettings, selectionSticker })
end
