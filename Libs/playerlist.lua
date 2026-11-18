--[[ ════════════════════════════════════════════════════════════
  Noclipov · playerlist · v2.0
  Выезжающий список игроков с кнопками-действиями.
  API: PlayerList.Init(interactions, side?, toggleKey?) → экземпляр
       PlayerList.Get() · PlayerList.Stop()
       экземпляр: :Toggle() :Open() :Close() :RefreshList() :Destroy()
  interactions = { { Emoji = "👁", Condition = function(player) → bool, Callback = function(player) }, ... }
════════════════════════════════════════════════════════════ ]]

if not game:IsLoaded() then game.Loaded:Wait() end

-- [1] SERVICES
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- [2] CONFIG
local STYLE = {
	Accent = Color3.fromRGB(140, 100, 255),
	Bg     = Color3.fromRGB(15, 15, 20),
	Card   = Color3.fromRGB(22, 22, 28),
	Btn    = Color3.fromRGB(30, 30, 40),
	Text   = Color3.fromRGB(255, 255, 255),
}
local PANEL_W, PANEL_H = 280, 360
local SLIDE = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local DRAG_THRESHOLD = 6
local REFRESH_DELAY = 0.5

-- [3] HELPERS
local function guiParent(): Instance
	local ok, hui = pcall(function() return gethui and gethui() end)
	return (ok and hui) or CoreGui
end

local function make(class: string, props: { [string]: any }, parent: Instance?): Instance
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local function decorate(parent: Instance, radius: number, strokeThickness: number?, strokeTransp: number?)
	make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
	if strokeThickness then
		make("UIStroke", { Thickness = strokeThickness, Color = STYLE.Accent, Transparency = strokeTransp or 0.5 }, parent)
	end
end

-- Перетаскивание кнопки; возвращает функцию «меня только что таскали?»
local function makeDraggable(btn: GuiButton, track: (RBXScriptConnection) -> ())
	local dragging, moved = false, false
	local startMouse, startPos

	track(btn.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging, moved = true, false
			startMouse, startPos = input.Position, btn.Position
			local c; c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					c:Disconnect()
				end
			end)
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
		local d = input.Position - startMouse
		if d.Magnitude > DRAG_THRESHOLD then moved = true end
		btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end))

	return function() return moved end
end

-- [4] CLASS
local List = {}
List.__index = List

function List.new(interactions, side, toggleKey)
	local self = setmetatable({
		Interactions = interactions or {},
		Side = side == "Right" and "Right" or "Left",
		ToggleKey = toggleKey or Enum.KeyCode.L,
		IsOpen = false,
		_conns = {},
		_pending = false,
		_destroyed = false,
	}, List)
	self:_build()
	self:_connect()
	self:_update()
	return self
end

function List:_track(conn: RBXScriptConnection)
	table.insert(self._conns, conn)
end

function List:_slidePos(open: boolean): UDim2
	if self.Side == "Left" then
		return open and UDim2.new(0, 85, 0.5, -PANEL_H / 2) or UDim2.new(0, -PANEL_W - 20, 0.5, -PANEL_H / 2)
	end
	return open and UDim2.new(1, -PANEL_W - 85, 0.5, -PANEL_H / 2) or UDim2.new(1, PANEL_W + 20, 0.5, -PANEL_H / 2)
end

