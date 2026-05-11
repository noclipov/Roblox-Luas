local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local PlayerListModule = {}

-- [[ СТИЛИ ИНТЕРФЕЙСА ]]
local STYLE = {
    Accent = Color3.fromRGB(140, 100, 255),
    Bg = Color3.fromRGB(15, 15, 20),
    Text = Color3.fromRGB(255, 255, 255),
}

local PlayerListUI = {}
PlayerListUI.__index = PlayerListUI

-- Функция реализации перетаскивания (Drag) для круглой кнопки вызова меню
local function makeButtonDraggable(guiButton)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        guiButton.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end

    guiButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiButton.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Конструктор интерфейса
-- @param interactions - Список действий (кнопок) напротив ников
-- @param side - Сторона вылета меню: "Left" или "Right" (по умолчанию "Left")
-- @param toggleKey - Клавиша вызова меню (по умолчанию Enum.KeyCode.L)
function PlayerListUI.new(interactions, side, toggleKey)
    local self = setmetatable({}, PlayerListUI)
    self.Visible = false
    self.Side = (side == "Right") and "Right" or "Left"
    self.ToggleKey = toggleKey or Enum.KeyCode.L -- Кастомный бинд клавиши
    self.Gui = nil
    self.MainFrame = nil
    self.ScrollFrame = nil
    self.ToggleBtn = nil
    self.Connections = {}
    self.Interactions = interactions or {}
    
    self:BuildUI()
    self:RefreshList()
    self:BindEvents()
    
    return self
end

function PlayerListUI:BuildUI()
    local oldList = PlayerGui:FindFirstChild("CustomPlayerListDynamic")
    if oldList then oldList:Destroy() end

    self.Gui = Instance.new("ScreenGui", PlayerGui)
    self.Gui.Name = "CustomPlayerListDynamic"
    self.Gui.ResetOnSpawn = false

    -- === КНОПКА ВЫЗОВА МЕНЮ (ПЕРЕТАСКИВАЕМАЯ) ===
    local toggle = Instance.new("TextButton", self.Gui)
    toggle.Size = UDim2.fromOffset(40, 40)
    
    -- Начальная позиция кнопки зависит от стороны вылета
    if self.Side == "Left" then
        toggle.Position = UDim2.new(0, 15, 0.5, -20)
    else
        toggle.Position = UDim2.new(1, -55, 0.5, -20)
    end
    
    toggle.BackgroundColor3 = STYLE.Bg
    toggle.BackgroundTransparency = 0.2
    toggle.Text = "👥"
    toggle.TextColor3 = STYLE.Text
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 18
    toggle.Active = true
    self.ToggleBtn = toggle
    
    local tCorner = Instance.new("UICorner", toggle)
    tCorner.CornerRadius = UDim.new(0, 10)
    local tStroke = Instance.new("UIStroke", toggle)
    tStroke.Color = STYLE.Accent
    tStroke.Thickness = 1.5

    -- Включаем перетаскивание ТОЛЬКО для этой кнопки
    makeButtonDraggable(toggle)

    -- === ГЛАВНЫЙ КОНТЕЙНЕР СПИСКА ИГРОКОВ (НЕПЕРЕТАСКИВАЕМЫЙ) ===
    local main = Instance.new("Frame", self.Gui)
    main.Size = UDim2.fromOffset(280, 400)
    
    -- Начальное скрытое положение за пределами видимости экрана
    if self.Side == "Left" then
        main.Position = UDim2.new(0, -300, 0.5, -200)
    else
        main.Position = UDim2.new(1, 300, 0.5, -200)
    end
    
    main.BackgroundColor3 = STYLE.Bg
    main.BackgroundTransparency = 0.15
    self.MainFrame = main

    local mCorner = Instance.new("UICorner", main)
    mCorner.CornerRadius = UDim.new(0, 12)
    local mStroke = Instance.new("UIStroke", main)
    mStroke.Color = STYLE.Accent
    mStroke.Thickness = 1.5

    -- Заголовок списка
    local header = Instance.new("TextLabel", main)
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    header.Text = "Список игроков"
    header.TextColor3 = STYLE.Text
    header.Font = Enum.Font.GothamBold
    header.TextSize = 14

    local separator = Instance.new("Frame", main)
    separator.Size = UDim2.new(0.9, 0, 0, 1)
    separator.Position = UDim2.new(0.05, 0, 0, 40)
    separator.BackgroundColor3 = STYLE.Accent
    separator.BackgroundTransparency = 0.5

    -- Прокрутка списка
    local scroll = Instance.new("ScrollingFrame", main)
    scroll.Size = UDim2.new(1, -20, 1, -60)
    scroll.Position = UDim2.fromOffset(10, 50)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = STYLE.Accent
    self.ScrollFrame = scroll

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
end

