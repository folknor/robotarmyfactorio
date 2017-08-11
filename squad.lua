local squad = {}

local _forceOrderAccept = {
	[defines.command.attack] = true,
	[defines.command.attack_area] = true,
}

local rawset, assert, type, max, tremove = rawset, assert, type, math.max, table.remove
local _log = require("util.logger")
local _util = require("util.utility")
local _meta = require("meta")
local _ASSERT_SETTING_DEFAULT = "Squad settings must have default values, can not find one for %q."
local _ASSERT_SETTING_VALUE_NIL = "Trying to set squad setting value %q to a nil value."
local _waterTiles = {deepwater = true, ["deepwater-green"] = true, water = true, ["water-green"] = true }

-------------------------------------------------------------------------------
-- DOCS
--

--- Gets a reference to a squad object, and creates it if necessary.
-- This function is provided by control.lua
-- @param forceName string, the force that owns this squad
-- @param squadId string/int, a valid squad ID as found in _meta.registeredSquadIds, or a player index
-- @param force boolean, whether or not GetSquad should forcefully create a squad object if none exist for the given parameters
-- @return a squad object
--
-- local squad = _G.GetSquad(forceName, squadId, forceCreate)
--
-- To iterate the members of a squad, do
-- for i = 1, #squad do
--     local member = squad(i)
--     if member.valid then
--        -- Note that in a tasks/task.lua files process(), you dont have to check .valid
--     end
-- end
--
-- To add a luaentity robot unit to a squad, do
-- local robot = LuaEntity
-- local added = squad + robot
-- if added == false then error("Robot is invalid or already part of another squad") end
--

-------------------------------------------------------------------------------
-- Squad object properties
--
-- Other than the methods below, a squad contains these properties:
--
-- wait = ticks,             -- The next tick we will process on, can be nil
-- task = string,            -- _meta.tasks.*, can never be nil
-- taskData = anything,      -- anything the current task wants to store, nil'd between task switches
-- lastCommand = command,    -- the last :Order, can be nil
-- position = {x,y},         -- this is the position the squad wants to attain
-- home = {x,y},             -- initial spawn position of the first squad member, reapplied on assembler processing and util.findClosestAssembler
-- lastUser = playername,    -- can be nil
-- error = _ERROR_FOO,       -- _meta.errors.*, can be nil
-- name = LocalizedString,   -- util/names.lua-generated name, a factorio localized string for GUI display
-- members = {},             -- array of LuaEntity, integrity verified by :Validate, before every task process
-- force = forceName,        -- string
-- group = luaunitgroup,     -- integrity is verified in :Validate, before every task process
-- id = squadId,             -- type(id) == "number" means it belongs to that player index, otherwise _meta.registeredSquadIds
--
-- The only properties that can/should be modified runtime are:
-- wait, task, taskData, lastCommand, position, home, lastUser, error

-------------------------------------------------------------------------------
--
--- Returns the ideal task for this squad.
-- Remember that a squad is not reprocessed/retasked until however long you return from the
-- tasks process() function. So if you return 120 from process(), this function wont be called
-- for the squad until 2 minutes have passed.
--
-- @returns Nothing, if the squads current task wants to continue.
-- @returns false, if the squads current task wants to continue.
-- @returns _meta.tasks.*, if the squad wants to be assigned a new :Task.
--
function squad:GetIdealTask()
	-- If self.id is a number, this squad is a player-owned squad.
	if type(self.id) == "number" then
		if self.task == _meta.tasks.follow then return end
		-- Immediately retask to follow
		return _meta.tasks.follow
	end

	-- ShouldSquadHeal and IsSquadSafe are provided by tasks/heal.lua
	local needsHeal = _G.ShouldSquadHeal(self)
	if needsHeal then
		local safe = _G.IsSquadSafe(self) -- XXX task-heal should simply move to a safe spot instead of this
		-- task-heal always does a direct :Task back to the old task, so it needs to know what that was
		if safe then return _meta.tasks.heal, {oldTask=self.task} end
	end

	local task = _G.GetTaskProcessor(self.task)
	if task then
		-- :ShouldRetask can either return a boolean, in which case
		--    true means we should retask
		--    false means we should not retask
		-- Or, it can return a string value that is an explicit _meta.tasks.*,
		-- in which case we should retask to that one immediately.
		-- This is done in on_tick.
		local retask = task.shouldRetask(self)
		if retask ~= true then return retask end
	end

	-- Since :ShouldRetask has returned simply |true|, or no valid task processor has been found,
	-- we need to get the squad settings or defaults, and apply that.

	local setting = self:Get(_meta.settings.task)
	if setting == _meta.tasks.hunt and self.task ~= _meta.tasks.hunt then
		if self.task == _meta.tasks.idle and not self:IsFull() then return end -- Return here so we dont default to guard below
		return _meta.tasks.hunt
	elseif setting == _meta.tasks.guard and self.task ~= _meta.tasks.guard then
		return _meta.tasks.guard
	end

	return _meta.tasks.idle
