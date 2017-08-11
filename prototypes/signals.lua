
_G.data:extend(
{
	{
		type = "item-subgroup",
		name = "virtual-signal-robotarmy-squadids",
		group = "droids",
		order = "a",
	},
	{
		type = "item-subgroup",
		name = "virtual-signal-robotarmy-settings",
		group = "droids",
		order = "b",
	},
	{
		type = "item-subgroup",
		name = "virtual-signal-robotarmy-output",
		group = "droids",
		order = "c",
	},
	{
		type = "virtual-signal",
		name = "signal-squadid-player",
		icon = "__robotarmy__/graphics/icons/yoursquad.png",
		subgroup = "virtual-signal-robotarmy-squadids",
		order = "a-squadid-a"
	},
	{
		type = "virtual-signal",
		name = "signal-order-hunt",
		icon = "__robotarmy__/graphics/icons/order-hunt.png",
		subgroup = "virtual-signal-robotarmy-settings",
		order = "b-settings-1"
	},
	{
		type = "virtual-signal",
		name = "signal-order-guard",
		icon = "__robotarmy__/graphics/icons/order-guard.png",
		subgroup = "virtual-signal-robotarmy-settings",
		order = "b-settings-2"
	},
	{
		type = "virtual-signal",
		name = "signal-hunt-radius",
		icon = "__robotarmy__/graphics/icons/signal_hunt_radius.png",
		subgroup = "virtual-signal-robotarmy-settings",
		order = "b-settings-3"
	},
	{
		type = "virtual-signal",
		name = "signal-retreat-size",
		icon = "__robotarmy__/graphics/icons/signal_retreat_size.png",
		subgroup = "virtual-signal-robotarmy-settings",
		order = "b-settings-4"
	},
	{
		type = "virtual-signal",
		name = "signal-squad-size",
		icon = "__robotarmy__/graphics/icons/signal_squad_size.png",
		subgroup = "virtual-signal-robotarmy-settings",
		order = "b-settings-5"
	},
})
