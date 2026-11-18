--[[ ════════════════════════════════════════════════════════════
  Noclipov · notify · v3.0
  Стек уведомлений в правом нижнем углу (полное и компактное).
  API: Notify.New(theme, title, text, duration?, callback?, buttonText?) → handle
       Notify.Mini(theme, text, duration?, callback?)                    → handle
       Notify.Clear() · Notify.Destroy() · Notify.Presets
  theme    = имя пресета ("Mint", "Coral"…) | Color3 | { Accent, Text, Bg }
  duration = nil / 0 / "inf" / math.huge — без таймера
  handle   = { Close = function }
  callback + buttonText → кнопка; callback без buttonText → кликабельная карточка
════════════════════════════════════════════════════════════ ]]

if not game:IsLoaded() then game.Loaded:Wait() end

-- [1] SERVICES
local TweenService = game:GetService("TweenService")
local TextService  = game:GetService("TextService")
local CoreGui      = game:GetService("CoreGui")

-- [2] CONFIG
local GUI_NAME = "Noclipov_UI_Storage"
local WIDTH, PADDING = 340, 10
local FONTS = {
	Title  = Enum.Font.SourceSansBold,
	Desc   = Enum.Font.SourceSans,
	Mini   = Enum.Font.SourceSansSemibold,
	Button = Enum.Font.SourceSansSemibold,
}
local OFFSCREEN = UDim2.new(1.3, 0, 0, 0)
local IN_TWEEN  = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function P(a, t, b)
	return {
		Accent = Color3.fromRGB(a[1], a[2], a[3]),
		Text   = Color3.fromRGB(t[1], t[2], t[3]),
		Bg     = Color3.fromRGB(b[1], b[2], b[3]),
	}
end

local PRESETS = {
	-- холодные
	Purple = P({167,139,250}, {240,235,255}, {24,20,36}),  Sky      = P({96,165,250},  {235,245,255}, {15,24,38}),
	Mint   = P({110,230,160}, {230,255,240}, {12,30,22}),  Teal     = P({45,212,191},  {225,255,250}, {10,28,28}),
	Sage   = P({163,230,53},  {245,255,225}, {22,28,12}),  Ice      = P({186,230,253}, {240,250,255}, {18,26,32}),
	Lavender = P({196,181,253}, {245,243,255}, {28,24,38}), Marine  = P({14,165,233},  {224,242,254}, {12,26,36}),
	-- тёплые
	Coral  = P({248,113,113}, {255,235,235}, {34,18,18}),  Honey    = P({251,191,36},  {255,248,225}, {30,25,12}),
	Peach  = P({251,146,60},  {255,242,230}, {32,22,14}),  Rose     = P({244,114,182}, {255,235,245}, {32,16,26}),
	Sakura = P({253,164,186}, {255,240,243}, {32,18,22}),  Vanilla  = P({245,230,185}, {255,253,240}, {26,24,18}),
	Amber  = P({245,158,11},  {254,243,199}, {30,20,10}),  Crimson  = P({225,29,72},   {255,228,230}, {35,12,16}),
	-- строгие
	Obsidian = P({156,163,175}, {243,244,246}, {17,24,39}), Midnight = P({59,130,246}, {219,234,254}, {10,15,30}),
	Plum   = P({192,132,252}, {243,232,255}, {24,12,36}),  Wine     = P({239,68,68},   {254,226,226}, {28,10,10}),
	Forest = P({52,211,153},  {209,250,229}, {6,30,24}),   Gunmetal = P({129,140,248}, {238,242,255}, {20,24,33}),
	Carbon = P({75,85,99},    {209,213,219}, {12,12,14}),  Shadow   = P({31,41,55},    {156,163,175}, {8,8,10}),
	-- неон
	Cyber  = P({0,255,255},   {220,255,255}, {10,20,25}),  NeonPink = P({255,0,127},   {255,220,240}, {28,10,20}),
	Acid   = P({191,255,0},   {240,255,210}, {20,26,10}),  Gold     = P({255,215,0},   {255,250,220}, {28,24,10}),
	Electric = P({0,102,255}, {215,235,255}, {8,16,32}),   Magma    = P({255,69,0},    {255,225,210}, {30,14,10}),
	Matrix = P({0,255,70},    {210,255,220}, {8,24,12}),   Vampire  = P({150,0,0},     {255,210,210}, {18,5,5}),
}