end

-------------------------------------------------------------------------------
--
--- Forcefully applies a new given task to the squad.
-- If the given task is the same as the current one, nothing is done.
--
-- The 2nd parameter can be any data the new squad wants before its first :process.
--
-- @param newTask A new task from _meta.tasks.*
-- @param newData New data to put in squad.taskData. If not given, squad.taskData is nil'd.
--
-- squad:Task(_meta.tasks.hunt, LuaEntity target to hunt)
-- squad:Task(_meta.tasks.follow, player.index)
-- squad:Task(_meta.tasks.idle)
-- squad:Task(_meta.tasks.guard)
--
function squad:Task(newTask, newData)
	local oldTask = self.task
	if oldTask ~= newTask then
		_log(self, _log.RETASK, newTask)
		self.task = newTask
		self.taskData = newData
		self.error = _meta.errors.retasking
	end
	return 3, _meta.errors.retasking -- Wait 3 seconds after retasking
end

-------------------------------------------------------------------------------
--
--- Returns the set or default value for the given squad setting.
-- Valid setting keys are available in _meta.settings[key] = signal
-- @param setting The setting key.
-- @return The value of the given setting, or its default from _meta.squadSettingDefaults.
--
-- local value = squad:Get(setting)
--
function squad:Get(setting)
	assert(type(_meta.squadSettingDefaults[setting]) ~= "nil", _ASSERT_SETTING_DEFAULT:format(setting))
	if type(global.squadSettings[self.force][self.id][setting]) == "nil" then return _meta.squadSettingDefaults[setting], true end
	return global.squadSettings[self.force][self.id][setting]
end

-------------------------------------------------------------------------------
--
--- Sets a squad setting.
-- Valid setting keys are available in _meta.settings[key] = signal.
-- Note: If the given value is not the same as the previous value of the given setting,
-- this method instantly puts the squad into idle mode.
-- @param setting The setting key.
-- @param value The value.
--
-- squad:Set(_meta.settings.*, value)
--
function squad:Set(setting, value)
	assert(type(value) ~= "nil", _ASSERT_SETTING_VALUE_NIL:format(setting))
	-- always do getSquadSetting first here so we assert on |setting| immediately
	local old = self:Get(setting)
	if old == value then
		-- this is the same value as before, simply return
		return
	end
	global.squadSettings[self.force][self.id][setting] = value
	self.task = _meta.tasks.idle
	self.taskData = nil
	self.error = _meta.errors.retasking
end

-------------------------------------------------------------------------------
--
--- Returns whether or not the squad wants reinforcements at this time.
--
-- Depends on active task type, and the relative distance between the squads position
-- and squad.home (a position, set by the assembler and _util.findClosestAssembler)
--
-- @param location Where we would put the reinforcements, if the squad wants them.
--
-- @return true If the squad wants reinforcements at the given position.
--
-- local spawn = squad:ShouldReinforce(location)
--
function squad:ShouldReinforce(location)
	if self:IsFull() then return false end
	-- This almost never triggers because we always set the position unless there is an error in the code somewhere
	if not self.position or not self.task then
		_log(self, _log.MISSING_POSITION)
		return true
	end
	local task = _G.GetTaskProcessor(self.task)
	return task.shouldReinforce(self, location)
end

