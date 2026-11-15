--============================================================
-- NoclipovUI v4.9.1 — Premium Edition (Clipping & Glow Fixes)
--============================================================
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local ContentProvider  = game:GetService("ContentProvider")
local TextService      = game:GetService("TextService")

local SCRIPT_VERSION = "4.9.1"
local UI_NAME        = "NoclipovUI"
local LocalPlayer    = Players.LocalPlayer

local function PreloadAssets()
    local assets = { "rbxassetid://" .. tostring(LocalPlayer.UserId) }
    pcall(function() ContentProvider:PreloadAsync(assets) end)
end

local function CleanupOldUIs()
    local function destroyIn(parent)
        if not parent then return end
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ScreenGui") and (child.Name:match("^" .. UI_NAME) or child.Name == "Noclipov_UI_Storage") then
                pcall(function() child:Destroy() end)
            end
        end
    end
    local containers = {}
    if gethui then local ok, hui = pcall(gethui); if ok and hui then table.insert(containers, hui) end end
    if CoreGui then table.insert(containers, CoreGui) end
    if LocalPlayer then local pg = LocalPlayer:FindFirstChild("PlayerGui"); if pg then table.insert(containers, pg) end end
    for _, container in ipairs(containers) do destroyIn(container) end
end

local function MakeTheme(t)
    t.AccentGlow      = t.Accent:Lerp(Color3.new(1,1,1), 0.5)
    t.AccentShadow    = t.Accent:Lerp(t.BgDarkest, 0.6)
    t.SurfaceElevated = t.SurfaceLight:Lerp(t.BgMain, 0.3)
    t.HeaderPill      = t.BgMain:Lerp(t.BgDarkest, 0.4)
    return t
end

local Themes = {
    Amethyst = MakeTheme({
        name="Amethyst", BgDarkest=Color3.fromRGB(10,8,14), BgMain=Color3.fromRGB(16,13,22), BgSidebar=Color3.fromRGB(12,9,17),
        SurfaceBase=Color3.fromRGB(24,20,33), SurfaceLight=Color3.fromRGB(34,28,46), SurfaceHover=Color3.fromRGB(48,40,65),
        Accent=Color3.fromRGB(180,130,255), AccentHover=Color3.fromRGB(205,165,255), AccentDark=Color3.fromRGB(80,50,130), AccentSoft=Color3.fromRGB(220,190,255),
        Success=Color3.fromRGB(130,220,160), Danger=Color3.fromRGB(255,110,140), Warning=Color3.fromRGB(255,210,120), Info=Color3.fromRGB(140,190,255),
        Text=Color3.fromRGB(240,235,245), TextBright=Color3.fromRGB(255,255,255), TextDim=Color3.fromRGB(170,160,185), TextMuted=Color3.fromRGB(110,100,125),
        Border=Color3.fromRGB(50,44,65), BorderLight=Color3.fromRGB(80,70,105),
    }),
    Midnight = MakeTheme({
        name="Midnight", BgDarkest=Color3.fromRGB(3,6,12), BgMain=Color3.fromRGB(8,13,22), BgSidebar=Color3.fromRGB(5,10,18),
        SurfaceBase=Color3.fromRGB(15,22,36), SurfaceLight=Color3.fromRGB(22,32,50), SurfaceHover=Color3.fromRGB(32,46,70),
        Accent=Color3.fromRGB(100,180,255), AccentHover=Color3.fromRGB(140,205,255), AccentDark=Color3.fromRGB(35,80,140), AccentSoft=Color3.fromRGB(170,215,255),
        Success=Color3.fromRGB(100,220,180), Danger=Color3.fromRGB(255,100,110), Warning=Color3.fromRGB(255,200,100), Info=Color3.fromRGB(150,200,255),
        Text=Color3.fromRGB(225,235,250), TextBright=Color3.fromRGB(255,255,255), TextDim=Color3.fromRGB(140,155,180), TextMuted=Color3.fromRGB(85,100,125),
        Border=Color3.fromRGB(28,38,58), BorderLight=Color3.fromRGB(50,65,95),
    }),
    Emerald = MakeTheme({
        name="Emerald", BgDarkest=Color3.fromRGB(5,11,9), BgMain=Color3.fromRGB(10,18,14), BgSidebar=Color3.fromRGB(7,14,11),
        SurfaceBase=Color3.fromRGB(18,30,24), SurfaceLight=Color3.fromRGB(26,42,33), SurfaceHover=Color3.fromRGB(36,58,46),
        Accent=Color3.fromRGB(120,220,180), AccentHover=Color3.fromRGB(150,245,205), AccentDark=Color3.fromRGB(45,110,85), AccentSoft=Color3.fromRGB(180,240,210),
        Success=Color3.fromRGB(130,230,150), Danger=Color3.fromRGB(255,110,120), Warning=Color3.fromRGB(255,210,110), Info=Color3.fromRGB(120,200,220),
        Text=Color3.fromRGB(230,245,235), TextBright=Color3.fromRGB(255,255,255), TextDim=Color3.fromRGB(150,175,160), TextMuted=Color3.fromRGB(90,110,95),
        Border=Color3.fromRGB(34,54,44), BorderLight=Color3.fromRGB(60,90,75),
    }),
    Sunset = MakeTheme({
        name="Sunset", BgDarkest=Color3.fromRGB(12,6,6), BgMain=Color3.fromRGB(20,11,11), BgSidebar=Color3.fromRGB(16,8,8),
        SurfaceBase=Color3.fromRGB(33,18,18), SurfaceLight=Color3.fromRGB(46,26,26), SurfaceHover=Color3.fromRGB(66,38,38),
        Accent=Color3.fromRGB(255,160,120), AccentHover=Color3.fromRGB(255,195,155), AccentDark=Color3.fromRGB(140,72,45), AccentSoft=Color3.fromRGB(255,215,185),
        Success=Color3.fromRGB(140,210,130), Danger=Color3.fromRGB(255,100,100), Warning=Color3.fromRGB(255,210,100), Info=Color3.fromRGB(140,180,255),
        Text=Color3.fromRGB(250,235,230), TextBright=Color3.fromRGB(255,255,255), TextDim=Color3.fromRGB(180,160,150), TextMuted=Color3.fromRGB(115,90,80),
        Border=Color3.fromRGB(54,36,36), BorderLight=Color3.fromRGB(90,60,60),
    }),
    Crimson = MakeTheme({
        name="Crimson", BgDarkest=Color3.fromRGB(8,3,5), BgMain=Color3.fromRGB(15,6,10), BgSidebar=Color3.fromRGB(12,5,8),
        SurfaceBase=Color3.fromRGB(27,12,18), SurfaceLight=Color3.fromRGB(40,18,26), SurfaceHover=Color3.fromRGB(56,28,38),
        Accent=Color3.fromRGB(230,80,100), AccentHover=Color3.fromRGB(255,115,135), AccentDark=Color3.fromRGB(125,28,48), AccentSoft=Color3.fromRGB(255,165,185),
        Success=Color3.fromRGB(110,210,150), Danger=Color3.fromRGB(255,70,70), Warning=Color3.fromRGB(255,190,80), Info=Color3.fromRGB(140,160,255),
        Text=Color3.fromRGB(245,225,230), TextBright=Color3.fromRGB(255,255,255), TextDim=Color3.fromRGB(175,145,155), TextMuted=Color3.fromRGB(110,80,90),
        Border=Color3.fromRGB(55,32,42), BorderLight=Color3.fromRGB(85,50,65),
    }),
    Monochrome = MakeTheme({
        name="Monochrome", BgDarkest=Color3.fromRGB(8,8,8), BgMain=Color3.fromRGB(15,15,15), BgSidebar=Color3.fromRGB(11,11,11),
        SurfaceBase=Color3.fromRGB(24,24,24), SurfaceLight=Color3.fromRGB(36,36,36), SurfaceHover=Color3.fromRGB(52,52,52),
        Accent=Color3.fromRGB(210,210,210), AccentHover=Color3.fromRGB(240,240,240), AccentDark=Color3.fromRGB(95,95,95), AccentSoft=Color3.fromRGB(245,245,245),
        Success=Color3.fromRGB(180,180,180), Danger=Color3.fromRGB(150,150,150), Warning=Color3.fromRGB(190,190,190), Info=Color3.fromRGB(220,220,220),
        Text=Color3.fromRGB(235,235,235), TextBright=Color3.fromRGB(255,255,255), TextDim=Color3.fromRGB(150,150,150), TextMuted=Color3.fromRGB(90,90,90),
        Border=Color3.fromRGB(50,50,50), BorderLight=Color3.fromRGB(80,80,80),
    }),
}
local ThemeOrder = {"Amethyst", "Midnight", "Emerald", "Sunset", "Crimson", "Monochrome"}
local Theme = Themes.Amethyst
local CurrentThemeName = "Amethyst"

local Disposer = { items = {}, disposed = false }
function Disposer:track(kind, obj)
    if not obj then return obj end
    if self.disposed then
        pcall(function()
            if kind == "connection" and obj.Connected then obj:Disconnect()
            elseif kind == "instance" and obj.Parent then obj:Destroy() end
        end)
        return obj
    end
    table.insert(self.items, {kind = kind, obj = obj}); return obj
end
function Disposer:dispose()
    if self.disposed then return end
    self.disposed = true
    for i = #self.items, 1, -1 do
        local it = self.items[i]
        pcall(function()
            if it.kind == "connection" then if it.obj.Connected then it.obj:Disconnect() end
            elseif it.kind == "instance" then if it.obj.Parent then it.obj:Destroy() end end
        end)
        self.items[i] = nil
    end
end
local function TrackConnection(c) return Disposer:track("connection", c) end

local TweenManager = { active = setmetatable({}, {__mode = "k"}) }
local function CanTweenSequence(inst)
    return inst:IsA("UIGradient") or inst:IsA("Beam") or inst:IsA("ParticleEmitter") or inst:IsA("Trail")
end
function TweenManager.Create(inst, info, props)
    if not inst or not props then return end
    if props.Color and typeof(props.Color) == "ColorSequence" and not CanTweenSequence(inst) then
        pcall(function() inst.Color = props.Color end); props.Color = nil
    end
    if next(props) == nil then return nil end
    local existing = TweenManager.active[inst]
    if existing then pcall(function() existing:Cancel() end) end
    local ok, tw = pcall(TweenService.Create, TweenService, inst, info, props)
    if not ok or not tw then
        pcall(function() for k, v in pairs(props) do inst[k] = v end end); return nil
    end
    TweenManager.active[inst] = tw
    tw.Completed:Connect(function() if TweenManager.active[inst] == tw then TweenManager.active[inst] = nil end end)
    tw:Play(); return tw
end
function TweenManager.Cancel(inst)
    local tw = TweenManager.active[inst]
    if tw then pcall(function() tw:Cancel() end); TweenManager.active[inst] = nil end
end
local function Tween(inst, props, t, style, dir)
    if not inst then return end
    return TweenManager.Create(inst, TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
end
local function Spring(inst, props) return Tween(inst, props, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out) end

--============================================================
-- ⚡ NOTIFICATION SYSTEM
--============================================================
local Notify = { container = nil, maxVisible = 5, enabled = true }

local function ResolveNotifyTheme(nType)
    local t = Theme
    local accent = t.Accent
    if nType == "success" then accent = t.Success
    elseif nType == "warning" then accent = t.Warning
    elseif nType == "error" then accent = t.Danger
    elseif nType == "info" then accent = t.Info or t.Accent
    end
    return { Accent = accent, Text = t.Text, Bg = t.BgDarkest, Border = t.Border }
end

local function GetNotifyContainer()
    if Notify.container and Notify.container.Parent then return Notify.container end
    local parent = CoreGui
    if gethui then local ok, hui = pcall(gethui); if ok and hui then parent = hui end end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = UI_NAME .. "_NotifyStorage"; sg.ResetOnSpawn = false; sg.DisplayOrder = 999; sg.IgnoreGuiInset = true; sg.Parent = parent
    
    local frame = Instance.new("Frame")
    frame.Name = "NotifyContainer"; frame.Position = UDim2.new(1, -20, 1, -20)
    frame.Size = UDim2.new(0, 340, 0, 0); frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.AnchorPoint = Vector2.new(1, 1); frame.BackgroundTransparency = 1; frame.BorderSizePixel = 0; frame.Parent = sg
    
    local layout = Instance.new("UIListLayout")
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom; layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 10); layout.Parent = frame
    
    Notify.container = frame
    return frame
end

local function IsInfinite(duration) return duration == nil or duration == 0 or duration == "inf" or duration == math.huge end

