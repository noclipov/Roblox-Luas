-- loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/anti_afk.lua"))()
while not game.IsLoaded do task.wait() end
local LINK = "https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/anti_afk.lua"
local msg = loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/Libs/notify.lua"))()
if not _G.AntiAfkLoaded then
	local gcn = getconnections or get_signal_cons
	if gcn then
		for i, v in gcn(game.Players.LocalPlayer.Idled) do
			pcall(function()
				if v["Disable"] then
					v["Disable"](v)
				elseif v["Disconnect"] then
					v["Disconnect"](v)
				end
			end)
		end
	end
	local VirtualUser = cloneref(game:GetService("VirtualUser"))
	game.Players.LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
	_G.AntiAfkLoaded = true
	queue_on_teleport('_G.AntiAfkLoaded = false; task.wait(0.2); loadstring(game:HttpGet("'..LINK..'"))()')
	msg.Mini("Purple", "Anti-AFK: Loaded", 2)
end
