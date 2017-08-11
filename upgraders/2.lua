-- This upgrader makes sure that the .entityUnitNameMap is valid, and populated.
-- Note that you cant require() in these files.
-- The global scope is available though.
return function(meta, util, log)
	global.entityUnitNameMap = {}
	for _, squad in next, global.squads do
		for i = 1, #squad do
			local m = squad(i)
			if m.valid then global.entityUnitNameMap[m] = m.name end
		end
	end
	return 3
end