function Notify.New(themeOrType, title, text, duration, callback, buttonText)
    if not Notify.enabled then return end
    local theme = ResolveNotifyTheme(type(themeOrType) == "string" and themeOrType or "info")
    local container = GetNotifyContainer()
    local hasTimer = not IsInfinite(duration)
    local hasCallback = typeof(callback) == "function"
    local hasButton = hasCallback and (buttonText ~= nil and buttonText ~= "")
    local isCardClickable = hasCallback and not hasButton
    
    local active = {}
    for _, child in ipairs(container:GetChildren()) do
        if child.Name == "NotifyWrapper" and child:IsA("GuiObject") then table.insert(active, child) end
    end
    if #active >= Notify.maxVisible then pcall(function() active[1]:Destroy() end) end
    
    local placeholder = Instance.new("Frame", container)
    placeholder.Name = "NotifyWrapper"; placeholder.Size = UDim2.new(1, 0, 0, 0)
    placeholder.BackgroundTransparency = 1; placeholder.BorderSizePixel = 0; placeholder.ClipsDescendants = true; placeholder.ZIndex = 200
    
    local frame = Instance.new(isCardClickable and "TextButton" or "Frame", placeholder)
    frame.Size = UDim2.new(1, 0, 1, 0); frame.Position = UDim2.new(1.3, 0, 0, 0)
    frame.BackgroundTransparency = 1; frame.BorderSizePixel = 0
    if isCardClickable then frame.Text = ""; frame.AutoButtonColor = false end
    
    local bgFrame = Instance.new("Frame", frame)
    bgFrame.Size = UDim2.new(1, 0, 1, 0); bgFrame.BackgroundColor3 = theme.Bg
    bgFrame.BorderSizePixel = 0; bgFrame.ZIndex = 1
    Instance.new("UICorner", bgFrame).CornerRadius = UDim.new(0, 10)
    local gradient = Instance.new("UIGradient", bgFrame)
    gradient.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(160,160,160))
    gradient.Rotation = 90
    
    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -45, 0, 18); titleLbl.Position = UDim2.new(0, 25, 0, 12)
    titleLbl.Text = tostring(title):upper(); titleLbl.TextColor3 = theme.Accent
    titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.BackgroundTransparency = 1; titleLbl.ZIndex = 2
    titleLbl.TextStrokeTransparency = 1
    
    local progressGradient
    if hasTimer then
        local barContainer = Instance.new("Frame", frame)
        barContainer.Size = UDim2.new(1, -45, 0, 2); barContainer.Position = UDim2.new(0, 25, 0, 34)
        barContainer.BackgroundColor3 = theme.Accent; barContainer.BackgroundTransparency = 0.85
        barContainer.BorderSizePixel = 0; barContainer.ClipsDescendants = true; barContainer.ZIndex = 2
        Instance.new("UICorner", barContainer)
        local progressInner = Instance.new("Frame", barContainer)
        progressInner.Size = UDim2.new(1, 0, 1, 0); progressInner.BackgroundColor3 = Color3.fromRGB(255,255,255)
        progressInner.BorderSizePixel = 0; Instance.new("UICorner", progressInner)
        progressGradient = Instance.new("UIGradient", progressInner)
        progressGradient.Color = ColorSequence.new(theme.Accent)
        progressGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.999, 0), NumberSequenceKeypoint.new(1, 1)
        })
    end
    
    local availableWidth = 340 - 45
    local descHeight = TextService:GetTextSize(text, 14, Enum.Font.GothamMedium, Vector2.new(availableWidth, 1000)).Y
    local finalHeight = math.max(50, descHeight + 42)
    
    local descLbl = Instance.new("TextLabel", frame)
    descLbl.Size = UDim2.new(1, -35, 0, descHeight); descLbl.Position = UDim2.new(0, 25, 0, 34)
    descLbl.Text = text; descLbl.TextColor3 = theme.Text; descLbl.Font = Enum.Font.GothamMedium
    descLbl.TextSize = 14; descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.TextYAlignment = Enum.TextYAlignment.Top
    descLbl.TextWrapped = true; descLbl.BackgroundTransparency = 1; descLbl.ZIndex = 2
    descLbl.TextStrokeTransparency = 1
    
    local accentLine = Instance.new("Frame", frame)
    accentLine.Size = UDim2.new(0, 3, 1, -20); accentLine.Position = UDim2.new(0, 12, 0, 10)
    accentLine.BackgroundColor3 = theme.Accent; accentLine.BorderSizePixel = 0; accentLine.ZIndex = 2
    Instance.new("UICorner", accentLine)
    
    local function closeNotification()
        local slideOut = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1.3, 0, 0, 0)})
        slideOut:Play(); slideOut.Completed:Wait()
        local collapse = TweenService:Create(placeholder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)})
        collapse:Play(); collapse.Completed:Wait(); placeholder:Destroy()
    end
    
    local clickConnection, mouseEnterConnection, mouseLeaveConnection
    local canClick = false
    task.delay(0.5, function() canClick = true end)
    
    if hasButton then
        local btnTextWidth = TextService:GetTextSize(tostring(buttonText):upper(), 12, Enum.Font.GothamBold, Vector2.new(200, 50)).X
        local btnWidth = math.round(math.clamp(btnTextWidth + 24, 80, 140))
        local actionBtn = Instance.new("TextButton", frame)
        actionBtn.Size = UDim2.new(0, btnWidth, 0, 24); actionBtn.Position = UDim2.new(1, -20, 1, -12)
        actionBtn.AnchorPoint = Vector2.new(1, 1); actionBtn.BackgroundColor3 = theme.Accent
        actionBtn.BackgroundTransparency = 0.93; actionBtn.Text = tostring(buttonText):upper()
        actionBtn.TextColor3 = theme.Accent; actionBtn.Font = Enum.Font.GothamBold
        actionBtn.TextSize = 12; actionBtn.AutoButtonColor = false; actionBtn.ZIndex = 3
        actionBtn.TextStrokeTransparency = 1
        Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 5)
        local btnStroke = Instance.new("UIStroke", actionBtn)
        btnStroke.Color = theme.Accent; btnStroke.Thickness = 1; btnStroke.Transparency = 0.75
        
        actionBtn.MouseEnter:Connect(function()
            TweenService:Create(actionBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.8}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.4}):Play()
        end)
        actionBtn.MouseLeave:Connect(function()
            TweenService:Create(actionBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.93}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.75}):Play()
        end)
        clickConnection = actionBtn.MouseButton1Click:Connect(function()
            if not canClick then return end
            if clickConnection then clickConnection:Disconnect() end
            task.spawn(callback); closeNotification()
        end)
    elseif isCardClickable then
        local hoverColor = theme.Bg:Lerp(Color3.new(1,1,1), 0.05)
        mouseEnterConnection = frame.MouseEnter:Connect(function()
            TweenService:Create(bgFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = hoverColor}):Play()
        end)
        mouseLeaveConnection = frame.MouseLeave:Connect(function()
            TweenService:Create(bgFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = theme.Bg}):Play()
        end)
        clickConnection = frame.MouseButton1Click:Connect(function()
            if not canClick then return end
            if mouseEnterConnection then mouseEnterConnection:Disconnect() end
            if mouseLeaveConnection then mouseLeaveConnection:Disconnect() end
            if clickConnection then clickConnection:Disconnect() end
            task.spawn(callback); closeNotification()
        end)
    end
    
    TweenService:Create(placeholder, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, finalHeight)}):Play()
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    
    if hasTimer and progressGradient then
        local progressTween = TweenService:Create(progressGradient, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Offset = Vector2.new(-1, 0)})
        progressTween:Play()
        progressTween.Completed:Connect(function()
            if clickConnection then clickConnection:Disconnect() end
            if mouseEnterConnection then mouseEnterConnection:Disconnect() end
            if mouseLeaveConnection then mouseLeaveConnection:Disconnect() end
            closeNotification()
        end)
    end
    return { dismiss = closeNotification }
end

function Notify.Push(title, text, nType, duration)
    if not Notify.enabled then return end
    return Notify.New(nType or "info", title, text, duration or 3)
end

local Notifications = { enabled = true }
function Notifications.Push(text, nType, duration) Notify.Push("NOTIFICATION", text, nType, duration) end

--============================================================
-- BIND SYSTEM
--============================================================
local BindSystem = { 
    Bindings = {}, Buttons = {}, Held = {}, Capture = nil, MaxCaptureTime = 12, 
    _lastCompleted = {actionId = nil, at = 0}, Listeners = {}, _lastToggleTime = 0
}

local INPUT_PRETTIFY = {
    [Enum.KeyCode.LeftShift]="LShift", [Enum.KeyCode.RightShift]="RShift", [Enum.KeyCode.LeftControl]="LCtrl", [Enum.KeyCode.RightControl]="RCtrl",
    [Enum.KeyCode.LeftAlt]="LAlt", [Enum.KeyCode.RightAlt]="RAlt", [Enum.KeyCode.CapsLock]="CAPS", [Enum.KeyCode.Backspace]="BKSP",
    [Enum.KeyCode.Return]="ENTER", [Enum.KeyCode.Escape]="ESC", [Enum.KeyCode.Tab]="TAB", [Enum.KeyCode.Space]="SPACE",
    [Enum.KeyCode.Delete]="DELETE", [Enum.KeyCode.Insert]="INSERT",
    [Enum.UserInputType.MouseButton1]="M1", [Enum.UserInputType.MouseButton2]="M2", [Enum.UserInputType.MouseButton3]="M3",
}
local MOUSE_TYPES = {[Enum.UserInputType.MouseButton1]=true, [Enum.UserInputType.MouseButton2]=true, [Enum.UserInputType.MouseButton3]=true}

function BindSystem.FormatDisplay(b)
    if not b then return "None" end
    if b.type == "wheel" then return b.value > 0 and "MW↑" or "MW↓" end
    if b.type == "key" then return INPUT_PRETTIFY[b.value] or b.value.Name end
    if b.type == "mouse" then return INPUT_PRETTIFY[b.value] or tostring(b.value) end
    return "None"
end
function BindSystem.GetDisplay(id) return BindSystem.FormatDisplay(BindSystem.Bindings[id]) end
function BindSystem.NotifyListeners(id) for _, fn in ipairs(BindSystem.Listeners) do pcall(fn, id) end end
function BindSystem.Subscribe(fn) table.insert(BindSystem.Listeners, fn) end
function BindSystem.UpdateButton(id)
    local btn = BindSystem.Buttons[id]
    if btn and btn.Parent then
        btn.Text = BindSystem.GetDisplay(id)
        btn.TextColor3 = BindSystem.Bindings[id] and Theme.TextBright or Theme.TextMuted
    end
    BindSystem.NotifyListeners(id)
end
function BindSystem.RegisterButton(id, btn) BindSystem.Buttons[id] = btn; BindSystem.UpdateButton(id) end
function BindSystem.Set(id, binding, notify)
    if binding then
        for otherId, ob in pairs(BindSystem.Bindings) do
            if otherId ~= id and ob.type == binding.type and ob.value == binding.value then
                BindSystem.Bindings[otherId] = nil; BindSystem.Held[otherId] = nil; BindSystem.UpdateButton(otherId)
            end
        end
    end
    BindSystem.Bindings[id] = binding; BindSystem.Held[id] = nil; BindSystem.UpdateButton(id)
end
function BindSystem.Clear(id) BindSystem.Bindings[id] = nil; BindSystem.Held[id] = nil; BindSystem.UpdateButton(id) end
function BindSystem.MatchBinding(binding, input)
    if not binding then return false end
    if binding.type == "key" then return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == binding.value
    elseif binding.type == "mouse" then return input.UserInputType == binding.value
    elseif binding.type == "wheel" then
        if input.UserInputType ~= Enum.UserInputType.MouseWheel then return false end
        return (input.Position.Z > 0 and binding.value > 0) or (input.Position.Z < 0 and binding.value < 0)
    end
    return false
