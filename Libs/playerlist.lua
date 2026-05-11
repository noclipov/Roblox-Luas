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

-- Конструктор интерфейса
-- @param interactions - Список кастомных действий, передаваемый из основного кода
function PlayerListUI.new(interactions)
    local self = setmetatable({}, PlayerListUI)
    self.Visible = false
    self.Gui = nil
    self.MainFrame = nil
    self.ScrollFrame = nil
    self.ToggleBtn = nil
    self.Connections = {}
    self.Interactions = interactions or {} -- Сохраняем кастомные действия
    
    self:BuildUI()
    self:RefreshList()
    self:BindEvents()
    
    return self
end

function PlayerListUI:BuildUI()
    -- Удаляем старый интерфейс, если он уже был создан
    local oldList = PlayerGui:FindFirstChild("CustomPlayerList")
    if oldList then oldList:Destroy() end

    self.Gui = Instance.new("ScreenGui", PlayerGui)
    self.Gui.Name = "CustomPlayerList"
    self.Gui.ResetOnSpawn = false

    -- Кнопка быстрого открытия на экране (слева)
    local toggle = Instance.new("TextButton", self.Gui)
    toggle.Size = UDim2.fromOffset(40, 40)
    toggle.Position = UDim2.new(0, 15, 0.5, -20)
    toggle.BackgroundColor3 = STYLE.Bg
    toggle.BackgroundTransparency = 0.2
    toggle.Text = "👥"
    toggle.TextColor3 = STYLE.Text
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 18
    self.ToggleBtn = toggle
    
    local tCorner = Instance.new("UICorner", toggle)
    tCorner.CornerRadius = UDim.new(0, 10)
    local tStroke = Instance.new("UIStroke", toggle)
    tStroke.Color = STYLE.Accent
    tStroke.Thickness = 1.5

    -- Главный контейнер списка игроков (выдвигается СЛЕВА)
    local main = Instance.new("Frame", self.Gui)
    main.Size = UDim2.fromOffset(280, 400)
    main.Position = UDim2.new(0, -300, 0.5, -200) -- Изначально скрыт за левым краем экрана
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

    -- Прокручиваемый список игроков
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

-- Плавное выдвижение меню слева
function PlayerListUI:Toggle()
    self.Visible = not self.Visible
    local targetPos = self.Visible and UDim2.new(0, 15, 0.5, -200) or UDim2.new(0, -300, 0.5, -200)
    TweenService:Create(self.MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = targetPos
    }):Play()
end

function PlayerListUI:RefreshList()
    -- Очищаем список игроков
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

        -- Отображение ника
        local nameLabel = Instance.new("TextLabel", pFrame)
        nameLabel.Size = UDim2.new(0.6, -10, 1, 0)
        nameLabel.Position = UDim2.fromOffset(8, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ("%s (%s)"):format(p.DisplayName, p.Name)
        nameLabel.TextColor3 = STYLE.Text
        nameLabel.Font = Enum.Font.GothamSemibold
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left

        -- Контейнер для кнопок взаимодействий справа в строке
        local btnsFrame = Instance.new("Frame", pFrame)
        btnsFrame.Size = UDim2.new(0.4, 0, 1, 0)
        btnsFrame.Position = UDim2.new(0.6, 0, 0, 0)
        btnsFrame.BackgroundTransparency = 1

        local btnList = Instance.new("UIListLayout", btnsFrame)
        btnList.FillDirection = Enum.FillDirection.Horizontal
        btnList.HorizontalAlignment = Enum.HorizontalAlignment.Right
        btnList.VerticalAlignment = Enum.VerticalAlignment.Center
        btnList.Padding = UDim.new(0, 6)

        -- Рендерим кнопки, переданные при создании модуля
        for _, action in ipairs(self.Interactions) do
            -- Проверяем условие (если оно передано)
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

                -- Эффекты наведения мыши
                btn.MouseEnter:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = STYLE.Accent}):Play()
                    TweenService:Create(bStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
                end)
                btn.MouseLeave:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = STYLE.Bg}):Play()
                    TweenService:Create(bStroke, TweenInfo.new(0.15), {Transparency = 0.7}):Play()
                end)

                -- Клик вызывает коллбэк, передавая туда объект игрока (targetPlayer)
                btn.MouseButton1Click:Connect(function()
                    if action.Callback then
                        action.Callback(p)
                    end
                end)
            end
        end

        -- Небольшой отступ от правого края плашки
        local rightPadding = Instance.new("Frame", btnsFrame)
        rightPadding.Size = UDim2.fromOffset(2, 26)
        rightPadding.BackgroundTransparency = 1
    end
    
    self.ScrollFrame.CanvasSize = UDim2.fromOffset(0, self.ScrollFrame.UIListLayout.AbsoluteContentSize.Y)
end

function PlayerListUI:BindEvents()
    table.insert(self.Connections, self.ToggleBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end))

    -- Быстрое открытие на клавишу "L"
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, proc)
        if proc then return end
        if input.KeyCode == Enum.KeyCode.L then
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

-- [[ МЕТОДЫ МОДУЛЯ ДЛЯ ИМПОРТА ]]
local activeList = nil

-- Запуск с передачей действий
function PlayerListModule.Init(interactionsTable)
    if activeList then
        activeList:Destroy()
    end
    activeList = PlayerListUI.new(interactionsTable)
    return activeList
end

function PlayerListModule.Close()
    if activeList then
        activeList:Destroy()
        activeList = nil
    end
end

return PlayerListModule