-------------------------------------------------------------------------------
--
--- Does several things to validate the integrity of a squad object.
--
-- Most importantly, it loops the LuaEntity members of the squad and checks if they are valid,
-- and if not it removes their references. It does the same for squad.group, the LuaUnitGroup,
-- and automatically reapplies the .set_command to it if necessary.
--
-- @return true If no invalid members found, and group is intact.
--
function squad:Validate()
	-- Invoked before every processSquad
	local membersChanged
	local groupChanged
	for i = #self, 1, -1 do
		local member = self(i)
		if not member.valid then
			-- ZZZ This is the only place we should remove invalid members.
			membersChanged = true
			-- If a member is not valid, and it was not removed in on_entity_died/player_mined
			-- or through the droid pickup tool, that probably means we need to spawn a replacement.
			local droidName = tostring(global.entityUnitNameMap[member])
			_log(self, _log.SPAWN_REPLACEMENT, droidName)

			-- Remove references to the invalidated member
			global.entityUnitNameMap[member] = nil
			tremove(self.members, i)

			-- Spawn a replacement
			local freePosition = _util.findNonCollidingPosition(droidName, self)
			local droid = self:GetSurface().create_entity({
				name = droidName,
				position = freePosition,
				force = self.force,
			})
			if droid then
				local added = self + droid
				if not added then
					_log(self, _log.UNABLE_TO_ADD_REPLACEMENT, droidName)
				end
			else
				_log(self, _log.UNABLE_TO_SPAWN_REPLACEMENT, droidName)
			end
		end
	end

	local surface = self:GetSurface()
	local position = self:GetPosition()
	-- XXX need to validate that self.group.position is not over water tiles
	-- XXX to prevent groups of flying robots getting stuck
	-- XXX And if it is over water, we need a new tasks/ that fixes it
	local tile = surface.get_tile(position.x, position.y)
	if tile and _waterTiles[tile.name] then
		_log.log(tostring(squad) .. " seems to be trapped over water, is it?")
	end

	if _meta.useGroup and #self ~= 0 then
		if not self.group or not self.group.valid then
			local processor = _G.GetTaskProcessor(self.task)
			if not processor or not processor.recreateGroup or not processor.recreateGroup(squad) then
				if self.group then
					_log(self, _log.RECREATING_GROUP)
				end
				groupChanged = true
				-- create_unit_group can fail, so dont assume .group exists or is valid after this
				self.group = surface.create_unit_group({
					position = position,
					force = self.force
				})
			end
		end

		-- So apparently, from my testing, doing .add_member on a luaunitgroup
		-- where the given entity is already in the group works just fine, in the
		-- sense that it's not added to the table again.
		-- This is undocumented behavior though.
		if self.group and self.group.valid then
			for i = #self, 1, -1 do
				self.group.add_member(self(i))
			end
			if #self ~= #self.group.members then
				-- This actually probably means a squad member has legitimately died.
				_log(self, _log.VALIDATE_MEMBER_DISPARITY)
			end
			if groupChanged and self.lastCommand then
				self.group.set_command(self.lastCommand)
			end
		end
	end
	return not membersChanged and not groupChanged
end

-------------------------------------------------------------------------------
--
--- Presents the squad with a new order.
--
-- An order is not automatically accepted, and can be handled in various ways depending on several factors.
--
-- @param order A valid order table as used by the games .set_command.
-- @param force Whether or not to forcefully apply the new order or not, skipping any logic.
--
-- @return true If the order was accepted.
--
function squad:Order(order, force)
	if not _meta.useGroup or (self.group and self.group.valid and self.group.state ~= defines.group_state.finished) then
		local accept
		if not force then
			if self.lastCommand and self.lastCommand.type == order.type then
				--_log(self, _log.COMMAND_WAS_SAME)
				return false
			end
			if _meta.useGroup and self.group and self.group.valid then
				if self.group.state == defines.group_state.finished then
					accept = true
				elseif self.group.state == defines.group_state.gathering and (
					order.type == defines.command.go_to_location or
					order.type == defines.command.wander) then
					accept = true
				elseif _forceOrderAccept[order.type] then
					accept = true
				end
			else
				accept = true
			end
		end
		if not force and not accept then return false end
	end
	_log(self, _log.APPLIED_NEW_COMMAND, _log.commands[order.type])
	self.lastCommand = order
	--if order.type == defines.command.go_to_location then
	--	_log(self, "GTL order, make sure something happens!")
	--end
	if _meta.useGroup and self.group and self.group.valid then
		self.group.set_command(order)
		-- Force move if the squad is "gathering", which it seems to be 24/7
		--if self.group.state == defines.group_state.gathering and forceMoving[order.type] then
		--	_log("Forcefully moving.")
		if force then
			self.group.start_moving()
		end
	else
		for i = #self, 1, -1 do
			local m = self(i)
			if m.valid then
				m.set_command(order)
			end
		end
	end
	return true
end

-------------------------------------------------------------------------------
--
--- Gets the distance to the given position, and the closest member.
--
-- @return distance, member
--
function squad:Distance(position)
	local x, y, cD, cM = position.x, position.y
	for i = #self, 1, -1 do
		local member = self.members[i]
		if member.valid then
			local distance = (((member.position.x - x) ^ 2) + ((member.position.y - y) ^ 2)) ^ 0.5
			if not cD or (distance < cD) then
				cD = distance
				cM = member
				if cD == 0 then return cD, cM end
			end
		end
	end
	return cD, cM
end

