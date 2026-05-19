-- loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/fps_control.lua"))()
while not game.IsLoaded do task.wait() end
local LINK = "https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/fps_control.lua"
if not isrbxactive or not setfpscap or not getfpscap then msg.Mini("Coral", "Your executor rlly sucks", 0); return end
local maxfps = getfpscap and getfpscap() or 120
if not _G.FPSControlLoaded then
	_G.FPSControlLoaded = true
	local last_state
	local fpsthread = task.spawn(function()
		while _G.FPSControlLoaded do task.wait()
			local new_state = isrbxactive()
			if new_state ~= last_state then
				last_state = new_state
				task.wait(not new_state and 5 or 0.1)
				setfpscap(new_state and maxfps or 5)
			end
		end
	end)
	game.Players.PlayerRemoving:Connect(function(ply) _G.FPSControlLoaded = false; task.cancel(fpsthread) ;if ply == game.Players.LocalPlayer then setfpscap(maxfps) end end)
	queue_on_teleport('_G.FPSControlLoaded = false; task.wait(0.2); loadstring(game:HttpGet("'..LINK..'"))()')
	loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/notify.lua"))().Mini("Purple", "FPS-Control: Loaded", 2)
end
