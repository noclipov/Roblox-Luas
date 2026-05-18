while not game.IsLoaded do task.wait() end
-- ==========================================
-- [1. НАСТРОЙКИ И ИНИЦИАЛИЗАЦИЯ]
-- ==========================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local PlayerListModule = {}

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
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		guiButton.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X, 
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	guiButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiButton.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	guiButton.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input) end
	end)
end

-- ==========================================
-- [2. КОНСТРУКТОР И СОЗДАНИЕ ИНТЕРФЕЙСА]
-- ==========================================
function PlayerListUI.new(interactionsTable, side, toggleKey)
	local self = setmetatable({}, PlayerListUI)

	self.Interactions = interactionsTable or {}
	self.Side = side or "Left"
	self.ToggleKey = toggleKey or Enum.KeyCode.L
	self.IsOpen = false
	self.Connections = {}

	-- Основной контейнер ScreenGui
	local sg = Instance.new("ScreenGui")
	sg.Name = "Noclipov_PlayerList_UI"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 998
	sg.IgnoreGuiInset = true
	sg.Parent = PlayerGui
	self.Gui = sg

	-- Круглая кнопка вызова меню
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleMenuButton"
	toggleBtn.Size = UDim2.new(0, 44, 0, 44)
	toggleBtn.Position = (self.Side == "Left") and UDim2.new(0, 25, 0.5, -22) or UDim2.new(1, -69, 0.5, -22)
	toggleBtn.BackgroundColor3 = STYLE.Bg
	toggleBtn.Text = "👥"
	toggleBtn.TextSize = 18
	toggleBtn.TextColor3 = STYLE.Text
	toggleBtn.Font = Enum.Font.SourceSansSemibold
	toggleBtn.AutoButtonColor = false
	toggleBtn.ZIndex = 5
	toggleBtn.Parent = sg
	self.ToggleBtn = toggleBtn

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(1, 0)
	btnCorner.Parent = toggleBtn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Thickness = 1.5
	btnStroke.Color = STYLE.Accent
	btnStroke.Transparency = 0.4
	btnStroke.Parent = toggleBtn

	makeButtonDraggable(toggleBtn)

	-- Главный фрейм списка игроков
	local frame = Instance.new("Frame")
	frame.Name = "MainListFrame"
	frame.Size = UDim2.new(0, 280, 0, 360)
	frame.Position = (self.Side == "Left") and UDim2.new(0, -300, 0.5, -180) or UDim2.new(1, 300, 0.5, -180)
	frame.BackgroundColor3 = STYLE.Bg
	frame.BorderSizePixel = 0
	frame.ZIndex = 2
	frame.Parent = sg
	self.Frame = frame

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = frame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Thickness = 1.5
	frameStroke.Color = STYLE.Accent
	frameStroke.Transparency = 0.6
	frameStroke.Parent = frame

	-- Заголовок меню
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 40)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundTransparency = 1
	header.Text = "СПИСОК ИГРОКОВ"
	header.Font = Enum.Font.SourceSansBold
	header.TextSize = 14
	header.TextColor3 = STYLE.Accent
	header.ZIndex = 3
	header.Parent = frame

	-- Скролл-контейнер для игроков
	local scrollContainer = Instance.new("ScrollingFrame")
	scrollContainer.Name = "PlayersScroll"
	scrollContainer.Size = UDim2.new(1, -20, 1, -55)
	scrollContainer.Position = UDim2.new(0, 10, 0, 45)
	scrollContainer.BackgroundTransparency = 1
	scrollContainer.BorderSizePixel = 0
	scrollContainer.ScrollBarThickness = 2
	scrollContainer.ScrollBarImageColor3 = STYLE.Accent
	scrollContainer.ZIndex = 3
	scrollContainer.Parent = frame
	self.Scroll = scrollContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollContainer

	self:Init()
	return self
end

-- ==========================================
-- [3. ДИНАМИЧЕСКАЯ ОРИЕНТАЦИЯ ВИДИМОСТИ]
-- ==========================================
function PlayerListUI:UpdateVisibilityBasedOnPlayers()
	-- Считаем количество игроков на сервере (без учёта LocalPlayer)
	local actualPlayersCount = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			actualPlayersCount = actualPlayersCount + 1
		end
	end

	if actualPlayersCount == 0 then
		-- Если на сервере никого нет, полностью принудительно скрываем UI элементы
		if self.IsOpen then
			self:Toggle() -- Принудительно закрываем слайд-панель
		end
		self.ToggleBtn.Visible = false
		self.Frame.Visible = false
	else
		-- Если появляется хотя бы один игрок, возвращаем видимость кнопки вызова
		self.ToggleBtn.Visible = true
		self.Frame.Visible = true
	end
