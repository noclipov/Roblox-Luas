-- ==========================================
-- [1. НАСТРОЙКИ И РАСШИРЕННЫЕ МИНИ-ТЕМЫ]
-- ==========================================
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Notify = {}

local PRESETS = {
	-- [ХОЛОДНЫЕ ОТТЕНКИ]
	Purple   = {Accent = Color3.fromRGB(167, 139, 250), Text = Color3.fromRGB(240, 235, 255), Bg = Color3.fromRGB(24, 20, 36)},
	Sky      = {Accent = Color3.fromRGB(96, 165, 250),  Text = Color3.fromRGB(235, 245, 255), Bg = Color3.fromRGB(15, 24, 38)},
	Mint     = {Accent = Color3.fromRGB(110, 230, 160), Text = Color3.fromRGB(230, 255, 240), Bg = Color3.fromRGB(12, 30, 22)},
	Teal     = {Accent = Color3.fromRGB(45, 212, 191),  Text = Color3.fromRGB(225, 255, 250), Bg = Color3.fromRGB(10, 28, 28)},
	Sage     = {Accent = Color3.fromRGB(163, 230, 53),  Text = Color3.fromRGB(245, 255, 225), Bg = Color3.fromRGB(22, 28, 12)},
	Ice      = {Accent = Color3.fromRGB(186, 230, 253), Text = Color3.fromRGB(240, 250, 255), Bg = Color3.fromRGB(18, 26, 32)},
	Lavender = {Accent = Color3.fromRGB(196, 181, 253), Text = Color3.fromRGB(245, 243, 255), Bg = Color3.fromRGB(28, 24, 38)},
	Marine   = {Accent = Color3.fromRGB(14, 165, 233),  Text = Color3.fromRGB(224, 242, 254), Bg = Color3.fromRGB(12, 26, 36)},

	-- [ТЕПЛЫЕ ОТТЕНКИ]
	Coral    = {Accent = Color3.fromRGB(248, 113, 113), Text = Color3.fromRGB(255, 235, 235), Bg = Color3.fromRGB(34, 18, 18)},
	Honey    = {Accent = Color3.fromRGB(251, 191, 36),  Text = Color3.fromRGB(255, 248, 225), Bg = Color3.fromRGB(30, 25, 12)},
	Peach    = {Accent = Color3.fromRGB(251, 146, 60),  Text = Color3.fromRGB(255, 242, 230), Bg = Color3.fromRGB(32, 22, 14)},
	Rose     = {Accent = Color3.fromRGB(244, 114, 182), Text = Color3.fromRGB(255, 235, 245), Bg = Color3.fromRGB(32, 16, 26)},
	Sakura   = {Accent = Color3.fromRGB(253, 164, 186), Text = Color3.fromRGB(255, 240, 243), Bg = Color3.fromRGB(32, 18, 22)},
	Vanilla  = {Accent = Color3.fromRGB(245, 230, 185), Text = Color3.fromRGB(255, 253, 240), Bg = Color3.fromRGB(26, 24, 18)},
	Amber    = {Accent = Color3.fromRGB(245, 158, 11),  Text = Color3.fromRGB(254, 243, 199), Bg = Color3.fromRGB(30, 20, 10)},
	Crimson  = {Accent = Color3.fromRGB(225, 29, 72),   Text = Color3.fromRGB(255, 228, 230), Bg = Color3.fromRGB(35, 12, 16)},

	-- [СТРОГИЕ / ТЕМНЫЕ]
	Obsidian = {Accent = Color3.fromRGB(156, 163, 175), Text = Color3.fromRGB(243, 244, 246), Bg = Color3.fromRGB(17, 24, 39)},
	Midnight = {Accent = Color3.fromRGB(59, 130, 246),  Text = Color3.fromRGB(219, 234, 254), Bg = Color3.fromRGB(10, 15, 30)},
	Plum     = {Accent = Color3.fromRGB(192, 132, 252), Text = Color3.fromRGB(243, 232, 255), Bg = Color3.fromRGB(24, 12, 36)},
	Wine     = {Accent = Color3.fromRGB(239, 68, 68),   Text = Color3.fromRGB(254, 226, 226), Bg = Color3.fromRGB(28, 10, 10)},
	Forest   = {Accent = Color3.fromRGB(52, 211, 153),  Text = Color3.fromRGB(209, 250, 229), Bg = Color3.fromRGB(6, 30, 24)},
	Gunmetal = {Accent = Color3.fromRGB(129, 140, 248), Text = Color3.fromRGB(238, 242, 255), Bg = Color3.fromRGB(20, 24, 33)},
	Carbon   = {Accent = Color3.fromRGB(75, 85, 99),    Text = Color3.fromRGB(209, 213, 219), Bg = Color3.fromRGB(12, 12, 14)},
	Shadow   = {Accent = Color3.fromRGB(31, 41, 55),    Text = Color3.fromRGB(156, 163, 175), Bg = Color3.fromRGB(8, 8, 10)},

	-- [НЕОН / КИБЕРПАНК (ЯРКИЕ)]
	Cyber    = {Accent = Color3.fromRGB(0, 255, 255),   Text = Color3.fromRGB(220, 255, 255), Bg = Color3.fromRGB(10, 20, 25)},
	NeonPink = {Accent = Color3.fromRGB(255, 0, 127),   Text = Color3.fromRGB(255, 220, 240), Bg = Color3.fromRGB(28, 10, 20)},
	Acid     = {Accent = Color3.fromRGB(191, 255, 0),   Text = Color3.fromRGB(240, 255, 210), Bg = Color3.fromRGB(20, 26, 10)},
	Gold     = {Accent = Color3.fromRGB(255, 215, 0),   Text = Color3.fromRGB(255, 250, 220), Bg = Color3.fromRGB(28, 24, 10)},
	Electric = {Accent = Color3.fromRGB(0, 102, 255),   Text = Color3.fromRGB(215, 235, 255), Bg = Color3.fromRGB(8, 16, 32)},
	Magma    = {Accent = Color3.fromRGB(255, 69, 0),    Text = Color3.fromRGB(255, 225, 210), Bg = Color3.fromRGB(30, 14, 10)},
	Matrix   = {Accent = Color3.fromRGB(0, 255, 70),    Text = Color3.fromRGB(210, 255, 220), Bg = Color3.fromRGB(8, 24, 12)},
	Vampire  = {Accent = Color3.fromRGB(150, 0, 0),     Text = Color3.fromRGB(255, 210, 210), Bg = Color3.fromRGB(18, 5, 5)}
}

