-- This file is only sourced if meta.DEBUG is true

do
	local data = _G.data
	local chest = table.deepcopy(data.raw.container["wooden-chest"])
	chest.name = "robotarmy-debug-chest"

	local item = table.deepcopy(data.raw.item["wooden-chest"])
	item.name = "robotarmy-debug-chest"
	item.place_result = "robotarmy-debug-chest"
	item.icons = {
		{ icon = item.icon },
		{ icon = "__robotarmy__/graphics/icons/terminator.png" },
	}
	item.icon = nil

	local recipe = table.deepcopy(data.raw.recipe["wooden-chest"])
	recipe.name = "robotarmy-debug-chest"
	recipe.result = "robotarmy-debug-chest"

	data:extend({chest, item, recipe})
end