-- [3] HELPERS
local Notify = { Version = "3.0", Presets = PRESETS }
local _container: Frame?
local _active: { [Frame]: () -> () } = {}

local function guiParent(): Instance
	local ok, hui = pcall(function() return gethui and gethui() end)
	return (ok and hui) or CoreGui
end

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local function corner(p: Instance, r: number?) return make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p) end

local function resolveTheme(x: any)
	if type(x) == "string" and PRESETS[x] then return PRESETS[x] end
	if typeof(x) == "Color3" then
		return { Accent = x, Text = Color3.fromRGB(240, 240, 245), Bg = Color3.fromRGB(22, 22, 28) }
	end
	if type(x) == "table" and typeof(x.Accent) == "Color3" then
		return { Accent = x.Accent, Text = x.Text or PRESETS.Purple.Text, Bg = x.Bg or PRESETS.Purple.Bg }
	end
	return PRESETS.Purple
end

local function isInfinite(d: any): boolean
	return d == nil or d == 0 or d == "inf" or d == math.huge
end

local function getContainer(): Frame
	if _container and _container.Parent then return _container end
	local parent = guiParent()
	local sg = parent:FindFirstChild(GUI_NAME)
	if sg and sg:FindFirstChild("NotifyContainer") then
		_container = sg.NotifyContainer
		return _container
	end
	if sg then sg:Destroy() end

	sg = make("ScreenGui", { Name = GUI_NAME, ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true })
	local c = make("Frame", {
		Name = "NotifyContainer", Position = UDim2.new(1, -25, 1, -25), Size = UDim2.fromOffset(WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.one, BackgroundTransparency = 1, BorderSizePixel = 0,
	}, sg)
	make("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, PADDING),
	}, c)
	sg.Parent = parent
	_container = c
	return c
end

-- Общий жизненный цикл карточки: слайд-аут → схлопывание → Destroy. Идемпотентен.
local function lifecycle(placeholder: Frame, frame: GuiObject, slideT: number, collapseT: number, endSize: UDim2)
	local conns, closed = {}, false

	local function close()
		if closed then return end
		closed = true
		_active[placeholder] = nil
		for _, c in ipairs(conns) do c:Disconnect() end
		table.clear(conns)

		local slide = TweenService:Create(frame, TweenInfo.new(slideT, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ Position = OFFSCREEN })
		slide.Completed:Once(function()
			local collapse = TweenService:Create(placeholder, TweenInfo.new(collapseT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = endSize })
			collapse.Completed:Once(function() placeholder:Destroy() end)
			collapse:Play()
		end)
		slide:Play()
		task.delay(slideT + collapseT + 0.5, function() -- страховка, если Completed не придёт
			if placeholder.Parent then placeholder:Destroy() end
		end)
	end

	_active[placeholder] = close
	return close, function(c: RBXScriptConnection) conns[#conns + 1] = c return c end
end

-- Полоса прогресса (визуал); закрытие — по task.delay, а не по Completed твина
local function progressBar(parent: Instance, theme, duration: number, size: UDim2, pos: UDim2, height: number, bgTransp: number, rounded: boolean)
	local track = make("Frame", {
		Size = size, Position = pos, BackgroundColor3 = theme.Accent, BackgroundTransparency = bgTransp,
		BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2,
	}, parent)
	local fill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, track)
	if rounded then corner(track, height) corner(fill, height) end
	local grad = make("UIGradient", {
		Color = ColorSequence.new(theme.Accent),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.999, 0), NumberSequenceKeypoint.new(1, 1),
		}),
	}, fill)
	TweenService:Create(grad, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Offset = Vector2.new(-1, 0) }):Play()
end

local function hoverTween(obj: Instance, props: { [string]: any }, t: number?)
	TweenService:Create(obj, TweenInfo.new(t or 0.15), props):Play()
