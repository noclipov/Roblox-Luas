-- loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/fps_control.lua"))()
while not game.IsLoaded do task.wait() end
local LINK = "https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/fps_control.lua"
if not isrbxactive or not setfpscap then msg.Mini("Coral", "Your executor rlly sucks", 0); return end
local maxfps
if getfpscap then maxfps = getfpscap() else maxfps = 120 end
if not _G.FPSControlLoaded then
	_G.FPSControlLoaded = true
	game:GetService("RunService").RenderStepped:Connect(function()
		if not isrbxactive() then setfpscap(5)
		else setfpscap(maxfps) end
	end)
	game.Players.PlayerRemoving:Connect(function(ply) if ply == game.Players.LocalPlayer then setfpscap(maxfps) end end)
	queue_on_teleport('_G.FPSControlLoaded = false; task.wait(0.2); loadstring(game:HttpGet("'..LINK..'"))()')
	loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/notify.lua"))().Mini("Purple", "FPS-Control: Loaded", 2)
end
