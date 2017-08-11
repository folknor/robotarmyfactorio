-- Simply load these before anything else, to put their APIs in the global scope.
require("gui")
require("commands")

-------------------------------------------------------------------------------
-- Upvalues
--

local _meta = require("meta")
local _log = require("util.logger")
local _util = require("util.utility")

-- Just silence luacheckrc

-- Upvalue API from gui
local InitializeGUI = _G.InitializeGUI
local UpdateCommandFrame = _G.UpdateCommandFrame
local UpdateSquadButtons = _G.UpdateSquadButtons

-- Upvalue API from commands
--local SelectSquad = _G.SelectSquad -- not used in control
-- _G.RemoveSquadStickers(squad)
-- _G.DeselectSquads(player)

-- This file (control.lua) provides:
-- _G.GetSquad(forceName, squadId, force)
-- _G.GetTaskProcessor(_meta.tasks.task)

local assert, pairs, tremove, tinsert, type, random = assert, pairs, table.remove, table.insert, type, math.random

-------------------------------------------------------------------------------
-- Load all task processors
--

-- Direct access to task:Process, just for control.lua
local processShortHand = {}
do
	local processSquad = {}
	local taskFile = "tasks.%s"
	for task, id in pairs(_meta.tasks) do
		local path = taskFile:format(tostring(task))
		local processor = require(path)
		assert(type(processor) == "table", ("Invalid task %q"):format(path))
		assert(type(processor.process) == "function", ("Invalid task %q"):format(path))
		assert(type(processor.shouldRetask) == "function", ("Invalid task %q"):format(path))
		assert(type(processor.shouldReinforce) == "function", ("Invalid task %q"):format(path))
		processSquad[id] = processor
		processShortHand[id] = processor.process
		_log.log(_log.TASK_PROCESSOR:format(path, id))
	end
	_G.GetTaskProcessor = function(task)
		return processSquad[task]
	end
end

-------------------------------------------------------------------------------
-- Squad
-- Please see squad.lua for docs.
--

local getSquad, doSquadInjects

do
	local squadMeta = require("squad")
	local unique = require("util.names")

	doSquadInjects = function()
		if global.squads then
			for _, squad in next, global.squads do
				setmetatable(squad, squadMeta)
			end
		end
	end

	local _ASSERT_SQUAD_ID = "Invalid squad ID [%q] given to getSquad."
	local _ASSERT_FORCENAME = "Force name [%q] needs to be a string."

	getSquad = function(forceName, squadId, dontCreate)
		assert(type(forceName) == "string", _ASSERT_FORCENAME:format(tostring(forceName)))
		assert(_meta.registeredSquadIds[squadId] or type(squadId) == "number", _ASSERT_SQUAD_ID:format(tostring(squadId)))
		for i = 1, #global.squads do
			local s = global.squads[i]
			if forceName == s.force and squadId == s.id then return s end
		end
		if dontCreate then return end
		local n = setmetatable({
			force = forceName,
			id = squadId,
			members = {},
			task = _meta.tasks.idle,
			name = unique(forceName, squadId),
		}, squadMeta)
		tinsert(global.squads, n)
		_log(n, _log.CREATING_SQUAD)
		return n, true
	end

	local function findSquad(unitNumber)
		-- Find the squad this unit belongs to
		for k = 1, #global.squads do
			local squad = global.squads[k]
			for i = 1, #squad do
				local m = squad(i)
				if m.valid and m.unit_number == unitNumber then
					return squad, i
				end
			end
		end
	end

	_G.GetSquadFromUnitNumber = findSquad
	_G.GetSquad = getSquad
end

-------------------------------------------------------------------------------
-- Settings
--

local _settingsToSquadIdMap = {}


-- I have compared
-- 1. get_or_create_control_behavior().parameters.parameters, looping with #parameters
-- 2. get_control_behavior(), cc.get_signal(i)
-- over thousands of iterations
-- And there is essentially no difference, which is strange. I think my test was
-- suboptimal. Still, it's enough to convince me not to spend more time on it.

