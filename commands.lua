
local _meta = require("meta")
local _TOOL_COMMAND = "droid-selection-tool"
local _TOOL_GRAB = "droid-pickup-tool"

-------------------------------------------------------------------------------
-- Command feedback builder
--

local getFeedback
do
	-- you
	local you = {"robotarmy-interface.player"}
	-- clicked position
	local clicked = {"robotarmy-interface.clicked"}
	-- __1__ squad
	local squadName = "robotarmy-interface.squad-name"
	-- Your squad
	local playerSquadName = {"robotarmy-interface.player-squad-name"}
	-- Selected squads will __1__ near __2__.
	local commandSelected = "robotarmy-interface.command-selected"
	-- __1__ will __2__ near __3__.
	local commandOpened = "robotarmy-interface.command-opened"

	-- XXX some of these tables should probably be cached
	-- only used when the player uses an active squad command, so there's no rush
	getFeedback = function(squad, player, cmdId, clickPosition)
		local cmd = _meta.errors.command[cmdId] or "?"
		if squad.id == player.index then
			if clickPosition then
				return {commandOpened, playerSquadName, cmd, clicked}
			else
				return {commandOpened, playerSquadName, cmd, you}
			end
		elseif type(global.selectedSquads[player.index]) == "table" then
			if clickPosition then
				return {commandSelected, cmd, clicked}
			else
				return {commandSelected, cmd, you}
			end
		else
			if clickPosition then
				return {commandOpened, {squadName, squad.name}, cmd, clicked}
			else
				return {commandOpened, {squadName, squad.name}, cmd, you}
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Command processor
--

local placePatrolPoleCancel = {"robotarmy-interface.patrol-pole-cancel"}
local function hasTool(p)
	return p.cursor_stack and p.cursor_stack.valid_for_read and p.cursor_stack.name == _TOOL_COMMAND
end

-- ZZZ this variable is not persisted through saves because frankly I think the player
-- ZZZ would forget which command they had clicked anyway
-- index: player index, key: cmdid of the clicked command in the command palette ingame
local playerSelectedCommand = {}
-- key: player index, value: squad id
local patrolTool = {}

local commandProcessor
do
	local processCommand = {}
	local throttle = {}

	-- This function gets invoked for commands where a task has the same ID.
	-- For 0.4.1, this is only true for "follow".
	local function processTaskCommand(squad, player, cmdId)
		if cmdId == "follow" then
			-- .taskData is the 2nd argument
			squad:Task(_meta.tasks.follow, player.index)
			squad.wait = nil -- process immediately
		elseif cmdId == "patrol" then
			-- This never happens, the patrol task is assigned when placing the pole
			squad:Task(_meta.tasks.patrol)
		end
	end

	-- Processed during loading of control.lua
	local req = "commands.%s"
	_meta.commandInfo = {}
	for _, cmd in next, _meta.commands do
		if _meta.tasks[cmd.id] then
			processCommand[cmd.id] = processTaskCommand
		else
			local c = require(req:format(cmd.id))
			if type(c) ~= "function" then error("Commands must return a function to handle it.") end
			processCommand[cmd.id] = c
		end
		_meta.commandInfo[cmd.id] = cmd
	end
	-- use the long-form command format for the button names because
	-- these names are shared between all mods in the event handler for GUI elements

	-- id is processCommand entry
	-- player luaplayer
	-- squadId is global.commandOpen
	-- position is the position you want the command to act upon
	commandProcessor = function(id, player, squad, position)
		-- Just make sure we dont execute twice when idiots doubleclick
		-- and yes, it throttles by squad ID which is shared across forces, so
		-- if two players from opposing forces attempt to give a command at exactly
		-- the same time, it will throttle one of them
		if throttle[squad.id] and game.tick < throttle[squad.id] then return end
		throttle[squad.id] = game.tick + 20

		squad.position = position
		squad.lastUser = player.name

		-- Make sure we set active task before squad:Validate, so it doesnt retask
		local data = _meta.commandInfo[id]
		local wait
		if data.duration then
			wait = game.tick + (data.duration * 60) + math.random(1, 45)
		end
		if data.active then
			squad:Task(_meta.tasks.active, wait)
		end

		-- We dont check the return from validate, because commands should be processed no matter what
		squad:Validate()

		-- Process command in commands/id.lua
		processCommand[id](squad, player, id)
		squad.error = _meta.errors.command[id]
		if wait then squad.wait = wait end
	end

	local needsTool = {"robotarmy-errors.needs-tool"}
	local poleHelp = {"robotarmy-interface.patrol-pole-command"}
	local pathfinderBusy = {"robotarmy-errors.pathfinder-busy"}
	script.on_event(defines.events.on_gui_click, function(event)
		if not event or not event.element then return end
		local cmdId = event.element.name:match(_meta.commandMatch)
		if type(cmdId) == "string" and processCommand[cmdId] then
			local p = game.players[event.player_index]
			if not p then return end
			if p.force.is_pathfinder_busy() then
				p.print(pathfinderBusy)
				return
			end

			if cmdId == "patrol" then
				if hasTool(p) then
					patrolTool[p.index] = true
					p.print(poleHelp)
				else
					p.print(needsTool)
				end
				return
			end

			if patrolTool[p.index] then
				patrolTool[p.index] = nil
				p.print(placePatrolPoleCancel)
			end

			if hasTool(p) then
				playerSelectedCommand[p.index] = cmdId
				p.print({"robotarmy-interface.tool-command", _meta.errors.command[cmdId]})
			else
				-- if the player has any selected squads, command those instead of whatever is open
				if type(global.selectedSquads[p.index]) == "table" then
					for squadId in pairs(global.selectedSquads[p.index]) do
						local squad = _G.GetSquad(p.force.name, squadId, true)
						if squad then
							p.print(getFeedback(squad, p, cmdId, false))
							commandProcessor(cmdId, p, squad, p.position)
						end
					end
				else
					-- No squads selected, command the player-specific (placed by using items) squad instead
					local squad = _G.GetSquad(p.force.name, global.commandOpen[p.index], true)
					if squad then
						p.print(getFeedback(squad, p, cmdId, false))
						commandProcessor(cmdId, p, squad, p.position)
					end
				end
			end
		elseif _meta.registeredSquadIds[event.element.name] then
			local p = game.players[event.player_index]
			if not p then return end
			local transfer = _G.GetActiveTransfer(p)
			if transfer then
				_G.ExecuteTransfer(p, event.element.name)
			else
				_G.UpdateCommandFrame(p, event.element.name)
			end
		end
	end)
