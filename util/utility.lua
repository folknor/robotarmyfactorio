
-------------------------------------------------------------------------------
-- Random standalone utility functions
--

local _log = require("util.logger")

local function removeInvalidEntities(t)
	for i = #t, 1, -1 do if not t[i].valid then table.remove(t, i) end end
	return t
end

-- orientation is 1=north 0.25=east 0.5=south 0.75=west
local function getInterpolatedPosition(entity, distance)
	local radians = ((360 * entity.orientation) - 90) * math.pi / 180
	return (distance * math.cos(radians)) + entity.position.x, (distance * math.sin(radians)) + entity.position.y
end

-- key: luaentity (assembler), value: position
local _interpolationCache = {}
local function getAssemblerSpawnPosition(entity)
	if not _interpolationCache[entity] then _interpolationCache[entity] = {getInterpolatedPosition(entity, 10)} end
	local ret
	local radius = 10
	repeat
		ret = entity.surface.find_non_colliding_position(entity.name, _interpolationCache[entity], radius, 1)
		radius = radius + 2
	until ret
	return ret
end

-- This function also re-applies squad.home every time
local function findClosestAssembler(squad)
	local from = squad.home or squad:GetPosition()
	local best
	local closestAssembler
	for _, as in next, global.assemblers do
		if as.valid and as.force.name == squad.force then
			local d = (((from.x - as.position.x) ^ 2) + ((from.y - as.position.y) ^ 2)) ^ 0.5
			if not best or d < best then
				best = d
				closestAssembler = as
			end
		end
	end
	-- Sanity check just in case
	if not closestAssembler then
		if not game.forces[squad.force] then _log(squad, _log.FORCE_UNKNOWN) end
		return game.forces.player.players[math.random(1, #game.forces.player.players)]
	end
	squad.home = getAssemblerSpawnPosition(closestAssembler)
	return closestAssembler, best
end

local _MESSAGE_THROTTLE = 60 * 60 -- Per message (game.print/force.print)
-- key: whatever (hashmap), value: tick
local throttle = {}
local function throttledMessage(force, message, ...)
	if throttle[force.name] and game.tick < throttle[force.name] then return end
	throttle[force.name] = game.tick + _MESSAGE_THROTTLE
	force.print({message, ...})
	return 30
end

local function getNonCollidingPosition(droidName, squad)
	local surface = squad:GetSurface()
	local anchor = squad:GetPosition()
	local radius = #squad * 2
	local ret
	repeat
		ret = surface.find_non_colliding_position(droidName, anchor, radius, 1)
		radius = radius + 4
	until ret
	return ret
end

-- XXX EXPERIMENTAL
-- Trying to find an efficient way to judge universally whether or not
-- a squad is "stuck".
-- But then we also would need to define "stuck" first.
-- This code runs now, but it's not used. The only thing it does is print
-- results to stdout.
local newQueue
do
	local abs, floor, tinsert, tremove = math.abs, math.floor, table.insert, table.remove
	local _wait = 60 * 5
	local calc = ": (total=%d / #%d) = %d < 10"
	local meta = {
		__call = function(self, squad, diff)
			if not self.nextUpdate or (game.tick > self.nextUpdate) then
				self.nextUpdate = game.tick + _wait
				local p = squad:GetPosition()
				local n = floor(abs(p.x)+abs(p.y))
				if #self.queue == self.max then
					tremove(self.queue, 1)
					tinsert(self.queue, n)
				else
					tinsert(self.queue, n)
				end
			end
			if #self.queue < self.max then return end
			local total = 0
			for i = 1, (#self.queue - 1) do
				total = total + abs(self.queue[i] - self.queue[i + 1])
			end
			return ((total / #self.queue) < diff)
		end,
		__tostring = function(self)
			local s = "{" .. table.concat(self.queue, ", ") .. "}"
			if #self.queue < 2 then return s end
			local total = 0
			for i = 1, (#self.queue - 1) do
				total = total + abs(self.queue[i] - self.queue[i + 1])
			end
			s = s .. calc:format(total, #self.queue, (total / #self.queue))
			return s
		end
	}
	newQueue = function(size) return setmetatable({ max = size, queue = {} }, meta) end
end

-- Not actually a real deepcopy, but it's all we need for now.
local deepcopy
deepcopy = function(input)
	local copy
	if type(input) == "table" then
		copy = {}
		for k, v in next, input, nil do copy[deepcopy(k)] = deepcopy(v) end
	else
		copy = input
	end
	return copy
end

return {
	deepcopy = deepcopy,
	newDistanceChecker = newQueue,
	findClosestAssembler = findClosestAssembler,
	throttledMessage = throttledMessage,
	clearInvalid = removeInvalidEntities,
	assemblerPosition = getAssemblerSpawnPosition,
	interpolatedPosition = getInterpolatedPosition,
	findNonCollidingPosition = getNonCollidingPosition,
}