local function processDroidSetting(entity)
	local cc = entity.get_control_behavior()
	if not cc or not cc.valid then return end
	local squadId
	for i = 1, cc.signals_count do
		local p = cc.get_signal(i)
		if p and p.signal and p.signal.name and _meta.squadIdSignals[p.signal.name] then
			-- this is the squadId signal
			squadId = _meta.squadIdSignals[p.signal.name]
			break
		end
	end
	-- This droid settings module does not apply its settings to any squad IDs
	if not squadId then return end
	-- This means the signal used is signal-squadid-player, so we apply these settings to
	-- the player who built the entity
	if type(squadId) == "boolean" then squadId = entity.last_user.index end
	if not squadId then return end

	_settingsToSquadIdMap[entity.unit_number] = squadId

	local squad = getSquad(entity.force.name, squadId, true) -- dont create a squad reference
	if not squad then return end

	for i = 1, cc.signals_count do
		local p = cc.get_signal(i)
		if p and p.signal then
			local n = p.signal.name
			if n == _meta.settings.squadSize then
				squad:Set(_meta.settings.squadSize, p.count)
			elseif n == _meta.settings.retreatSize then
				squad:Set(_meta.settings.retreatSize, p.count)
			elseif n == _meta.settings.huntRadius then
				squad:Set(_meta.settings.huntRadius, p.count)
			elseif n == _meta.settings.orderGuard then
				squad:Set(_meta.settings.task, _meta.tasks.guard)
			elseif n == _meta.settings.orderHunt then
				squad:Set(_meta.settings.task, _meta.tasks.hunt)
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Droid Data Module
--

