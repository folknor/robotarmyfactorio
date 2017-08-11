local _gui = require("mod-gui")
local _meta = require("meta")

local L = {
	[_meta.tasks.follow] = {"robotarmy-task-names.task-follow"},
	[_meta.tasks.active] = {"robotarmy-task-names.task-active"},
	[_meta.tasks.hunt] = {"robotarmy-task-names.task-hunt"},
	[_meta.tasks.guard] = {"robotarmy-task-names.task-guard"},
	[_meta.tasks.idle] = {"robotarmy-task-names.task-idle"},
	[_meta.tasks.retreat] = {"robotarmy-task-names.task-retreat"},
	[_meta.tasks.trees] = {"robotarmy-task-names.task-trees"},
	[_meta.tasks.gather] = {"robotarmy-task-names.task-gather"},
	[_meta.tasks.patrol] = {"robotarmy-task-names.task-patrol"},
	[_meta.tasks.heal] = {"robotarmy-task-names.task-heal"},
}

local statusStrings = {
	[defines.group_state.gathering] = {"robotarmy-group-state.gathering"},
	[defines.group_state.moving] = {"robotarmy-group-state.moving"},
	[defines.group_state.attacking_distraction] = {"robotarmy-group-state.distraction"},
	[defines.group_state.attacking_target] = {"robotarmy-group-state.target"},
	[defines.group_state.finished] = {"robotarmy-group-state.finished"},
}
local pathfinder = {"robotarmy-errors.error-pathfinder"}

-------------------------------------------------------------------------------
-- UI update handling
--

local _playerSquadId = "squadid-player"
local function updateSquadButtons(player, squadId)
	local buttons = _gui.get_button_flow(player)
	if not buttons then return end

	-- Transfer command is active
	local transfer = _G.GetActiveTransfer(player)
	if transfer then
		for squad in pairs(_meta.registeredSquadIds) do
			buttons[squad].style.visible = (squad ~= _playerSquadId) and (squad ~= transfer)
		end
		return
	end

	-- Update all buttons
	if not squadId then
		for squad in pairs(_meta.registeredSquadIds) do
			buttons[squad].style.visible = false
		end
		for _, s in next, global.squads do
			if s.force == player.force.name and #s ~= 0 then
				if type(s.id) == "string" then
					buttons[s.id].style.visible = true
				elseif s.id == player.index then
					buttons[_playerSquadId].style.visible = true
				end
			end
		end
		return
	end
	local button
	if type(squadId) == "number" then button = buttons[_playerSquadId]
	else button = buttons[squadId] end
	if squadId == _playerSquadId then squadId = player.index end
	-- get a squad reference without forcefully creating one if it doesnt exist
	local s = _G.GetSquad(player.force.name, squadId, true)
	if s and #s ~= 0 then
		button.style.visible = true
	else
		button.style.visible = false
	end
end

local ceil = math.ceil
local timed = {"robotarmy-interface.task-timed"}
local function updateLabelTask(label, s)
	local wait = s.wait
	if not wait or (game.tick >= wait) or not L[s.task] then
		label.caption = L[s.task] or tostring(s.task)
	else
		local seconds = ceil((wait - game.tick) / 60)
		timed[2] = L[s.task]
		timed[3] = seconds
		label.caption = timed
	end
end

