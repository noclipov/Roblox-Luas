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
    Background_Top = Color3.fromRGB(20, 24, 33),
    Background_Bottom = Color3.fromRGB(15, 18, 25),
    Stroke = Color3.fromRGB(35, 40, 55),
    Text_Title = Color3.fromRGB(255, 255, 255),
    Text_Desc = Color3.fromRGB(180, 185, 200),
    Text_Button = Color3.fromRGB(255, 255, 255),
    Card_Hover_Add = Color3.fromRGB(15, 15, 20) -- Значение для подсветки карточки при наведении
}

-- Утилита для плавной анимации ухода
local function fadeOutAndDestroy(frame, uiStroke, duration)
    local tweenInfo = TweenInfo.new(duration or 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    
    -- Анимируем прозрачность всех элементов внутри
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child, tweenInfo, { TextTransparency = 1 }):Play()
        elseif child:IsA("Frame") and child.Name ~= "TimerLine" then
            TweenService:Create(child, tweenInfo, { BackgroundTransparency = 1 }):Play()
        elseif child:IsA("UIStroke") then
            TweenService:Create(child, tweenInfo, { Transparency = 1 }):Play()
        elseif child:IsA("UIGradient") and child.Parent.Name == "TimerLine" then
            -- Линию таймера плавно гасим через прозрачность родителя
            TweenService:Create(child.Parent, tweenInfo, { BackgroundTransparency = 1 }):Play()
        end
    end
    
    -- Анимируем саму подложку и обводку
    if uiStroke then
        TweenService:Create(uiStroke, tweenInfo, { Transparency = 1 }):Play()
    end
    
    local mainTween = TweenService:Create(frame, tweenInfo, {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    })
    
    mainTween.Completed:Connect(function()
        frame:Destroy()
    end)
    
    mainTween:Play()
end