local processDroidCounter
do
	local playerSignal = "signal-squadid-player"
	local squadSignal = setmetatable({}, {
		__index = function(self, k)
			local ret
			if type(k) == "number" then ret = playerSignal
			else ret = _meta.squadSignalFormat:format(k) end
			rawset(self, k, ret)
			return ret
		end
	})
	local p = {
		parameters = {
			{ index = 1, count = 1, signal = { type = "virtual" } }, -- Squad ID
			{ index = 2, count = 0, signal = { type = "virtual", name = "signal-T" } }, -- Total count
		}
	}
	local _COUNT_SIGNAL = "signal-droid-count-%s"
	for _, droid in next, _meta.classArray do
		tinsert(p.parameters, { index = #p.parameters + 1, count = 0, signal = { type = "virtual", name = _COUNT_SIGNAL:format(droid) } })
	end
	processDroidCounter = function(activity, ini)
		local squadId = _settingsToSquadIdMap[ini]
		if not squadId then return end
		local squad = getSquad(activity.force.name, squadId, true)
		local c = p.parameters
		c[1].signal.name = squadSignal[squadId]
		if squad then
			c[2].count = #squad
			local counts = {}
			for i = 1, #squad do
				local m = squad(i)
				if m.valid then counts[m.name] = (counts[m.name] or 0) + 1 end
			end
			for i = 1, #_meta.classArray do
				c[i+2].count = counts[_meta.classArray[i]] or 0
			end
		else
			c[2].count = 0
			for i = 1, #_meta.classArray do
				c[i+2].count = 0
			end
		end
		activity.get_or_create_control_behavior().parameters = p
	end
end

-------------------------------------------------------------------------------
-- Assembler/player using capsule handling
--

local idleWander = {
	type = defines.command.compound,
	structure_type = defines.compound_command.return_last,
	commands = {
		{ type = defines.command.go_to_location },
		{ type = defines.command.wander }
	}
}

-- 3rd unused argument is player
local function processSpawnedDroid(entity, squadId)
	local squad = getSquad(entity.force.name, squadId)
	local added = squad + entity
	if not added then return end

	-- squad.position is where the squad wants to end up,
	-- so newly spawned droids can just go there.
	idleWander.commands[1].destination = squad.position
	squad:Order(idleWander)
end

local function processAssembler(assembler)
	if not assembler.recipe or assembler.products_finished == 0 then return end
	local inv = assembler.get_output_inventory()
	if not inv or not inv.valid then
		return _util.throttledMessage(assembler.force, "robotarmy-errors.assembler-error-inventory")
	end
	if inv.is_empty() then return end -- This is the most used return statement, so make sure we get here fast
	-- ZZZ should test what's faster; inv.is_empty() or (inv[1] and inv[1].valid), for example

	local squadId = assembler.recipe.name:match("^(%w+)%-")
	if type(squadId) ~= "string" then return _util.throttledMessage(assembler.force, "robotarmy-errors.assembler-error-recipe", tostring(assembler.recipe.name)) end

	-- First, check if we have enough members alive in the squad already, in which case we just return
	local squad = getSquad(assembler.force.name, squadId)
	if squad:IsFull() then return 10 end

	local item = inv[1] -- our assemblers only have 1 output slot, so this should be safe (tm)
	if not item or not item.valid then
		return _util.throttledMessage(assembler.force, "robotarmy-errors.assembler-error-item")
	end
	local droidName = item.name:match("(.*)%-%w")
	if not droidName or not _meta.classes[droidName] then
		return _util.throttledMessage(assembler.force, "robotarmy-errors.assembler-error-not-droid", tostring(item.name))
	end

	local destination = _util.assemblerPosition(assembler)
	if type(destination) ~= "table" then
		return _util.throttledMessage(assembler.force, "robotarmy-errors.assembler-error-no-position")
	end

	-- Always set the position for newly created squads
	if not squad.position then squad.position = destination end

	-- Check if the squad wants reinforcements at the location we provide
	local spawn = squad:ShouldReinforce(destination)
	if not spawn then return 5 end

	local ent = assembler.surface.create_entity({
		name = droidName,
		position = destination,
		force = assembler.force,
	})
	if not ent or not ent.valid then
		return _util.throttledMessage(assembler.force, "robotarmy-errors.assembler-error-create-entity", tostring(droidName))
	end
	inv.clear()

	processSpawnedDroid(ent, squadId)
end

-------------------------------------------------------------------------------
-- Debug chests
-- Should contain all robot-army items
--
local processDebugChest
if _meta.DEBUG then
	local items = {
		["droid-assembling-machine"] = 50,
		["droid-counter"] = 50,
		["droid-settings"] = 50,
		["guard-pole"] = 50,
		["droid-selection-tool"] = 1,
		["droid-pickup-tool"] = 1,
	}
	for droid in pairs(_meta.classes) do items[droid] = 50 end
	local cache = {}
	local itemStackCache = setmetatable({}, {
		__index = cache,
		__newindex = function(_, key, value)
			if cache[key] then cache[key].count = value
			else cache[key] = { name = key, count = value }
			end
		end
	})
	processDebugChest = function(chest)
		local inv = chest.get_inventory(defines.inventory.chest)
		if not inv or not inv.valid then return end
		for item, count in pairs(items) do
			local missing = count - inv.get_item_count(item)
			if missing > 0 then
				itemStackCache[item] = missing
				inv.insert(itemStackCache[item])
			end
		end
	end
else
	processDebugChest = function() end
end

-------------------------------------------------------------------------------
-- Tick
--

do
	local throttle = {}

	local function usingPatrolPole(unitNumber)
		for k = 1, #global.squads do
			local s = global.squads[k]
			if s.task == _meta.tasks.patrol then
				for z = #s.taskData, 1, -1 do
					local p = s.taskData[z]
					if p.valid and p.unit_number == unitNumber then
						return true
					end
				end
			end
		end
	end

	-- yes, yes, I know that table.remove screws with the iteration,
	-- but we do it 3 times per second, so #care
	local function tick(event)
		local t = event.tick

		-- process settings every 10 seconds
		if t % 600 == 0 then
			-- XXX We should try and process this more on-demand
			for i = #global.settings, 1, -1 do
				local e = global.settings[i]
				if e and e.valid then processDroidSetting(e)
				else tremove(global.settings, i) end
			end

			-- Clean up unused patrol poles
			for i = #global.patrolPoles, 1, -1 do
				local pole = global.patrolPoles[i]
				if pole and pole.valid then
					-- Make sure some squad is still patrolling, and using this pole
					if not usingPatrolPole(pole.unit_number) then
						pole.destroy()
						tremove(global.patrolPoles, i)
					end
				else
					tremove(global.patrolPoles, i)
				end
			end
		end

		-- process assemblers and activity modules every second
		if t % 60 == 0 then
			for _, pair in next, global.counters do
				local a = pair.activity
				if not a.valid then
					tremove(global.counters, _)
				else
					processDroidCounter(a, pair.settings)
				end
			end
			for i = #global.assemblers, 1, -1 do
				local e = global.assemblers[i]
				if not throttle[e] or t > throttle[e] then
					if e and e.valid then
						local w = processAssembler(e)
						if w then throttle[e] = t + (w * 60)
						else throttle[e] = nil end
					else tremove(global.assemblers, i) end
				end
			end
			for i = #global.debugChests, 1, -1 do
				local e = global.debugChests[i]
				if e and e.valid then
					processDebugChest(e)
				else tremove(global.debugChests, i) end
			end
		end

		-- process squad table every half second
		if t % 30 == 0 then
			for i = 1, #global.squads do
				local squad = global.squads[i]
				if (not squad.wait or (t > squad.wait)) then
					if #squad == 0 then
						if squad.task ~= _meta.tasks.idle then
							squad.position = squad.home
							squad:Task(_meta.tasks.idle)
						end
					else
						if game.forces[squad.force] and not game.forces[squad.force].is_pathfinder_busy() then
							squad:Validate()
							--local still = squad:StandingStill()
							local newTask, newData = squad:GetIdealTask()
							if not newTask then
								local w, e = processShortHand[squad.task](squad)
								squad.error = e
								squad.wait = t + ((w or 1) * 60) + random(1, 45)
							else
								squad:Task(newTask, newData)
							end
						end
					end
				end
			end
		end

		-- update visible UIs every 2 seconds
		if t % 120 == 0 then
			for _, p in pairs(game.players) do
				if p.valid and p.connected then
					UpdateCommandFrame(p, nil, true)
					UpdateSquadButtons(p)
				end
			end
		end
	end
	script.on_event(defines.events.on_tick, tick)
end

-------------------------------------------------------------------------------
-- Built
--

do
	local counterError = {"robotarmy-errors.counter-error"}
	local tooManyError = {"robotarmy-errors.droid-counter-too-many"}
	local function findSettingsModule(cc)
		local droidSettings = cc.surface.find_entities_filtered({
			area = { { cc.position.x - 1, cc.position.y - 1 }, { cc.position.x + 1, cc.position.y + 1 } },
			name = "droid-settings",
			force = cc.force,
		})
		if type(droidSettings) ~= "table" or #droidSettings == 0 then
			cc.force.print(counterError)
		elseif #droidSettings ~= 1 then
			cc.force.print(tooManyError)
		end
		return droidSettings[1]
	end

	local function onBuilt(event)
		local entity = event.created_entity
		if entity.type == "unit" and _meta.classes[entity.name] then
			processSpawnedDroid(entity, event.player_index, game.players[event.player_index])
		elseif entity.name == "droid-assembling-machine" then
			-- XXX you cant rotate an assembler after placing it, this
			-- XXX saves lots of processing when we deploy a droid, calculating
			-- XXX all those positions. Players can simply pick them and re-place them
			-- XXX if they want to rotate anyway.
			entity.rotatable = false
			tinsert(global.assemblers, entity)
		elseif entity.name == "droid-counter" then
			entity.operable = false
			local partner = findSettingsModule(entity)
			if not partner then return end
			tinsert(global.counters, { activity = entity, settings = partner.unit_number })
		elseif entity.name == "droid-settings" then
			tinsert(global.settings, entity)
			entity.rotatable = false
		elseif entity.name == "guard-pole" then
			tinsert(global.guardPoles, entity)
		elseif entity.name == "robotarmy-debug-chest" then
			tinsert(global.debugChests, entity)
		end
	end

	script.on_event(defines.events.on_built_entity, onBuilt)
	script.on_event(defines.events.on_robot_built_entity, onBuilt)
end

-------------------------------------------------------------------------------
-- Track valid robot removals
--

do
	-- A squad member has legitimately died or been mined
	local function validDroidRemoval(event)
		if not event or not event.entity then return end
		if event.entity.type ~= "unit" or not _meta.classes[event.entity.name] then return end
		local squad, index = _G.GetSquadFromUnitNumber(event.entity.unit_number)
		if not squad then return end
		table.remove(squad.members, index)
		squad:Validate()
	end
	script.on_event(defines.events.on_player_mined_entity, validDroidRemoval)
	script.on_event(defines.events.on_entity_died, validDroidRemoval)
end

-------------------------------------------------------------------------------
-- Init
--

do
	local function autoIndex(self, key)
		local mt = getmetatable(self)
		local r
		if mt.defaults then r = _util.deepcopy(_meta.metatableDefaults[mt.defaults]) else r = {} end
		if mt.depth then setmetatable(r, { __index = mt.__index }) end
		self[key] = r
		return r
	end

	-- Since on_load triggers BEFORE on_configuration_changed, it's
	-- important to note that if you add another table that requires metatables,
	-- it wont necessarily exist at this point.
	local function applyGlobalMetas()
		if global.squadSettings then
			setmetatable(global.squadSettings, {__index = autoIndex, depth = true})
			for _, v in pairs(global.squadSettings) do setmetatable(v, { __index = autoIndex }) end
		end
		if global.availableNames then setmetatable(global.availableNames, {__index = autoIndex, defaults = "availableNames"}) end
		if global.assignedNames then setmetatable(global.assignedNames, {__index = autoIndex}) end
	end

	-- IF YOU CHANGE GLOBALS, LOOK BELOW AT on_configuration_changed
	local function initializeGlobals()
		-- arrays of entities
		global.assemblers = global.assemblers or {}
		global.counters = global.counters or {}
		global.settings = global.settings or {}
		global.guardPoles = global.guardPoles or {}
		global.patrolPoles = global.patrolPoles or {}
		global.debugChests = global.debugChests or {}

		-- key: player index, value: frameid
		global.commandOpen = global.commandOpen or {}
		-- key: player index, value = map of squad IDs (strings/number) to boolean:true
		global.selectedSquads = global.selectedSquads or {}

		-- key: force name, value = map of squad id : squad settings table
		global.squadSettings = global.squadSettings or {}

		-- util/names.lua
		global.availableNames = global.availableNames or {}
		global.assignedNames = global.assignedNames or {}

		-- used for recreating vanished units
		-- key: luaentity squad member, value: droid type
		global.entityUnitNameMap = global.entityUnitNameMap or {}

		-- array of squadmeta, please never access the table directly unless you are sure about what you are doing
		global.squads = global.squads or {}

		-- Set up metatables on globals
		applyGlobalMetas()
	end

	-- on_load triggers BEFORE on_configuration_changed
	script.on_load(function()
		-- Set up metatables on all squad objects
		doSquadInjects()
		-- Set up metatables on globals
		applyGlobalMetas()
	end)

	script.on_event(defines.events.on_player_created, function(event)
		InitializeGUI(game.players[event.player_index])
	end)

	local function getValidSquad()
		for id in pairs(_meta.registeredSquadIds) do
			if id ~= "squadid-player" then return id end
		end
	end

	-- remove one at a time so that we're certain to keep the integrity of the squads table
	local function removeFirstInvalidSquad()
		local transferTo = getValidSquad()
		for _, squad in next, global.squads do
			if type(squad.id) ~= "number" and not _meta.registeredSquadIds[squad.id] then
				squad:Transfer(transferTo)
				game.print("Destroying squad " .. tostring(squad.id) .. " because it no longer exists in the squad color setting.")
				squad:Destroy()
				return true
			end
		end
		return false
	end

	local _CURRENT_VERSION = 4

	local upgraders = {}
	-- There is no upgrade from version 1 to 2.
	for i = 2, (_CURRENT_VERSION - 1) do upgraders[i] = require("upgraders." .. i) end

	--
	-- If you change globals that require a migration, you can simply:
	-- 1. Add a new file in upgraders/X.lua where X=_CURRENT_VERSION
	-- 2. The file should return a single function that returns a single number that is (_CURRENT_VERSION + 1)
	-- 3. Increase _CURRENT_VERSION by 1.
	-- (so the function should return a number that is 1 higher than its filename, i.e.
	-- 1.lua returns 2, 2.lua returns 3, and so forth - and _CURRENT_VERSION should be same
	-- as the return value of the highest one)
	--
	-- Remember that this goes if you change a tasks .taskData structure as well,
	-- because there might be squads engaged in that task on game load.
	--
	-- Note that you can't require() files in upgrader-scripts.
	-- The function is given _meta, _util and _log as arguments.
	--
	script.on_configuration_changed(function()
		-- on_conf_changed also triggers when settings.lua startup settings are changed by the player
		if type(global.squads) == "table" and #global.squads ~= 0 then
			-- we actually need to iterate through all squads and check which ones still map
			-- to the settings.lua squad colors, because the setting can be changed between loads
			local removed
			repeat
				removed = removeFirstInvalidSquad()
			until not removed
		end

		if not global.version or global.version <= 1 then
			_log.log(_log.UPDATING_ROBOTARMY_DATA:format(1, 0))
			-- Nuke all previous robotarmy variables (pre-folk)
			for k in pairs(global) do global[k] = nil end
			initializeGlobals()
			global.version = 1
		end
		while global.version < _CURRENT_VERSION do
			if upgraders[global.version] then
				local newVersion = upgraders[global.version](_meta, _util, _log)
				_log.log(_log.UPDATING_ROBOTARMY_DATA:format(newVersion, global.version))
				global.version = newVersion
			else
				global.version = global.version + 1
			end
		end

		-- Most of the configuration changes in the UI should be handled in gui.lua:InitializeGUI
		for _, p in pairs(game.players) do
			if p.valid then
				InitializeGUI(p)
			end
		end
	end)

	script.on_init(function()
		initializeGlobals()
		global.version = _CURRENT_VERSION
	end)
end


