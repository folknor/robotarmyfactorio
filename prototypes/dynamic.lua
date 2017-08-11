do
	local m = require("meta")
	local _SIGNAL_ORDER = "a-squadid-b-%s"
	local _COUNT_ORDER = "c-count-3-%s"
	local _COUNT_SIGNAL = "signal-droid-count-%s"

	local _LOCALE = "entity-name.%s"
	local _DESC = "entity-description.%s"

	local _RECIPE = "%s-%s-deploy"
	local _ICON = "__robotarmy__/graphics/icons/%s.png"
	local _TINT = "__robotarmy__/graphics/icons/template_undep.png"
	local _DUMMY = "%s-dummy"
	local data = _G.data

	local quickbar = { "goes-to-quickbar" }
	local hidden = { "hidden" }
	for droid, droidInfo in pairs(m.classes) do
		local d = require("prototypes.robots." .. droid)
		if not d then print("Missing droid data for " .. droid) break end
		-- d contains the entity and the real recipe for making the undeployed version
		table.insert(d, {
			type = "virtual-signal",
			name = _COUNT_SIGNAL:format(droid),
			localised_name = { "virtual-signal-name.signal-droid-count", { _LOCALE:format(droid) } },
			icons = {
				{ icon = "__base__/graphics/icons/signal/shape_square.png" },
				{ icon = _ICON:format(droidInfo.icon) },
				{ icon = "__robotarmy__/graphics/icons/count.png" },
			},
			subgroup = "virtual-signal-robotarmy-output",
			order = _COUNT_ORDER:format(droidInfo.order),
		})
		table.insert(d, {
			type = "item",
			name = droid,
			localised_name = { _LOCALE:format(droid) },
			localised_description = { "item-description.droid-item-description", { _DESC:format(droid) } },
			icon = _ICON:format(droidInfo.icon),
			flags = quickbar,
			order = droidInfo.order,
			subgroup = "droid-combat-group",
			place_result = droid,
			stack_size = 50,
		})
		table.insert(d, {
			type = "item",
			name = _DUMMY:format(droid),
			localised_name = { "item-name.droid-dummy-item", { _LOCALE:format(droid) } },
			localised_description = { "item-description.droid-dummy-item" },
			icons = {
				{ icon = _ICON:format(droidInfo.icon) },
				{ icon = "__robotarmy__/graphics/icons/warning.png" },
			},
			flags = hidden,
			order = droidInfo.order,
			subgroup = "droid-combat-group",
			-- this is the item that the assembler produces, which the player "should not" pick up
			-- XXX kyranzor
			-- in robotarmy pre-0.4 place_result was "", so the player could not place it manually, but why?
			-- it works, but the problem is that when you place it, the item is not
			-- removed from the players inventory - I have no idea why
			-- Maybe an alternative is to make a recycling recipe for these items?
			place_result = droid,
			stack_size = 1,
		})
		table.insert(d, {
			type = "item-subgroup",
			name = droid,
			order = droidInfo.order,
			group = "droids",
		})
		data:extend(d)
		if data.raw.technology[droidInfo.tech] then
			table.insert(data.raw.technology[droidInfo.tech].effects, {
				type = "unlock-recipe",
				recipe = droid,
			})
		end
	end

	local function trim(s)
		local from = s:match"^%s*()"
		return from > #s and "" or s:match(".*%S", from)
	end
	local p = require("util.parse")
	local defaults = "#1abc9c,#2ecc71,#3498db,#9b59b6,#34495e,#f1c40f,#e67e22,#e74c3c,#ecf0f1,#95a5a6"
	local colors = trim(settings.startup[m.sSquadColors].value)
	if type(colors) ~= "string" or colors:len() == 0 then colors = defaults end
	local squads = p.readString(colors)
	if #squads == 0 then squads = p.readString(defaults) end

	local addthis = { }
	for _, c in next, squads do
		local color = c.color
		table.insert(addthis, {
			type = "virtual-signal",
			name = m.squadSignalFormat:format(c.name),
			localised_name = { "virtual-signal-name.signal-squadid-color" },
			icons = {
				{ icon = "__robotarmy__/graphics/icons/base.png" },
				{ icon = _TINT, tint = color },
				{ icon = "__robotarmy__/graphics/icons/squad.png" },
			},
			subgroup = "virtual-signal-robotarmy-squadids",
			order = _SIGNAL_ORDER:format(c.name)
		})
		for droid in pairs(m.classes) do
			table.insert(addthis, {
				type = "recipe",
				name = _RECIPE:format(c.name, droid),
				localised_name = { _LOCALE:format(droid) },
				icons = {
					{ icon = _TINT, tint = color },
					{ icon = _ICON:format(m.classes[droid].icon) },
				},
				category = "droids",
				subgroup = droid,
				energy_required = m.classes[droid].deploy,
				ingredients = { { droid, 1 } },
				result = _DUMMY:format(droid),
			})
		end
	end

	-- COMMANDS
	local ingredients = { {"coal", 42} }
	for _, d in next, m.commands do
		table.insert(addthis, {
			type = "recipe",
			name = m.commandFormat:format(d.id),
			icon = d.icon,
			enabled = false,
			hidden = true,
			energy_required = 300,
			ingredients = ingredients,
			result = "iron-plate",
		})
	end

	data:extend(addthis)
end
