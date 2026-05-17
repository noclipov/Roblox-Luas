local msg = loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/notify.lua"))()
repeat task.wait() until game.IsLoaded
if not isrbxactive or not setfpscap then msg.Mini("Coral", "Your executor rlly sucks", 0.1); return end
local maxfps
if getfpscap then maxfps = getfpscap() else maxfps = 120 end
game:GetService("RunService").RenderStepped:Connect(function()
	if not isrbxactive() then setfpscap(15)
	else setfpscap(maxfps) end
end)