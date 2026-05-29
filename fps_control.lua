local FpsControl = {}
FpsControl.__index = FpsControl

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer

local LINK = "https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/fps_control.lua"

-- Внутреннее состояние модуля
local isRunning = false
local fpsThread = nil
local maxFps = (getfpscap and getfpscap()) or 120

-- Функция отправки уведомлений
local function notify(text)
    local success, notificationLib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/notify.lua"))()
    end)
    if success and notificationLib and notificationLib.Mini then
        notificationLib.Mini("Purple", text, 2)
    else
        print("[FpsControl]: " .. text)
    end
end

-- Запуск контроля FPS
function FpsControl.Start()
    if isRunning then return end
    
    -- Проверка функций эксплойта
    if not isrbxactive or not setfpscap or not getfpscap then
        local success, notificationLib = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/notify.lua"))()
        end)
        if success and notificationLib and notificationLib.Mini then
            notificationLib.Mini("Coral", "Your executor rlly sucks", 0)
        else
            warn("FpsControl: Missing required executor functions (isrbxactive, setfpscap, getfpscap).")
        end
        return
    end

    isRunning = true
    maxFps = getfpscap() or 120
    
    local lastState = nil
    
    -- Основной поток отслеживания активности окна
    fpsThread = task.spawn(function()
        while isRunning do
            task.wait()
            local newState = isrbxactive()
            if newState ~= lastState then
                lastState = newState
                task.wait(not newState and 5 or 0)
                if isRunning then -- Дополнительная проверка на случай, если модуль выключили за 5 секунд ожидания
                    setfpscap(newState and maxFps or 5)
                end
            end
        end
    end)

    -- Настройка автопереноса при телепорте
    if queue_on_teleport then
        queue_on_teleport('task.wait(0.2); loadstring(game:HttpGet("'..LINK..'"))()')
    end

    notify("FPS-Control: Loaded")
end

-- Остановка контроля FPS и сброс настроек
function FpsControl.Stop()
    if not isRunning then return end
    isRunning = false
    
    if fpsThread then
        task.cancel(fpsThread)
        fpsThread = nil
    end
    
    if setfpscap and maxFps then
        setfpscap(maxFps)
    end
    
    print("[FpsControl]: Stopped and FPS restored.")
end

-- Автоматический сброс при выходе из игры
Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        FpsControl.Stop()
    end
end)

return FpsControl