-- This is used both during data stage and control stage
local tonumber = tonumber
local function factorify(color)
	color = color:gsub("#", "")
	return {r = tonumber(color:sub(1,2), 16) / 255, g = tonumber(color:sub(3,4), 16) / 255, b = tonumber(color:sub(5,6), 16) / 255, a = 0.6}
end
local function all(input)
	local ret = {}
	for color in input:gmatch("(#?%w+)[%p%s]?") do
		local c = factorify(color)
		table.insert(ret, {
			name = color:gsub("#", ""),
			color = c,
		})
	end
	return ret
end

return {readString=all, stringToFactorio=factorify}