end

-- ==========================================
-- [4. УПРАВЛЕНИЕ АНИМАЦИЕЙ И ОБНОВЛЕНИЕМ]
-- ==========================================
function PlayerListUI:Toggle()
	-- Запрещаем открытие, если на сервере нет других игроков
	if not self.ToggleBtn.Visible then return end
	
	self.IsOpen = not self.IsOpen
	local targetPos

	if self.IsOpen then
		targetPos = (self.Side == "Left") and UDim2.new(0, 85, 0.5, -180) or UDim2.new(1, -365, 0.5, -180)
	else
		targetPos = (self.Side == "Left") and UDim2.new(0, -300, 0.5, -180) or UDim2.new(1, 300, 0.5, -180)
	end

	TweenService:Create(self.Frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = targetPos}):Play()
end

function PlayerListUI:RefreshList()
	for _, child in ipairs(self.Scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, -6, 0, 32)
			card.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
			card.BorderSizePixel = 0
			card.ZIndex = 4
			card.Parent = self.Scroll

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 6)
			cardCorner.Parent = card

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.new(0, 120, 1, 0)
			nameLbl.Position = UDim2.new(0, 10, 0, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text = player.DisplayName or player.Name
			nameLbl.Font = Enum.Font.SourceSansSemibold
			nameLbl.TextSize = 14
			nameLbl.TextColor3 = STYLE.Text
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.ZIndex = 5
			nameLbl.Parent = card

			-- Добавление кнопок взаимодействия (Interactions)
			local rightOffset = -8
			for _, interact in ipairs(self.Interactions) do
				if not interact.Condition or interact.Condition(player) then
					local actBtn = Instance.new("TextButton")
					actBtn.Size = UDim2.new(0, 24, 0, 24)
					actBtn.Position = UDim2.new(1, rightOffset, 0.5, -12)
					actBtn.AnchorPoint = Vector2.new(1, 0)
					actBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
					actBtn.Text = interact.Emoji or "⚡"
					actBtn.TextSize = 12
					actBtn.TextColor3 = STYLE.Text
					actBtn.ZIndex = 5
					actBtn.AutoButtonColor = true
					actBtn.Parent = card

					local actCorner = Instance.new("UICorner")
					actCorner.CornerRadius = UDim.new(0, 4)
					actCorner.Parent = actBtn

					actBtn.MouseButton1Click:Connect(function()
						interact.Callback(player)
					end)

					rightOffset = rightOffset - 28
				end
			end
		end
	end
	self.Scroll.CanvasSize = UDim2.new(0, 0, 0, self.Scroll.UIListLayout.AbsoluteContentSize.Y)
end

-- ==========================================
-- [5. ЖИЗНЕННЫЙ ЦИКЛ И СОБЫТИЯ]
-- ==========================================
function PlayerListUI:Init()
	-- Первоначальная проверка видимости меню при запуске скрипта
	self:UpdateVisibilityBasedOnPlayers()
	self:RefreshList()

	-- Обработка нажатия на круглую кнопку вызова
	table.insert(self.Connections, self.ToggleBtn.MouseButton1Click:Connect(function()
		self:Toggle()
	end))

	-- Горячая клавиша вызова (использует установленный бинд)
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, proc)
		if proc then return end
		if input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end))

	-- Авто-обновление списка и динамическая проверка видимости при движении игроков
	table.insert(self.Connections, Players.PlayerAdded:Connect(function()
		task.wait(0.5)
		self:UpdateVisibilityBasedOnPlayers()
		self:RefreshList()
	end))

	table.insert(self.Connections, Players.PlayerRemoving:Connect(function()
		task.wait(0.5)
		self:UpdateVisibilityBasedOnPlayers()
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

function PlayerListModule.Init(interactionsTable, side, toggleKey)
	if activeList then
		activeList:Destroy()
		activeList = nil
	end
	activeList = PlayerListUI.new(interactionsTable, side, toggleKey)
	return activeList
end

return PlayerListModule