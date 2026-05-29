local AntiAfk = {}
AntiAfk.__index = AntiAfk

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer

local LINK = "https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Anti-AFK.lua"

-- Внутреннее состояние модуля
local isRunning = false
local afkConnection = nil
local VirtualUser = cloneref and cloneref(game:GetService("VirtualUser")) or game:GetService("VirtualUser")

-- Функция отправки уведомлений
local function notify(text)
    local success, notificationLib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/notify.lua"))()
    end)
    if success and notificationLib and notificationLib.Mini then
        notificationLib.Mini("Purple", text, 2)
    else
        print("[AntiAfk]: " .. text)
    end
end

-- Запуск Anti-AFK
function AntiAfk.Start()
    if isRunning then return end
    isRunning = true

    -- Отключаем стандартные обработчики AFK у игрока
    local getConnections = getconnections or get_signal_cons
    if getConnections then
        for _, connection in ipairs(getConnections(LocalPlayer.Idled)) do
            pcall(function()
                if connection["Disable"] then
                    connection["Disable"](connection)
                elseif connection["Disconnect"] then
                    connection["Disconnect"](connection)
                end
            end)
        end
    end

    -- Создаем симуляцию ввода при уходе в AFK
    afkConnection = LocalPlayer.Idled:Connect(function()
        if not isRunning then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)

    -- Настройка автопереноса при телепорте
    if queue_on_teleport then
        queue_on_teleport('task.wait(0.2); loadstring(game:HttpGet("'..LINK..'"))()')
    end

    notify("Anti-AFK: Loaded")
end

-- Отключение Anti-AFK
function AntiAfk.Stop()
    if not isRunning then return end
    isRunning = false
    
    if afkConnection then
        afkConnection:Disconnect()
        afkConnection = nil
    end
    
    print("[AntiAfk]: Stopped.")
end

return AntiAfk