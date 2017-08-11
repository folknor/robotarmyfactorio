local _meta = require("meta")
local _util = require("util.utility")
local _log = require("util.logger")
local tinsert, select, max, floor, unpack, min = table.insert, select, math.max, math.floor, unpack, math.min

local ret = {
	type = defines.command.compound,
	structure_type = defines.compound_command.return_last,
	--commands = {},
}
local attack = defines.command.attack
local function getCompoundKillCommand(...)
	ret.commands = {}
	for i = 1, select("#", ...) do
		tinsert(ret.commands, {
			type = attack,
			target = (select(i, ...))
		})
	end
	return ret
end

-- squad.position needs to be set to where the squad wants to end up after
-- they are done clearing the trees
local function process(squad)
	local data = squad.taskData
	if not data.init then
		local force = squad.force
		for i = 1, #data do
			if data[i].valid then data[i].order_deconstruction(force) end
		end
		data.init = true
	end

	_util.clearInvalid(data)

	local numData = #data
	local numSquad = #squad

	if numData < 3 then
		for i = 1, numData do data[i].destroy() end
		squad.taskData = nil
		squad:Order({
			type = defines.command.go_to_location,
			destination = squad.position,
			distraction = defines.distraction.by_anything,
		}, true)
		return 5
	else
		-- We floor() so that getCompoundKillCommand doesnt have to validate each argument
		-- We could, alternatively, do |local e = min(#data, s + treesPerMember)| below I guess,
		-- and do ceil() on treesPerMember.
		-- And never do more than 6 at a time.
		local treesPerMember = min(6, max(floor(numData / numSquad), 1))
		_log(squad, _log.TREES_TOTAL, numData, treesPerMember)
		for i = 1, numSquad do
			local m = squad(i)
			if treesPerMember == 1 then
				m.set_command({
					type = defines.command.attack,
					target = data[(i + numData) % numData + 1],
				})
			else
				local s = max(1, (i - 1) * treesPerMember)
				local e = s + treesPerMember
				--_log(squad, _log.TREES_PER, i, s, e)
				m.set_command(getCompoundKillCommand(unpack(data, s, e)))
			end
		end
		return max(1.5, (treesPerMember * 0.5))
	end
end

local function shouldweretask(squad)
	if not squad.taskData then return _meta.tasks.hunt end
	return false
end

local caption = {"robotarmy-interface.trees-remaining"}
return {
	process = process,
	recreateGroup = function(squad)
		if not squad.taskData then return true end
		if #squad.taskData == 0 then return true end
		-- If we are still clearing trees, dont bother recreating the luaunitgroup
		-- As of 0.4.1, this is the only task that stops squad:Validate from
		-- forcefully recreating the luaunitgroup
		return false
	end,
	shouldRetask = shouldweretask,
	shouldReinforce = function() return false end,
	updateUI = function(squad)
		if not squad.taskData then return caption, "-" end
		return caption, #squad.taskData
	end,
}
