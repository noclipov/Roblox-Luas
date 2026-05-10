local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Notify = {}

-- [[ ТАБЛИЦА ПРИЯТНЫХ ПАСТЕЛЬНЫХ ПРЕСЕТОВ ]]
local PRESETS = {
    Purple = Color3.fromRGB(167, 139, 250), -- Элегантный лавандовый (по умолчанию)
    Mint   = Color3.fromRGB(110, 230, 160), -- Освежающий мятный
    Coral  = Color3.fromRGB(248, 113, 113), -- Мягкий нежно-красный
    Honey  = Color3.fromRGB(251, 191, 36),  -- Приглушенный янтарный
    Sky    = Color3.fromRGB(96, 165, 250),  -- Спокойный небесный
    Rose   = Color3.fromRGB(244, 114, 182), -- Пыльно-розовый
}

-- [[ НАДЕЖНЫЕ И ЧЕТКИЕ ШРИФТЫ ]]
local FONTS = {
    Title = Enum.Font.SourceSansBold,       
    Desc  = Enum.Font.SourceSans,           
    Mini  = Enum.Font.SourceSansSemibold,   
    Button = Enum.Font.SourceSansSemibold   
}

local COLORS = {
    Background_Top = Color3.fromRGB(30, 30, 40),
    Background_Bottom = Color3.fromRGB(20, 20, 25),
    Mini_Background = Color3.fromRGB(20, 20, 26),
    Text_Title = Color3.fromRGB(255, 255, 255),
    Text_Desc = Color3.fromRGB(215, 215, 225),
}

local NOTIFY_WIDTH = 340
local NOTIFY_PADDING = 10

-- Функция выбора пресета или кастомного цвета
local function resolveColor(customColorOrPreset)
    if typeof(customColorOrPreset) == "Color3" then
        return customColorOrPreset
    elseif typeof(customColorOrPreset) == "string" then
        local presetColor = PRESETS[customColorOrPreset]
        if presetColor then
            return presetColor
        end
    end
    return PRESETS.Purple
end

-- Вспомогательная функция для создания контейнера
local function getContainer()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local sg = playerGui:FindFirstChild("Noclipov_UI_Storage")
    
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "Noclipov_UI_Storage"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 999
        sg.IgnoreGuiInset = true 
        sg.Parent = playerGui
        
        local container = Instance.new("Frame")
        container.Name = "NotifyContainer"
        container.Position = UDim2.new(1, -25, 1, -25)
        container.Size = UDim2.new(0, NOTIFY_WIDTH, 0, 0)
        container.AutomaticSize = Enum.AutomaticSize.Y
        container.AnchorPoint = Vector2.new(1, 1)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.Parent = sg
        
        local layout = Instance.new("UIListLayout")
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Padding = UDim.new(0, NOTIFY_PADDING)
        layout.Parent = container
    end
    
    return sg.NotifyContainer
end

-- Вспомогательная функция для проверки "бесконечного" времени жизни
local function isInfinite(duration)
    return duration == nil or duration == 0 or duration == "inf" or duration == math.huge
end