end

-- [4] PUBLIC API
function Notify.New(themeArg: any, title: any, text: any, duration: any, callback: (() -> ())?, buttonText: string?)
	local theme = resolveTheme(themeArg)
	text = tostring(text or "")
	local hasTimer = not isInfinite(duration)
	local hasCallback = typeof(callback) == "function"
	local hasButton = hasCallback and buttonText ~= nil and buttonText ~= ""
	local cardClickable = hasCallback and not hasButton

	local placeholder = make("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0 })
	local frame = make(cardClickable and "TextButton" or "Frame", {
		Size = UDim2.fromScale(1, 1), Position = OFFSCREEN, BackgroundTransparency = 1, BorderSizePixel = 0,
	}, placeholder)
	if cardClickable then frame.Text, frame.AutoButtonColor = "", false end

	local bg = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = theme.Bg, BorderSizePixel = 0, ZIndex = 1 }, frame)
	corner(bg, 10)
	make("UIGradient", {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160)) }),
		Rotation = 90,
	}, bg)

	make("TextLabel", {
		Size = UDim2.new(1, -45, 0, 18), Position = UDim2.fromOffset(25, 12), Text = tostring(title):upper(),
		TextColor3 = theme.Accent, Font = FONTS.Title, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1, ZIndex = 2,
	}, frame)

	if hasTimer then
		progressBar(frame, theme, duration, UDim2.new(1, -45, 0, 2), UDim2.fromOffset(25, 34), 2, 0.85, true)
	end

	local descH = TextService:GetTextSize(text, 14, FONTS.Desc, Vector2.new(WIDTH - 45, 1000)).Y
	local textY = hasTimer and 46 or 40
	local height = hasButton and math.max(descH + textY + 38, 106) or math.max(descH + textY + 18, 84)

	make("TextLabel", {
		Size = UDim2.new(1, -45, 0, descH), Position = UDim2.fromOffset(25, textY), Text = text, TextColor3 = theme.Text,
		Font = FONTS.Desc, TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, LineHeight = 1.15, BackgroundTransparency = 1, ZIndex = 2,
	}, frame)
	corner(make("Frame", {
		Size = UDim2.new(0, 3, 1, -20), Position = UDim2.fromOffset(12, 10), BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0, ZIndex = 2,
	}, frame), 3)

	local close, track = lifecycle(placeholder, frame, 0.4, 0.25, UDim2.new(1, 0, 0, 0))
	local born = os.clock()
	local function canClick() return os.clock() - born >= 0.5 end

	if hasButton then
		local label = tostring(buttonText):upper()
		local w = math.round(math.clamp(TextService:GetTextSize(label, 12, FONTS.Button, Vector2.new(200, 50)).X + 24, 80, 140))
		local btn = make("TextButton", {
			Size = UDim2.fromOffset(w, 24), Position = UDim2.new(1, -20, 1, -12), AnchorPoint = Vector2.one,
			BackgroundColor3 = theme.Accent, BackgroundTransparency = 0.93, Text = label, TextColor3 = theme.Accent,
			Font = FONTS.Button, TextSize = 12, AutoButtonColor = false, ZIndex = 3,
		}, frame)
		corner(btn, 5)
		local stroke = make("UIStroke", { Color = theme.Accent, Thickness = 1, Transparency = 0.75 }, btn)

		track(btn.MouseEnter:Connect(function()
			hoverTween(btn, { BackgroundTransparency = 0.8 }) hoverTween(stroke, { Transparency = 0.4 })
		end))
		track(btn.MouseLeave:Connect(function()
			hoverTween(btn, { BackgroundTransparency = 0.93 }) hoverTween(stroke, { Transparency = 0.75 })
		end))
		track(btn.MouseButton1Click:Connect(function()
			if not canClick() then return end
			task.spawn(callback)
			close()
		end))
	elseif cardClickable then
		local c = theme.Bg
		local hover = Color3.fromRGB(math.clamp(c.R * 255 + 12, 0, 255), math.clamp(c.G * 255 + 12, 0, 255), math.clamp(c.B * 255 + 16, 0, 255))
		track(frame.MouseEnter:Connect(function() hoverTween(bg, { BackgroundColor3 = hover }, 0.2) end))
		track(frame.MouseLeave:Connect(function() hoverTween(bg, { BackgroundColor3 = theme.Bg }, 0.2) end))
		track(frame.MouseButton1Click:Connect(function()
			if not canClick() then return end
			task.spawn(callback)
			close()
		end))
	end

	placeholder.Size = UDim2.new(1, 0, 0, height)
	placeholder.Parent = getContainer()
	TweenService:Create(frame, IN_TWEEN, { Position = UDim2.new() }):Play()
	if hasTimer then task.delay(duration, close) end

	return { Close = close }
