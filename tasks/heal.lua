local _meta = require("meta")

local _MINIMUM = _meta.config.HEAL_UNIT_MINIMUM
local _AVERAGE = _meta.config.HEAL_SQUAD_AVERAGE
local _RADIUS = _meta.config.HEAL_SAFE_RADIUS
local _STOP = _meta.config.HEAL_STOP

local maxHealth = setmetatable({}, {
	__index = function(self, k)
		local ret = game.entity_prototypes[k].max_health
		rawset(self, k, ret)
		return ret
	end
})

local function needsHealing(squad)
	local total = 0
	local n = #squad
	for i = 1, n do
		local m = squad(i)
		if m.valid then
			local percent = (m.health / maxHealth[m.name])
			if percent <= _MINIMUM then return true end
			total = total + percent
		end
	end
	local average = total / n
	if average <= _AVERAGE then return true end
end
_G.ShouldSquadHeal = needsHealing

local function safeToHeal(squad)
	local s = squad:GetSurface()
	local enemies = s.find_enemy_units((squad:GetPosition()), _RADIUS, squad.force)
	if not enemies or #enemies == 0 then return true end
end
_G.IsSquadSafe = safeToHeal


local function process(squad)
	local n = #squad
	if not squad.taskData then error("task-heal needs to be started with a taskData table") end
	if not squad.taskData.oldTask then error("task-heal needs a reference to the old squad task") end
	if not squad.taskData.init then
		-- This is the first process, find the squad member
		-- with the least health.
		local hurting, percent
		for i = 1, n do
			local m = squad(i)
			local p = (m.health / maxHealth[m.name])
			if not percent or p < percent then
				percent = p
				hurting = m
			end
		end
		-- That's where we want to go. Way down to Kokomo.
		squad.position = hurting.position
		squad.taskData.init = true
	end

	-- Update total percent
	local total = 0
	local anyMemberVeryLow = false
	for i = 1, n do
		local m = squad(i)
		if m.valid then
			local percent = (m.health / maxHealth[m.name])
			if percent <= _MINIMUM then anyMemberVeryLow = true end
			total = total + percent
		end
	end
	local average = total / n
	squad.taskData.avg = math.floor(average * 100)
	if average >= _STOP and not anyMemberVeryLow then
		-- squad.taskData.oldTask is set in squad.luas GetIdealTask
		return squad:Task(squad.taskData.oldTask)
	end
	squad:Order({
		type = defines.command.go_to_location,
		destination = squad.position,
		distraction = defines.distraction.by_damage,
	}, true)
	return 10
end

local fmt = "%d%%"
local caption = {"robotarmy-task-names.task-heal"}
return {
	process = process,
	shouldRetask = function() return false end, -- We retask manually in process
	shouldReinforce = function() return false end,
	updateUI = function(squad)
		local p = squad.taskData and fmt:format(squad.taskData.avg) or "-"
		return caption, p
	end,
}
