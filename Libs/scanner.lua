--[[ ════════════════════════════════════════════════════════════
  Noclipov · scanner · v3.0
  Числовые выноски над частями тела игрока (атрибуты) + док действий по клику.
  API: Scanner.Init(config) · Scanner.RefreshLocal(config) · Scanner.Stop()
       Scanner.SetDependencies({ ToLetters = fn, Notify = { Mini = fn } })
  config = {
    StatsConfig  = { [partName] = { Name, Emoji, Attr, Color, Offset = Vector3 } },
    Style        = { Bg, Accent, Text, Success, Distance, MaxUiVisibleDistance },
    Interactions = { { Name, Emoji, Condition?, Callback(player) } },
    LocalSetup   = { Offsets = { [partName] = Vector3 }, MaxUiVisibleDistance? },   -- опц.
  }
════════════════════════════════════════════════════════════ ]]

if not game:IsLoaded() then game.Loaded:Wait() end

-- [1] SERVICES
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- [2] CONFIG / ЗАВИСИМОСТИ
local BASE_URL = "https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/Libs/"
local FADE_RANGE = 15          -- studs, на которых выноска плавно гаснет
local CLICK_MARGIN = 5         -- клик/hover работают только чуть ближе предела видимости
local AUTOCLOSE_INTERVAL = 0.2 -- как часто проверяем дистанцию до чужого сканера

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
local function fallbackToLetters(n: any): string
	n = tonumber(n) or 0
	local i = 1
	while math.abs(n) >= 1000 and i < #SUFFIXES do n /= 1000 i += 1 end
	if i == 1 then return tostring(math.floor(n)) end
	return (string.format("%.2f", n):gsub("%.?0+$", "")) .. SUFFIXES[i]
end

local Deps = { ToLetters = nil, Notify = nil }

local function remote(name: string)
	local ok, lib = pcall(function() return loadstring(game:HttpGet(BASE_URL .. name))() end)
	return ok and lib or nil
end

-- Ленивая загрузка: HttpGet выполняется один раз и только если зависимость не передана
local function toLetters(n: any): string
	if not Deps.ToLetters then
		local add = remote("additional.lua")
		Deps.ToLetters = add and add.ToLetters or fallbackToLetters
	end
	return Deps.ToLetters(n)
end

local function notifyMini(color: string, text: string, duration: number)
	if not Deps.Notify then Deps.Notify = remote("notify.lua") or false end
	if Deps.Notify then pcall(Deps.Notify.Mini, color, text, duration) end
end

-- [3] HELPERS
local function guiParent(): Instance
	local ok, hui = pcall(function() return gethui and gethui() end)
	return (ok and hui) or CoreGui
end

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent -- Parent последним
	return o
end

local function copyToClipboard(text: any): boolean
	local set = setclipboard or toclipboard or (Clipboard and Clipboard.set)
	return set ~= nil and (pcall(set, tostring(text)))
end

-- Персонаж по произвольной детали (аксессуар, инструмент, часть тела)
local function characterFromPart(part: BasePart?): Model?
	local m = part and part:FindFirstAncestorOfClass("Model")
	while m do
		if m:FindFirstChildOfClass("Humanoid") then return m end
		m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model")
	end
	return nil
end

-- alpha: 1 — полностью видно, 0 — скрыто; плавный переход на FADE_RANGE перед пределом
local function fadeAlpha(dist: number, maxDist: number): number
	return math.clamp((maxDist - dist) / FADE_RANGE, 0, 1)
end

-- Один общий RenderStepped на все выноски вместо соединения на каждую
local Ticker = { _fns = {}, _conn = nil }
function Ticker.add(fn: (cam: Camera) -> ()): () -> ()
	Ticker._fns[fn] = true
	if not Ticker._conn then
		Ticker._conn = RunService.RenderStepped:Connect(function()
			local cam = Workspace.CurrentCamera
			if not cam then return end
			for f in pairs(Ticker._fns) do f(cam) end
		end)
	end
	return function()
		Ticker._fns[fn] = nil
		if next(Ticker._fns) == nil and Ticker._conn then
			Ticker._conn:Disconnect()
			Ticker._conn = nil
		end
	end
end

-- [4] CLASS
local Instance_ = {}
Instance_.__index = Instance_

local activeTarget, localScanner

