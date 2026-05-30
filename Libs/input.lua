local Camera = workspace:FindFirstChildWhichIsA("Camera")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Library = {}
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/Libs/input.lua"))()
Library.MouseClick = function(x, y, wtime)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, nil, 0)
    if wtime then task.wait(wtime) end
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, nil, 0)
end
Library.MoveMouse = function(x, y)
    VirtualInputManager:SendMouseMoveEvent(x, y, nil)
end
Library.PressKey = function(keycode, wtime)
    VirtualInputManager:SendKeyEvent(true, keycode, false, nil)
    if wtime then task.wait(wtime) end
    VirtualInputManager:SendKeyEvent(false, keycode, false, nil)
end
Library.CenterMouseClick = function()
    Library.MouseClick(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
end
return Library