end
function BindSystem.InputToBinding(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.Unknown then return nil end
        return {type = "key", value = input.KeyCode}
    end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        if input.Position.Z > 0 then return {type = "wheel", value = 1} end
        if input.Position.Z < 0 then return {type = "wheel", value = -1} end
        return nil
    end
    if MOUSE_TYPES[input.UserInputType] then return {type = "mouse", value = input.UserInputType} end
    return nil
end
function BindSystem.CaptureStart(id, btn)
    if BindSystem.Capture then BindSystem.CaptureCancel() end
    BindSystem.Capture = {actionId = id, button = btn, startedAt = os.clock()}
    if btn and btn.Parent then btn.Text = "…"; btn.TextColor3 = Theme.Accent; pcall(function() Tween(btn, {BackgroundColor3 = Theme.AccentDark}, 0.15) end) end
end
function BindSystem.CaptureCancel()
    local cap = BindSystem.Capture; if not cap then return end
    BindSystem.Capture = nil
    if cap.button and cap.button.Parent then
        BindSystem.UpdateButton(cap.actionId)
        pcall(function() Tween(cap.button, {BackgroundColor3 = Theme.SurfaceLight}, 0.15) end)
    end
end
function BindSystem.CaptureComplete(binding)
    local cap = BindSystem.Capture; if not cap then return end
    BindSystem.Capture = nil; BindSystem._lastCompleted = {actionId = cap.actionId, at = os.clock()}
    if cap.button and cap.button.Parent then pcall(function() Tween(cap.button, {BackgroundColor3 = Theme.SurfaceLight}, 0.15) end) end
    BindSystem.Set(cap.actionId, binding, true)
end
function BindSystem.CaptureTick()
    local cap = BindSystem.Capture; if not cap then return end
    if os.clock() - cap.startedAt > BindSystem.MaxCaptureTime then BindSystem.CaptureCancel() end
end
function BindSystem.Serialize(id)
    local b = BindSystem.Bindings[id]; if not b then return nil end
    if b.type == "key" then return {type="key", value=b.value.Name} end
    if b.type == "mouse" then return {type="mouse", value=b.value.Name} end
    if b.type == "wheel" then return {type="wheel", value=b.value} end
end
function BindSystem.Deserialize(data)
    if type(data) ~= "table" then return nil end
    if data.type == "key" and type(data.value) == "string" then
        local kc = Enum.KeyCode[data.value]; if kc then return {type="key", value=kc} end
    elseif data.type == "mouse" and type(data.value) == "string" then
        local uit = Enum.UserInputType[data.value]; if uit and MOUSE_TYPES[uit] then return {type="mouse", value=uit} end
    elseif data.type == "wheel" and type(data.value) == "number" then
        return {type="wheel", value=data.value >= 0 and 1 or -1}
    end
    return nil
end
TrackConnection(RunService.Heartbeat:Connect(function() BindSystem.CaptureTick() end))

--============================================================
-- THEME SYSTEM
--============================================================
local ThemeBindings, ThemeGradients, ThemeListeners, ActiveColorTweens = {}, {}, {}, {}
local _lastCleanupAt, CLEANUP_INTERVAL = 0, 15
local _lastApplyAt, APPLY_DEBOUNCE = 0, 0.05

local ThemeSystem = {}
function ThemeSystem.Bind(inst, props)
    if not inst then return end
    local data = ThemeBindings[inst]
    if not data then data = {}; ThemeBindings[inst] = data end
    for prop, key in pairs(props) do
        if Theme[key] then data[prop] = key; inst[prop] = Theme[key] end
    end
end
function ThemeSystem.BindGradient(grad, k1, k2, rot, transp)
    if not grad then return end
    ThemeGradients[grad] = {k1, k2}
    local c1, c2 = Theme[k1], Theme[k2]
    if c1 and c2 then grad.Color = ColorSequence.new(c1, c2) end
    if rot then grad.Rotation = rot end
    if transp then grad.Transparency = transp end
end
function ThemeSystem.Subscribe(fn)
    table.insert(ThemeListeners, fn)
    return function()
        for i = #ThemeListeners, 1, -1 do
            if ThemeListeners[i] == fn then table.remove(ThemeListeners, i); break end
        end
    end
end
function ThemeSystem.Get(key) return Theme[key] end
function ThemeSystem.GetName() return CurrentThemeName end

local function CleanupBindings()
    local now = os.clock()
    if now - _lastCleanupAt < CLEANUP_INTERVAL then return end
    _lastCleanupAt = now
    for inst in pairs(ThemeBindings)  do if not inst.Parent then ThemeBindings[inst]  = nil end end
    for g    in pairs(ThemeGradients) do if not g.Parent    then ThemeGradients[g]    = nil end end
    for inst in pairs(ActiveColorTweens) do if not inst.Parent then ActiveColorTweens[inst] = nil end end
end

function ThemeSystem.Apply(name, silent)
    local new = Themes[name]; if not new then return end
    if CurrentThemeName == name and not silent then return end
    local now = os.clock()
    if not silent and now - _lastApplyAt < APPLY_DEBOUNCE and CurrentThemeName == name then return end
    _lastApplyAt = now
    local old = Theme; Theme = new; CurrentThemeName = name
    CleanupBindings()
    local info = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    for inst, props in pairs(ThemeBindings) do
        if inst.Parent then
            local targetProps = {}
            for prop, key in pairs(props) do
                local target = new[key]
                if target and typeof(inst[prop]) == "Color3" and inst[prop] ~= target then targetProps[prop] = target end
            end
            if next(targetProps) ~= nil then
                if silent then pcall(function() for k, v in pairs(targetProps) do inst[k] = v end end)
                else
                    local prev = ActiveColorTweens[inst]
                    if prev then pcall(function() prev:Cancel() end) end
                    local ok, tw = pcall(TweenService.Create, TweenService, inst, info, targetProps)
                    if ok and tw then
                        ActiveColorTweens[inst] = tw
                        tw.Completed:Connect(function() if ActiveColorTweens[inst] == tw then ActiveColorTweens[inst] = nil end end)
                        tw:Play()
                    else pcall(function() for k, v in pairs(targetProps) do inst[k] = v end end) end
                end
            end
        end
    end
    for grad, keys in pairs(ThemeGradients) do
        if grad.Parent then
            local c1, c2 = new[keys[1]], new[keys[2]]
            if c1 and c2 then pcall(function() grad.Color = ColorSequence.new(c1, c2) end) end
        end
    end
    for _, fn in ipairs(ThemeListeners) do pcall(fn, new, old) end
end

--============================================================
-- BUILDERS
--============================================================
local function CreateInstance(class, props)
    local inst = Instance.new(class)
    if props then for k, v in pairs(props) do pcall(function() inst[k] = v end) end end
    return inst
end
local function Corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p; return c end
local function Gradient(p, k1, k2, rot, transp)
    local g = Instance.new("UIGradient")
    if type(k1) == "string" and type(k2) == "string" then
        ThemeSystem.BindGradient(g, k1, k2, rot or 0, transp)
    else
        g.Color = ColorSequence.new(k1, k2); g.Rotation = rot or 0
        if transp then g.Transparency = transp end
    end
    g.Parent = p; return g
end
local function Stroke(p, themeKey, thick, transp)
    local s = Instance.new("UIStroke")
    if type(themeKey) == "string" then s.Color = Theme[themeKey] or Theme.Border; ThemeSystem.Bind(s, {Color = themeKey})
    else s.Color = themeKey end
    s.Thickness = thick or 1; s.Transparency = transp or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end
local function Pad(p, t, r, b, l)
    local x = Instance.new("UIPadding")
    x.PaddingTop = UDim.new(0, t or 0); x.PaddingBottom = UDim.new(0, b or 0)
    x.PaddingLeft = UDim.new(0, l or 0); x.PaddingRight = UDim.new(0, r or 0)
    x.Parent = p; return p
end

-- ⚡ FIX: Улучшенный AddShadow без обрезания
local function AddShadow(p, opts)
    opts = opts or {}
    local ok, sh = pcall(function() return Instance.new("UIShadow") end)
    if ok and sh then
        if opts.themeKey then sh.Color = Theme[opts.themeKey] or Theme.BgDarkest; ThemeSystem.Bind(sh, {Color = opts.themeKey})
        else sh.Color = opts.color or Theme.BgDarkest end
        sh.Transparency = opts.transparency or 0.6
        pcall(function()
            sh.BlurRadius = UDim.new(0, opts.blur or 24)
            sh.Spread     = UDim.new(0, opts.spread or 0)
        end)
        pcall(function() sh.Offset = opts.offset or Vector2.new(0, 6) end)
        sh.Parent = p; return sh
    end
    local shadowImg = Instance.new("ImageLabel")
    shadowImg.Name = "ShadowImg"
    shadowImg.AnchorPoint = Vector2.new(0.5, 0.5)
    shadowImg.Position = UDim2.new(0.5, opts.offset and opts.offset.X or 0, 0.5, opts.offset and opts.offset.Y or 0)
    shadowImg.Size = UDim2.new(1, (opts.blur or 24) * 2, 1, (opts.blur or 24) * 2)
    shadowImg.BackgroundTransparency = 1
    shadowImg.Image = "rbxassetid://1316045217"
    shadowImg.ImageColor3 = opts.themeKey and Theme[opts.themeKey] or opts.color or Theme.BgDarkest
    shadowImg.ImageTransparency = opts.transparency or 0.6
    shadowImg.ScaleType = Enum.ScaleType.Slice
    shadowImg.SliceCenter = Rect.new(10, 10, 118, 118)
    shadowImg.ZIndex = math.max(0, p.ZIndex - 1)
    shadowImg.Parent = p.Parent
    return shadowImg
end

local function MakeFrame(parent, props)
    props = props or {}
    local f = Instance.new("Frame")
    f.Name = props.Name or "Frame"; f.Size = props.Size or UDim2.new(1, 0, 0, 0)
    f.Position = props.Position or UDim2.fromOffset(0, 0); f.AnchorPoint = props.AnchorPoint or Vector2.zero
    f.BackgroundTransparency = props.BackgroundTransparency or 0; f.BorderSizePixel = 0
    f.ZIndex = props.ZIndex or 1; f.Visible = props.Visible ~= false
    if props.Active ~= nil then f.Active = props.Active end
    if props.ClipsDescendants ~= nil then f.ClipsDescendants = props.ClipsDescendants end
    f.Parent = parent
    if props.BackgroundTheme then f.BackgroundColor3 = Theme[props.BackgroundTheme] or Theme.SurfaceBase; ThemeSystem.Bind(f, {BackgroundColor3 = props.BackgroundTheme})
    else f.BackgroundColor3 = props.BackgroundColor3 or Theme.SurfaceBase end
    return f
end
local function MakeLabel(parent, props)
    props = props or {}
    local l = Instance.new("TextLabel")
    l.Name = props.Name or "Label"; l.Size = props.Size or UDim2.new(1, 0, 1, 0)
    l.Position = props.Position or UDim2.fromOffset(0, 0); l.BackgroundTransparency = props.BackgroundTransparency or 1
    l.Text = props.Text or ""; l.TextSize = props.TextSize or 14; l.Font = props.Font or Enum.Font.GothamMedium
    l.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    l.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    l.TextWrapped = props.TextWrapped or false; l.TextTruncate = props.TextTruncate or Enum.TextTruncate.None
    l.RichText = props.RichText or false; l.ZIndex = props.ZIndex or 1
    l.TextStrokeTransparency = 1
    if props.AutomaticSize then l.AutomaticSize = props.AutomaticSize end
    if props.TextTransparency then l.TextTransparency = props.TextTransparency end
    l.Parent = parent
    if props.TextTheme then l.TextColor3 = Theme[props.TextTheme] or Theme.Text; ThemeSystem.Bind(l, {TextColor3 = props.TextTheme})
    else l.TextColor3 = props.TextColor3 or Theme.Text end
    if props.BackgroundTheme then l.BackgroundColor3 = Theme[props.BackgroundTheme] or Theme.SurfaceBase; ThemeSystem.Bind(l, {BackgroundColor3 = props.BackgroundTheme})
    elseif props.BackgroundColor3 then l.BackgroundColor3 = props.BackgroundColor3 end
    return l
end
local function EnsureUIScale(inst)
    local s = inst:FindFirstChildOfClass("UIScale")
    if not s then s = Instance.new("UIScale"); s.Scale = 1; s.Parent = inst end
    return s
end

local CurrentInteraction = nil
local function SetInteraction(h) CurrentInteraction = h end

local function ApplyHover(inst, opts)
    opts = opts or {}
    local uiscale = EnsureUIScale(inst)
    local baseTransp = opts.stroke and opts.stroke.Transparency
    local function resolve(key, fb)
        if not key then return Theme[fb] end
        if typeof(key) == "Color3" then return key end
        return Theme[key] or Theme[fb]
    end
    TrackConnection(inst.MouseEnter:Connect(function()
        Spring(uiscale, {Scale = opts.scale or 1.015})
        if opts.stroke then Tween(opts.stroke, {Color = resolve(opts.hoverStrokeColor, "Accent"), Transparency = opts.hoverStrokeTransp or 0.35}, 0.2) end
    end))
    TrackConnection(inst.MouseLeave:Connect(function()
        Tween(uiscale, {Scale = 1}, 0.2)
        if opts.stroke then Tween(opts.stroke, {Color = resolve(opts.baseStrokeColor, "Border"), Transparency = baseTransp}, 0.2) end
    end))
end
local function ApplyPress(inst, opts)
    opts = opts or {}
    local uiscale = EnsureUIScale(inst)
    TrackConnection(inst.MouseButton1Down:Connect(function() Tween(uiscale, {Scale = opts.pressScale or 0.97}, 0.1) end))
    TrackConnection(inst.MouseButton1Up:Connect(function() Spring(uiscale, {Scale = opts.hoverScale or 1.015}) end))
end

--============================================================
-- HELPERS
--============================================================
local function GetPlayerThumb(userId, size)
    size = size or 150
    return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d", userId, size, size)
end
local function MakeDraggableClickable(frame, onClick)
    local startPos, dragStart; local moved = false; local dragging = false
    TrackConnection(frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            startPos = frame.AbsolutePosition
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            moved = false; dragging = true
            local moveConn
            moveConn = UserInputService.InputChanged:Connect(function(inp)
                if not dragging then return end
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
                    if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
                        moved = true
                        local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
                        frame.Position = UDim2.fromOffset(
                            math.clamp(startPos.X + delta.X, 0, math.max(0, vp.X - frame.AbsoluteSize.X)),
                            math.clamp(startPos.Y + delta.Y, 0, math.max(0, vp.Y - frame.AbsoluteSize.Y))
                        )
                    end
                end
            end)
            local endConn
            endConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                    if not moved and onClick then onClick() end
                end
            end)
            TrackConnection(moveConn); TrackConnection(endConn)
        end
    end))
end

--============================================================
-- COMPONENTS
--============================================================
local ToggleRefs, SliderRefs = {}, {}

local function StyleCard(card, opts)
    opts = opts or {}; Corner(card, opts.radius or 10)
    Gradient(card, "SurfaceBase", "BgDarkest", 90)
    local st = Stroke(card, "Border", 1, 0.7)
    local info = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TrackConnection(card.MouseEnter:Connect(function()
        TweenManager.Create(st, info, {Color = Theme.Accent, Transparency = 0.5})
    end))
    TrackConnection(card.MouseLeave:Connect(function()
        TweenManager.Create(st, info, {Color = Theme.Border, Transparency = 0.7})
    end))
    return st
end
local function MakeIconBadge(parent, size, pos, iconData)
    if not iconData then return nil, nil end
    local box = MakeFrame(parent, { Size=UDim2.fromOffset(size, size), Position=pos, BackgroundTheme="SurfaceLight", BackgroundTransparency=0.3 })
    Corner(box, math.floor(size * 0.32)); Gradient(box, "SurfaceHover", "SurfaceBase", 45)
    local st = Stroke(box, "Border", 1, 0.6)
    MakeLabel(box, { Size=UDim2.fromScale(1, 1), Text=iconData, TextTheme="TextDim", TextSize=15, TextXAlignment=Enum.TextXAlignment.Center, TextYAlignment=Enum.TextYAlignment.Center })
    return box, st
end
local function MakeSwitch(parent, default, cb, opts)
    opts = opts or {}; local swW, swH = opts.width or 46, opts.height or 24
    local knobSize = opts.knobSize or 18; local padRight = opts.padRight or 14; local toggled = default
    local sw = Instance.new("TextButton")
    sw.Size = UDim2.fromOffset(swW, swH); sw.Position = UDim2.new(1, -(swW + padRight), 0.5, -swH / 2)
    sw.BackgroundColor3 = toggled and Theme.AccentDark or Theme.SurfaceBase
    sw.BackgroundTransparency = 0; sw.BorderSizePixel = 0; sw.Text = ""; sw.AutoButtonColor = false
    sw.TextStrokeTransparency = 1
    sw.ZIndex = 3; sw.ClipsDescendants = true; sw.Parent = parent; Corner(sw, math.floor(swH / 2))
    local swGrad = Instance.new("UIGradient")
    swGrad.Color = toggled and ColorSequence.new(Theme.AccentSoft, Theme.AccentDark) or ColorSequence.new(Theme.SurfaceBase, Theme.BgDarkest)
    swGrad.Rotation = 90; swGrad.Parent = sw
    local knobPosOn  = UDim2.new(1, -(knobSize + 3), 0.5, -knobSize / 2)
    local knobPosOff = UDim2.new(0, 3, 0.5, -knobSize / 2)
    local knob = MakeFrame(sw, { Size=UDim2.fromOffset(knobSize, knobSize), Position=toggled and knobPosOn or knobPosOff, BackgroundTheme="TextBright", ZIndex=5 })
    Corner(knob, math.floor(knobSize / 2)); Gradient(knob, Color3.fromRGB(255,255,255), Color3.fromRGB(220,225,235), 90)
    AddShadow(knob, {transparency = 0.5, blur = 8, offset = Vector2.new(0, 2)})
    local function applyThemeColors()
        if not sw.Parent then return end
        if toggled then sw.BackgroundColor3 = Theme.AccentDark; swGrad.Color = ColorSequence.new(Theme.AccentSoft, Theme.AccentDark)
        else sw.BackgroundColor3 = Theme.SurfaceBase; swGrad.Color = ColorSequence.new(Theme.SurfaceBase, Theme.BgDarkest) end
    end
    local unsub = ThemeSystem.Subscribe(applyThemeColors)
    TrackConnection(sw.Destroying:Connect(unsub))
    local function set(val, silent)
        toggled = val; local targetPos = toggled and knobPosOn or knobPosOff
        if silent then applyThemeColors(); knob.Position = targetPos
        else
            Tween(sw, {BackgroundColor3 = toggled and Theme.AccentDark or Theme.SurfaceBase}, 0.25)
            Spring(knob, {Position = targetPos})
            swGrad.Color = toggled and ColorSequence.new(Theme.AccentSoft, Theme.AccentDark) or ColorSequence.new(Theme.SurfaceBase, Theme.BgDarkest)
        end
        if cb then cb(toggled) end
    end
    local function get() return toggled end
    TrackConnection(sw.MouseButton1Click:Connect(function() set(not toggled, false) end))
    return set, get