end

function Notify.Mini(themeArg: any, text: any, duration: any, callback: (() -> ())?)
	local theme = resolveTheme(themeArg)
	text = tostring(text or "")
	local hasTimer = not isInfinite(duration)
	local hasCallback = typeof(callback) == "function"

	local placeholder = make("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, BorderSizePixel = 0 })
	local frame = make(hasCallback and "TextButton" or "Frame", {
		Size = UDim2.fromScale(1, 1), Position = OFFSCREEN, BackgroundColor3 = theme.Bg,
		BackgroundTransparency = 0.15, BorderSizePixel = 0,
	}, placeholder)
	if hasCallback then frame.Text, frame.AutoButtonColor = "", false end
	corner(frame, 8)

	corner(make("Frame", {
		Size = UDim2.fromOffset(3, 16), Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = theme.Accent, BorderSizePixel = 0,
	}, frame), 3)

	make("TextLabel", {
		Size = UDim2.new(1, -36, 1, hasTimer and -12 or 0), Position = UDim2.fromOffset(24, hasTimer and 3 or 0),
		Text = text, TextColor3 = theme.Text, Font = FONTS.Mini, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
	}, frame)

	if hasTimer then
		progressBar(frame, theme, duration, UDim2.new(1, -32, 0, 1), UDim2.new(0, 16, 1, -5), 1, 0.92, false)
	end

	-- ширина по тексту (GetTextSize работает и до вставки в иерархию, в отличие от TextBounds)
	local textW = TextService:GetTextSize(text, 14, FONTS.Mini, Vector2.new(1000, 36)).X
	local width = math.round(math.clamp(textW + 42, 110, 320))
	placeholder.Size = UDim2.fromOffset(width, 36)

	local close, track = lifecycle(placeholder, frame, 0.35, 0.2, UDim2.fromOffset(width, 0))
	local born = os.clock()

	if hasCallback then
		local stroke = make("UIStroke", {
			Thickness = 1, Color = theme.Accent, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, frame)
		track(frame.MouseEnter:Connect(function()
			hoverTween(frame, { BackgroundTransparency = 0.05 }) hoverTween(stroke, { Transparency = 0.4 })
		end))
		track(frame.MouseLeave:Connect(function()
			hoverTween(frame, { BackgroundTransparency = 0.15 }) hoverTween(stroke, { Transparency = 1 })
		end))
		track(frame.MouseButton1Click:Connect(function()
			if os.clock() - born < 1 then return end
			task.spawn(callback)
			close()
		end))
	elseif not hasTimer then
		-- бессрочное без callback: закрывается наведением (но не раньше чем через 1 с)
		track(frame.MouseEnter:Connect(function()
			task.delay(math.max(0, 1 - (os.clock() - born)), close)
		end))
	end

	placeholder.Parent = getContainer()
	TweenService:Create(frame, IN_TWEEN, { Position = UDim2.new() }):Play()
	if hasTimer then task.delay(duration, close) end

	return { Close = close }
end

function Notify.Clear()
	local list = {}
	for _, close in pairs(_active) do list[#list + 1] = close end
	for _, close in ipairs(list) do close() end
end

function Notify.Destroy()
	table.clear(_active)
	if _container and _container.Parent then _container.Parent:Destroy() end
	_container = nil
end

return Notify
