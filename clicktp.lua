-- loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/clicktp.lua"))()
local Player = game.Players.LocalPlayer
local PlyRP = Player.Character:WaitForChild("HumanoidRootPart")
local mouse = Player:GetMouse()
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(key)
	if key.KeyCode == Enum.KeyCode.B then
		if mouse.Target then
			PlyRP.CFrame = CFrame.new(mouse.Hit.x, mouse.Hit.y + 10, mouse.Hit.z)
		end
	end
end)