local FONTS = {
	Title = Enum.Font.SourceSansBold,       
	Desc  = Enum.Font.SourceSans,           
	Mini  = Enum.Font.SourceSansSemibold,   
	Button = Enum.Font.SourceSansSemibold   
}

local NOTIFY_WIDTH = 340
local NOTIFY_PADDING = 10

-- ==========================================
-- [2. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ И ИНИЦИАЛИЗАЦИЯ]
-- ==========================================
local function resolveTheme(customOrPreset)
	if typeof(customOrPreset) == "string" and PRESETS[customOrPreset] then
		return PRESETS[customOrPreset]
	elseif typeof(customOrPreset) == "Color3" then
		return {Accent = customOrPreset, Text = Color3.fromRGB(240, 240, 245), Bg = Color3.fromRGB(22, 22, 28)}
	end
	return PRESETS.Purple
end

local function getContainer()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local sg = playerGui:FindFirstChild("Noclipov_UI_Storage")
	
	if not sg then
		sg = Instance.new("ScreenGui", playerGui)
		sg.Name = "Noclipov_UI_Storage"
		sg.ResetOnSpawn = false
		sg.DisplayOrder = 999
		sg.IgnoreGuiInset = true 
		
		local container = Instance.new("Frame", sg)
		container.Name = "NotifyContainer"
		container.Position = UDim2.new(1, -25, 1, -25)
		container.Size = UDim2.new(0, NOTIFY_WIDTH, 0, 0)
		container.AutomaticSize = Enum.AutomaticSize.Y
		container.AnchorPoint = Vector2.new(1, 1)
		container.BackgroundTransparency = 1
		container.BorderSizePixel = 0
		
		local layout = Instance.new("UIListLayout", container)
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		layout.Padding = UDim.new(0, NOTIFY_PADDING)
	end
	return sg.NotifyContainer