function Instance_.new(player: Player, config, isLocal: boolean)
	local char = player.Character
	if not char then return nil end

	local self = setmetatable({
		Target = player, Config = config, IsLocal = isLocal,
		_conns = {}, _unticks = {},
	}, Instance_)

	self.Gui = make("ScreenGui", {
		Name = isLocal and "LocalNumericScanner" or "NumericScanner", ResetOnSpawn = false,
	})
	if not pcall(function() self.Gui.Parent = guiParent() end) then
		warn("[Scanner] Нет доступа к CoreGui/gethui — убедитесь, что исполнитель это поддерживает")
		self.Gui:Destroy()
		return nil
	end

	for partName, data in pairs(config.StatsConfig) do
		local part = char:FindFirstChild(partName)
		if part then self:_callout(part, data) end
	end

	if isLocal then
		self:_track(player.CharacterAdded:Connect(function()
			task.wait(0.5)
			if localScanner == self then Instance_.RefreshLocal(config) end
		end))
	else
		local head = char:FindFirstChild("Head")
		if head then self:_dock(head) end
		self:_autoClose(char)
	end
	return self
end

function Instance_:_track(c: RBXScriptConnection) self._conns[#self._conns + 1] = c return c end
function Instance_:_tick(fn) self._unticks[#self._unticks + 1] = Ticker.add(fn) end

-- Авто-закрытие чужого сканера при удалении от игрока (квадраты расстояний, без sqrt)
function Instance_:_autoClose(targetChar: Model)
	local limit2 = self.Config.Style.Distance ^ 2
	local acc = 0
	self:_track(RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < AUTOCLOSE_INTERVAL then return end
		acc = 0
		local my = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
		local their = targetChar.Parent and targetChar.PrimaryPart
		if not my or not their or (their.Position - my.Position):Dot(their.Position - my.Position) > limit2 then
			self:Destroy()
		end
	end))
end

function Instance_:_callout(part: BasePart, data)
	local cfg, style = self.Config, self.Config.Style
	local player = self.Target
	local local_ = self.IsLocal and cfg.LocalSetup

	local maxDist = (local_ and local_.MaxUiVisibleDistance) or style.MaxUiVisibleDistance
	local offset = (local_ and local_.Offsets and local_.Offsets[part.Name]) or data.Offset

	local bgu = make("BillboardGui", {
		Adornee = part, AlwaysOnTop = true, Active = false, Size = UDim2.fromOffset(100, 45), StudsOffset = offset,
	})
	local card = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = style.Bg, BackgroundTransparency = 0.2 }, bgu)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
	local stroke = make("UIStroke", { Color = data.Color, Thickness = 1.5 }, card)
	local title = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 4), Text = data.Emoji .. " " .. data.Name,
		TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.GothamBold, TextSize = 10,
		BackgroundTransparency = 1, ZIndex = 2,
	}, card)
	local value = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 18), Text = "0", TextColor3 = data.Color,
		Font = Enum.Font.GothamBlack, TextSize = 14, BackgroundTransparency = 1, ZIndex = 2,
	}, card)
	local click = make("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5, Active = false,
	}, card)
	bgu.Parent = self.Gui

	local lastAlpha = -1
	local function camDist(cam: Camera): number
		return (part.Position - cam.CFrame.Position).Magnitude
	end
	local function tooFar(): boolean
		local cam = Workspace.CurrentCamera
		return not cam or camDist(cam) > maxDist - CLICK_MARGIN
	end

	-- Плавное затухание; пишем свойства только когда alpha реально изменилась
	self:_tick(function(cam)
		if not bgu.Parent then return end
		local a = fadeAlpha(camDist(cam), maxDist)
		if a == lastAlpha then return end
		lastAlpha = a
		card.BackgroundTransparency = 1 - a * 0.8
		title.TextTransparency, value.TextTransparency, stroke.Transparency = 1 - a, 1 - a, 1 - a
	end)

	self:_track(click.MouseEnter:Connect(function()
		if tooFar() then return end
		TweenService:Create(stroke, TweenInfo.new(0.15), { Thickness = 2.5, Color = data.Color:Lerp(Color3.new(1, 1, 1), 0.25) }):Play()
		TweenService:Create(card, TweenInfo.new(0.15), { BackgroundTransparency = 0.05 }):Play()
	end))
	self:_track(click.MouseLeave:Connect(function()
		if tooFar() then return end
		TweenService:Create(stroke, TweenInfo.new(0.15), { Thickness = 1.5, Color = data.Color }):Play()
		TweenService:Create(card, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 }):Play()
	end))

	self:_track(click.MouseButton1Click:Connect(function()
		if tooFar() then return end
		if copyToClipboard(value.Text) then
			task.spawn(notifyMini, "Mint", ("%s скопировано в буфер!"):format(value.Text), 3)
		else
			task.spawn(notifyMini, "Coral", "Ошибка доступа к буферу обмена", 3)
		end
		local original = data.Color
		TweenService:Create(stroke, TweenInfo.new(0.08), { Color = style.Success, Thickness = 3 }):Play()
		task.delay(0.2, function()
			if stroke.Parent then
				TweenService:Create(stroke, TweenInfo.new(0.3), { Color = original, Thickness = 1.5 }):Play()
			end
		end)
	end))

	local function refresh()
		value.Text = toLetters(player:GetAttribute(data.Attr) or 0)
		value.TextSize = 18
		TweenService:Create(value, TweenInfo.new(0.3), { TextSize = 14 }):Play()
	end
	self:_track(player:GetAttributeChangedSignal(data.Attr):Connect(refresh))
	refresh()