-- [[ ВЕРСИЯ 1: ПОЛНОЕ УВЕДОМЛЕНИЕ ]]
function Notify.New(customColorOrPreset, title, text, duration, callback, buttonText)
    local accentColor = resolveColor(customColorOrPreset)
    local container = getContainer()
    
    local hasTimer = not isInfinite(duration)
    local hasCallback = typeof(callback) == "function" or not hasTimer
    buttonText = buttonText or (hasTimer and "ОТКРЫТЬ" or "ЗАКРЫТЬ")
    
    local placeholder = Instance.new("Frame")
    placeholder.Size = UDim2.new(1, 0, 0, 0)
    placeholder.BackgroundTransparency = 1
    placeholder.BorderSizePixel = 0
    placeholder.Parent = container

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(1.3, 0, 0, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.BorderSizePixel = 0
    frame.Parent = placeholder
    
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

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -45, 0, 18)
    titleLbl.Position = UDim2.new(0, 25, 0, 12)
    titleLbl.Text = tostring(title):upper()
    titleLbl.TextColor3 = accentColor
    titleLbl.Font = FONTS.Title
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.BackgroundTransparency = 1
    titleLbl.Parent = frame

    -- Тонкий таймер под заголовком (Оптимизирован для плавности)
    local progressGradient
    if hasTimer then
        local barContainer = Instance.new("Frame")
        barContainer.Size = UDim2.new(1, -45, 0, 2)
        barContainer.Position = UDim2.new(0, 25, 0, 34)
        barContainer.BackgroundColor3 = accentColor
        barContainer.BackgroundTransparency = 0.85
        barContainer.BorderSizePixel = 0
        barContainer.ClipsDescendants = true
        barContainer.Parent = frame

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = barContainer

        local progressInner = Instance.new("Frame")
        progressInner.Size = UDim2.new(1, 0, 1, 0)
        progressInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Белый для применения градиента
        progressInner.BorderSizePixel = 0
        progressInner.Parent = barContainer

        local innerCorner = Instance.new("UICorner")
        innerCorner.CornerRadius = UDim.new(1, 0)
        innerCorner.Parent = progressInner

        -- Плавный аппаратный градиент-слайдер вместо изменения размера фрейма
        progressGradient = Instance.new("UIGradient")
        progressGradient.Color = ColorSequence.new(accentColor)
        progressGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.999, 0),
            NumberSequenceKeypoint.new(1, 1)
        })
        progressGradient.Offset = Vector2.new(0, 0)
        progressGradient.Parent = progressInner
    end

    local availableWidth = NOTIFY_WIDTH - 45
    local descHeight = game:GetService("TextService"):GetTextSize(text, 14, FONTS.Desc, Vector2.new(availableWidth, 1000)).Y
    
    local textYOffset = hasTimer and 46 or 40
    
    local finalHeight
    if hasCallback then
        finalHeight = math.max(descHeight + textYOffset + 38, 106)
    else
        finalHeight = math.max(descHeight + textYOffset + 18, 84)
    end

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -45, 0, descHeight)
    descLbl.Position = UDim2.new(0, 25, 0, textYOffset)
    descLbl.Text = text
    descLbl.TextColor3 = COLORS.Text_Desc
    descLbl.Font = FONTS.Desc
    descLbl.TextSize = 14
    descLbl.TextWrapped = true
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.TextYAlignment = Enum.TextYAlignment.Top
    descLbl.LineHeight = 1.15
    descLbl.BackgroundTransparency = 1
    descLbl.Parent = frame

    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(0, 3, 1, -20)
    accentLine.Position = UDim2.new(0, 12, 0, 10)
    accentLine.BackgroundColor3 = accentColor
    accentLine.BorderSizePixel = 0
    accentLine.Parent = frame
    
    local lineCorner = Instance.new("UICorner")
    lineCorner.CornerRadius = UDim.new(1, 0)
    lineCorner.Parent = accentLine

    local function closeNotification()
        local slideOut = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1.3, 0, 0, 0)
        })
        slideOut:Play()
        slideOut.Completed:Wait()
        
        local collapse = TweenService:Create(placeholder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 0)
        })
        collapse:Play()
        collapse.Completed:Wait()
        
        placeholder:Destroy()
    end

    local btnConnection
    if hasCallback then
        local textService = game:GetService("TextService")
        local btnTextWidth = textService:GetTextSize(tostring(buttonText):upper(), 12, FONTS.Button, Vector2.new(200, 50)).X
        local btnWidth = math.round(math.clamp(btnTextWidth + 24, 80, 140))

        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.new(0, btnWidth, 0, 24)
        actionBtn.Position = UDim2.new(1, -20, 1, -12)
        actionBtn.AnchorPoint = Vector2.new(1, 1)
        actionBtn.BackgroundColor3 = accentColor
        actionBtn.BackgroundTransparency = 0.93
        actionBtn.Text = tostring(buttonText):upper()
        actionBtn.TextColor3 = accentColor
        actionBtn.Font = FONTS.Button
        actionBtn.TextSize = 12
        actionBtn.AutoButtonColor = false
        actionBtn.Parent = frame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = actionBtn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = accentColor
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.75
        btnStroke.Parent = actionBtn

        actionBtn.MouseEnter:Connect(function()
            TweenService:Create(actionBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.8}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.4}):Play()
        end)
        actionBtn.MouseLeave:Connect(function()
            TweenService:Create(actionBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.93}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.75}):Play()
        end)

        btnConnection = actionBtn.MouseButton1Click:Connect(function()
            if btnConnection then btnConnection:Disconnect() end
            if typeof(callback) == "function" then
                task.spawn(callback)
            end
            closeNotification()
        end)
    end

    placeholder.Size = UDim2.new(1, 0, 0, finalHeight)
    
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    -- Плавное аппаратное убывание таймера через сдвиг градиента
    if hasTimer and progressGradient then
        local progressTween = TweenService:Create(progressGradient, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Offset = Vector2.new(-1, 0)
        })
        progressTween:Play()

        local timerDelay
        timerDelay = progressTween.Completed:Connect(function()
            if timerDelay then timerDelay:Disconnect() end
            if btnConnection then btnConnection:Disconnect() end
            closeNotification()
        end)
    end
end