end

local function isInfinite(duration)
	return duration == nil or duration == 0 or duration == "inf" or duration == math.huge
end

-- ==========================================
-- [3. ВЕРСИЯ 1: ПОЛНОЕ УВЕДОМЛЕНИЕ]
-- ==========================================
function Notify.New(customColorOrPreset, title, text, duration, callback, buttonText)
	local theme = resolveTheme(customColorOrPreset)
	local container = getContainer()
	
	local hasTimer = not isInfinite(duration)
	local hasCallback = typeof(callback) == "function"
	local hasPhysicalButton = hasCallback and (buttonText ~= nil and buttonText ~= "")
	local isCardClickable = hasCallback and not hasPhysicalButton

	local placeholder = Instance.new("Frame", container)
	placeholder.Size = UDim2.new(1, 0, 0, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.BorderSizePixel = 0

	local frame = Instance.new(isCardClickable and "TextButton" or "Frame", placeholder)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Position = UDim2.new(1.3, 0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	if isCardClickable then frame.Text = ""; frame.AutoButtonColor = false end

	local bgFrame = Instance.new("Frame", frame)
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = theme.Bg
	bgFrame.BorderSizePixel = 0
	bgFrame.ZIndex = 1
	Instance.new("UICorner", bgFrame).CornerRadius = UDim.new(0, 10)
	
	local gradient = Instance.new("UIGradient", bgFrame)
	gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160))})
	gradient.Rotation = 90

	local titleLbl = Instance.new("TextLabel", frame)
	titleLbl.Size = UDim2.new(1, -45, 0, 18)
	titleLbl.Position = UDim2.new(0, 25, 0, 12)
	titleLbl.Text = tostring(title):upper()
	titleLbl.TextColor3 = theme.Accent
	titleLbl.Font = FONTS.Title
	titleLbl.TextSize = 13
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.BackgroundTransparency = 1
	titleLbl.ZIndex = 2

	local progressGradient
	if hasTimer then
		local barContainer = Instance.new("Frame", frame)
		barContainer.Size = UDim2.new(1, -45, 0, 2)
		barContainer.Position = UDim2.new(0, 25, 0, 34)
		barContainer.BackgroundColor3 = theme.Accent
		barContainer.BackgroundTransparency = 0.85
		barContainer.BorderSizePixel = 0
		barContainer.ClipsDescendants = true
		barContainer.ZIndex = 2
		Instance.new("UICorner", barContainer)

		local progressInner = Instance.new("Frame", barContainer)
		progressInner.Size = UDim2.new(1, 0, 1, 0)
		progressInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		progressInner.BorderSizePixel = 0
		Instance.new("UICorner", progressInner)

		progressGradient = Instance.new("UIGradient", progressInner)
		progressGradient.Color = ColorSequence.new(theme.Accent)
		progressGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.999, 0), NumberSequenceKeypoint.new(1, 1)})
	end

	local availableWidth = NOTIFY_WIDTH - 45
	local descHeight = game:GetService("TextService"):GetTextSize(text, 14, FONTS.Desc, Vector2.new(availableWidth, 1000)).Y
	local textYOffset = hasTimer and 46 or 40
	local finalHeight = hasPhysicalButton and math.max(descHeight + textYOffset + 38, 106) or math.max(descHeight + textYOffset + 18, 84)

	local descLbl = Instance.new("TextLabel", frame)
	descLbl.Size = UDim2.new(1, -45, 0, descHeight)
	descLbl.Position = UDim2.new(0, 25, 0, textYOffset)
	descLbl.Text = text
	descLbl.TextColor3 = theme.Text
	descLbl.Font = FONTS.Desc
	descLbl.TextSize = 14
	descLbl.TextWrapped = true
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.TextYAlignment = Enum.TextYAlignment.Top
	descLbl.LineHeight = 1.15
	descLbl.BackgroundTransparency = 1
	descLbl.ZIndex = 2

	local accentLine = Instance.new("Frame", frame)
	accentLine.Size = UDim2.new(0, 3, 1, -20)
	accentLine.Position = UDim2.new(0, 12, 0, 10)
	accentLine.BackgroundColor3 = theme.Accent
	accentLine.BorderSizePixel = 0
	accentLine.ZIndex = 2
	Instance.new("UICorner", accentLine)

	local function closeNotification()
		local slideOut = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1.3, 0, 0, 0)})
		slideOut:Play() slideOut.Completed:Wait()
		local collapse = TweenService:Create(placeholder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)})
		collapse:Play() collapse.Completed:Wait()
		placeholder:Destroy()
	end

	local clickConnection, mouseEnterConnection, mouseLeaveConnection
	local canClick = false task.delay(0.5, function() canClick = true end)

	if hasPhysicalButton then
		local btnTextWidth = game:GetService("TextService"):GetTextSize(tostring(buttonText):upper(), 12, FONTS.Button, Vector2.new(200, 50)).X
		local btnWidth = math.round(math.clamp(btnTextWidth + 24, 80, 140))

		local actionBtn = Instance.new("TextButton", frame)
		actionBtn.Size = UDim2.new(0, btnWidth, 0, 24)
		actionBtn.Position = UDim2.new(1, -20, 1, -12)
		actionBtn.AnchorPoint = Vector2.new(1, 1)
		actionBtn.BackgroundColor3 = theme.Accent
		actionBtn.BackgroundTransparency = 0.93
		actionBtn.Text = tostring(buttonText):upper()
		actionBtn.TextColor3 = theme.Accent
		actionBtn.Font = FONTS.Button
		actionBtn.TextSize = 12
		actionBtn.AutoButtonColor = false
		actionBtn.ZIndex = 3
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
			if hasCallback then task.spawn(callback) end
			closeNotification()
		end)
	elseif isCardClickable then
		local hoverColor = Color3.fromRGB(math.clamp(theme.Bg.R*255+12,0,255), math.clamp(theme.Bg.G*255+12,0,255), math.clamp(theme.Bg.B*255+16,0,255))
		mouseEnterConnection = frame.MouseEnter:Connect(function()
			TweenService:Create(bgFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = hoverColor}):Play()
		end)
		mouseLeaveConnection = frame.MouseLeave:Connect(function()
			TweenService:Create(bgFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = theme.Bg}):Play()
		end)
		clickConnection = frame.MouseButton1Click:Connect(function()
			if not canClick then return end
			if mouseEnterConnection then mouseEnterConnection:Disconnect() end
			if mouseLeaveConnection then mouseLeaveConnection:Disconnect() end
			if clickConnection then clickConnection:Disconnect() end
			task.spawn(callback)
			closeNotification()
		end)
	end

	placeholder.Size = UDim2.new(1, 0, 0, finalHeight)
	TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()

	if hasTimer and progressGradient then
		local progressTween = TweenService:Create(progressGradient, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Offset = Vector2.new(-1, 0)})
		progressTween:Play()
		local timerDelay; timerDelay = progressTween.Completed:Connect(function()
			if timerDelay then timerDelay:Disconnect() end
			if clickConnection then clickConnection:Disconnect() end
			if mouseEnterConnection then mouseEnterConnection:Disconnect() end
			if mouseLeaveConnection then mouseLeaveConnection:Disconnect() end
			closeNotification()
		end)
	end