-- Метод открытия и закрытия меню
function PlayerListUI:Toggle()
    self.Visible = not self.Visible
    local targetPos
    
    if self.Side == "Left" then
        targetPos = self.Visible and UDim2.new(0, 15, 0.5, -200) or UDim2.new(0, -300, 0.5, -200)
    else
        targetPos = self.Visible and UDim2.new(1, -295, 0.5, -200) or UDim2.new(1, 300, 0.5, -200)
    end
    
    TweenService:Create(self.MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()
end

function PlayerListUI:RefreshList()
    -- Очистка старых строк игроков
    for _, item in ipairs(self.ScrollFrame:GetChildren()) do
        if item:IsA("Frame") then item:Destroy() end
    end

    local currentPlayers = Players:GetPlayers()
    for _, p in ipairs(currentPlayers) do
        if p == LocalPlayer then continue end -- Игнорируем себя

        local pFrame = Instance.new("Frame", self.ScrollFrame)
        pFrame.Size = UDim2.new(1, 0, 0, 36)
        pFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        pFrame.BackgroundTransparency = 0.4
        
        local pfCorner = Instance.new("UICorner", pFrame)
        pfCorner.CornerRadius = UDim.new(0, 6)

        -- Имя игрока
        local nameLabel = Instance.new("TextLabel", pFrame)
        nameLabel.Size = UDim2.new(0.6, -10, 1, 0)
        nameLabel.Position = UDim2.fromOffset(8, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ("%s (%s)"):format(p.DisplayName, p.Name)
        nameLabel.TextColor3 = STYLE.Text
        nameLabel.Font = Enum.Font.GothamSemibold
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left

        -- Контейнер для кнопок быстрого взаимодействия (они НЕ перетаскиваются)
        local btnsFrame = Instance.new("Frame", pFrame)
        btnsFrame.Size = UDim2.new(0.4, 0, 1, 0)
        btnsFrame.Position = UDim2.new(0.6, 0, 0, 0)
        btnsFrame.BackgroundTransparency = 1

        local btnList = Instance.new("UIListLayout", btnsFrame)
        btnList.FillDirection = Enum.FillDirection.Horizontal
        btnList.HorizontalAlignment = Enum.HorizontalAlignment.Right
        btnList.VerticalAlignment = Enum.VerticalAlignment.Center
        btnList.Padding = UDim.new(0, 6)

        -- Добавление кнопок
        for _, action in ipairs(self.Interactions) do
            if not action.Condition or action.Condition(p) then
                local btn = Instance.new("TextButton", btnsFrame)
                btn.Size = UDim2.fromOffset(26, 26)
                btn.BackgroundColor3 = STYLE.Bg
                btn.Text = action.Emoji or "?"
                btn.TextColor3 = STYLE.Text
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 12
                
                local bCorner = Instance.new("UICorner", btn)
                bCorner.CornerRadius = UDim.new(0, 6)
                local bStroke = Instance.new("UIStroke", btn)
                bStroke.Color = STYLE.Accent
                bStroke.Thickness = 1
                bStroke.Transparency = 0.7

                -- Анимации ховера
                btn.MouseEnter:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = STYLE.Accent}):Play()
                    TweenService:Create(bStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
                end)
                btn.MouseLeave:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = STYLE.Bg}):Play()
                    TweenService:Create(bStroke, TweenInfo.new(0.15), {Transparency = 0.7}):Play()
                end)

                btn.MouseButton1Click:Connect(function()
                    if action.Callback then
                        action.Callback(p)
                    end
                end)
            end
        end

        local rightPadding = Instance.new("Frame", btnsFrame)
        rightPadding.Size = UDim2.fromOffset(2, 26)
        rightPadding.BackgroundTransparency = 1
    end
    
    self.ScrollFrame.CanvasSize = UDim2.fromOffset(0, self.ScrollFrame.UIListLayout.AbsoluteContentSize.Y)
end

function PlayerListUI:BindEvents()
    -- Обработка нажатия на кнопку вызова (отличаем просто Клик от Перетаскивания)
    local dragDeltaThreshold = 5
    local clickStartPos
    
    self.ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickStartPos = input.Position
        end
    end)

    self.ToggleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if clickStartPos then
                local delta = (input.Position - clickStartPos).Magnitude
                -- Если сдвиг мыши при клике меньше порога, значит это обычный клик -> открываем меню
                if delta < dragDeltaThreshold then
                    self:Toggle()
                end
            end
        end
    end)

    -- Горячая клавиша вызова (использует установленный бинд)
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, proc)
        if proc then return end
        if input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end))

    -- Авто-обновление списка
    table.insert(self.Connections, Players.PlayerAdded:Connect(function()
        task.wait(0.5)
        self:RefreshList()
    end))

    table.insert(self.Connections, Players.PlayerRemoving:Connect(function()
        task.wait(0.5)
        self:RefreshList()
    end))
end

function PlayerListUI:Destroy()
    for _, conn in ipairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    if self.Gui then self.Gui:Destroy() end
end

-- [[ МЕТОДЫ ЭКСПОРТА ]]
local activeList = nil

-- @param interactionsTable - Массив кастомных кнопок
-- @param side - Строка "Left" или "Right" (по умолчанию "Left")
-- @param toggleKey - Объект Enum.KeyCode (по умолчанию Enum.KeyCode.L)
function PlayerListModule.Init(interactionsTable, side, toggleKey)
    if activeList then
        activeList:Destroy()
    end
    activeList = PlayerListUI.new(interactionsTable, side, toggleKey)
    return activeList
end

function PlayerListModule.Close()
    if activeList then
        activeList:Destroy()
        activeList = nil
    end
end

return PlayerListModule