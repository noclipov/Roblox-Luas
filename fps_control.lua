if not isrbxactive or not setfpscap then return end
game:GetService("RunService").RenderStepped:Connect(function()
	if isrbxactive and not isrbxactive() then setfpscap(15)
	else setfpscap(120) end
end)