-- [[ МЕТОД СОЗДАНИЯ БОЛЬШОГО УВЕДОМЛЕНИЯ ]]
function Notify.Big(title: string, desc: string, buttonText: string?, presetName: string?, callback: () -> ()?)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Ищем или создаем контейнер
    local screenGui = playerGui:FindFirstChild("RobloxNotificationGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "RobloxNotificationGui"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 100
        screenGui.Parent = playerGui
    end
    
    local container = screenGui:FindFirstChild("BigNotificationsContainer")
    if not container then
        container = Instance.new("Frame")
        container.Name = "BigNotificationsContainer"
        container.Size = UDim2.new(0, 320, 1, 0)
        container.Position = UDim2.new(1, -340, 0, 0) -- Отступ справа
        container.BackgroundTransparency = 1
        container.Parent = screenGui
        
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 15)
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Parent = container
        
        local padding = Instance.new("UIPadding")
        padding.PaddingBottom = UDim.new(0, 20)
        padding.Parent = container
    end

    -- Цвет эффектов по пресету
    local accentColor = PRESETS[presetName] or PRESETS.Purple
    
    -- Главная карточка
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    -- Если кнопки нет, высота карточки уменьшается (130 вместо 170)
    local hasButton = buttonText and buttonText ~= ""
    local frameHeight = hasButton and 170 or 120
    
    frame.Size = UDim2.new(0, 300, 0, frameHeight)
    frame.BackgroundColor3 = COLORS.Background_Top
    frame.BorderSizePixel = 0
    frame.LayoutOrder = #container:GetChildren()
    frame.Parent = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Stroke
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    -- Градиент фона (сверху вниз)
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.Background_Top),
        ColorSequenceKeypoint.new(1, COLORS.Background_Bottom)
    })
    bgGradient.Rotation = 90
    bgGradient.Parent = frame

    -- Декоративная светящаяся полоска сверху
    local topBar = Instance.new("Frame")
    topBar.Name = "TopGlowingBar"
    topBar.Size = UDim2.new(1, 0, 0, 4)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = accentColor
    topBar.BorderSizePixel = 0
    topBar.Parent = frame
    
    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 16)
    topBarCorner.Parent = topBar
    
    -- Маскируем нижние углы полоски, чтобы они не вылезали за общие скругления
    local topBarMask = Instance.new("Frame")
    topBarMask.Size = UDim2.new(1, 0, 0, 2)
    topBarMask.Position = UDim2.new(0, 0, 0, 2)
    topBarMask.BackgroundColor3 = accentColor
    topBarMask.BorderSizePixel = 0
    topBarMask.Parent = topBar

    -- Текст заголовка
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -30, 0, 25)
    titleLabel.Position = UDim2.new(0, 15, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = FONTS.Title
    titleLabel.Text = title:upper()
    titleLabel.TextColor3 = COLORS.Text_Title
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    -- Текст описания
    local descLabel = Instance.new("TextLabel")
    -- Если кнопки нет, описание может занять чуть больше места по высоте
    local descHeight = hasButton and 65 or 60
    descLabel.Size = UDim2.new(1, -30, 0, descHeight)
    descLabel.Position = UDim2.new(0, 15, 0, 40)
    descLabel.BackgroundTransparency = 1
    descLabel.Font = FONTS.Desc
    descLabel.Text = desc
    descLabel.TextColor3 = COLORS.Text_Desc
    descLabel.TextSize = 14
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.Parent = frame

    -- Переменные для хранения подключений событий мыши
    local hoverEnterConn, hoverLeaveConn, clickConn

    local function closeBig()
        if hoverEnterConn then hoverEnterConn:Disconnect() end
        if hoverLeaveConn then hoverLeaveConn:Disconnect() end
        if clickConn then clickConn:Disconnect() end
        fadeOutAndDestroy(frame, stroke, 0.4)
    end

    -- [[ ЛОГИКА С КНОПКОЙ ИЛИ ЦЕЛИКОМ КЛИКАБЕЛЬНОЙ КАРТОЧКОЙ ]]
    if hasButton then
        -- Создаем обычную кнопку снизу
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -30, 0, 36)
        button.Position = UDim2.new(0, 15, 1, -51)
        button.BackgroundColor3 = accentColor
        button.Font = FONTS.Button
        button.Text = buttonText:upper()
        button.TextColor3 = COLORS.Text_Button
        button.TextSize = 13
        button.AutoButtonColor = false
        button.Parent = frame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = button
        
        -- Эффекты наведения на кнопку
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {
                BackgroundColor3 = accentColor:Lerp(Color3.new(1,1,1), 0.15)
            }):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {
                BackgroundColor3 = accentColor
            }):Play()
        end)
        
        clickConn = button.MouseButton1Click:Connect(function()
            if callback then task.spawn(callback) end
            closeBig()
        end)
    else
        -- КНОПКИ НЕТ: Делаем всю карточку кликабельной кнопкой-невидимкой поверх
        local overlayButton = Instance.new("TextButton")
        overlayButton.Name = "ClickOverlay"
        overlayButton.Size = UDim2.new(1, 0, 1, 0)
        overlayButton.BackgroundTransparency = 1
        overlayButton.Text = ""
        overlayButton.Parent = frame
        
        -- Эффект наведения (Hover) на всю карточку: плавная подсветка фона и легкое увеличение размера
        hoverEnterConn = overlayButton.MouseEnter:Connect(function()
            TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = COLORS.Background_Top:Lerp(COLORS.Card_Hover_Add, 0.5),
                Size = UDim2.new(0, 306, 0, frameHeight + 4) -- Легкое увеличение
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.25), {
                Color = accentColor
            }):Play()
        end)
        
        hoverLeaveConn = overlayButton.MouseLeave:Connect(function()
            TweenService:Create(frame, TweenInfo.new(0.2), {
                BackgroundColor3 = COLORS.Background_Top,
                Size = UDim2.new(0, 300, 0, frameHeight) -- Возврат к дефолту
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.2), {
                Color = COLORS.Stroke
            }):Play()
        end)
        
        clickConn = overlayButton.MouseButton1Click:Connect(function()
            if callback then task.spawn(callback) end
            closeBig()
        end)
    end

    -- Анимация появления уведомления (выезд сбоку)
    frame.Position = UDim2.new(1, 320, 0, 0) -- Старт за экраном справа
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
end