-- [[ ВЕРСИЯ 2: КОМПАКТНОЕ (МИНИ) УВЕДОМЛЕНИЕ ]]
function Notify.Mini(customColorOrPreset, text, duration, callback)
    local accentColor = resolveColor(customColorOrPreset)
    local container = getContainer()
    
    local hasTimer = not isInfinite(duration)
    local hasCallback = typeof(callback) == "function"
    
    local placeholder = Instance.new("Frame")
    placeholder.Size = UDim2.new(1, 0, 0, 36)
    placeholder.BackgroundTransparency = 1
    placeholder.BorderSizePixel = 0
    placeholder.Parent = container

    local frame = Instance.new(hasCallback and "TextButton" or "Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(1.3, 0, 0, 0)
    frame.BackgroundColor3 = COLORS.Mini_Background
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = placeholder
    
    if hasCallback then
        frame.Text = ""
        frame.AutoButtonColor = false
    end
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = frame

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 16)
    indicator.Position = UDim2.new(0, 12, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BackgroundColor3 = accentColor
    indicator.BorderSizePixel = 0
    indicator.Parent = frame
    
    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator

    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size = UDim2.new(1, -36, 1, hasTimer and -12 or 0)
    msgLbl.Position = UDim2.new(0, 24, 0, hasTimer and 3 or 0)
    msgLbl.Text = text
    msgLbl.TextColor3 = Color3.fromRGB(245, 245, 245)
    msgLbl.Font = FONTS.Mini
    msgLbl.TextSize = 14
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.BackgroundTransparency = 1
    msgLbl.Parent = frame

    -- Полоска таймера в мини-сообщении (Оптимизирована для плавности)
    local progressGradient
    if hasTimer then
        local progressContainer = Instance.new("Frame")
        progressContainer.Size = UDim2.new(1, -32, 0, 1)
        progressContainer.Position = UDim2.new(0, 16, 1, -5)
        progressContainer.BackgroundColor3 = accentColor
        progressContainer.BackgroundTransparency = 0.92
        progressContainer.BorderSizePixel = 0
        progressContainer.ClipsDescendants = true
        progressContainer.Parent = frame

        local progressInner = Instance.new("Frame")
        progressInner.Size = UDim2.new(1, 0, 1, 0)
        progressInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        progressInner.BorderSizePixel = 0
        progressInner.Parent = progressContainer
        
        -- Специальный скользящий градиент для плавного убывания
        progressGradient = Instance.new("UIGradient")
        progressGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, accentColor),
            ColorSequenceKeypoint.new(1, accentColor)
        })
        progressGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.999, 0),
            NumberSequenceKeypoint.new(1, 1)
        })
        progressGradient.Offset = Vector2.new(0, 0)
        progressGradient.Parent = progressInner
    end

    local textWidth = msgLbl.TextBounds.X + 42
    local finalWidth = math.round(math.clamp(textWidth, 110, 320))

    placeholder.Size = UDim2.new(0, finalWidth, 0, 36)
    frame.Size = UDim2.new(1, 0, 1, 0)

    local isDestroyed = false
    local function closeMini()
        if isDestroyed then return end
        isDestroyed = true
        
        local slideOut = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1.3, 0, 0, 0),
            BackgroundTransparency = 0.5
        })
        slideOut:Play()
        slideOut.Completed:Wait()
        
        local collapse = TweenService:Create(placeholder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, finalWidth, 0, 0)
        })
        collapse:Play()
        collapse.Completed:Wait()
        
        placeholder:Destroy()
    end

    local mouseEnterConnection
    local mouseLeaveConnection
    local clickConnection

    local canCloseWithMouse = false
    task.delay(1, function()
        canCloseWithMouse = true
    end)

    if hasCallback then
        mouseEnterConnection = frame.MouseEnter:Connect(function()
            TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.05}):Play()
        end)
        
        mouseLeaveConnection = frame.MouseLeave:Connect(function()
            TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
        end)

        clickConnection = frame.MouseButton1Click:Connect(function()
            if not canCloseWithMouse then return end
            
            if mouseEnterConnection then mouseEnterConnection:Disconnect() end
            if mouseLeaveConnection then mouseLeaveConnection:Disconnect() end
            if clickConnection then clickConnection:Disconnect() end
            
            task.spawn(callback)
            closeMini()
        end)
    else
        mouseEnterConnection = frame.MouseEnter:Connect(function()
            if not canCloseWithMouse then
                while not canCloseWithMouse do
                    task.wait(0.1)
                end
            end
            
            if mouseEnterConnection then mouseEnterConnection:Disconnect() end
            closeMini()
        end)
    end

    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    -- Плавное аппаратное убывание мини-таймера
    if hasTimer and progressGradient then
        local progressTween = TweenService:Create(progressGradient, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Offset = Vector2.new(-1, 0)
        })
        progressTween:Play()
        progressTween.Completed:Connect(function()
            if mouseEnterConnection then mouseEnterConnection:Disconnect() end
            if mouseLeaveConnection then mouseLeaveConnection:Disconnect() end
            if clickConnection then clickConnection:Disconnect() end
            closeMini()
        end)
    end
end

return Notify