end

function Instance_:_dock(head: BasePart)
	local cfg, style = self.Config, self.Config.Style
	local player = self.Target

	local actions = {}
	for _, a in ipairs(cfg.Interactions or {}) do
		if not a.Condition or a.Condition(player) == true then actions[#actions + 1] = a end
	end
	if #actions == 0 then return end

	local BTN_W, GAP = 85, 6
	local bgu = make("BillboardGui", {
		Adornee = head, StudsOffset = Vector3.new(0, 5, 0), AlwaysOnTop = true, Active = false,
		Size = UDim2.fromOffset(#actions * BTN_W + (#actions - 1) * GAP + 16, 40),
	})
	local main = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = style.Bg, BackgroundTransparency = 0.25 }, bgu)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, main)
	local mainStroke = make("UIStroke", { Color = style.Accent, Thickness = 1.5, Transparency = 0.4 }, main)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, GAP),
	}, main)

	local IDLE = Color3.fromRGB(30, 30, 40)
	local buttons = {}
	for _, act in ipairs(actions) do
		local btn = make("TextButton", {
			Size = UDim2.fromOffset(BTN_W, 28), BackgroundColor3 = IDLE, BackgroundTransparency = 0.3,
			Text = act.Emoji .. " " .. act.Name, TextColor3 = style.Text, Font = Enum.Font.GothamBold,
			TextSize = 10, AutoButtonColor = false, Active = false,
		}, main)
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
		local bs = make("UIStroke", { Color = style.Text, Thickness = 1, Transparency = 0.85 }, btn)
		buttons[#buttons + 1] = { btn = btn, stroke = bs }

		self:_track(btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = style.Accent, BackgroundTransparency = 0.1 }):Play()
			TweenService:Create(bs, TweenInfo.new(0.2), { Transparency = 0.4 }):Play()
		end))
		self:_track(btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = IDLE, BackgroundTransparency = 0.3 }):Play()
			TweenService:Create(bs, TweenInfo.new(0.2), { Transparency = 0.85 }):Play()
		end))
		self:_track(btn.MouseButton1Click:Connect(function()
			task.spawn(act.Callback, player)
			self:Destroy()
		end))
	end
	bgu.Parent = self.Gui

	-- Затухание дока по дистанции камеры; в зоне полной видимости ничего не пишем
	local maxDist, lastAlpha = style.MaxUiVisibleDistance, -1
	self:_tick(function(cam)
		if not bgu.Parent then return end
		local a = fadeAlpha((head.Position - cam.CFrame.Position).Magnitude, maxDist)
		if a == lastAlpha then return end
		lastAlpha = a
		main.BackgroundTransparency = 1 - a * 0.75
		mainStroke.Transparency = 1 - a * 0.6
		for _, b in ipairs(buttons) do
			b.btn.BackgroundTransparency = 1 - a * 0.7
			b.btn.TextTransparency = 1 - a
			b.stroke.Transparency = 1 - a * 0.15
		end
	end)
end

function Instance_:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, c in ipairs(self._conns) do c:Disconnect() end
	for _, un in ipairs(self._unticks) do un() end
	if self.Gui then self.Gui:Destroy() end
	if activeTarget == self then activeTarget = nil end
	if localScanner == self then localScanner = nil end
end

function Instance_.RefreshLocal(config)
	if localScanner then localScanner:Destroy() end
	if LocalPlayer.Character then localScanner = Instance_.new(LocalPlayer, config, true) end
end

-- [5] PUBLIC API
local Scanner = { Version = "3.0" }
local clickConn

function Scanner.SetDependencies(deps)
	for k, v in pairs(deps or {}) do Deps[k] = v end
end

function Scanner.Init(config)
	Scanner.Stop()
	if LocalPlayer.Character then localScanner = Instance_.new(LocalPlayer, config, true) end

	clickConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end

		local char = characterFromPart(Mouse.Target)
		local player = char and Players:GetPlayerFromCharacter(char)

		if activeTarget then activeTarget:Destroy() end
		if player and player ~= LocalPlayer then
			activeTarget = Instance_.new(player, config, false)
		end
	end)
end

function Scanner.RefreshLocal(config) Instance_.RefreshLocal(config) end

function Scanner.Stop()
	if clickConn then clickConn:Disconnect() clickConn = nil end
	if activeTarget then activeTarget:Destroy() end
	if localScanner then localScanner:Destroy() end
end

return Scanner
