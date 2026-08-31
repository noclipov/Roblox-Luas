local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")   -- используем CoreGui

local TimerModule = {}
TimerModule.__index = TimerModule

-- [[ НАСТРОЙКИ ]]
local UI_NAME = "Noclipov_UniversalTimer_System"
local COLORS = {
    Background = Color3.fromRGB(25, 25, 30),
    Accent = Color3.fromRGB(140, 100, 255),
    Text = Color3.fromRGB(240, 240, 240),
    Shadow = Color3.fromRGB(0, 0, 0),
}
local SHADOW_ID = "rbxassetid://1316045217"

function TimerModule.new(mode)
    local self = setmetatable({}, TimerModule)
    
    self.Mode = mode or "Timer" -- "Timer" или "Clock"
    self.startTime = 0
    self.elapsedTime = 0
    self.isRunning = false
    
    self:_buildInterface()
    
    self.connection = RunService.RenderStepped:Connect(function()
        self:_update()
    end)
    
    return self
end

function TimerModule:_buildInterface()
    -- Работаем с CoreGui
    local coreGui = CoreGui
    
    -- Удаляем старый GUI, если есть
    local old = coreGui:FindFirstChild(UI_NAME)
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = UI_NAME
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = coreGui
    self.Gui = sg

    -- ТЕНЬ
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 1)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 90)
    shadow.Size = UDim2.new(0, 160, 0, 45)
    shadow.BackgroundTransparency = 1
    shadow.Image = SHADOW_ID
    shadow.ImageColor3 = COLORS.Shadow
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Parent = sg

    -- ГЛАВНЫЙ ФРЕЙМ (Прозрачный фон)
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(1, -10, 1, -10)
    main.Position = UDim2.new(0, 5, 0, 5)
    main.BackgroundColor3 = COLORS.Background
    main.BackgroundTransparency = 0.5
    main.BorderSizePixel = 0
    main.Parent = shadow

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = main
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Parent = main

    -- ВНУТРЕННЯЯ ПОЛОСКА
    local accent = Instance.new("Frame")
    accent.Name = "InnerAccent"
    accent.Size = UDim2.new(1, -40, 0, 2)
    accent.Position = UDim2.new(0.5, 0, 1, -6)
    accent.AnchorPoint = Vector2.new(0.5, 0)
    accent.BackgroundColor3 = COLORS.Accent
    accent.BorderSizePixel = 0
    accent.ZIndex = 7
    accent.Parent = main

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accent

    -- ТЕКСТ
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, -8)
    label.BackgroundTransparency = 1
    label.TextColor3 = COLORS.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.RichText = true
    label.Text = "00:00:00"
    label.ZIndex = 8
    label.Parent = main
    
    self.Label = label
end

-- [[ МЕТОДЫ ]]

function TimerModule:SetMode(mode)
    self.Mode = mode
end

function TimerModule:Start()
    if self.Mode == "Timer" and not self.isRunning then
        self.startTime = os.clock() - self.elapsedTime
        self.isRunning = true
    end
end

function TimerModule:Stop()
    if self.isRunning then
        self.elapsedTime = os.clock() - self.startTime
        self.isRunning = false
    end
end

function TimerModule:Reset()
    self.elapsedTime = 0
    self.startTime = self.isRunning and os.clock() or 0
end

function TimerModule:Destroy()
    if self.connection then self.connection:Disconnect() end
    if self.Gui then self.Gui:Destroy() end
end

function TimerModule:_update()
    if not self.Label then return end
    
    if self.Mode == "Clock" then
        local timeString = os.date("%H:%M:%S")
        self.Label.Text = timeString
    else
        local total = self.isRunning and (os.clock() - self.startTime) or self.elapsedTime
        local mins = math.floor(total / 60)
        local secs = math.floor(total % 60)
        local ms = math.floor((total % 1) * 100)
        self.Label.Text = string.format("%02d:%02d.<font size='12'>%02d</font>", mins, secs, ms)
    end
end

return TimerModule