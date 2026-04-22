local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Library = {}
Library.Link = "https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/NotifyModule.lua"
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/NotifyModule.lua"))()
local COLORS = {
    Background_Top = Color3.fromRGB(35, 35, 45),
    Background_Bottom = Color3.fromRGB(25, 25, 30),
    Mini_Background = Color3.fromRGB(30, 30, 35),
    Text_Title = Color3.fromRGB(255, 255, 255),
    Text_Desc = Color3.fromRGB(200, 200, 210),

    Success = Color3.fromRGB(140, 100, 255),
    Warning = Color3.fromRGB(255, 190, 70),
    Error   = Color3.fromRGB(255, 90, 90),
}
local NOTIFY_WIDTH = 340
local NOTIFY_PADDING = 12
local function getContainer()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local sg = playerGui:FindFirstChild("Noclipov_UI_Storage")
    
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "Noclipov_UI_Storage"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 999
        sg.Parent = playerGui
        
        local container = Instance.new("Frame")
        container.Name = "NotifyContainer"
        container.Position = UDim2.new(1, -25, 1, -25)
        container.Size = UDim2.new(0, NOTIFY_WIDTH, 0.8, 0)
        container.AnchorPoint = Vector2.new(1, 1)
        container.BackgroundTransparency = 1
        container.Parent = sg
        
        local layout = Instance.new("UIListLayout")
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Padding = UDim.new(0, NOTIFY_PADDING)
        layout.Parent = container
    end
    
    return sg.NotifyContainer
end

Library.New = function(type, title, text, duration)
    duration = duration or 5
    local accentColor = COLORS[type] or COLORS.Success
    local container = getContainer()
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = container
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = frame
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.Background_Top),
        ColorSequenceKeypoint.new(1, COLORS.Background_Bottom)
    })
    gradient.Rotation = 90
    gradient.Parent = frame

    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(1, 0, 1, 0)
    inner.BackgroundTransparency = 1
    inner.Parent = frame

    -- Заголовок
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -45, 0, 18)
    titleLbl.Position = UDim2.new(0, 25, 0, 10)
    titleLbl.Text = title:upper()
    titleLbl.TextColor3 = accentColor
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1
    titleLbl.Parent = inner

    -- Полоска-разделитель (Таймер)
    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(1, -45, 0, 2)
    barContainer.Position = UDim2.new(0, 25, 0, 32)
    barContainer.BackgroundColor3 = accentColor
    barContainer.BackgroundTransparency = 0.85
    barContainer.BorderSizePixel = 0
    barContainer.ClipsDescendants = true
    barContainer.Parent = inner

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = barContainer

    local progressInner = Instance.new("Frame")
    progressInner.Size = UDim2.new(1, 0, 1, 0)
    progressInner.BackgroundColor3 = accentColor
    progressInner.BorderSizePixel = 0
    progressInner.Parent = barContainer

    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(1, 0)
    innerCorner.Parent = progressInner

    -- Описание
    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -45, 0, 0)
    descLbl.Position = UDim2.new(0, 25, 0, 44)
    descLbl.Text = text
    descLbl.TextColor3 = COLORS.Text_Desc
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextSize = 14
    descLbl.TextWrapped = true
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.TextYAlignment = Enum.TextYAlignment.Top
    descLbl.LineHeight = 1.1
    descLbl.BackgroundTransparency = 1
    descLbl.Parent = inner

    -- Акцентная линия слева
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(0, 3, 1, -20)
    accentLine.Position = UDim2.new(0, 12, 0, 10)
    accentLine.BackgroundColor3 = accentColor
    accentLine.BorderSizePixel = 0
    accentLine.Parent = inner
    
    local lineCorner = Instance.new("UICorner")
    lineCorner.CornerRadius = UDim.new(1, 0)
    lineCorner.Parent = accentLine

    -- Анимации
    local descHeight = descLbl.TextBounds.Y
    local finalHeight = math.max(descHeight + 60, 80)

    frame.Position = UDim2.new(1.3, 0, 0, 0)
    
    TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, finalHeight)
    }):Play()

    TweenService:Create(progressInner, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    }):Play()

    task.delay(duration, function()
        local out = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1.3, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 0)
        })
        out:Play()
        out.Completed:Wait()
        frame:Destroy()
    end)
end

Library.Mini = function(type, text, duration)
    duration = duration or 3
    local accentColor = COLORS[type] or COLORS.Success
    local container = getContainer()
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 0, 0, 38)
    frame.BackgroundColor3 = COLORS.Mini_Background
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = container
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Parent = frame

    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(1, 0, 1, 0)
    inner.BackgroundTransparency = 1
    inner.Parent = frame

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 4, 0, 16)
    indicator.Position = UDim2.new(0, 10, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BackgroundColor3 = accentColor
    indicator.BorderSizePixel = 0
    indicator.Parent = inner
    
    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator

    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size = UDim2.new(1, -35, 1, 0)
    msgLbl.Position = UDim2.new(0, 24, 0, 0)
    msgLbl.Text = text
    msgLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    msgLbl.Font = Enum.Font.GothamMedium
    msgLbl.TextSize = 13
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.BackgroundTransparency = 1
    msgLbl.Parent = inner

    local progressInner = Instance.new("Frame")
    progressInner.Size = UDim2.new(1, 0, 0, 2)
    progressInner.Position = UDim2.new(0, 0, 1, -2)
    progressInner.BackgroundColor3 = accentColor
    progressInner.BorderSizePixel = 0
    progressInner.Parent = frame

    local textWidth = msgLbl.TextBounds.X + 45
    local finalWidth = math.clamp(textWidth, 120, 300)

    frame.Position = UDim2.new(1.3, 0, 0, 0)
    
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, finalWidth, 0, 38)
    }):Play()

    TweenService:Create(progressInner, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()

    task.delay(duration, function()
        local out = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1.3, 0, 0, 0),
            BackgroundTransparency = 1
        })
        out:Play()
        out.Completed:Wait()
        frame:Destroy()
    end)
end

return Library