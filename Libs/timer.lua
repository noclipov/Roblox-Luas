--[[ ════════════════════════════════════════════════════════════
  Noclipov · timer · v2.0
  Секундомер / часы на экране.
  API: Timer.new(mode?) → :Start() :Stop() :Reset() :Lap() :SetMode(m) :GetTime()
       :IsRunning() :Destroy()        mode = "Timer" | "Clock"
════════════════════════════════════════════════════════════ ]]

-- [1] SERVICES
local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")

-- [2] CONFIG
local UI_NAME   = "Noclipov_UniversalTimer_System"
local SHADOW_ID = "rbxassetid://1316045217"
local COLORS = {
	Background = Color3.fromRGB(25, 25, 30),
	Accent     = Color3.fromRGB(140, 100, 255),
	Text       = Color3.fromRGB(240, 240, 240),
	Shadow     = Color3.fromRGB(0, 0, 0),
}

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

local function formatTimer(total: number): string
	local h = math.floor(total / 3600)
	local m = math.floor(total / 60) % 60
	local s = math.floor(total) % 60
	local cs = math.floor((total % 1) * 100)
	local head = h > 0 and string.format("%d:%02d:%02d", h, m, s) or string.format("%02d:%02d", m, s)
	return string.format("%s.<font size='12'>%02d</font>", head, cs)
end

-- [4] CLASS
local Timer = { Version = "2.0" }
Timer.__index = Timer

function Timer.new(mode: string?)
	local self = setmetatable({
		Mode = mode or "Timer",
		Running = false,
		Laps = {},
		_elapsed = 0,
		_startedAt = 0,
		_text = "",
	}, Timer)

	self:_build()
	self._conn = RunService.RenderStepped:Connect(function() self:_update() end)
	return self
end

function Timer:_build()
	local old = CoreGui:FindFirstChild(UI_NAME)
	if old then old:Destroy() end

	local sg = make("ScreenGui", { Name = UI_NAME, ResetOnSpawn = false, IgnoreGuiInset = true })
	local shadow = make("ImageLabel", {
		Name = "Shadow", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.5, 90),
		Size = UDim2.fromOffset(160, 45), BackgroundTransparency = 1, Image = SHADOW_ID,
		ImageColor3 = COLORS.Shadow, ImageTransparency = 0.5, ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
	}, sg)
	local main = make("Frame", {
		Name = "Main", Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromOffset(5, 5),
		BackgroundColor3 = COLORS.Background, BackgroundTransparency = 0.5, BorderSizePixel = 0,
	}, shadow)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, main)
	make("UIStroke", { Color = COLORS.Accent, Thickness = 1, Transparency = 0.7 }, main)

	local bar = make("Frame", {
		Name = "InnerAccent", Size = UDim2.new(1, -40, 0, 2), Position = UDim2.new(0.5, 0, 1, -6),
		AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = COLORS.Accent, BorderSizePixel = 0, ZIndex = 7,
	}, main)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)

	self.Label = make("TextLabel", {
		Size = UDim2.new(1, 0, 1, -8), BackgroundTransparency = 1, TextColor3 = COLORS.Text,
		Font = Enum.Font.GothamBold, TextSize = 18, RichText = true, Text = "00:00.00", ZIndex = 8,
	}, main)

	sg.Parent = guiParent() -- Parent последним: один reflow вместо десятка
	self.Gui = sg
end

function Timer:_update()
	local text
	if self.Mode == "Clock" then
		text = os.date("%H:%M:%S")
	else
		text = formatTimer(self:GetTime())
	end
	if text ~= self._text then -- не трогаем Text, если строка не изменилась
		self._text = text
		self.Label.Text = text
	end
end

-- [5] PUBLIC API
function Timer:GetTime(): number
	return self.Running and (os.clock() - self._startedAt) or self._elapsed
end

function Timer:IsRunning(): boolean
	return self.Running
end

function Timer:SetMode(mode: string)
	self.Mode = mode
	self._text = ""
end

function Timer:Start()
	if self.Mode ~= "Timer" or self.Running then return end
	self._startedAt = os.clock() - self._elapsed
	self.Running = true
end

function Timer:Stop()
	if not self.Running then return end
	self._elapsed = os.clock() - self._startedAt
	self.Running = false
end

function Timer:Reset()
	self._elapsed = 0
	self._startedAt = self.Running and os.clock() or 0
	table.clear(self.Laps)
end

function Timer:Lap(): number
	local t = self:GetTime()
	self.Laps[#self.Laps + 1] = t
	return t
end

function Timer:Destroy()
	if self._conn then self._conn:Disconnect() self._conn = nil end
	if self.Gui then self.Gui:Destroy() self.Gui = nil end
end

return Timer