end
local function MakeSlider(parent, min, max, default, cb, opts)
    opts = opts or {}; local decimals = opts.decimals or 0; local mult = 10 ^ decimals
    local pillW = opts.pillWidth or 50; local currentV = default
    local pill = MakeFrame(parent, { Size=UDim2.fromOffset(pillW, 22), Position=UDim2.new(1, -64, 0, 10), BackgroundTheme="BgDarkest", BackgroundTransparency=0.4, ZIndex=2 })
    Corner(pill, 11); Stroke(pill, "Border", 1, 0.7)
    local val = Instance.new("TextBox")
    val.Size = UDim2.fromScale(1, 1); val.BackgroundTransparency = 1; val.Text = string.format("%." .. decimals .. "f", default)
    val.TextColor3 = Theme.Accent; val.TextSize = 11; val.Font = Enum.Font.Code
    val.TextXAlignment = Enum.TextXAlignment.Center; val.TextEditable = true; val.ClearTextOnFocus = false; val.Parent = pill
    val.TextStrokeTransparency = 1
    Pad(val, 0, 6, 0, 6)
    ThemeSystem.Bind(val, {TextColor3 = "Accent"})
    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -28, 0, 6); track.Position = UDim2.new(0, 14, 1, -16); track.BackgroundColor3 = Theme.BgDarkest
    track.BackgroundTransparency = 0.4; track.BorderSizePixel = 0; track.Text = ""; track.AutoButtonColor = false; track.ZIndex = 3; track.Parent = parent
    Corner(track, 3); Stroke(track, "Border", 1, 0.8); ThemeSystem.Bind(track, {BackgroundColor3 = "BgDarkest"})
    local fill = MakeFrame(track, { Size=UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundTheme="Accent", ZIndex=3 })
    Corner(fill, 3); Gradient(fill, "AccentDark", "AccentSoft", 0)
    local knob = MakeFrame(track, { Size=UDim2.fromOffset(14, 14), AnchorPoint=Vector2.new(0.5, 0.5), Position=UDim2.new((default - min) / (max - min), 0, 0.5, 0), BackgroundTheme="TextBright", ZIndex=5 })
    Corner(knob, 7); Stroke(knob, "Accent", 1.5, 0.2); AddShadow(knob, {themeKey = "BgDarkest", transparency=0.5, blur=6, offset=Vector2.new(0, 2)})
    local function updateUI(v, applyMagnet)
        v = math.clamp(v, min, max)
        currentV = v; v = math.floor(v * mult + 0.5) / mult; local pct = (v - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, 0, 0.5, 0)
        val.Text = string.format("%." .. decimals .. "f", v); if cb then cb(v) end
    end
    local function getValue() return currentV end
    TrackConnection(val.FocusLost:Connect(function()
        local n = tonumber(val.Text); if n then updateUI(n, true) else val.Text = string.format("%." .. decimals .. "f", currentV) end
    end))
    TrackConnection(track.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local raw = min + (max - min) * (math.clamp(input.Position.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X) / track.AbsoluteSize.X)
        updateUI(raw, true); Spring(knob, {Size = UDim2.fromOffset(16, 16)})
        if opts.onDragStart then opts.onDragStart() end
        SetInteraction({
            onMove = function(inp) local rawMove = min + (max - min) * (math.clamp(inp.Position.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X) / track.AbsoluteSize.X); updateUI(rawMove, false) end,
            onEnd = function() Tween(knob, {Size = UDim2.fromOffset(14, 14)}, 0.15); updateUI(currentV, true); if opts.onDragEnd then opts.onDragEnd() end end,
        })
    end))
    return updateUI, getValue
end
local function MakeKeycap(parent, actionId)
    local w, h = 76, 26
    local holder = MakeFrame(parent, { Size=UDim2.fromOffset(w, h), Position=UDim2.new(1, -90, 0.5, -13), BackgroundTransparency=1, ZIndex=2 }); Corner(holder, 6)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1); btn.BackgroundColor3 = Theme.SurfaceLight; btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0; btn.Text = "None"; btn.TextColor3 = Theme.TextMuted; btn.TextSize = 11; btn.Font = Enum.Font.GothamBold
    btn.TextStrokeTransparency = 1; btn.AutoButtonColor = false; btn.ZIndex = 2; btn.Parent = holder
    ThemeSystem.Bind(btn, {BackgroundColor3 = "SurfaceLight"}); Corner(btn, 6)
    local st = Stroke(btn, "Border", 1, 0.5)
    
    ApplyHover(btn, {scale=1.0, stroke=st, hoverStrokeColor="Accent", hoverStrokeTransp=0.2, baseStrokeColor="Border"})
    ApplyPress(btn, {pressScale=0.95, hoverScale=1.0})
    
    BindSystem.RegisterButton(actionId, btn)
    TrackConnection(btn.MouseButton1Click:Connect(function()
        local last = BindSystem._lastCompleted
        if last.actionId == actionId and (os.clock() - last.at) < 0.25 then return end
        if BindSystem.Capture and BindSystem.Capture.actionId == actionId then BindSystem.CaptureCancel(); return end
        if BindSystem.Capture then BindSystem.CaptureCancel() end
        BindSystem.CaptureStart(actionId, btn)
    end))
    TrackConnection(btn.MouseButton2Click:Connect(function()
        BindSystem.Clear(actionId); Notify.Push("BIND", "Bind cleared", "info", 1.5)
    end))
    return btn, holder
end

--============================================================
-- WINDOW
--============================================================
local Window = {}
Window.__index = Window
local CONST = { HEADER_H = 56, TAB_H = 46, PAD = 14, MIN_W = 480, MIN_H = 380, PANEL_W = 180 }

function Window.new(opts)
    CleanupOldUIs()
    PreloadAssets()
    opts = opts or {}; local self = setmetatable({}, Window)
    self.Title = opts.Title or "Window"; self.Version = opts.Version or SCRIPT_VERSION
    self.Width = opts.Size and opts.Size.X.Offset or 720
    self.Height = opts.Size and opts.Size.Y.Offset or 580
    self.Tabs = {}; self.ActiveTab = nil; self.IsVisible = false
    self.ThemeDots = {}
    self.ThemeMenuOpen = false; self.CaptureHotkeys = {}
    self.OnClose = opts.OnClose; self.ConfigPath = opts.ConfigPath
    self._SavedPos = nil
    self._isDestroying = false
    self._destroyed = false
    self._animToken = 0
    self._lastToggleTime = 0
    self._PanelSlideDir = 1; self._PanelTargetPos = nil; self._PanelTargetSize = nil
    self.FloatingWindows = {}
    self:_Build()
    if self.ConfigPath then self:_LoadConfig() end
    if opts.Theme and Themes[opts.Theme] then ThemeSystem.Apply(opts.Theme, true) end
    self:Show()
    return self
end

function Window:_Build()
    local W, H = self.Width, self.Height
    local HEADER_H, TAB_H, PAD = CONST.HEADER_H, CONST.TAB_H, CONST.PAD
    
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = UI_NAME .. "_" .. self.Title
    self.ScreenGui.ResetOnSpawn = false; self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    do
        local ok, hui = pcall(function() return gethui and gethui() end)
        self.ScreenGui.Parent = (ok and hui) or CoreGui
    end
    
    TrackConnection(self.ScreenGui.Destroying:Connect(function()
        if self._destroyed then return end
        self._destroyed = true; self._isDestroying = true
        if self.ConfigPath then pcall(function() self:SaveConfig() end) end
        if self._ThemeUnsub then pcall(self._ThemeUnsub); self._ThemeUnsub = nil end
        Disposer:dispose()
    end))
    
    -- LAUNCHER ICON
    self.LauncherIcon = Instance.new("TextButton")
    self.LauncherIcon.Name = "LauncherIcon"; self.LauncherIcon.Size = UDim2.fromOffset(54, 54)
    self.LauncherIcon.Position = UDim2.fromOffset(16, 16); self.LauncherIcon.BackgroundColor3 = Theme.BgMain
    self.LauncherIcon.Text = "N"; self.LauncherIcon.TextColor3 = Theme.TextBright; self.LauncherIcon.TextSize = 26
    self.LauncherIcon.Font = Enum.Font.GothamBlack; self.LauncherIcon.AutoButtonColor = false; self.LauncherIcon.ZIndex = 2
    self.LauncherIcon.TextStrokeTransparency = 1; self.LauncherIcon.ClipsDescendants = false; self.LauncherIcon.Parent = self.ScreenGui
    ThemeSystem.Bind(self.LauncherIcon, {BackgroundColor3 = "BgMain", TextColor3 = "TextBright"})
    Corner(self.LauncherIcon, 16)
    
    local launcherGrad = Instance.new("UIGradient")
    launcherGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(0.5, Theme.AccentHover),
        ColorSequenceKeypoint.new(1, Theme.AccentDark)
    })
    launcherGrad.Rotation = 135; launcherGrad.Parent = self.LauncherIcon
    
    local lst = Stroke(self.LauncherIcon, "AccentSoft", 1.5, 0.2)
    task.spawn(function()
        while self.LauncherIcon and self.LauncherIcon.Parent do
            Tween(lst, {Transparency = 0.0}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut); task.wait(1.5)
            Tween(lst, {Transparency = 0.6}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut); task.wait(1.5)
        end
    end)
    ApplyHover(self.LauncherIcon, {scale=1.05, stroke=lst, hoverStrokeColor="AccentSoft", hoverStrokeTransp=0.0, baseStrokeColor="AccentSoft"})
    ApplyPress(self.LauncherIcon, {pressScale=0.92, hoverScale=1.05})

    -- MainFrame
    self.MainFrame = MakeFrame(self.ScreenGui, {
        Name = "MainFrame", Size = UDim2.fromOffset(W, H), Position = UDim2.fromOffset(100, 100),
        BackgroundTheme = "BgMain", BackgroundTransparency = 0.15, ClipsDescendants = true, Active = true, ZIndex = 5, Visible = false,
    })
    Corner(self.MainFrame, 18); Stroke(self.MainFrame, "BorderLight", 1.2, 0.4)
    AddShadow(self.MainFrame, {themeKey = "Accent", transparency = 0.75, blur = 45, offset = Vector2.new(0, 12)})

    -- TopBar
    self.TopBar = MakeFrame(self.MainFrame, {
        Name = "TopBar", Size = UDim2.new(1, -20, 0, HEADER_H + TAB_H), Position = UDim2.fromOffset(10, 10),
        BackgroundTheme = "BgDarkest", BackgroundTransparency = 0.1, ZIndex = 4,
    })
    Corner(self.TopBar, 16); Stroke(self.TopBar, "Border", 1, 0.6); Gradient(self.TopBar, "BgSidebar", "BgMain", 90)
    self.Header = MakeFrame(self.TopBar, { Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundTransparency = 1, ZIndex = 5 })

    -- Profile
    local profile = MakeFrame(self.Header, {
        Size = UDim2.new(1, -120, 0, 44), Position = UDim2.new(0, 6, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5), BackgroundTheme = "SurfaceElevated", BackgroundTransparency = 0.1, ZIndex = 6,
    })
    Corner(profile, 22); Stroke(profile, "BorderLight", 1.4, 0.4); Gradient(profile, "SurfaceElevated", "SurfaceBase", 45)
    
    local avatarHolder = MakeFrame(profile, {
        Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(6, 5), BackgroundTheme = "BgDarkest", ZIndex = 7,
    })
    Corner(avatarHolder, 17); Stroke(avatarHolder, "AccentSoft", 1.5, 0.2)
    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(1, 0, 1, 0); avatarImg.BackgroundTransparency = 1
    avatarImg.Image = GetPlayerThumb(LocalPlayer.UserId, 150); avatarImg.ZIndex = 8; avatarImg.Parent = avatarHolder; Corner(avatarImg, 17)
    
    local displayName = LocalPlayer.DisplayName or LocalPlayer.Name
    self._TitleLabel = MakeLabel(profile, {
        Size = UDim2.new(1, -100, 0, 16), Position = UDim2.fromOffset(48, 6),
        Text = self.Title, TextSize = 13, Font = Enum.Font.GothamBold, TextTheme = "AccentSoft", ZIndex = 8,
    })
    MakeLabel(profile, {
        Size = UDim2.new(1, -100, 0, 14), Position = UDim2.fromOffset(48, 23),
        Text = string.format("@%s · %s", LocalPlayer.Name, displayName),
        TextTheme = "TextBright", TextSize = 10, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 8,
    })
    
    local verBadge = MakeFrame(profile, {
        Size = UDim2.fromOffset(40, 18), Position = UDim2.new(1, -48, 0.5, -9), BackgroundTheme = "AccentDark", BackgroundTransparency = 0.2, ZIndex = 7,
    })
    Corner(verBadge, 9); Stroke(verBadge, "AccentSoft", 1, 0.3)
    MakeLabel(verBadge, { Text = "v" .. self.Version, TextTheme = "TextBright", TextSize = 9, Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 8 })

    -- Controls
    local controls = MakeFrame(self.Header, {
        Size = UDim2.fromOffset(0, 28), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), BackgroundTransparency = 1, ZIndex = 10,
    })
    controls.AutomaticSize = Enum.AutomaticSize.X
    CreateInstance("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = controls })
    local gearBtn = Instance.new("TextButton")
    gearBtn.Name = "GearBtn"; gearBtn.Size = UDim2.fromOffset(28, 28); gearBtn.BackgroundColor3 = Theme.SurfaceLight; gearBtn.BackgroundTransparency = 0.4
    gearBtn.BorderSizePixel = 0; gearBtn.Text = "⚙"; gearBtn.TextColor3 = Theme.Text; gearBtn.TextSize = 14; gearBtn.Font = Enum.Font.GothamBold
    gearBtn.TextStrokeTransparency = 1; gearBtn.AutoButtonColor = false; gearBtn.ZIndex = 11; gearBtn.LayoutOrder = 1; gearBtn.Parent = controls
    ThemeSystem.Bind(gearBtn, {BackgroundColor3 = "SurfaceLight", TextColor3 = "Text"}); Corner(gearBtn, 14)
    local gearSt = Stroke(gearBtn, "Border", 1, 0.5)
    ApplyHover(gearBtn, { scale = 1.1, stroke = gearSt, hoverStrokeColor = "Accent", hoverStrokeTransp = 0.2, baseStrokeColor = "Border" })
    ApplyPress(gearBtn, {pressScale = 0.9})
    self._GearBtn = gearBtn
    
    local lights = MakeFrame(controls, { Size = UDim2.fromOffset(34, 14), BackgroundTransparency = 1, ZIndex = 11, LayoutOrder = 2 })
    CreateInstance("UIListLayout", { Padding = UDim.new(0, 6), FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = lights })
    local function light(color, sym, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(12, 12); b.BackgroundColor3 = color; b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false; b.Parent = lights; Corner(b, 6); Stroke(b, Color3.new(0, 0, 0), 1, 0.8)
        local inner = MakeLabel(b, { Text = "", TextColor3 = Color3.fromRGB(30, 20, 20), TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1 })
        local us = Instance.new("UIScale"); us.Scale = 1; us.Parent = b
        TrackConnection(b.MouseEnter:Connect(function() Spring(us, {Scale = 1.2}); inner.Text = sym; Tween(inner, {TextTransparency = 0.15}, 0.12) end))
        TrackConnection(b.MouseLeave:Connect(function() Tween(us, {Scale = 1}, 0.12); Tween(inner, {TextTransparency = 1}, 0.12) end))
        TrackConnection(b.MouseButton1Click:Connect(cb))
    end
    light(Theme.Warning, "—", function() self:Hide() end)
    light(Theme.Danger, "×", function()
        self:Hide()
        task.delay(0.35, function()
            if not self.IsVisible then
                if self.OnClose then pcall(self.OnClose) end
                self:Destroy()
            end
        end)
    end)

    -- Tab bar
    self.TabBar = MakeFrame(self.TopBar, { Name = "TabBar", Size = UDim2.new(1, 0, 0, TAB_H), Position = UDim2.fromOffset(0, HEADER_H), BackgroundTransparency = 1, ZIndex = 5 })
    Pad(self.TabBar, 6, 10, 6, 10)
    self.TabContainer = MakeFrame(self.TabBar, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6 })
    CreateInstance("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.TabContainer })

    -- Content
    local contentTop = 10 + HEADER_H + TAB_H + PAD
    self.ContentCanvas = Instance.new("CanvasGroup")
    self.ContentCanvas.Name = "ContentCanvas"; self.ContentCanvas.Size = UDim2.new(1, -(PAD * 2), 1, -(contentTop + PAD))
    self.ContentCanvas.Position = UDim2.fromOffset(PAD, contentTop); self.ContentCanvas.BackgroundTransparency = 1; self.ContentCanvas.GroupTransparency = 0; self.ContentCanvas.Parent = self.MainFrame
    self.Content = Instance.new("ScrollingFrame")
    self.Content.Name = "Content"; self.Content.Size = UDim2.fromScale(1, 1); self.Content.Position = UDim2.fromOffset(0, 0)
    self.Content.BackgroundTransparency = 1; self.Content.BorderSizePixel = 0; self.Content.ScrollBarThickness = 0
    self.Content.AutomaticCanvasSize = Enum.AutomaticSize.Y; self.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.Content.ElasticBehavior = Enum.ElasticBehavior.Never; self.Content.ScrollingDirection = Enum.ScrollingDirection.Y; self.Content.Parent = self.ContentCanvas

    -- Scrollbar
    local SB_W = 4
    self.ScrollTrack = MakeFrame(self.MainFrame, { Name = "ScrollBarTrack", Size = UDim2.new(0, SB_W, 1, -(contentTop + PAD)), Position = UDim2.new(1, -12, 0, contentTop), BackgroundTheme = "BgDarkest", BackgroundTransparency = 0.5, ZIndex = 10, Visible = false })
    Corner(self.ScrollTrack, SB_W / 2)
    self.ScrollThumb = MakeFrame(self.ScrollTrack, { Name = "ScrollBarThumb", Size = UDim2.new(1, 0, 0.2, 0), BackgroundTheme = "Accent", BackgroundTransparency = 0.2, ZIndex = 11 })
    Corner(self.ScrollThumb, SB_W / 2)
    local scrollToken = 0
    local function showScroll()
        self.ScrollTrack.Visible = true; scrollToken = scrollToken + 1; local tok = scrollToken
        Tween(self.ScrollTrack, {BackgroundTransparency = 0.5}, 0.1); Tween(self.ScrollThumb, {BackgroundTransparency = 0.2}, 0.1)
        task.delay(2, function() if tok == scrollToken and self.ScrollTrack.Visible then Tween(self.ScrollTrack, {BackgroundTransparency = 0.85}, 0.3); Tween(self.ScrollThumb, {BackgroundTransparency = 0.65}, 0.3) end end)
    end
    local queued = false
    local function updateScroll()
        if queued then return end; queued = true
        task.defer(function()
            queued = false
            if not self.Content.ScrollingEnabled then self.ScrollTrack.Visible = false; return end
            local vH = self.Content.AbsoluteSize.Y; local cH = self.Content.CanvasSize.Y.Offset
            if cH <= vH or cH == 0 or vH == 0 then self.ScrollTrack.Visible = false; return end
            local tH = math.max(0.08, vH / cH); local maxS = cH - vH
            self.ScrollThumb.Size = UDim2.new(1, 0, tH, 0)
            local pos = maxS > 0 and math.clamp(self.Content.CanvasPosition.Y / maxS, 0, 1) * (1 - tH) or 0
            self.ScrollThumb.Position = UDim2.new(0, 0, pos, 0); showScroll()
        end)
    end
    TrackConnection(self.Content:GetPropertyChangedSignal("CanvasPosition"):Connect(updateScroll))
    TrackConnection(self.Content:GetPropertyChangedSignal("CanvasSize"):Connect(updateScroll))
    TrackConnection(self.Content:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScroll))

    self:_MakeResizeHandle()
    self:_MakeWindowDrag()
    MakeDraggableClickable(self.LauncherIcon, function() if self.IsVisible then self:Hide() else self:Show() end end)
    self:_BuildSettingsPanel()
    self:_HookInput()
    local unsubTheme = ThemeSystem.Subscribe(function()
        if self.ScreenGui and self.ScreenGui.Parent and self.RefreshThemeDots then
            pcall(function() self:RefreshThemeDots() end)
        end
    end)
    self._ThemeUnsub = unsubTheme
    TrackConnection(self.ScreenGui.Destroying:Connect(unsubTheme))
end

function Window:_MakeResizeHandle()
    local handle = Instance.new("TextButton")
    handle.Name = "ResizeHandle"; handle.Size = UDim2.fromOffset(24, 24); handle.Position = UDim2.new(1, -20, 1, -20)
    handle.BackgroundTransparency = 1; handle.Text = ""; handle.AutoButtonColor = false; handle.ZIndex = 20; handle.Parent = self.MainFrame
    local dots = {}
    for i, d in ipairs({{-4, -16}, {-10, -10}, {-16, -4}}) do
        local dot = MakeFrame(handle, { Size = UDim2.fromOffset(3, 3), Position = UDim2.new(1, d[1], 1, d[2]), BackgroundTheme = "TextMuted", BackgroundTransparency = 0.4, ZIndex = 21 })
        Corner(dot, 1.5); dots[i] = dot
    end
    local function setHover(h) for _, dot in ipairs(dots) do Tween(dot, {BackgroundTransparency = h and 0.1 or 0.4, BackgroundColor3 = h and Theme.Accent or Theme.TextMuted}, 0.15) end end
    TrackConnection(handle.MouseEnter:Connect(function() setHover(true) end))
    TrackConnection(handle.MouseLeave:Connect(function() setHover(false) end))
    TrackConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local startSize = Vector2.new(self.Width, self.Height)
        local startPos  = Vector2.new(input.Position.X, input.Position.Y)
        local absPos = self.MainFrame.AbsolutePosition
        local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
        SetInteraction({
            onMove = function(inp)
                local dx = inp.Position.X - startPos.X; local dy = inp.Position.Y - startPos.Y
                local maxW = math.max(CONST.MIN_W, vp.X - absPos.X - 8); local maxH = math.max(CONST.MIN_H, vp.Y - absPos.Y - 8)
                self:_ApplySize(math.clamp(startSize.X + dx, CONST.MIN_W, maxW), math.clamp(startSize.Y + dy, CONST.MIN_H, maxH))
            end,
            onEnd = function() if self.ConfigPath then self:SaveConfig() end end,
        })
    end))
