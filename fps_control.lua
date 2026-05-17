if not isrbxactive or not setfpscap then return end
local maxfps = getfpscap and getfpscap() or 120
game:GetService("RunService").RenderStepped:Connect(function()
	if not isrbxactive() then setfpscap(15)
	else setfpscap(120) end
end)