end

-- ==========================================
-- [4. ВЕРСИЯ 2: КОМПАКТНОЕ (МИНИ) УВЕДОМЛЕНИЕ]
-- ==========================================
function Notify.Mini(customColorOrPreset, text, duration, callback)
	local theme = resolveTheme(customColorOrPreset)
	local container = getContainer()
	
	local hasTimer = not isInfinite(duration)
	local hasCallback = typeof(callback) == "function"
	
	local placeholder = Instance.new("Frame", container)
	placeholder.Size = UDim2.new(1, 0, 0, 36)
	placeholder.BackgroundTransparency = 1
	placeholder.BorderSizePixel = 0

	local frame = Instance.new(hasCallback and "TextButton" or "Frame", placeholder)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Position = UDim2.new(1.3, 0, 0, 0)
	frame.BackgroundColor3 = theme.Bg
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	if hasCallback then frame.Text = ""; frame.AutoButtonColor = false end
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local indicator = Instance.new("Frame", frame)
	indicator.Size = UDim2.new(0, 3, 0, 16)
	indicator.Position = UDim2.new(0, 12, 0.5, 0)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.BackgroundColor3 = theme.Accent
	indicator.BorderSizePixel = 0
	Instance.new("UICorner", indicator)

	local msgLbl = Instance.new("TextLabel", frame)
	msgLbl.Size = UDim2.new(1, -36, 1, hasTimer and -12 or 0)
	msgLbl.Position = UDim2.new(0, 24, 0, hasTimer and 3 or 0)
	msgLbl.Text = text
	msgLbl.TextColor3 = theme.Text
	msgLbl.Font = FONTS.Mini
	msgLbl.TextSize = 14
	msgLbl.TextXAlignment = Enum.TextXAlignment.Left
	msgLbl.BackgroundTransparency = 1

	local progressGradient
	if hasTimer then
		local progressContainer = Instance.new("Frame", frame)
		progressContainer.Size = UDim2.new(1, -32, 0, 1)
		progressContainer.Position = UDim2.new(0, 16, 1, -5)
		progressContainer.BackgroundColor3 = theme.Accent
		progressContainer.BackgroundTransparency = 0.92
		progressContainer.BorderSizePixel = 0
		progressContainer.ClipsDescendants = true

		local progressInner = Instance.new("Frame", progressContainer)
		progressInner.Size = UDim2.new(1, 0, 1, 0)
		progressInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		progressInner.BorderSizePixel = 0
		
		progressGradient = Instance.new("UIGradient", progressInner)
		progressGradient.Color = ColorSequence.new(theme.Accent)
		progressGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.999, 0), NumberSequenceKeypoint.new(1, 1)})
	end

	local textWidth = msgLbl.TextBounds.X + 42
	local finalWidth = math.round(math.clamp(textWidth, 110, 320))
	placeholder.Size = UDim2.new(0, finalWidth, 0, 36)
	frame.Size = UDim2.new(1, 0, 1, 0)

	local isDestroyed = false
	local function closeMini()
		if isDestroyed then return end isDestroyed = true
		local slideOut = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1.3, 0, 0, 0), BackgroundTransparency = 0.5})
		slideOut:Play() slideOut.Completed:Wait()
		local collapse = TweenService:Create(placeholder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, finalWidth, 0, 0)})
		collapse:Play() collapse.Completed:Wait()
		placeholder:Destroy()
	end

	local mouseEnterConnection, mouseLeaveConnection, clickConnection
	local canCloseWithMouse = false task.delay(1, function() canCloseWithMouse = true end)

	if hasCallback then
		local stroke = Instance.new("UIStroke", frame)
		stroke.Thickness = 1
		stroke.Color = theme.Accent
		stroke.Transparency = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		mouseEnterConnection = frame.MouseEnter:Connect(function()
			TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.05}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.4}):Play()
		end)
		
		mouseLeaveConnection = frame.MouseLeave:Connect(function()
			TweenService:Create(frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.15}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 1}):Play()
		end)

		clickConnection = frame.MouseButton1Click:Connect(function()
			if not canCloseWithMouse then return end
			if mouseEnterConnection then mouseEnterConnection:Disconnect() end
			if mouseLeaveConnection then mouseLeaveConnection:Disconnect() end
			if clickConnection then clickConnection:Disconnect() end
			task.spawn(callback)
			closeMini()
		end)
	elseif not hasTimer then
		mouseEnterConnection = frame.MouseEnter:Connect(function()
			if not canCloseWithMouse then repeat task.wait(0.1) until canCloseWithMouse end
			if mouseEnterConnection then mouseEnterConnection:Disconnect() end
			closeMini()
		end)
	end

	TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()

	if hasTimer and progressGradient then
		local progressTween = TweenService:Create(progressGradient, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Offset = Vector2.new(-1, 0)})
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