end
function Window:_ApplySize(w, h)
    self.Width = w; self.Height = h
    self.MainFrame.Size = UDim2.fromOffset(w, h)
    if self.ThemeMenuOpen then self:_PositionSettingsPanel(true) end
end
function Window:_MakeWindowDrag()
    TrackConnection(self.MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if UserInputService:GetFocusedTextBox() then return end
        local startPos = self.MainFrame.AbsolutePosition
        local dragStart = Vector2.new(input.Position.X, input.Position.Y)
        local size = self.MainFrame.AbsoluteSize
        local moved = false
        SetInteraction({
            onMove = function(inp)
                local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
                if math.abs(delta.X) < 4 and math.abs(delta.Y) < 4 then return end
                moved = true
                local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
                self.MainFrame.Position = UDim2.fromOffset(math.clamp(startPos.X + delta.X, 8, math.max(8, vp.X - size.X - 8)), math.clamp(startPos.Y + delta.Y, 8, math.max(8, vp.Y - size.Y - 8)))
                if self.ThemeMenuOpen then self:_PositionSettingsPanel(true) end
            end,
            onEnd = function()
                if moved then
                    self._SavedPos = UDim2.fromOffset(
                        math.floor(self.MainFrame.Position.X.Offset),
                        math.floor(self.MainFrame.Position.Y.Offset)
                    )
                    if self.ConfigPath then self:SaveConfig() end
                end
            end,
        })
    end))
end

function Window:_BuildSettingsPanel()
    local panelW = CONST.PANEL_W
    local panel = MakeFrame(self.ScreenGui, { 
        Name = "SettingsPanel", Size = UDim2.fromOffset(panelW, self.Height), Position = UDim2.fromOffset(-500, -500), 
        BackgroundTheme = "BgMain", BackgroundTransparency = 0.15, Visible = false, ZIndex = 40 
    })
    Corner(panel, 18); Stroke(panel, "BorderLight", 1.2, 0.4); Gradient(panel, "BgSidebar", "BgMain", 90)
    AddShadow(panel, {themeKey = "BgDarkest", transparency = 0.5, blur = 30, offset = Vector2.new(0, 8)})
    
    local titleBar = MakeFrame(panel, { Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 41 })
    MakeLabel(titleBar, { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 2), Text = "Appearance", TextTheme = "TextBright", TextSize = 11, Font = Enum.Font.GothamBold, ZIndex = 42 })
    MakeFrame(panel, { Size = UDim2.new(1, -20, 0, 1), Position = UDim2.fromOffset(10, 42), BackgroundTheme = "Border", BackgroundTransparency = 0.5, ZIndex = 41 })
    
    local listScroll = Instance.new("ScrollingFrame")
    listScroll.Name = "ThemeList"; listScroll.Size = UDim2.new(1, -20, 1, -56); listScroll.Position = UDim2.fromOffset(10, 48)
    listScroll.BackgroundTransparency = 1; listScroll.BorderSizePixel = 0; listScroll.ScrollBarThickness = 2
    listScroll.ScrollBarImageColor3 = Theme.Border; listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0); listScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    listScroll.ElasticBehavior = Enum.ElasticBehavior.Never; listScroll.ZIndex = 41; listScroll.Parent = panel
    CreateInstance("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listScroll })
    
    for i, name in ipairs(ThemeOrder) do
        local td = Themes[name]
        local btn = Instance.new("TextButton")
        -- ⚡ FIX: Отступы 6px слева/справа, чтобы обводка не обрезалась
        btn.Size = UDim2.new(1, -12, 0, 30); btn.Position = UDim2.fromOffset(6, 0)
        btn.BackgroundColor3 = Theme.SurfaceBase; btn.BackgroundTransparency = 0.4; btn.BorderSizePixel = 0; btn.Text = ""; btn.AutoButtonColor = false; btn.LayoutOrder = i; btn.ZIndex = 42; btn.Parent = listScroll
        Corner(btn, 6); local st = Stroke(btn, "Border", 1, 0.7)
        local inner = MakeFrame(btn, { Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, ZIndex = 43 })
        CreateInstance("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })
        local dot = Instance.new("Frame"); dot.Size = UDim2.fromOffset(14, 14); dot.BackgroundColor3 = td.Accent; dot.BorderSizePixel = 0; dot.LayoutOrder = 1; dot.Parent = inner
        Corner(dot, 7); local dotStroke = Instance.new("UIStroke"); dotStroke.Color = td.AccentGlow; dotStroke.Thickness = 1.2; dotStroke.Transparency = 0.2; dotStroke.Parent = dot
        local dotScale = Instance.new("UIScale"); dotScale.Scale = 1; dotScale.Parent = dot
        MakeLabel(inner, { Size = UDim2.new(0, 0, 0, 12), AutomaticSize = Enum.AutomaticSize.X, Text = td.name, TextTheme = "TextDim", TextSize = 10, Font = Enum.Font.GothamBold, LayoutOrder = 2, ZIndex = 43 })
        self.ThemeDots[name] = {btn = btn, stroke = st, dot = dot, dotScale = dotScale}
        TrackConnection(btn.MouseEnter:Connect(function() if name ~= CurrentThemeName and self.ThemeMenuOpen then Tween(btn, {BackgroundColor3 = Theme.SurfaceLight, BackgroundTransparency = 0.2}, 0.15) end; Spring(dotScale, {Scale = 1.15}) end))
        TrackConnection(btn.MouseLeave:Connect(function() if name ~= CurrentThemeName then Tween(btn, {BackgroundColor3 = Theme.SurfaceBase, BackgroundTransparency = 0.4}, 0.15) end; Tween(dotScale, {Scale = 1}, 0.15) end))
        TrackConnection(btn.MouseButton1Click:Connect(function() if self.ThemeMenuOpen then self:SetTheme(name); self:_CloseSettings() end end))
    end
    self.SettingsPanel = panel
    TrackConnection(self._GearBtn.MouseButton1Click:Connect(function() if self.ThemeMenuOpen then self:_CloseSettings() else self:_OpenSettings() end end))
end

function Window:RefreshThemeDots()
    if not self.ThemeDots then return end
    for name, data in pairs(self.ThemeDots) do
        local isActive = (name == CurrentThemeName)
        Tween(data.btn, {BackgroundColor3 = isActive and Theme.AccentDark or Theme.SurfaceBase}, 0.2)
        data.stroke.Color = isActive and Theme.Accent or Theme.Border
        data.stroke.Transparency = isActive and 0.2 or 0.7
        if data.dotScale then Tween(data.dotScale, {Scale = isActive and 1.12 or 1}, 0.2) end
    end
end

function Window:_PositionSettingsPanel(silent)
    if not self.SettingsPanel then return end
    local mPos = self.MainFrame.Position
    local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
    local panelW = CONST.PANEL_W; local gap = 10; local mW, mH = self.Width, self.Height
    local xRight = mPos.X.Offset + mW + gap; local xLeft = mPos.X.Offset - panelW - gap
    local slideDir, targetX
    if xRight + panelW <= vp.X - 8 then targetX = xRight; slideDir = 1
    elseif xLeft >= 8 then targetX = xLeft; slideDir = -1
    else targetX = math.clamp(xRight, 8, math.max(8, vp.X - panelW - 8)); slideDir = 1 end
    local targetY = math.clamp(mPos.Y.Offset, 8, math.max(8, vp.Y - mH - 8))
    self._PanelSlideDir = slideDir; self._PanelTargetPos = UDim2.fromOffset(targetX, targetY); self._PanelTargetSize = UDim2.fromOffset(panelW, math.max(mH, 240))
    if silent and self.SettingsPanel.Visible then self.SettingsPanel.Position = self._PanelTargetPos; self.SettingsPanel.Size = self._PanelTargetSize end
end

function Window:_OpenSettings()
    if self.ThemeMenuOpen then return end
    self.ThemeMenuOpen = true; self:RefreshThemeDots(); self:_PositionSettingsPanel(false)
    local p = self.SettingsPanel; local target = self._PanelTargetPos; local dir = self._PanelSlideDir or 1
    p.Size = self._PanelTargetSize; p.Position = UDim2.fromOffset(target.X.Offset + 20 * dir, target.Y.Offset); p.Visible = true
    local uiScale = EnsureUIScale(p); uiScale.Scale = 0.95
    TweenManager.Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = target})
    TweenManager.Create(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 1})