function List:_build()
	local sg = make("ScreenGui", { Name = "Noclipov_PlayerList_UI", ResetOnSpawn = false, DisplayOrder = 998, IgnoreGuiInset = true })

	local btn = make("TextButton", {
		Name = "ToggleMenuButton", Size = UDim2.fromOffset(44, 44),
		Position = self.Side == "Left" and UDim2.new(0, 25, 0.5, -22) or UDim2.new(1, -69, 0.5, -22),
		BackgroundColor3 = STYLE.Bg, Text = "👥", TextSize = 18, TextColor3 = STYLE.Text,
		Font = Enum.Font.SourceSansSemibold, AutoButtonColor = false, ZIndex = 5,
	}, sg)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, btn) -- круглая кнопка
	make("UIStroke", { Thickness = 1.5, Color = STYLE.Accent, Transparency = 0.4 }, btn)

	local frame = make("Frame", {
		Name = "MainListFrame", Size = UDim2.fromOffset(PANEL_W, PANEL_H), Position = self:_slidePos(false),
		BackgroundColor3 = STYLE.Bg, BorderSizePixel = 0, ZIndex = 2,
	}, sg)
	decorate(frame, 12, 1.5, 0.6)

	make("TextLabel", {
		Name = "Header", Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "СПИСОК ИГРОКОВ",
		Font = Enum.Font.SourceSansBold, TextSize = 14, TextColor3 = STYLE.Accent, ZIndex = 3,
	}, frame)

	local scroll = make("ScrollingFrame", {
		Name = "PlayersScroll", Size = UDim2.new(1, -20, 1, -55), Position = UDim2.fromOffset(10, 45),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
		ScrollBarImageColor3 = STYLE.Accent, ZIndex = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, frame)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

	self.Gui, self.ToggleBtn, self.Frame, self.Scroll = sg, btn, frame, scroll
	self._wasDragged = makeDraggable(btn, function(c) self:_track(c) end)
	sg.Parent = guiParent()
end

function List:_connect()
	self:_track(self.ToggleBtn.MouseButton1Click:Connect(function()
		if not self._wasDragged() then self:Toggle() end
	end))
	self:_track(UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == self.ToggleKey then self:Toggle() end
	end))
	self:_track(Players.PlayerAdded:Connect(function() self:_queueRefresh() end))
	self:_track(Players.PlayerRemoving:Connect(function() self:_queueRefresh() end))
end

-- Несколько входов/выходов подряд → один пересчёт
function List:_queueRefresh()
	if self._pending then return end
	self._pending = true
	task.delay(REFRESH_DELAY, function()
		self._pending = false
		if not self._destroyed then self:_update() end
	end)
end

function List:_others(): { Player }
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then out[#out + 1] = p end
	end
	return out
end

function List:_update()
	local others = self:_others()
	local any = #others > 0
	if not any and self.IsOpen then self:Close() end
	self.ToggleBtn.Visible, self.Frame.Visible = any, any
	if any then self:RefreshList(others) end
end

function List:RefreshList(others: { Player }?)
	for _, child in ipairs(self.Scroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for i, player in ipairs(others or self:_others()) do
		local card = make("Frame", {
			Size = UDim2.new(1, -6, 0, 32), BackgroundColor3 = STYLE.Card, BorderSizePixel = 0,
			ZIndex = 4, LayoutOrder = i,
		})
		decorate(card, 6)
		make("TextLabel", {
			Size = UDim2.new(0, 120, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
			Text = player.DisplayName ~= "" and player.DisplayName or player.Name,
			Font = Enum.Font.SourceSansSemibold, TextSize = 14, TextColor3 = STYLE.Text,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5,
		}, card)

		local offset = -8
		for _, act in ipairs(self.Interactions) do
			if not act.Condition or act.Condition(player) then
				local b = make("TextButton", {
					Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, offset, 0.5, -12), AnchorPoint = Vector2.new(1, 0),
					BackgroundColor3 = STYLE.Btn, Text = act.Emoji or "⚡", TextSize = 12,
					TextColor3 = STYLE.Text, ZIndex = 5, AutoButtonColor = true,
				}, card)
				decorate(b, 4)
				b.MouseButton1Click:Connect(function() task.spawn(act.Callback, player) end) -- умрёт вместе с кнопкой
				offset -= 28
			end
		end
		card.Parent = self.Scroll
	end
end

-- [5] PUBLIC API
function List:Open()
	if self.IsOpen or not self.ToggleBtn.Visible then return end
	self.IsOpen = true
	TweenService:Create(self.Frame, SLIDE, { Position = self:_slidePos(true) }):Play()
end

function List:Close()
	if not self.IsOpen then return end
	self.IsOpen = false
	TweenService:Create(self.Frame, SLIDE, { Position = self:_slidePos(false) }):Play()
end

function List:Toggle()
	if self.IsOpen then self:Close() else self:Open() end
end

function List:Destroy()
	self._destroyed = true
	for _, c in ipairs(self._conns) do c:Disconnect() end
	table.clear(self._conns)
	if self.Gui then self.Gui:Destroy() self.Gui = nil end
end

local PlayerList = { Version = "2.0" }
local active

function PlayerList.Init(interactions, side, toggleKey)
	PlayerList.Stop()
	active = List.new(interactions, side, toggleKey)
	return active
end

function PlayerList.Get() return active end

function PlayerList.Stop()
	if active then active:Destroy() active = nil end
end

return PlayerList