end


-------------------------------------------------------------------------------
-- Selection tools
--

do
	local function fixArea(area)
		area.left_top.x = area.left_top.x - 0.01
		area.left_top.y = area.left_top.y - 0.01
		area.right_bottom.x = area.right_bottom.x + 0.01
		area.right_bottom.y = area.right_bottom.y + 0.01
		return area
	end

	local function removeSquadStickers(squad)
		for i = 1, #squad do
			local member = squad(i)
			if member.valid and type(member.stickers) ~= "nil" then
				for k = #member.stickers, 1, -1 do
					member.stickers[k].destroy()
				end
			end
		end
	end
	_G.RemoveSquadStickers = removeSquadStickers

	local function removeStickers(player)
		local selected = global.selectedSquads[player.index]
		if not selected then return end
		for squadId in pairs(selected) do
			local squad = _G.GetSquad(player.force.name, squadId, true)
			if squad then removeSquadStickers(squad) end
		end
	end

	local sticker = {
		name = "selection-sticker",
		position = nil,
		target = nil,
	}
	local function applyStickers(player)
		local selected = global.selectedSquads[player.index]
		if not selected then return end
		for squadId in pairs(selected) do
			local squad = _G.GetSquad(player.force.name, squadId, true)
			if squad then
				for i = 1, #squad do
					local member = squad(i)
					if member.valid then
						sticker.position = member.position
						sticker.target = member
						member.surface.create_entity(sticker)
					end
				end
			end
		end
	end

	_G.DeselectSquads = function(player)
		removeStickers(player)
		global.selectedSquads[player.index] = nil
	end

	_G.SelectSquad = function(squad, player)
		removeStickers(player)
		if not global.selectedSquads[player.index] then global.selectedSquads[player.index] = {} end
		global.selectedSquads[player.index][squad.id] = true
		applyStickers(player)
		_G.UpdateCommandFrame(player)
	end

	local function selectionTool(event)
		if event.item ~= _TOOL_COMMAND and event.item ~= _TOOL_GRAB then return end
		-- is it weird that event.entities doesn't contain all the units?

		local player = game.players[event.player_index]
		if not player then return end
		local area = fixArea(event.area)

		-- Get all selected units and remove entities that are not robots
		local units = player.surface.find_entities_filtered({area = area, type = "unit", force = player.force})
		for i = #units, 1, -1 do
			if not _meta.classes[units[i].name] then
				table.remove(units, i)
			end
		end

		if patrolTool[player.index] then
			patrolTool[player.index] = nil
			player.print(placePatrolPoleCancel)
		end

		if event.item == "droid-selection-tool" then
			removeStickers(player) -- Remove all previously applied stickers

			if #units == 0 then
				-- We are either trying to select the closest squad, or deselect
				-- If we already have a squad selected, deselect it.
				if type(global.selectedSquads[player.index]) == "table" then
					global.selectedSquads[player.index] = nil
				else
					-- Find the closest squad to this position
					local click = {x = (area.right_bottom.x + area.left_top.x) / 2 , y = (area.right_bottom.y + area.left_top.y) / 2}
					local closestSquadID
					local closestDistance
					for _, squad in next, global.squads do
						if squad.force == player.force.name and #squad ~= 0 then
							local distance
							if _meta.useGroup and squad.group and squad.group.valid then
								-- Use the groups position
								distance = (((click.x - squad.group.position.x) ^ 2) + ((click.y - squad.group.position.y) ^ 2)) ^ 0.5
							else
								-- Use the squads position
								distance = (((click.x - squad.position.x) ^ 2) + ((click.y - squad.position.y) ^ 2)) ^ 0.5
							end
							if distance < _meta.config.SQUAD_CHECK_RANGE and (not closestDistance or distance < closestDistance) then
								closestSquadID = squad.id
								closestDistance = distance
							end
						end
					end
					-- No squad found, GTFO!
					if not closestSquadID then return end
					global.selectedSquads[player.index] = {
						[closestSquadID] = true
					}
				end
			else
				if not global.selectedSquads[player.index] then global.selectedSquads[player.index] = {} end
				-- There's a few units selected, so make sure we select all the squads they are part of
				for i = 1, #units do
					local unit = units[i]
					if unit.valid then
						local squad = _G.GetSquadFromUnitNumber(unit.unit_number)
						if squad then
							global.selectedSquads[player.index][squad.id] = true
						end
					end
				end
			end

			applyStickers(player)
			_G.UpdateCommandFrame(player)
		elseif event.item == _TOOL_GRAB then
			local squadsAffected = {}
			for i = 1, #units do
				local unit = units[i]
				if unit.valid then
					-- Find the squad this unit belongs to
					local squad, index = _G.GetSquadFromUnitNumber(unit.unit_number)
					if squad then
						squadsAffected[squad] = true
						player.insert({name = unit.name, count = 1})
						table.remove(squad.members, index)
						unit.destroy()
					end
				end
			end
			for squad in pairs(squadsAffected) do
				squad:Validate()
			end
		end
	end

	local noPosition = {"robotarmy-errors.no-valid-position"}
	local function orderTool(event)
		if event.item ~= _TOOL_COMMAND then return end
		local p = game.players[event.player_index]
		if not p then return end
		local area = fixArea(event.area)
		local clickPosition = {x = (area.right_bottom.x + area.left_top.x) / 2 , y = (area.right_bottom.y + area.left_top.y) / 2}

		if patrolTool[p.index] then
			patrolTool[p.index] = nil
			local position = p.surface.find_non_colliding_position("patrol-pole", clickPosition, 30, 1)
			if not position then
				p.print(noPosition)
				return
			end
			local ent = p.surface.create_entity({
				name = "patrol-pole",
				position = position,
				force = p.force,
			})
			if not ent or not ent.valid then
				p.print(noPosition)
				return
			end
			-- We play the sound at the players position so that he can hear it
			p.surface.create_entity({name = "pole-plop", position = p.position})
			ent.operable = false
			ent.destructible = false

			table.insert(global.patrolPoles, ent)

			if type(global.selectedSquads[p.index]) == "table" then
				for squadId in pairs(global.selectedSquads[p.index]) do
					local squad = _G.GetSquad(p.force.name, squadId, true)
					if squad then
						if squad.task == _meta.tasks.patrol then
							table.insert(squad.taskData, ent)
						else
							squad:Task(_meta.tasks.patrol, {ent})
						end
					end
				end
			else
				local squad = _G.GetSquad(p.force.name, global.commandOpen[p.index], true)
				if squad then
					if squad.task == _meta.tasks.patrol then
						table.insert(squad.taskData, ent)
					else
						squad:Task(_meta.tasks.patrol, {ent})
					end
				end
			end
		else
			local cmdId = playerSelectedCommand[p.index] or _meta.config.DEFAULT_COMMAND
			playerSelectedCommand[p.index] = nil -- Reset

			-- Apply to the players own squad
			local playerSquad = _G.GetSquad(p.force.name, p.index, true)
			if playerSquad then
				p.print(getFeedback(playerSquad, p, cmdId, true))
				commandProcessor(cmdId, p, playerSquad, clickPosition)
			end

			-- Apply to the selected squads
			if type(global.selectedSquads[p.index]) == "table" then
				for squadId in pairs(global.selectedSquads[p.index]) do
					local squad = _G.GetSquad(p.force.name, squadId, true)
					if squad then
						p.print(getFeedback(squad, p, cmdId, true))
						commandProcessor(cmdId, p, squad, clickPosition)
					end
				end
			end
		end
	end

	script.on_event(defines.events.on_player_selected_area, selectionTool)
	script.on_event(defines.events.on_player_alt_selected_area, orderTool)
end