end
function Window:_CloseSettings(instant)
    if not self.ThemeMenuOpen then return end
    self.ThemeMenuOpen = false
    local p = self.SettingsPanel
    if instant then p.Visible = false; return end
    local target = self._PanelTargetPos or p.Position; local dir = self._PanelSlideDir or 1
    local uiScale = EnsureUIScale(p)
    Tween(p, {Position = UDim2.fromOffset(target.X.Offset + 20 * dir, target.Y.Offset)}, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    Tween(uiScale, {Scale = 0.95}, 0.25)
    task.delay(0.26, function() if not self.ThemeMenuOpen and p then p.Visible = false end end)
end

function Window:_HookInput()
    TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not self.ThemeMenuOpen then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos = input.Position
        local function inB(inst)
            if not inst then return false end
            local ap, as = inst.AbsolutePosition, inst.AbsoluteSize
            return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
        end
        if inB(self.SettingsPanel) or inB(self._GearBtn) then return end
        self:_CloseSettings()
    end))

    TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
        if BindSystem.Capture then
            local cap = BindSystem.Capture
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then BindSystem.CaptureCancel(); Notify.Push("BIND", "Bind cancelled", "info", 1.5); return end
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Backspace then local id = cap.actionId; BindSystem.CaptureCancel(); BindSystem.Clear(id); Notify.Push("BIND", "Bind cleared", "info", 1.5); return end
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then Notify.Push("BIND", "Space is reserved", "warning", 1.5); return end
            local binding = BindSystem.InputToBinding(input); if binding then BindSystem.CaptureComplete(binding) end
            return
        end
        if UserInputService:GetFocusedTextBox() then return end
        
        for actionId, binding in pairs(BindSystem.Bindings) do
            if BindSystem.MatchBinding(binding, input) then
                local wasHeld = BindSystem.Held[actionId]
                if binding.type ~= "wheel" then BindSystem.Held[actionId] = true end
                if actionId == "UI" then
                    local now = os.clock()
                    local db = (binding.type == "wheel") and 0.3 or 0.1
                    local canFire = (binding.type == "wheel") or (not wasHeld)
                    if canFire and now - self._lastToggleTime > db then
                        self._lastToggleTime = now
                        self:Toggle()
                    end
                else
                    if not gpe then
                        local cbs = self.CaptureHotkeys[actionId]
                        if cbs then for _, fn in ipairs(cbs) do pcall(fn) end end
                    end
                end
            end
        end
    end))
    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        for actionId, binding in pairs(BindSystem.Bindings) do
            if BindSystem.MatchBinding(binding, input) then BindSystem.Held[actionId] = nil end
        end
    end))
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if not CurrentInteraction then return end
        if not (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then return end
        CurrentInteraction.onMove(input)
    end))
    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if not CurrentInteraction then return end
        if not (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then return end
        local h = CurrentInteraction.onEnd; CurrentInteraction = nil; if h then h() end
    end))
end

function Window:OnHotkey(actionId, cb)
    if type(cb) ~= "function" then return end
    if not self.CaptureHotkeys[actionId] then self.CaptureHotkeys[actionId] = {} end
    table.insert(self.CaptureHotkeys[actionId], cb)
end

function Window:_ComputeCenterPos()
    local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
    local x = math.max(20, math.floor((vp.X - self.Width) / 2)); local y = math.max(20, math.floor((vp.Y - self.Height) / 2))
    return UDim2.fromOffset(x, y)
end

function Window:Show()
    if self.IsVisible or self._isDestroying or self._destroyed then return end
    self.IsVisible = true
    self._animToken = (self._animToken or 0) + 1
    local targetPos = self._SavedPos or self:_ComputeCenterPos()
    self._SavedPos = targetPos
    TweenManager.Cancel(self.MainFrame)
    local uiScale = EnsureUIScale(self.MainFrame)
    TweenManager.Cancel(uiScale)
    self.MainFrame.Visible = true
    self.MainFrame.Position = targetPos + UDim2.fromOffset(0, 15)
    self.MainFrame.Rotation = -2
    self.MainFrame.BackgroundTransparency = 1
    uiScale.Scale = 0.92
    if self.ContentCanvas then self.ContentCanvas.GroupTransparency = 1 end
    local posTween = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local scaleTween = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenManager.Create(self.MainFrame, posTween, {Position = targetPos, Rotation = 0, BackgroundTransparency = 0.15})
    TweenManager.Create(uiScale, scaleTween, {Scale = 1})
    if self.ContentCanvas then TweenManager.Create(self.ContentCanvas, posTween, {GroupTransparency = 0}) end
end

function Window:Hide()
    if not self.IsVisible or self._isDestroying or self._destroyed then return end
    self.IsVisible = false
    self._animToken = (self._animToken or 0) + 1
    local token = self._animToken
    self._SavedPos = UDim2.fromOffset(
        math.floor(self.MainFrame.Position.X.Offset),
        math.floor(self.MainFrame.Position.Y.Offset)
    )
    TweenManager.Cancel(self.MainFrame)
    local uiScale = EnsureUIScale(self.MainFrame)
    TweenManager.Cancel(uiScale)
    local posTween = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    local scaleTween = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    TweenManager.Create(self.MainFrame, posTween, {Position = self._SavedPos + UDim2.fromOffset(0, 15), Rotation = 2, BackgroundTransparency = 1})
    TweenManager.Create(uiScale, scaleTween, {Scale = 0.92})
    if self.ContentCanvas then TweenManager.Create(self.ContentCanvas, posTween, {GroupTransparency = 1}) end
    task.delay(0.32, function()
        if self._animToken == token and not self.IsVisible and not self._isDestroying and not self._destroyed then
            self.MainFrame.Visible = false
            self.MainFrame.Rotation = 0
            self.MainFrame.Position = self._SavedPos
            self.MainFrame.BackgroundTransparency = 0.15
            uiScale.Scale = 1
        end
    end)
    if BindSystem.Capture then BindSystem.CaptureCancel() end
    if self.ConfigPath then self:SaveConfig() end
end

function Window:Toggle()
    if self._isDestroying or self._destroyed then return end
    if self.IsVisible then self:Hide() else self:Show() end
end

function Window:Notify(...) Notify.Push(...) end
function Window:SetTitle(text) self.Title = text; if self._TitleLabel then self._TitleLabel.Text = text end end
function Window:SetTheme(name) if not Themes[name] then return end; ThemeSystem.Apply(name); self:RefreshThemeDots(); if self.ConfigPath then self:SaveConfig() end end
function Window:SetNotificationsEnabled(v) Notify.enabled = v end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true; self._isDestroying = true; self.IsVisible = false
    if self.ConfigPath then pcall(function() self:SaveConfig() end) end
    if self._ThemeUnsub then pcall(self._ThemeUnsub); self._ThemeUnsub = nil end
    Disposer:dispose()
    if self.MainFrame then
        TweenManager.Cancel(self.MainFrame)
        local us = self.MainFrame:FindFirstChildOfClass("UIScale")
        if us then TweenManager.Cancel(us) end
    end
    if self.ScreenGui and self.ScreenGui.Parent then pcall(function() self.ScreenGui:Destroy() end) end
    if Notify.container then
        local parent = Notify.container.Parent
        if parent and parent:IsA("ScreenGui") and #parent:GetChildren() <= 2 then
            pcall(function() parent:Destroy() end); Notify.container = nil
        end
    end
end

function Window:SetScale(scale)
    scale = math.clamp(scale, 0.5, 1.5)
    EnsureUIScale(self.MainFrame).Scale = scale
    EnsureUIScale(self.LauncherIcon).Scale = scale
    for _, fw in ipairs(self.FloatingWindows) do if fw and fw.Parent then EnsureUIScale(fw).Scale = scale end end
    if self.ConfigPath then self:SaveConfig() end
end
function Window:CreateFloatingWindow(opts)
    local name = opts.Name or "FloatWindow"
    local w, h = opts.Size and opts.Size.X.Offset or 200, opts.Size and opts.Size.Y.Offset or 150
    local pos = opts.Position or UDim2.fromOffset(100, 100)
    local frame = MakeFrame(self.ScreenGui, { Name = name, Size = UDim2.fromOffset(w, h), Position = pos, BackgroundTheme = "BgMain", BackgroundTransparency = 0.15, Active = true, Visible = opts.Visible ~= false })
    Corner(frame, 18); Stroke(frame, "BorderLight", 1, 0.5)
    AddShadow(frame, {themeKey="BgDarkest", transparency=0.5, blur=25, offset=Vector2.new(0, 6)})
    if opts.Draggable ~= false then MakeDraggableClickable(frame, function() end) end
    table.insert(self.FloatingWindows, frame)
    return {
        Instance = frame,
        SetVisible = function(_, v) frame.Visible = v end,
        SetScale = function(_, s) EnsureUIScale(frame).Scale = math.clamp(s, 0.5, 1.5) end
    }
end

function Window:CreateWatermark()
    local frame = self:CreateFloatingWindow({ Name = "Watermark", Size = UDim2.fromOffset(260, 148), Position = UDim2.fromOffset(16, 76), Visible = false }).Instance
    Corner(frame, 14); Stroke(frame, "BorderLight", 1.2, 0.5); Gradient(frame, "SurfaceBase", "BgDarkest", 135)
    AddShadow(frame, {transparency = 0.4, blur = 40, offset = Vector2.new(0, 12)})
    Pad(frame, 12, 14, 10, 14)
    local head = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1 })
    MakeLabel(head, { Size = UDim2.new(1, 0, 1, 0), Text = "NOCLIPOV", TextSize = 10, TextTheme = "Text", Font = Enum.Font.GothamBold })
    local div1 = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, 19), BackgroundTheme = "Border", BackgroundTransparency = 0.6 }); Gradient(div1, "BorderLight", "BgDarkest", 0)
    local hero = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 52), Position = UDim2.fromOffset(0, 25), BackgroundTransparency = 1 })
    local speedVal = MakeLabel(hero, { Size = UDim2.new(1, -50, 0, 34), Position = UDim2.fromOffset(0, 0), Text = "0.0", TextTheme = "TextBright", TextSize = 30, Font = Enum.Font.GothamBold })
    MakeLabel(hero, { Size = UDim2.fromOffset(50, 16), Position = UDim2.new(1, -50, 0, 10), Text = "U/S", TextTheme = "Accent", TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right })
    local subSpeedLbl = MakeLabel(hero, { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.fromOffset(0, 38), Text = "CURRENT SPEED", TextTheme = "TextMuted", TextSize = 8, Font = Enum.Font.GothamBold })
    local div2 = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, 79), BackgroundTheme = "Border", BackgroundTransparency = 0.6 }); Gradient(div2, "BorderLight", "BgDarkest", 0)
    local grid = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 85), BackgroundTransparency = 1 })
    local colW = 0.25
    local function MakeMiniStat(x, label)
        local col = MakeFrame(grid, { Size = UDim2.new(colW, -2, 1, 0), Position = UDim2.new(x + 0.002, 0, 0, 0), BackgroundTransparency = 1 })
        local v = MakeLabel(col, { Size = UDim2.new(1, 0, 0, 16), Text = "--", TextSize = 13, Font = Enum.Font.GothamBold, TextTheme = "Text" })
        MakeLabel(col, { Size = UDim2.new(1, 0, 0, 9), Position = UDim2.fromOffset(0, 17), Text = label, TextSize = 7, TextTheme = "TextMuted", Font = Enum.Font.GothamBold })
        return v
    end
    local fpsVal = MakeMiniStat(0, "FPS")
    local pingVal = MakeMiniStat(colW, "PING")
    local maxVal = MakeMiniStat(colW * 2, "MAX")
    local timeVal = MakeMiniStat(colW * 3, "TIME")
    local barBg = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundTheme = "BgMain", BackgroundTransparency = 0.3 })
    Corner(barBg, 1.5); Stroke(barBg, "Border", 1, 0.6)
    local barFill = MakeFrame(barBg, { Size = UDim2.new(0, 0, 1, 0), BackgroundTheme = "Accent" })
    Corner(barFill, 1.5); Gradient(barFill, "Accent", "AccentSoft", 0)
    return {
        Instance = frame, SpeedVal = speedVal, FpsVal = fpsVal, PingVal = pingVal,
        MaxVal = maxVal, TimeVal = timeVal, SpeedBarFill = barFill, SubSpeedLbl = subSpeedLbl,
    }
end

function Window:CreateRecorderStatus()
    local frame = self:CreateFloatingWindow({ Name = "RecorderStatus", Size = UDim2.fromOffset(280, 152), Position = UDim2.fromOffset(16, 232), Visible = false }).Instance
    Corner(frame, 14); Stroke(frame, "BorderLight", 1.2, 0.5); Gradient(frame, "SurfaceBase", "BgDarkest", 135)
    AddShadow(frame, {transparency = 0.4, blur = 40, offset = Vector2.new(0, 12)})
    Pad(frame, 12, 14, 12, 14)
    local header = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1 })
    MakeLabel(header, { Size = UDim2.new(1, -66, 1, 0), Text = "RECORDER", TextSize = 10, TextTheme = "Accent", Font = Enum.Font.GothamBold })
    local pill = MakeFrame(header, { Size = UDim2.fromOffset(60, 14), Position = UDim2.new(1, -60, 0, 0), BackgroundTheme = "SurfaceBase", BackgroundTransparency = 0.4, ZIndex = 2 })
    Corner(pill, 7); Stroke(pill, "Border", 1, 0.5)
    local pillDot = MakeFrame(pill, { Size = UDim2.fromOffset(5, 5), Position = UDim2.new(0, 7, 0.5, -2.5), BackgroundTheme = "TextMuted", ZIndex = 3 }); Corner(pillDot, 2.5)
    local pillLbl = MakeLabel(pill, { Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(16, 0), Text = "IDLE", TextSize = 8, Font = Enum.Font.GothamBold, TextTheme = "TextMuted" })
    local div1 = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, 19), BackgroundTheme = "Border", BackgroundTransparency = 0.6 }); Gradient(div1, "BorderLight", "BgDarkest", 0)
    local hero = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 48), Position = UDim2.fromOffset(0, 25), BackgroundTransparency = 1 })
    local durCol = MakeFrame(hero, { Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1 })
    local durVal = MakeLabel(durCol, { Size = UDim2.new(1, 0, 0, 30), Text = "--", TextSize = 26, Font = Enum.Font.GothamBold, TextTheme = "TextBright" })
    MakeLabel(durCol, { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.fromOffset(0, 32), Text = "DURATION", TextSize = 7, TextTheme = "TextMuted", Font = Enum.Font.GothamBold })
    local framesCol = MakeFrame(hero, { Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(0.5, 4, 0, 0), BackgroundTransparency = 1 })
    local framesVal = MakeLabel(framesCol, { Size = UDim2.new(1, 0, 0, 30), Text = "--", TextSize = 26, Font = Enum.Font.GothamBold, TextTheme = "TextBright", TextXAlignment = Enum.TextXAlignment.Right })
    MakeLabel(framesCol, { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.fromOffset(0, 32), Text = "FRAMES", TextSize = 7, TextTheme = "TextMuted", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right })
    local div2 = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, 77), BackgroundTheme = "Border", BackgroundTransparency = 0.6 }); Gradient(div2, "BorderLight", "BgDarkest", 0)
    local infoLbl = MakeLabel(frame, { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 83), Text = "Idle", TextTheme = "TextDim", TextSize = 12, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd })
    local subLbl = MakeLabel(frame, { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.fromOffset(0, 101), Text = "", TextTheme = "TextMuted", TextSize = 9, Font = Enum.Font.Gotham, TextTruncate = Enum.TextTruncate.AtEnd })
    local progBg = MakeFrame(frame, { Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundTheme = "BgMain", BackgroundTransparency = 0.3, Visible = false })
    Corner(progBg, 1.5); Stroke(progBg, "Border", 1, 0.6)
    local progFill = MakeFrame(progBg, { Size = UDim2.new(0, 0, 1, 0), BackgroundTheme = "Accent" })
    Corner(progFill, 1.5); Gradient(progFill, "Accent", "AccentSoft", 0)
    return {
        Instance = frame, Pill = pill, PillDot = pillDot, PillLbl = pillLbl,
        DurVal = durVal, FramesVal = framesVal, InfoLbl = infoLbl, SubLbl = subLbl,
        ProgBg = progBg, ProgFill = progFill,
    }