-------------------------------------------------------------------------------
--
--- Checks if all members of a squad are within a reasonable distance of eachother.
--
-- The distance is defined as (_meta.config.BUNCH_PER_MEMBER * #members).
--
-- @param position Optional, defaults to self.position.
--
-- @return boolean Whether or not we are bunched up.
-- @return member The member that is closest to squad.position
--
function squad:IsGathered(position)
	local _, closest = self:Distance(position or self.position)
	local x, y = closest.position.x, closest.position.y
	-- make sure we never check for bunching in a stupidly small radius
	local m = max(10, _meta.config.BUNCH_PER_MEMBER * #self)
	for i = 1, #self do
		local member = self(i)
		if member.valid then
			local d = (((member.position.x - x) ^ 2) + ((member.position.y - y) ^ 2)) ^ 0.5
			if d > m then
				return false, closest
			end
		end
	end
	return true, closest
end

-------------------------------------------------------------------------------
--
--- Returns whether or not the squad is full, as determined by the settings.
-- @return true/false
--
function squad:IsFull()
	local idealSize = self:Get(_meta.settings.squadSize)
	return #self >= idealSize
end

-------------------------------------------------------------------------------
--
--- Instantly destroys the squad.
--
-- After invoking this method, the squad object you're using will
-- no longer be valid.
--
function squad:Destroy()
	for _, p in pairs(game.players) do
		_G.DeselectSquads(p)
	end

	for i = #self, 1, -1 do
		local m = tremove(self.members, i)
		if m.valid then m.destroy() end
	end

	if self.group and self.group.valid then self.group.destroy() end
	for i = #global.squads, 1, -1 do
		if global.squads[i].id == self.id then
			tremove(global.squads, i)
			break
		end
	end
	for k in pairs(self) do self[k] = nil end
end

-------------------------------------------------------------------------------
--
--- Transfers the members of this squad to the given squad ID.
--
-- The given squadId does not have to exist. Transferring members to or from
-- player-specific squads does not work. Both squads must be from the same LuaForce.
-- Note: If the transfer succeeds, you probably want to :Destroy the squad.
--
-- @param squadId The ID of the squad to transfer to.
--
-- @return true If the transfer completed.
--
-- local success = squad:Transfer(squadId)
-- if success then squad:Destroy() end
-- squad:Set(_meta.settings.whatever, 123) -- Will error, because the squad object is no longer valid after :Destroy
--
function squad:Transfer(squadId)
	if type(squadId) ~= "string" then return end
	if not _meta.registeredSquadIds[squadId] then return end

	for _, p in pairs(game.players) do
		_G.DeselectSquads(p)
	end

	if self.group and self.group.valid then self.group.destroy() end

	local to = _G.GetSquad(self.force, squadId)
	for i = #self, 1, -1 do
		local m = tremove(self.members, i)
		if m.valid then
			local added = to + m
			if not added then
				game.print("Failed to transfer squad member.")
			end
		end
	end
	return true
end


-------------------------------------------------------------------------------
--
--- Get the squads current position
--
-- @return position, the squads current position.
--
function squad:GetPosition()
	if _meta.useGroups and self.group and self.group.valid and self.group.position then
		return self.group.position
	end
	for i = 1, #self do
		local m = self(i)
		if m.valid and m.position then return m.position end
	end
	return self.position or self.home
end

function squad:GetSurface()
	for i = 1, #self do if self(i).valid then return self(i).surface end end
	return game.surfaces.nauvis
end

do -- EXPERIMENTAL, currently unused
	local checkers = setmetatable({}, {
		__index = function(self, key)
			local n = _util.newDistanceChecker(12)
			rawset(self, key, n)
			return n
		end,
	})
	function squad:StandingStill()
		local queue = checkers[self]
		local ret = queue(self, 8)
		if ret then
			print(tostring(queue))
		end
		return ret
	end
end

-------------------------------------------------------------------------------
-- Beware: Dragons.
--

local acceptedNewIndexes = {
	taskData = true, -- Can be anything the task wants
	position = "table",
	home = "table",
	group = "table",
	error = true, -- Can be table, nil, or string
	wait = true, -- Can be nil or number
	task = "string",
	lastUser = "string",
	lastCommand = "table",
}
local toStringFormat = "[squad:%s]"
local squadMeta = {
	__index = squad,
	__newindex = function(self, k, v)
		if acceptedNewIndexes[k] == true or type(v) == acceptedNewIndexes[k] then
			rawset(self, k, v)
		else
			error("Invalid key assignment (" .. tostring(k) .. ") on squad object.")
		end
	end,
	__tostring = function(self) return toStringFormat:format(tostring(self.id)) end,
	__add = function(self, member)
		if type(member) ~= "table" then return end
		if not member.valid or not member.name then return end
		if not _meta.classes[member.name] then return end
		if not self.position then self.position = member.position end
		-- Reset home position if it doesnt exist or this is the first member of the squad
		if not self.home or #self == 0 then self.home = member.position end

		-- Store this spawned droids unit name, so that we can spawn a replacement
		-- if the game engine decides to "vanish" it.
		global.entityUnitNameMap[member] = member.name

		table.insert(self.members, member)

		-- Always has to be called before orderSquad, but we always do validateSquad before we on_tick process
		-- any squad commands, so usually don't worry about it.
		self:Validate()
		return true
	end,
	__len = function(self) return #self.members end,
	__call = function(self, index) return self.members[index] end,
}

return squadMeta
