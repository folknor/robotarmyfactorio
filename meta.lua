-- This file can only contain constant values, and must be usable
-- in the settings, data, and control stage.

-- values need to be unique
local settingKeys = {
	squadSize = "signal-squad-size",
	retreatSize = "signal-retreat-size",
	-- Setting huntradius to -1 in the droid settings causes the squad to hunt
	-- in a 10000 radius from their current position after every kill.
	-- Which is essentially forever.
	huntRadius = "signal-hunt-radius",
	orderHunt = "signal-order-hunt",
	orderGuard = "signal-order-guard",
	task = "fake-task-signal", -- There is no such signal, there is a signal per task type (guard/hunt)
}

local meta = {
	metatableDefaults = {
		availableNames = {
			{"robotarmy-squad-names.alpha"},
			{"robotarmy-squad-names.beta"},
			{"robotarmy-squad-names.gamma"},
			{"robotarmy-squad-names.delta"},
			{"robotarmy-squad-names.eta"},
			{"robotarmy-squad-names.theta"},
			{"robotarmy-squad-names.iota"},
			{"robotarmy-squad-names.kappa"},
			{"robotarmy-squad-names.lambda"},
			{"robotarmy-squad-names.rho"},
			{"robotarmy-squad-names.tau"},
			{"robotarmy-squad-names.omega"},
			{"robotarmy-squad-names.zeta"},
			{"robotarmy-squad-names.epsilon"},
			{"robotarmy-squad-names.sigma"},
			{"robotarmy-squad-names.omicron"},
		},
	},
	uiSprites = {},
	registeredSquadIds = {},
	squadIdSignals = {},
	-- Settings fall back to _squadSettingDefaults in getSquadSetting
	-- if a setting type is "nil".
	squadSettingDefaults = {
		[settingKeys.squadSize] = 30, -- XXX for testing
		[settingKeys.retreatSize] = 15, -- XXX for testing, too low
		[settingKeys.huntRadius] = 5000,
		[settingKeys.task] = "task-hunt",
		[settingKeys.orderHunt] = true,
		[settingKeys.orderGuard] = false,
	},
	useGroup = true, -- Set to false to not use LuaUnitGroups and instead give commands to each entity. Mostly for testing.
	DEBUG = true, -- Write to stdout (log()) ? If this is false, the options below do nothing.
	CONSOLEDEBUG = true, -- Write to ingame console (game.print) ?
	FILEDEBUG = false, -- Write to file? Note that a new file is created every load, so clean out the directory sometimes
	sSquadColors = "robotarmy-squad-colors",
	squadSignalFormat = "signal-squadid-%s",
	-- We use commandFormat/commandMatch for the button IDs, so that other addons that might use a button called "attack" wont
	-- fuck us over.
	commandFormat = "fake-droid-command-%s",
	commandMatch = "fake%-droid%-command%-(%S+)",
	settings = settingKeys,
	tasks = { -- Key here needs to match filename: mod/tasks/filename.lua
		hunt = "task-hunt",
		guard = "task-guard",
		idle = "task-idle",
		retreat = "task-retreat",
		active = "task-active",
		follow = "task-follow",
		trees = "task-trees",
		gather = "task-gather",
		patrol = "task-patrol",
		heal = "task-heal",
	},
	errors = {
		-- more of a status than "error"
		assembler = {"robotarmy-errors.error-no-assembler"},
		settings = {"robotarmy-errors.error-settings"},
		guardPoles = {"robotarmy-errors.error-guard"},
		noPlayer = {"robotarmy-errors.error-no-player"},
		retasking = {"robotarmy-errors.error-retasking"},
		notFull = {"robotarmy-errors.error-not-full"},
		gathering = {"robotarmy-errors.error-gathering"},
		command = {
			move = {"robotarmy-errors.error-commanded", {"robotarmy-command-names.move"} },
			stop = {"robotarmy-errors.error-commanded", {"robotarmy-command-names.stop"} },
			hold = {"robotarmy-errors.error-commanded", {"robotarmy-command-names.hold"} },
			patrol = {"robotarmy-errors.error-commanded", {"robotarmy-command-names.patrol"} },
			attack = {"robotarmy-errors.error-commanded", {"robotarmy-command-names.attack"} },
			follow = {"robotarmy-errors.error-commanded", {"robotarmy-command-names.follow"} },
			select = {"robotarmy-errors.error-commanded", {"robotarmy-command-names.select"} },
			transfer = {"robotarmy-errors.error-commanded", {"robotarmy-command-names.transfer"} },
		},
	},
	noUserString = "-",
	memberFormat = "%d/%d",
	colors = {
		white = {r=1, g=1, b=1},
		red = {r=1, g=0.2, b=0.3},
		green = {r=0.6, g=0.8, b=0.5},
	},
	-- If a commands entry has the same id= as a .tasks key (follow=follow), the command processing
	-- makes the script in addon/tasks/id.lua handle that command instead of addon/commands/id.lua
	-- So tasks with the same ID take precedence.
	-- IDs need to match filenames in commands/id.lua
	commands = { -- This is an array so that the entries will always be in the same order.
		{
			id = "move",
			icon = "__robotarmy__/graphics/commands/move.png",
			active = true, -- Active means that the squad is prevented from retasking for the set duration
			duration = 120,
		},
		{
			id = "stop",
			icon = "__robotarmy__/graphics/commands/stop.png",
			active = true,
			duration = 30,
		},
		{
			id = "hold",
			icon = "__robotarmy__/graphics/commands/hold.png",
			active = true,
			duration = 240,
		},
		{
			id = "patrol",
			icon = "__robotarmy__/graphics/commands/patrol.png",
			active = false,
			duration = false,
		},
		{
			id = "attack",
			icon = "__robotarmy__/graphics/commands/attack.png",
			active = true,
			duration = 120,
		},
		{
			id = "follow",
			icon = "__robotarmy__/graphics/commands/follow.png",
			active = false, -- This command is immediately reassigned to the follow task, so no processing
			duration = false,
		},
		{
			id = "select",
			icon = "__robotarmy__/graphics/commands/select.png",
			active = false,
			duration = false,
		},
		{
			id = "transfer",
			icon = "__robotarmy__/graphics/commands/transfer.png",
			active = false,
			duration = false,
		}
	},
	classArray = {"droid-rifle", "droid-rocket", "droid-smg", "droid-flame", "terminator", "defender-unit", "distractor-unit", "destroyer-unit"},
	-- XXX kyranzor: fix craft/deploy times
	classes = {
		["droid-rifle"] = {
			icon = "droid_rifle",
			tech = "military",
			deploy = 6,
			craft = 5,
			order = "droid[1]",
		},
		["droid-rocket"] = {
			icon = "droid_rocket",
			tech = "military-2",
			deploy = 6,
			craft = 10,
			order = "droid[2]",
		},
		["droid-smg"] = {
			icon = "droid_smg",
			tech = "military-2",
			deploy = 6,
			craft = 10,
			order = "droid[3]",
		},
		["droid-flame"] = {
			icon = "droid_flame",
			tech = "military-2",
			deploy = 6,
			craft = 10,
			order = "droid[4]",
		},
		terminator = {
			icon = "terminator",
			tech = "military-3",
			deploy = 10,
			craft = 10,
			order = "droid[5]",
		},
		["defender-unit"] = {
			icon = "defender",
			tech = "combat-robotics",
			deploy = 5,
			craft = 5,
			order = "droid[a]",
			flying = true,
		},
		["distractor-unit"] = {
			icon = "distractor",
			tech = "combat-robotics",
			deploy = 5,
			craft = 5,
			order = "droid[b]",
			flying = true,
		},
		["destroyer-unit"] = {
			icon = "destroyer",
			tech = "combat-robotics",
			deploy = 8,
			craft = 8,
			order = "droid[c]",
			flying = true,
		},
	},
	config = {
		-- Safe zone radius; squads will not stop to heal if they find any enemies within this radius
		HEAL_SAFE_RADIUS = 50,
		-- If any member in a squad drops below 15% HP while out of combat, the squad is forced to stop and heal.
		HEAL_UNIT_MINIMUM = 0.15,
		-- If all squad healths together average less than this, and it is not in combat, it is forced to stop and heal.
		HEAL_SQUAD_AVERAGE = 0.5,
		-- When squad health reaches this average, retask
		HEAL_STOP = 0.85,
		-- The default command used when the player uses the droid selection tool to click somewhere
		DEFAULT_COMMAND = "attack", -- Actually it's attack_area
		-- When the player uses the droid selection tool and clicks on an empty area,
		-- the closest squad within this distance gets selected.
		SQUAD_CHECK_RANGE = 20,
		-- squad:IsGathered() checks if any members are further away than (BUNCH_PER_MEMBER * #members) from the squad position
		BUNCH_PER_MEMBER = 1.8,
		-- When a squad is within this distance to the pole, they are "at" the pole.
		GUARD_VALIDATE_POLE_DISTANCE = 12,
		-- When a squad is idling at a patrol pole, they engage enemies within this distance.
		GUARD_ENGAGE_DISTANCE = 20,
		-- If a task wants to clear trees, it should build a list of trees within either #members*PER_MEMBER or MAX_RADIUS
		-- and send of to squad:Task(_meta.task.trees, treeArray)
		TREE_KILL_RADIUS_PER_MEMBER = 2,
		TREE_KILL_MAX_RADIUS = 16,
		-- Threshold is a bit weird. If the number of trees found within the computed radius from the above
		-- variables is above (given radius * 6), it means we should retask to killing trees.
		TREE_DENSITY_THRESHOLD = 6,
		-- While a squad is hunting, it gets commanded to attack_area in this radius
		HUNT_AREA_ATTACK_RADIUS = 40,
		-- After a squad is done killing its current target, find targets within this distance of the squad
		-- before scanning 5000 tile range from squad.home
		HUNT_CHAIN_RADIUS = 100,
		-- If the player sets the hunt radius to -1, droids will chain-hunt from their current position
		-- in this radius.
		HUNT_ROAM_RADIUS = 5000,
		-- If a squads .position is further away from the assembler than this, the assembler wont spawn anything.
		HOLD_SPAWNS_RANGE = 30,
		HEALTH_SCALAR = 1.0, -- scales health by this value, default 1.0. 0.5, gives 50% health, 2.0, doubles their health etc.
		DAMAGE_SCALAR = 1.0, -- scales base damage by this value. default is 1.0. 0.5, makes 50% less base damage.
							-- 1.5, gives 50% more base damage. remember, technologies apply multipliers to the base damage so this value should take
							-- that into consideration.
	},
}


-------------------------------------------------------------------------------
-- Parses the squad colors when control.lua is executed
--

do
	local function trim(s)
		local from = s:match"^%s*()"
		return from > #s and "" or s:match(".*%S", from)
	end
	local parse = require("util.parse")
	local defaults = "#1abc9c,#2ecc71,#3498db,#9b59b6,#34495e,#f1c40f,#e67e22,#e74c3c,#ecf0f1,#95a5a6"
	local colors = trim(settings.startup[meta.sSquadColors].value)
	if type(colors) ~= "string" or colors:len() == 0 then colors = defaults end
	local squads = parse.readString(colors)
	if #squads == 0 then squads = parse.readString(defaults) end
	for _, c in next, squads do
		meta.uiSprites[c.name] = string.format("recipe/%s-droid-flame-deploy", c.name)
		c.color.a = nil -- We use the color in the interface, set the alpha to full
		meta.registeredSquadIds[c.name] = c.color
		meta.squadIdSignals[meta.squadSignalFormat:format(c.name)] = c.name
	end
	meta.uiSprites["squadid-player"] = "virtual-signal/signal-squadid-player"
	meta.registeredSquadIds["squadid-player"] = meta.colors.white
	meta.squadIdSignals["signal-squadid-player"] = true
end

return meta