local function updateLabelMembers(label, s)
	local size, sizeDefault = s:Get(_meta.settings.squadSize)
	label.caption = _meta.memberFormat:format(#s, size)
	if sizeDefault then
		label.style.font_color = _meta.colors.white
	else
		label.style.font_color = _meta.colors.green
	end
end

local function updateLabelTaskData(label, s, player, labelLabel)
	local t = _G.GetTaskProcessor(s.task)
	local caption, display
	if t and t.updateUI then
		caption, display = t.updateUI(s, player)
	end
	if caption and display then
		label.caption = display
		labelLabel.caption = caption
		label.style.visible = true
		labelLabel.style.visible = true
	else
		label.style.visible = false
		labelLabel.style.visible = false
	end
end

local function updateLabelUser(label, s)
	if s.lastUser then
		label.caption = s.lastUser
	else
		label.caption = _meta.noUserString
	end
end

local function updateLabelName(label, squad)
	label.caption = squad.name
	label.style.font_color = _meta.registeredSquadIds[squad.id] or _meta.colors.white
end

local function updateLabelStatus(label, squad)
	-- XXX kyranzor: use different colors for robotarmy-status and luaunitgroup-states?
	if game.forces[squad.force] and game.forces[squad.force].is_pathfinder_busy() then
		label.caption = pathfinder
	elseif squad.error then
		label.caption = squad.error or "Unknown status"
	elseif squad.group and squad.group.valid then
		label.caption = statusStrings[squad.group.state] or "Unknown state"
	else
		label.caption = _meta.noUserString
	end
end

-- This needs to be an indexed array so that order is preserved
-- Remember, the id must be something that is not listed as a property in
-- http://lua-api.factorio.com/latest/LuaGuiElement.html
-- for example, id=name will not work :-P
local infoLabels = {
	{ id = "task", process = updateLabelTask },
	{ id = "groupstatus", process = updateLabelStatus },
	{ id = "taskdata", process = updateLabelTaskData },
	{ id = "squadname", process = updateLabelName },
	{ id = "members", process = updateLabelMembers },
	{ id = "user", process = updateLabelUser },
}
local labelFormat = setmetatable({}, {
	__index = function(self, k)
		local ret = "label_" .. k
		rawset(self, k, ret)
		return ret
	end
})

local function updateCommandFrame(player, squadId, refresh)
	local frame = _gui.get_frame_flow(player).squad_command_frame
	if not frame then return end
	if refresh and not frame.style.visible then return end -- if we are refreshing, and the frame is hidden, just get out
	-- if the frame is visible, and the passed squadId is not the same as the one we are showing, GTFO
	if frame.style.visible and squadId and global.commandOpen[player.index] and global.commandOpen[player.index] ~= squadId then return end
	-- if we are not commanded to refresh the frame, and the passed in squad id is the same as it was previously,
	-- it means we are probably clicking the same button again, in which case we toggle
	if not refresh and squadId and global.commandOpen[player.index] and global.commandOpen[player.index] == squadId then
		frame.style.visible = false
		global.commandOpen[player.index] = nil
		return
	end
	-- if squadId isn't passed in, read it from commandOpen
	if not squadId then squadId = global.commandOpen[player.index] end
	-- if squadId is nil, hide frame and gtfo
	if not squadId then frame.style.visible = false; return end

	global.commandOpen[player.index] = squadId

	-- This should never really happen, _playerSquadId is only used
	-- for the squad buttons.
	if squadId == _playerSquadId then squadId = player.index end

	-- get a squad reference without forcefully creating one if it doesnt exist
	local s = _G.GetSquad(player.force.name, squadId, true)
	if not s or #s == 0 then
		global.commandOpen[player.index] = nil
		frame.style.visible = false
		return
	end

	for _, label in next, infoLabels do
		label.process(frame.status[label.id], s, player, frame.status[labelFormat[label.id]])
	end

	frame.style.visible = true
end

-------------------------------------------------------------------------------
-- Command palette and squad button interface
--

-- We run this function every time on_configuration_changed fires and when a player is created.
-- Which means it must be safe to run it repeatedly for the same player.
-- Of course you can easily add a global.uiVersion and migrate here just like in
-- on_configuration_changed, or however you want.
local function initGui(player)
	local buttons = _gui.get_button_flow(player)
	for squad in pairs(_meta.registeredSquadIds) do
		if not buttons[squad] then
			buttons.add({
				type = "sprite-button",
				name = squad,
				sprite = _meta.uiSprites[squad],
				style = _gui.button_style,
				tooltip = { "robotarmy-interface.squad-button" }
			}).style.visible = false
		end
	end

	local frames = _gui.get_frame_flow(player)
	local frame = frames.squad_command_frame
	if not frame then
		frame = frames.add({
			type = "frame",
			name = "squad_command_frame",
			direction = "vertical",
			style = "robotarmy_command_palette",
		})
	end
	if not frame.grid then
		local grid = frame.add({
			type = "flow",
			name = "grid",
			direction = "horizontal",
			style = "robotarmy_command_palette_buttons"
		})
		grid.style.max_on_row = 4 -- seems this can't be set from the data style properly
		--grid.style.resize_row_to_width = true
		grid.style.resize_to_row_height = true
	end

	-- Remove all children of frame.grid so that we can easily invoke
	-- initGui on configuration changed / mod upgrade or whatever
	frame.grid.clear()

	for _, cmd in next, _meta.commands do
		frame.grid.add({
			type = "sprite-button",
			sprite = "recipe/" .. _meta.commandFormat:format(cmd.id),
			style = _gui.button_style,
			tooltip = { "robotarmy-interface." .. _meta.commandFormat:format(cmd.id) },
			name = _meta.commandFormat:format(cmd.id),
		})
	end

	if not frame.status then
		frame.add({
			type = "flow",
			name = "status",
			direction = "horizontal",
			style = "robotarmy_command_information"
		})
		frame.status.style.max_on_row = 2 -- seems this can't be set from the data style properly
		frame.status.style.resize_row_to_width = true
		frame.status.style.resize_to_row_height = true
	end

	if frame.status.label_retreat then frame.status.label_retreat.destroy() end
	if frame.status.retreat then frame.status.retreat.destroy() end

	for _, label in next, infoLabels do
		if not frame.status[labelFormat[label.id]] then
			frame.status.add({
				type = "label",
				name = labelFormat[label.id],
				style = "robotarmy_command_label",
				caption = {"robotarmy-interface.label-" .. label.id},
			})
			frame.status[labelFormat[label.id]].single_line = true
		end
		if not frame.status[label.id] then
			frame.status.add({
				type = "label",
				name = label.id,
				style = "robotarmy_command_data",
				caption = "",
			})
			frame.status[label.id].single_line = true
		end
	end

	frame.style.visible = false
	updateCommandFrame(player)
	updateSquadButtons(player)
end

_G.InitializeGUI = initGui
_G.UpdateCommandFrame = updateCommandFrame
_G.UpdateSquadButtons = updateSquadButtons
