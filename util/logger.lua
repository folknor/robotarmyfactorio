--
--
-- If DEBUG is off, logger.lua does nothing. So if you want to print a message to a player, force,
-- or everyone, you need to use player.print/force.print/game.print.
--
--
local _meta = require("meta")
local DEBUG = _meta.DEBUG
local CONSOLE = _meta.CONSOLEDEBUG
local FILE = _meta.FILEDEBUG

-------------------------------------------------------------------------------
-- Debug
--
-- CUSTOM REPLACEMENTS IN STRINGS:
-- [command] = commandDescriptions based on squad.lastCommand.type, or "-"
-- [state] = stateDescriptions based on squad.group.state, or "-"
-- members, groupsize, id, task, force
local stateDescriptions = {
	[defines.group_state.gathering] = "G",
	[defines.group_state.moving] = "M",
	[defines.group_state.attacking_distraction] = "AD",
	[defines.group_state.attacking_target] = "AT",
	[defines.group_state.finished] = "F",
}
local commandDescriptions = {
	[defines.command.attack] = "A",
	[defines.command.go_to_location] = "GTL",
	[defines.command.compound] = "C",
	[defines.command.group] = "G",
	[defines.command.attack_area] = "AA",
	[defines.command.wander] = "W",
	[defines.command.build_base] = "BB"
}
-- GTFO if not debug and just noop the __call and __index
if not DEBUG then return setmetatable({
	states = stateDescriptions,
	commands = commandDescriptions,
}, { __call = function() end, __index = function() end }) end

local strings = {
	UPDATING_ROBOTARMY_DATA = "Robot Army data upgraded to format %d from format %d.",
	TASK_PROCESSOR = "Registered task processor: %q (%q)."
}

local squadStrings = {
	TREES_TOTAL = "Total trees: %d. Per member: %d.",
	TREES_PER = "Member %d attacks trees from %d to %d.",
	UNABLE_TO_ADD_REPLACEMENT = "We tried to spawn a replacement droid for a 'vanished' %q, but we were unable to add it to the squad.",
	UNABLE_TO_SPAWN_REPLACEMENT = "Unable to spawn replacement droid for 'vanished' droid %q.",
	MISSING_POSITION = "Squad does not have a valid position or task in :ShouldReinforce.",
	VALIDATE_MEMBER_DISPARITY = "Squad/LuaUnitGroup disparity: [members]/[groupsize]",
	COMMAND_WAS_SAME = "Previous command was the same.",
	APPLIED_NEW_COMMAND = "New order: %s.",
	FORCE_UNKNOWN = "Squad force doesnt exist.",
	SPAWN_REPLACEMENT = "Spawning replacement for vanished %q.",
	CREATING_SQUAD = "Creating new squad.",
	RETASK = "Retasking to %s.",
	GUARD_FOUND_ENEMY = "Engaging enemy within guard distance.",
	HUNT_TARGET = "Attacking towards %q.",
	SQUAD_IS_FULL = "Squad is full, retasking...",
	UNACCEPTED_COMMAND = "Command was not accepted, we should use force=true probably.",
	RETREATING = "RUN AWAY!",
	RECREATING_GROUP = "UnitGroup dissolved by engine, recreating.",
}

local _defaultCmd = "-"
local _defaultState = "-"
local _defaultSize = "0"

-- yes, yes, I know table.concat is better
--local prefix = "[[id] [command] [state] [members] [force] [task]] "
local prefix = "[[id] [command] [state] [task]] "
for k, v in pairs(squadStrings) do squadStrings[k] = prefix .. v end

local tostring = tostring

local function replaceState(squad, pattern, input)
	local cmd = _defaultCmd
	if squad.lastCommand then cmd = commandDescriptions[squad.lastCommand.type] or "?" end
	return input:gsub(pattern, cmd)
end

local function replaceCommand(squad, pattern, input)
	local state = _defaultState
	if squad.group and squad.group.valid then state = stateDescriptions[squad.group.state] or "?" end
	return input:gsub(pattern, state)
end

local function replaceGroupSize(squad, pattern, input)
	local gsize = _defaultSize
	if squad.group and squad.group.valid and squad.group.members then gsize = #squad.group.members end
	return input:gsub(pattern, gsize)
end

local function replaceMembers(squad, pattern, input) return input:gsub(pattern, #squad) end
local function replaceId(squad, pattern, input) return input:gsub(pattern, tostring(squad.id)) end
local function replaceTask(squad, pattern, input) return input:gsub(pattern, tostring(squad.task)) end
local function replaceForce(squad, pattern, input) return input:gsub(pattern, tostring(squad.force)) end

local replacements = {
	["%[state%]"] = replaceState,
	["%[command%]"] = replaceCommand,
	["%[members%]"] = replaceMembers,
	["%[groupsize%]"] = replaceGroupSize,
	["%[id%]"] = replaceId,
	["%[task%]"] = replaceTask,
	["%[force%]"] = replaceForce,
}

local outputFileFormat = "robotarmy/log-from-%d.txt"
local outputFile = nil

local function writeFile(msg)
	local first
	if not outputFile then
		first = true
		outputFile = outputFileFormat:format(game.tick)
	end
	game.write_file(outputFile, msg, not first)
end

local function pureLog(msg)
	log(msg)
	if game then
		if CONSOLE then game.print(msg) end
		if FILE then writeFile(msg) end
	end
end

-- id, order, state, members/luaunitgroup members, force, task
-- first argument to a __call function is the table, which we dont care about, so _
local function squadlog(_, squad, msg, ...)
	if not DEBUG then return end
	for k, replacer in pairs(replacements) do
		if msg:find(k) then msg = replacer(squad, k, msg) end
	end
	if msg:find("%%") then msg = msg:format(...) end
	pureLog(msg)
end

local INVALID = "Invalid logger key."
local UNKNOWN = "Logger key %q does not exist."
return setmetatable({
	states = stateDescriptions,
	commands = commandDescriptions,
	log = pureLog,
}, {
	__call = squadlog,
	__index = function(_, key)
		if type(key) ~= "string" then return INVALID end
		if not strings[key] and not squadStrings[key] then return UNKNOWN:format(tostring(key)) end
		return strings[key] or squadStrings[key]
	end
})
