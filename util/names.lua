local idName = "robotarmy-squad-names.id"

-- These persist through the save for each colored-id per force
local function getUniqueSquadName(force, id)
	if global.assignedNames[force][id] then return global.assignedNames[force][id] end
	if #global.availableNames[force] == 0 then
		global.assignedNames[force][id] = {idName, id}
	else
		global.assignedNames[force][id] = table.remove(global.availableNames[force], math.random(1, #global.availableNames[force]))
	end
	return global.assignedNames[force][id]
end

return getUniqueSquadName
