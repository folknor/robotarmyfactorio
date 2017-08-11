
local transferStatus = {}

local function GetActiveTransfer(player)
	return transferStatus[player.index]
end
_G.GetActiveTransfer = GetActiveTransfer

local function ExecuteTransfer(player, toSquadId)
	local squad = _G.GetSquad(player.force.name, transferStatus[player.index], true)
	transferStatus[player.index] = nil

	if squad then
		local success = squad:Transfer(toSquadId)
		if success then
			squad:Destroy()
		end
	end

	_G.UpdateSquadButtons(player)
	_G.UpdateCommandFrame(player, squad.id)
end
_G.ExecuteTransfer = ExecuteTransfer

-- XXX This task doesn't properly handle it if the player has selected multiple
-- XXX squads. We would do it by simply having transferStatus[p.index] = {} and doing
-- XXX transferStatus[p.index][squadId] = true and then looping the squads.
-- e-z-p-z
local hleplul = {"robotarmy-interface.transfer-squad-help"}
local function handle(squad, player)
	player.print(hleplul)

	transferStatus[player.index] = squad.id
	_G.UpdateSquadButtons(player)

	-- Hide the command frame
	global.commandOpen[player.index] = squad.id
	_G.UpdateCommandFrame(player, squad.id)
end

return handle
