_G.data:extend({
	{
		type = "recipe",
		name = "droid-assembling-machine",
		enabled = false,
		ingredients = {
			{ "iron-plate", 10 },
			{ "electronic-circuit", 50 },
			{ "iron-gear-wheel", 50 },
			{ "assembling-machine-1", 1 }
		},
		result = "droid-assembling-machine"
	},
	{
		type = "recipe",
		name = "droid-counter",
		enabled = false,
		ingredients = {
			{ "constant-combinator", 1 },
			{ "iron-plate", 20 },
			{ "electronic-circuit", 25 },
		},
		result = "droid-counter",
	},
	{
		type = "recipe",
		name = "droid-settings",
		enabled = false,
		ingredients = {
			{ "constant-combinator", 1 },
			{ "iron-plate", 20 },
			{ "electronic-circuit", 25 },
		},
		result = "droid-settings",
	},
	{
		type = "recipe",
		name = "droid-selection-tool",
		enabled = true,
		ingredients = {
			{ "electronic-circuit", 1 }
		},
		result = "droid-selection-tool",
		requester_paste_multiplier = 1
	},
	{
		type = "recipe",
		name = "droid-pickup-tool",
		enabled = true,
		ingredients = {
			{ "electronic-circuit", 1 }
		},
		result = "droid-pickup-tool",
		requester_paste_multiplier = 1
	},
	{
		type = "recipe",
		name = "guard-pole",
		enabled = false,
		ingredients = {
			{ "steel-plate", 5 },
			{ "electronic-circuit", 5 },
		},
		result = "guard-pole",
		requester_paste_multiplier = 4
	},
})