-- [[ МЕТОД СОЗДАНИЯ МИНИ-УВЕДОМЛЕНИЯ ]]
function Notify.Mini(message: string, duration: number?, presetName: string?, callback: () -> ()?)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    duration = duration or 4.5
    
    local screenGui = playerGui:FindFirstChild("RobloxNotificationGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "RobloxNotificationGui"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 100
        screenGui.Parent = playerGui
    end
    
    local container = screenGui:FindFirstChild("MiniNotificationsContainer")
    if not container then
        container = Instance.new("Frame")
        container.Name = "MiniNotificationsContainer"
        container.Size = UDim2.new(0, 260, 1, 0)
        container.Position = UDim2.new(1, -280, 0, 0)
        container.BackgroundTransparency = 1
        container.Parent = screenGui
        
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 10)
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Parent = container
        
        local padding = Instance.new("UIPadding")
        padding.PaddingBottom = UDim.new(0, 20)
        padding.Parent = container
    end

    local accentColor = PRESETS[presetName] or PRESETS.Purple

    local frame = Instance.new("Frame")
    frame.Name = "MiniFrame"
    frame.Size = UDim2.new(0, 240, 0, 48)
    frame.BackgroundColor3 = COLORS.Background_Top
    frame.BorderSizePixel = 0
    frame.LayoutOrder = #container:GetChildren()
    frame.Parent = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Stroke
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    -- Фоновый градиент с интеграцией таймера во вторую половину
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.Background_Top),
        ColorSequenceKeypoint.new(1, COLORS.Background_Bottom)
    })
    bgGradient.Rotation = 90
    bgGradient.Parent = frame

    -- Текстовое сообщение
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = FONTS.Mini
    label.Text = message
    label.TextColor3 = COLORS.Text_Title
    label.TextSize = 13
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    -- Подложка для линии прогресса, чтобы она не вылезала на скругленные углы
    local timerContainer = Instance.new("Frame")
    timerContainer.Name = "TimerContainer"
    timerContainer.Size = UDim2.new(1, -4, 0, 3)
    timerContainer.Position = UDim2.new(0, 2, 1, -5)
    timerContainer.BackgroundTransparency = 1
    timerContainer.ClipsDescendants = true -- Защита от вылезания на углах
    timerContainer.Parent = frame

    -- Линия таймера
    local progressLine = Instance.new("Frame")
    progressLine.Name = "TimerLine"
    progressLine.Size = UDim2.new(1, 0, 1, 0)
    progressLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    progressLine.BorderSizePixel = 0
    progressLine.Parent = timerContainer
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 8)
    progressCorner.Parent = progressLine

    -- Плавный переход от цвета пресета в прозрачность
    local progressGradient = Instance.new("UIGradient")
    progressGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accentColor),
        ColorSequenceKeypoint.new(1, accentColor)
    })
    progressGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    progressGradient.Offset = Vector2.new(0, 0)
    progressGradient.Parent = progressLine

    local mouseEnterConnection, mouseLeaveConnection, clickConnection
    local canCloseWithMouse = false
    local hasTimer = duration > 0

    -- Таймаут блокировки закрытия курсором на первые полсекунды появления
    task.delay(0.5, function()
        canCloseWithMouse = true
    end)

    local function closeMini()
        if mouseEnterConnection then mouseEnterConnection:Disconnect() end
        if mouseLeaveConnection then mouseLeaveConnection:Disconnect() end
        if clickConnection then clickConnection:Disconnect() end
        fadeOutAndDestroy(frame, stroke, 0.3)
    end

    -- Клик-событие, если передан callback
    if callback then
        clickConnection = frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if mouseEnterConnection then mouseEnterConnection:Disconnect() end
                if mouseLeaveConnection then mouseLeaveConnection:Disconnect() end
                if clickConnection then clickConnection:Disconnect() end
                
                task.spawn(callback)
                closeMini()
            end
        end)
        
        -- Визуальный отклик на наведение (Hover) для интерактивных мини-сообщений
        mouseEnterConnection = frame.MouseEnter:Connect(function()
            TweenService:Create(frame, TweenInfo.new(0.2), {
                BackgroundColor3 = COLORS.Background_Top:Lerp(COLORS.Card_Hover_Add, 0.5)
            }):Play()
        end)
        mouseLeaveConnection = frame.MouseLeave:Connect(function()
            TweenService:Create(frame, TweenInfo.new(0.2), {
                BackgroundColor3 = COLORS.Background_Top
            }):Play()
        end)
    elseif not hasTimer then
        -- Если у сообщения нет таймера авто-закрытия — оно закрывается по наведению курсора мыши
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

    -- Появление мини-сообщения (выезд сбоку)
    frame.Position = UDim2.new(1, 280, 0, 0)
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