end

--============================================================
-- TAB
--============================================================
local Tab = {}
Tab.__index = Tab

function Window:Tab(name, icon, width)
    local idx = #self.Tabs + 1
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(width or 80, 34); btn.BackgroundColor3 = Theme.SurfaceBase
    btn.BackgroundTransparency = 1; btn.BorderSizePixel = 0; btn.Text = ""; btn.AutoButtonColor = false
    btn.LayoutOrder = idx; btn.Parent = self.TabContainer; btn.ZIndex = 2; Corner(btn, 8)
    local bg = MakeFrame(btn, { Size = UDim2.fromScale(1, 1), BackgroundTheme = "AccentDark", BackgroundTransparency = 1, ZIndex = 1 })
    Corner(bg, 8)
    local inner = MakeFrame(btn, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 })
    CreateInstance("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })
    local iconLbl = MakeLabel(inner, { Size = UDim2.fromOffset(16, 16), Text = icon or "", TextTheme = "TextMuted", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, LayoutOrder = 1, ZIndex = 3 })
    local lbl = MakeLabel(inner, { Size = UDim2.new(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X, Text = string.upper(name), TextTheme = "TextDim", TextSize = 10, Font = Enum.Font.GothamBold, LayoutOrder = 2, ZIndex = 3 })
    local page = MakeFrame(self.Content, { Name = name .. "Page", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false })
    page.AutomaticSize = Enum.AutomaticSize.Y
    CreateInstance("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
    Pad(page, 10, 10, 10, 10)
    local tabData = { Window = self, Btn = btn, Page = page, Lbl = lbl, IconLbl = iconLbl, Bg = bg, Inner = inner, Name = name, Index = idx }
    setmetatable(tabData, Tab); table.insert(self.Tabs, tabData)
    TrackConnection(btn.MouseButton1Click:Connect(function() self:_SwitchTab(idx) end))
    TrackConnection(btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabData then Tween(bg, {BackgroundTransparency = 0.85}, 0.2); Tween(lbl, {TextColor3 = Theme.Text}, 0.2); Tween(iconLbl, {TextColor3 = Theme.Text}, 0.2) end
    end))
    TrackConnection(btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabData then Tween(bg, {BackgroundTransparency = 1}, 0.2); Tween(lbl, {TextColor3 = Theme.TextDim}, 0.2); Tween(iconLbl, {TextColor3 = Theme.TextMuted}, 0.2) end
    end))
    if #self.Tabs == 1 then self:_SwitchTab(idx) end
    return tabData
end

function Window:_SwitchTab(idx)
    local tab = self.Tabs[idx]
    if not tab or self.ActiveTab == tab then return end
    if self.ActiveTab then
        Tween(self.ActiveTab.Bg, {BackgroundTransparency = 1}, 0.25)
        Tween(self.ActiveTab.Lbl, {TextColor3 = Theme.TextDim}, 0.25)
        Tween(self.ActiveTab.IconLbl, {TextColor3 = Theme.TextMuted}, 0.25)
        self.ActiveTab.Page.Visible = false
    end
    tab.Page.Visible = true
    tab.Page.Position = UDim2.new(0, 0, 0, 12)
    if self.ContentCanvas then self.ContentCanvas.GroupTransparency = 0.5; Tween(self.ContentCanvas, {GroupTransparency = 0}, 0.25) end
    Tween(tab.Page, {Position = UDim2.fromOffset(0, 0)}, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    Tween(tab.Bg, {BackgroundTransparency = 0.72}, 0.25)
    Tween(tab.Lbl, {TextColor3 = Theme.TextBright}, 0.25)
    Tween(tab.IconLbl, {TextColor3 = Theme.Accent}, 0.25)
    local sc = EnsureUIScale(tab.Btn); sc.Scale = 0.9; Spring(sc, {Scale = 1})
    self.ActiveTab = tab
end

function Tab:Section(text)
    local holder = MakeFrame(self.Page, { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 })
    local bar = MakeFrame(holder, { Size = UDim2.fromOffset(3, 12), Position = UDim2.new(0, 4, 0.5, -6), BackgroundTheme = "Accent" })
    Corner(bar, 1.5)
    MakeLabel(holder, { Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(12, 0), Text = string.upper(text), TextTheme = "TextMuted", TextSize = 9, Font = Enum.Font.GothamBold })
end
function Tab:Label(text, opts)
    opts = opts or {}
    return MakeLabel(self.Page, { Size = UDim2.new(1, 0, 0, opts.height or 20), Text = text, TextTheme = opts.theme or "Text", TextSize = opts.size or 10, Font = opts.font or Enum.Font.Gotham, TextWrapped = true, TextXAlignment = opts.align or Enum.TextXAlignment.Left })
end

function Tab:Toggle(opts)
    local title = opts.Name or "Toggle"; local desc = opts.Description or ""
    local default = opts.Default or false; local icon = opts.Icon; local cb = opts.Callback; local window = self.Window
    local card = MakeFrame(self.Page, { Size = UDim2.new(1, 0, 0, 56), BackgroundTheme = "SurfaceBase", BackgroundTransparency = 0.5 })
    StyleCard(card, {radius = 10})
    local _, iconSt = MakeIconBadge(card, 28, UDim2.new(0, 14, 0.5, -14), icon)
    local textX = icon and 52 or 14; local textRight = 80
    MakeLabel(card, { Size = UDim2.new(1, -textRight, 0, 16), Position = UDim2.fromOffset(textX, 10), Text = title, TextSize = 12, TextTheme = "TextBright", Font = Enum.Font.GothamBold })
    MakeLabel(card, { Size = UDim2.new(1, -textRight, 0, 14), Position = UDim2.fromOffset(textX, 28), Text = desc, TextTheme = "TextDim", TextSize = 10, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.AtEnd })
    local setToggle, getToggle = MakeSwitch(card, default, function(v)
        if iconSt then Tween(iconSt, {Color = v and Theme.Accent or Theme.Border, Transparency = v and 0.4 or 0.6}, 0.22) end
        if cb then cb(v) end
    end, {width = 46, height = 24, knobSize = 18, padRight = 14})
    ToggleRefs[title] = setToggle
    local obj = { Instance = card, Set = function(_, v) setToggle(v, false) end, Get = function() return getToggle() end, Toggle = setToggle }
    setmetatable(obj, { __call = function(_, v) setToggle(v) end })
    local bindId = opts.Hotkey or opts.Bind or opts.ActionId
    if bindId then
        obj._bindId = bindId
        if opts.DefaultBind and not BindSystem.Bindings[bindId] then BindSystem.Set(bindId, {type = "key", value = opts.DefaultBind}, false) end
        window:OnHotkey(bindId, function()
            local newState = not getToggle()
            setToggle(newState, false)
            -- ⚡ NOTIFICATION FIX: Уведомление о смене состояния бинда
            Notify.Push(title, "Toggled " .. (newState and "ON" or "OFF"), newState and "success" or "info", 2)
        end)
    end
    return obj
end

function Tab:Slider(opts)
    local title = opts.Name or "Slider"; local desc = opts.Description or ""
    local min, max = opts.Min or 0, opts.Max or 100; local default = opts.Default or min
    local icon = opts.Icon; local decimals = opts.Decimals or 0; local cb = opts.Callback
    local card = MakeFrame(self.Page, { Size = UDim2.new(1, 0, 0, 72), BackgroundTheme = "SurfaceBase", BackgroundTransparency = 0.5 })
    local st = StyleCard(card, {radius = 10})
    MakeIconBadge(card, 28, UDim2.fromOffset(14, 10), icon)
    local textX = icon and 52 or 14; local textRight = 80
    MakeLabel(card, { Size = UDim2.new(1, -textRight, 0, 16), Position = UDim2.fromOffset(textX, 10), Text = title, TextSize = 12, TextTheme = "TextBright", Font = Enum.Font.GothamBold })
    MakeLabel(card, { Size = UDim2.new(1, -textRight, 0, 14), Position = UDim2.fromOffset(textX, 28), Text = desc, TextTheme = "TextDim", TextSize = 10, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.AtEnd })
    local setVal, getVal = MakeSlider(card, min, max, default, cb, { decimals = decimals, pillWidth = 50,
        onDragStart = function() Tween(st, {Color = Theme.Accent, Transparency = 0.4}, 0.15) end,
        onDragEnd   = function() Tween(st, {Color = Theme.Border, Transparency = 0.7}, 0.15) end,
    })
    SliderRefs[title] = setVal
    local obj = { Instance = card, Set = function(_, v) setVal(v, false) end, Get = function() return getVal() end, Setter = setVal }
    setmetatable(obj, { __call = function(_, v) setVal(v) end })
    return obj
end

function Tab:Button(opts)
    local title = opts.Name or "Button"; local desc = opts.Description or ""; local cb = opts.Callback or function() end
    local style = opts.Style or "Primary"
    local card = Instance.new("TextButton")
    -- ⚡ FIX: Отступы 8px слева/справа, чтобы тень и свечение не обрезались
    card.Size = UDim2.new(1, -16, 0, 48); card.Position = UDim2.fromOffset(8, 0); card.BackgroundTransparency = 0
    card.BorderSizePixel = 0; card.Text = ""; card.AutoButtonColor = false; card.Parent = self.Page
    card.TextStrokeTransparency = 1
    ThemeSystem.Bind(card, {BackgroundColor3 = "Accent"}); Corner(card, 10)
    
    local btnGrad = Instance.new("UIGradient")
    btnGrad.Rotation = 90; btnGrad.Parent = card
    
    local st = Stroke(card, "AccentSoft", 1.2, 0.2)
    AddShadow(card, {themeKey = "Accent", transparency = 0.5, blur = 25, offset = Vector2.new(0, 5)})
    
    local titleLbl = MakeLabel(card, { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 6), Text = title, TextColor3 = Color3.new(1,1,1), TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center })
    local descLbl = MakeLabel(card, { Size = UDim2.new(1, -20, 0, 14), Position = UDim2.fromOffset(10, 24), Text = desc, TextColor3 = Color3.new(1,1,1), TextTransparency = 0.3, TextSize = 9, Font = Enum.Font.GothamMedium, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center })
    
    local function updateStyle()
        if style == "Primary" then
            titleLbl.TextColor3 = Color3.new(1,1,1)
            descLbl.TextColor3 = Color3.new(1,1,1)
            btnGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.AccentSoft),
                ColorSequenceKeypoint.new(0.5, Theme.Accent),
                ColorSequenceKeypoint.new(1, Theme.AccentDark)
            })
            st.Color = Theme.AccentSoft
            st.Transparency = 0.2
        elseif style == "Secondary" then
            titleLbl.TextColor3 = Theme.Text
            descLbl.TextColor3 = Theme.TextDim
            btnGrad.Color = ColorSequence.new(Theme.SurfaceBase, Theme.BgDarkest)
            st.Color = Theme.Border
            st.Transparency = 0.4
        elseif style == "Danger" then
            titleLbl.TextColor3 = Color3.new(1,1,1)
            descLbl.TextColor3 = Color3.new(1,1,1)
            btnGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Danger:Lerp(Color3.new(1,1,1),0.2)),
                ColorSequenceKeypoint.new(1, Theme.Danger)
            })
            st.Color = Theme.Danger
            st.Transparency = 0.2
        end
    end
    
    updateStyle()
    local unsub = ThemeSystem.Subscribe(updateStyle)
    TrackConnection(card.Destroying:Connect(unsub))
    
    ApplyHover(card, {scale=1.015, stroke=st, hoverStrokeColor="TextBright", hoverStrokeTransp=0.1, baseStrokeColor=style == "Primary" and "AccentSoft" or "Border"})
    ApplyPress(card, {pressScale=0.98, hoverScale=1.015})
    
    TrackConnection(card.MouseButton1Click:Connect(function() local ok, err = pcall(cb); if not ok then warn("[UI] button error: " .. tostring(err)) end end))
    local obj = { Instance = card }; setmetatable(obj, { __call = function(_, ...) cb(...) end })
    return obj
end

function Tab:ButtonRow(opts)
    local buttons = opts.Buttons or {}
    if #buttons == 0 then return end
    local row = MakeFrame(self.Page, { Size = UDim2.new(1, 0, 0, opts.Height or 40), BackgroundTransparency = 1 })
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = row

    for i, data in ipairs(buttons) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/#buttons, -8, 1, 0)
        btn.BackgroundColor3 = Theme.BgDarkest
        btn.BackgroundTransparency = 0.4
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = i
        btn.Parent = row
        btn.TextStrokeTransparency = 1

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Thickness = 1
        stroke.Parent = btn

        local grad = Instance.new("UIGradient")
        grad.Rotation = 90
        grad.Parent = btn

        local style = data.Style or "Secondary"

        local lbl = MakeLabel(btn, {
            Size = UDim2.fromScale(1, 1),
            Text = string.upper(data.Name or "Button"),
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center
        })

        local function updateStyle()
            if style == "Primary" then
                btn.BackgroundTransparency = 0
                lbl.TextColor3 = Color3.new(1,1,1)
                grad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.AccentSoft),
                    ColorSequenceKeypoint.new(0.5, Theme.Accent),
                    ColorSequenceKeypoint.new(1, Theme.AccentDark)
                })
                stroke.Color = Theme.AccentSoft
                stroke.Transparency = 0.2
            elseif style == "Danger" then
                btn.BackgroundTransparency = 0
                lbl.TextColor3 = Color3.new(1,1,1)
                grad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.Danger:Lerp(Color3.new(1,1,1),0.2)),
                    ColorSequenceKeypoint.new(1, Theme.Danger)
                })
                stroke.Color = Theme.Danger
                stroke.Transparency = 0.2
            else -- Secondary
                btn.BackgroundTransparency = 0.4
                lbl.TextColor3 = Theme.Text
                grad.Color = ColorSequence.new(Theme.BgDarkest, Theme.BgMain)
                stroke.Color = Theme.BorderLight
                stroke.Transparency = 0.5
            end
        end

        updateStyle()
        local unsub = ThemeSystem.Subscribe(updateStyle)
        TrackConnection(btn.Destroying:Connect(unsub))

        ApplyHover(btn, {scale=1.015, stroke=stroke, hoverStrokeColor="TextBright", hoverStrokeTransp=0.1, baseStrokeColor=style == "Primary" and "AccentSoft" or "BorderLight"})
        ApplyPress(btn, {pressScale=0.98, hoverScale=1.015})

        TrackConnection(btn.MouseButton1Click:Connect(function()
            if data.Callback then pcall(data.Callback) end
        end))
    end
    return row
