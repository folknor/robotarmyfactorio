local function handle(squad)
	for i = 1, #squad do
		local member = squad(i)
		if member.valid then
			member.set_command({
				type = defines.command.go_to_location,
				destination = member.position,
				distraction = defines.distraction.by_anything,
			})
		end
	end
end

return handle