end

function Tab:Keybind(opts)
    local title = opts.Name or "Keybind"; local actionId = opts.ActionId or title
    local default = opts.Default; local desc = opts.Description or ""
    local height = (desc ~= "") and 56 or 42
    local card = MakeFrame(self.Page, { Size = UDim2.new(1, 0, 0, height), BackgroundTheme = "SurfaceBase", BackgroundTransparency = 0.5 })
    StyleCard(card, {radius = 10})
    if desc ~= "" then
        MakeLabel(card, { Size = UDim2.new(1, -100, 0, 16), Position = UDim2.fromOffset(14, 10), Text = title, TextSize = 12, TextTheme = "TextBright", Font = Enum.Font.GothamBold })
        MakeLabel(card, { Size = UDim2.new(1, -100, 0, 14), Position = UDim2.fromOffset(14, 28), Text = desc, TextTheme = "TextDim", TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd })
    else
        MakeLabel(card, { Size = UDim2.new(1, -100, 1, 0), Position = UDim2.fromOffset(14, 0), Text = title, TextSize = 12, TextTheme = "TextBright", Font = Enum.Font.GothamBold })
    end
    if default and not BindSystem.Bindings[actionId] then BindSystem.Set(actionId, {type = "key", value = default}, false) end
    MakeKeycap(card, actionId)
    local obj = { Instance = card, ActionId = actionId, Set = function(_, b) BindSystem.Set(actionId, b, true) end, Get = function() return BindSystem.Bindings[actionId] end }
    setmetatable(obj, { __call = function(_, b) BindSystem.Set(actionId, b, true) end })
    return obj
end

function Tab:TextBox(opts)
    local title = opts.Name or "Input"; local default = opts.Default or ""; local desc = opts.Description or ""; local cb = opts.Callback
    local card = MakeFrame(self.Page, { Size = UDim2.new(1, 0, 0, 64), BackgroundTheme = "SurfaceBase", BackgroundTransparency = 0.5 })
    StyleCard(card, {radius = 10})
    if desc ~= "" then
        MakeLabel(card, { Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(14, 8), Text = title, TextSize = 12, TextTheme = "TextBright", Font = Enum.Font.GothamBold })
        MakeLabel(card, { Size = UDim2.new(1, -20, 0, 14), Position = UDim2.fromOffset(14, 24), Text = desc, TextTheme = "TextDim", TextSize = 10 })
    else
        MakeLabel(card, { Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.fromOffset(14, 0), Text = title, TextSize = 12, TextTheme = "TextBright", Font = Enum.Font.GothamBold })
    end
    local box = Instance.new("TextBox")
    box.Size = desc ~= "" and UDim2.new(1, -28, 0, 22) or UDim2.new(0.55, 0, 0, 28)
    box.Position = desc ~= "" and UDim2.new(0, 14, 0, 40) or UDim2.new(0.45, -14, 0.5, -14)
    box.BackgroundColor3 = Theme.BgDarkest; box.BackgroundTransparency = 0.4; box.BorderSizePixel = 0
    box.Text = default; box.PlaceholderText = opts.Placeholder or "Type here..."
    box.PlaceholderColor3 = Theme.TextMuted; box.TextColor3 = Theme.Text; box.TextSize = 11
    box.TextStrokeTransparency = 1
    box.Font = Enum.Font.Code; box.TextXAlignment = Enum.TextXAlignment.Left; box.ClearTextOnFocus = false; box.Parent = card
    ThemeSystem.Bind(box, {BackgroundColor3 = "BgDarkest", TextColor3 = "Text"}); Corner(box, 6); Stroke(box, "Border", 1, 0.6); Pad(box, 0, 8, 0, 8)
    TrackConnection(box.FocusLost:Connect(function() if cb then cb(box.Text) end end))
    local obj = { Instance = card, TextBox = box, Get = function() return box.Text end, Set = function(_, v) box.Text = v end }
    setmetatable(obj, { __call = function(_, v) box.Text = v end })
    return obj
end

function Tab:List(opts)
    local size = opts.Size or UDim2.new(1, 0, 0, 200)
    local container = MakeFrame(self.Page, { Size = size, BackgroundTransparency = 1 })
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.fromScale(1, 1); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = Theme.Border
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = container
    CreateInstance("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
    local listObj = {}
    function listObj:AddItem(itemOpts)
        -- ⚡ FIX: Отступы 8px слева/справа, чтобы обводка не обрезалась
        local card = MakeFrame(scroll, { Size = UDim2.new(1, -16, 0, 54), Position = UDim2.fromOffset(8, 0), BackgroundTheme = "SurfaceBase", BackgroundTransparency = 0.4 })
        StyleCard(card, {radius = 8}); Pad(card, 8, 12, 8, 12)
        local icon = itemOpts.Icon or "📄"; local title = itemOpts.Title or "Item"; local sub = itemOpts.Subtitle or ""
        MakeLabel(card, { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0, 0, 0.5, -15), Text = icon, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center })
        MakeLabel(card, { Size = UDim2.new(1, -130, 0, 16), Position = UDim2.fromOffset(36, 4), Text = title, TextSize = 11, TextTheme = "TextBright", Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd })
        MakeLabel(card, { Size = UDim2.new(1, -130, 0, 12), Position = UDim2.fromOffset(36, 22), Text = sub, TextTheme = "TextDim", TextSize = 9, Font = Enum.Font.Code, TextTruncate = Enum.TextTruncate.AtEnd })
        if itemOpts.OnPlay then
            local playBtn = Instance.new("TextButton")
            playBtn.Size = UDim2.fromOffset(24, 24); playBtn.Position = UDim2.new(1, -56, 0.5, -12)
            playBtn.BackgroundColor3 = Theme.Accent; playBtn.BackgroundTransparency = 0.2; playBtn.Text = "▶"
            playBtn.TextColor3 = Theme.TextBright; playBtn.TextSize = 12; playBtn.Font = Enum.Font.GothamBold; playBtn.AutoButtonColor = false
            playBtn.TextStrokeTransparency = 1; playBtn.Parent = card; Corner(playBtn, 6); Stroke(playBtn, "Accent", 1, 0.4)
            ApplyHover(playBtn, {scale=1.1}); ApplyPress(playBtn, {pressScale=0.9})
            TrackConnection(playBtn.MouseButton1Click:Connect(itemOpts.OnPlay))
        end
        if itemOpts.OnDelete then
            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.fromOffset(24, 24); delBtn.Position = UDim2.new(1, -28, 0.5, -12)
            delBtn.BackgroundColor3 = Theme.SurfaceLight; delBtn.BackgroundTransparency = 0.3; delBtn.Text = "🗑"
            delBtn.TextColor3 = Theme.TextDim; delBtn.TextSize = 12; delBtn.Font = Enum.Font.GothamBold; delBtn.AutoButtonColor = false
            delBtn.TextStrokeTransparency = 1; delBtn.Parent = card; Corner(delBtn, 6); Stroke(delBtn, "Border", 1, 0.6)
            ApplyHover(delBtn, {scale=1.1}); ApplyPress(delBtn, {scale=1.1, pressScale=0.9})
            TrackConnection(delBtn.MouseButton1Click:Connect(itemOpts.OnDelete))
        end
        return card
    end
    function listObj:Clear()
        for _, c in ipairs(scroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    end
    return listObj
end

function Tab:Dropdown(opts)
    local title = opts.Name or "Dropdown"; local items = opts.Items or {}
    local default = opts.Default or (items[1] or "None"); local cb = opts.Callback
    local card = MakeFrame(self.Page, { Size = UDim2.new(1, 0, 0, 52), BackgroundTheme = "SurfaceBase", BackgroundTransparency = 0.5 })
    StyleCard(card, {radius = 10}); Pad(card, 10, 14, 10, 14)
    MakeLabel(card, { Size = UDim2.new(1, -100, 1, 0), Text = title, TextSize = 12, TextTheme = "TextBright", Font = Enum.Font.GothamBold })
    local current = default
    local selectedBtn = Instance.new("TextButton")
    selectedBtn.Size = UDim2.fromOffset(90, 28); selectedBtn.Position = UDim2.new(1, -90, 0.5, -14)
    selectedBtn.BackgroundColor3 = Theme.SurfaceLight; selectedBtn.BackgroundTransparency = 0.2
    selectedBtn.Text = current; selectedBtn.TextColor3 = Theme.Text; selectedBtn.TextSize = 10; selectedBtn.Font = Enum.Font.GothamBold
    selectedBtn.TextStrokeTransparency = 1; selectedBtn.AutoButtonColor = false; selectedBtn.Parent = card
    Corner(selectedBtn, 6); Stroke(selectedBtn, "Border", 1, 0.5)
    local menu = MakeFrame(self.ScreenGui, { Size = UDim2.fromOffset(90, 0), BackgroundTheme = "BgDarkest", BackgroundTransparency = 0.05, Visible = false, ZIndex = 100 })
    Corner(menu, 6); Stroke(menu, "BorderLight", 1, 0.4)
    local list = Instance.new("UIListLayout"); list.Parent = menu
    local menuScale = EnsureUIScale(menu); menuScale.Scale = 0.9
    local isOpen = false
    local function closeMenu() isOpen = false; menu.Visible = false; Tween(menuScale, {Scale=0.9}, 0.15); Tween(menu, {Size=UDim2.fromOffset(90, 0)}, 0.15) end
    TrackConnection(selectedBtn.MouseButton1Click:Connect(function()
        if isOpen then closeMenu() return end
        isOpen = true
        menu.Position = UDim2.fromOffset(selectedBtn.AbsolutePosition.X, selectedBtn.AbsolutePosition.Y + 32)
        menu.Size = UDim2.fromOffset(90, 0); menu.Visible = true
        Tween(menu, {Size = UDim2.fromOffset(90, #items * 26)}, 0.25, Enum.EasingStyle.Quint)
        Tween(menuScale, {Scale = 1}, 0.25, Enum.EasingStyle.Back)
    end))
    for _, item in ipairs(items) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 26); btn.BackgroundTransparency = 1
        btn.Text = item; btn.TextColor3 = Theme.TextDim; btn.TextSize = 10; btn.Font = Enum.Font.GothamMedium
        btn.TextStrokeTransparency = 1
        btn.TextXAlignment = Enum.TextXAlignment.Left; btn.AutoButtonColor = false; btn.Parent = menu; Pad(btn, 0, 8, 0, 8)
        TrackConnection(btn.MouseButton1Click:Connect(function() current = item; selectedBtn.Text = item; if cb then cb(item) end; closeMenu() end))
        TrackConnection(btn.MouseEnter:Connect(function() btn.TextColor3 = Theme.TextBright end))
        TrackConnection(btn.MouseLeave:Connect(function() btn.TextColor3 = Theme.TextDim end))
    end
    local obj = { Instance = card, Get = function() return current end }
    return obj
end

function Tab:Custom(opts)
    local size = opts.Size or UDim2.new(1, 0, 0, 100)
    local frame = MakeFrame(self.Page, { Size = size, BackgroundTransparency = 1, ClipsDescendants = opts.ClipsDescendants or false })
    return frame
end

--============================================================
-- CONFIG
--============================================================
function Window:_LoadConfig()
    if not self.ConfigPath then return end
    local ok, data = pcall(function()
        if not (isfile and isfile(self.ConfigPath)) then return nil end
        return HttpService:JSONDecode(readfile(self.ConfigPath))
    end)
    if not ok or type(data) ~= "table" then return end
    if data.Theme and Themes[data.Theme] then ThemeSystem.Apply(data.Theme, true); self:RefreshThemeDots() end
    if data.Size then self.Width = data.Size.W or self.Width; self.Height = data.Size.H or self.Height; self:_ApplySize(self.Width, self.Height) end
    if data.MainFramePos then self._SavedPos = UDim2.fromOffset(data.MainFramePos.X or 100, data.MainFramePos.Y or 100) end
    if type(data.Hotkeys) == "table" then
        for actionId, val in pairs(data.Hotkeys) do
            if type(val) == "table" then BindSystem.Bindings[actionId] = BindSystem.Deserialize(val); BindSystem.UpdateButton(actionId) end
        end
    end
end
function Window:SaveConfig()
    if not self.ConfigPath then return end
    local pos = self._SavedPos or self.MainFrame.Position
    local data = { version = SCRIPT_VERSION, Theme = CurrentThemeName, Size = {W = self.Width, H = self.Height}, MainFramePos = {X = pos.X.Offset, Y = pos.Y.Offset}, Hotkeys = {} }
    for actionId in pairs(BindSystem.Bindings) do data.Hotkeys[actionId] = BindSystem.Serialize(actionId) end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if ok and encoded then
        pcall(function()
            local folder = self.ConfigPath:match("^(.*)/[^/]+$")
            if folder and isfolder and makefolder and not isfolder(folder) then makefolder(folder) end
            writefile(self.ConfigPath, encoded)
        end)
    end
end

--============================================================
-- PUBLIC API
--============================================================
local UI = {}
UI.Version = SCRIPT_VERSION; UI.Themes = Themes; UI.ThemeOrder = ThemeOrder; UI.Bindings = BindSystem; UI.Refs = {Toggle = ToggleRefs, Slider = SliderRefs}; UI.Notify = Notify
UI.GUI = { MakeFrame = MakeFrame, MakeLabel = MakeLabel, Corner = Corner, Gradient = Gradient, Stroke = Stroke, Pad = Pad, AddShadow = AddShadow, EnsureUIScale = EnsureUIScale, ApplyHover = ApplyHover, ApplyPress = ApplyPress, ThemeSystem = ThemeSystem, GetTheme = function() return Theme end, CreateInstance = CreateInstance }
function UI:CreateWindow(opts) return Window.new(opts) end
function UI:Notify(...) Notify.Push(...) end
function UI:SetTheme(name) ThemeSystem.Apply(name) end
function UI:GetThemeName() return CurrentThemeName end
function UI:GetTheme() return Theme end
function UI:SetNotificationsEnabled(v) Notify.enabled = v end
return UI