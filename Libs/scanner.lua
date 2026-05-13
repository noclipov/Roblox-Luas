local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local conv = loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/convs.lua"))()
local msg = loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/notify.lua"))()
local ObjectInteractionModule = table.create(4)
local activeTargetScanner = nil
local localPlayerScanner = nil

-- [[ ВСТРОЕННЫЕ СЛУЖЕБНЫЕ МЕТОДЫ ]]
local Utils = table.create(1)
function Utils.CopyToClipboard(text)
	local setC = setclipboard or toclipboard or (Clipboard and Clipboard.set)
	if setC then
		pcall(function() setC(tostring(text)) end)
		return true
	end
	return false
end

-- [[ КЛАСС ВЗАИМОДЕЙСТВИЯ (SCANNER INSTANCE) ]]
local ScannerInstance = {}
ScannerInstance.__index = ScannerInstance

function ScannerInstance.new(targetPlayer, config, isLocal)
	local self = setmetatable({}, ScannerInstance)
	
	self.TargetPlayer = targetPlayer
	self.Config = config
	self.Style = config.Style
	self.IsLocal = isLocal
	self.Connections = table.create(4)
	self.AttributeConnections = table.create(4)
	self.Buttons = table.create(4)
	
	self:CreateUI()
	if not isLocal then
		self:CreateInteractions()
	end
	self:StartTracking()
	
	return self
end

function ScannerInstance:CreateUI()
	local bb = Instance.new("BillboardGui")
	bb.Name = "Noclipov_Scanner_3D"
	bb.AlwaysOnTop = true
	bb.ResetOnSpawn = false
	bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	if self.IsLocal then
		bb.Size = UDim2.new(0, 160, 0, 85)
	else
		bb.Size = UDim2.new(0, 190, 0, 120)
	end
	
	local card = Instance.new("CanvasGroup")
	card.Name = "CardFrame"
	card.Size = UDim2.new(1, 0, 1, 0)
	card.BackgroundColor3 = self.Style.Bg or Color3.fromRGB(15, 15, 20)
	card.BorderSizePixel = 0
	card.GroupTransparency = 0
	card.Parent = bb
	self.CardFrame = card
	
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = card
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.2
	stroke.Color = self.Style.Accent
	stroke.Transparency = 0.5
	stroke.Parent = card
	
	local title = Instance.new("TextLabel")
	title.Name = "PlayerTitle"
	title.Size = UDim2.new(1, -20, 0, 24)
	title.Position = UDim2.new(0, 10, 0, 4)
	title.BackgroundTransparency = 1
	title.Text = tostring(self.TargetPlayer.DisplayName or self.TargetPlayer.Name):upper()
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 13
	title.TextColor3 = self.Style.Highlight
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card
	
	local list = Instance.new("Frame")
	list.Name = "StatsList"
	list.Size = UDim2.new(1, -20, 0, self.IsLocal and 50 or 45)
	list.Position = UDim2.new(0, 10, 0, 26)
	list.BackgroundTransparency = 1
	list.Parent = card
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	
	local cfgMap = self.IsLocal and self.Config.LocalSetup.Offsets or self.Config.StatsConfig
	local idx = 1
	
	for partName, statData in pairs(cfgMap) do
		local globalData = self.Config.StatsConfig[partName]
		if globalData then
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 13)
			row.BackgroundTransparency = 1
			row.LayoutOrder = idx
			row.Parent = list
			
			local txt = Instance.new("TextLabel")
			txt.Size = UDim2.new(1, 0, 1, 0)
			txt.BackgroundTransparency = 1
			txt.Font = Enum.Font.SourceSansSemibold
			txt.TextSize = 12
			txt.TextColor3 = self.Style.Text
			txt.TextXAlignment = Enum.TextXAlignment.Left
			txt.Parent = row
			
			local function updateValue()
				local val = self.TargetPlayer:GetAttribute(globalData.Attr) or 0
				txt.Text = string.format("%s %s: <font color='#%s'>%s</font>", 
					globalData.Emoji or "", 
					globalData.Name, 
					globalData.Color:ToHex(), 
					conv.ToLetters(val)
				)
				txt.RichText = true
			end
			
			updateValue()
			table.insert(self.AttributeConnections, self.TargetPlayer:GetAttributeChangedSignal(globalData.Attr):Connect(updateValue))
			idx = idx + 1
		end
	end
	
	self.Gui = bb
	bb.Parent = PlayerGui
end

function ScannerInstance:CreateInteractions()
	local btnContainer = Instance.new("Frame")
	btnContainer.Name = "InteractionsContainer"
	btnContainer.Size = UDim2.new(1, -20, 0, 32)
	btnContainer.Position = UDim2.new(0, 10, 1, -38)
	btnContainer.BackgroundTransparency = 1
	btnContainer.Parent = self.CardFrame
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = btnContainer
	
	local availableInteractions = table.create(4)
	for _, inter in ipairs(self.Config.Interactions) do
		if not inter.Condition or inter.Condition(self.TargetPlayer) then
			table.insert(availableInteractions, inter)
		end
	end
	
	local num = #availableInteractions
	if num == 0 then return end
	
	local btnWidth = math.floor((btnContainer.AbsoluteSize.X - ((num - 1) * 6)) / num)
	if btnWidth <= 0 then btnWidth = 45 end
	
	for i, inter in ipairs(availableInteractions) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, btnWidth, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		btn.Text = string.format("%s %s", inter.Emoji or "", inter.Name)
		btn.Font = Enum.Font.SourceSansSemibold
		btn.TextSize = 12
		btn.TextColor3 = self.Style.Text
		btn.LayoutOrder = i
		btn.Active = true
		btn.Parent = btnContainer
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = btn
		
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = self.Style.Accent
		stroke.Transparency = 0.8
		stroke.Parent = btn
		
		btn.MouseEnter:Connect(function()
			if self.CardFrame.GroupTransparency >= 0.95 then return end
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 60)}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.4}):Play()
		end)
		
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.8}):Play()
		end)
		
		btn.MouseButton1Click:Connect(function()
			if self.CardFrame.GroupTransparency >= 0.95 then return end
			inter.Callback(self.TargetPlayer)
		end)
		
		table.insert(self.Buttons, btn)
	end
end

function ScannerInstance:StartTracking()
	local maxDist = self.IsLocal and (self.Config.LocalSetup.MaxUiVisibleDistance or 20) or (self.Style.MaxUiVisibleDistance or 80)
	local startFade = self.IsLocal and (maxDist * 0.5) or (self.Style.Distance or 60)
	
	table.insert(self.Connections, RunService.Heartbeat:Connect(function()
		local char = self.TargetPlayer.Character
		local localChar = LocalPlayer.Character
		
		if not char or not char:FindFirstChild("Head") or not localChar or not localChar:FindFirstChild("Head") then
			self.Gui.Enabled = false
			return
		end
		
		local targetPartName = "Head"
		if self.IsLocal then
			local pName = next(self.Config.LocalSetup.Offsets)
			if pName and char:FindFirstChild(pName) then targetPartName = pName end
		end
		
		local part = char:FindFirstChild(targetPartName)
		if not part then self.Gui.Enabled = false return end
		
		-- РАСЧЕТ ДИСТАНЦИИ: Если проверяем себя, считаем расстояние от своей головы до КАМЕРЫ.
		-- Если проверяем чужого игрока, считаем расстояние между головами.
		local distance
		if self.IsLocal then
			distance = (Camera.CFrame.Position - part.Position).Magnitude
		else
			distance = (localChar.Head.Position - part.Position).Magnitude
		end
		
		-- Скрытие по максимальной дистанции
		if distance > maxDist then
			self.Gui.Enabled = false
			self.Gui.Active = false
			self.CardFrame.Visible = false
			return
		end
		
		self.Gui.Adornee = part
		if self.IsLocal then
			local offset = self.Config.LocalSetup.Offsets[targetPartName] or Vector3.new(0, 2, 0)
			self.Gui.StudsOffset = offset
		else
			self.Gui.StudsOffset = Vector3.new(0, 2.5, 0)
		end
		self.Gui.Enabled = true
		
		-- Расчет плавного изменения прозрачности (GroupTransparency)
		if distance > startFade then
			local alpha = (distance - startFade) / (maxDist - startFade)
			self.CardFrame.GroupTransparency = math.clamp(alpha, 0, 1)
		else
			self.CardFrame.GroupTransparency = 0
		end
		
		-- Управление блокировкой мыши (обработка наведения) и свойством Visible
		if self.CardFrame.GroupTransparency >= 0.95 then
			if self.Gui.Active then self.Gui.Active = false end
			if self.CardFrame.Visible then self.CardFrame.Visible = false end
		else
			if not self.Gui.Active then self.Gui.Active = true end
			if not self.CardFrame.Visible then self.CardFrame.Visible = true end
		end
	end))
end

function ScannerInstance:Destroy()
	for _, conn in ipairs(self.Connections) do if conn then conn:Disconnect() end end
	for _, conn in ipairs(self.AttributeConnections) do if conn then conn:Disconnect() end end
	if self.Gui then self.Gui:Destroy() end
	table.clear(self.Buttons)
end

-- [[ МЕТОДЫ ЭКСПОРТА МОДУЛЯ ]]
function ObjectInteractionModule.Init(configTable)
	ObjectInteractionModule.Stop()
	
	if LocalPlayer.Character then
		localPlayerScanner = ScannerInstance.new(LocalPlayer, configTable, true)
	end
	
	table.insert(ObjectInteractionModule.Connections, LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		if localPlayerScanner then localPlayerScanner:Destroy() end
		localPlayerScanner = ScannerInstance.new(LocalPlayer, configTable, true)
	end))
	
	ObjectInteractionModule.clickConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local targetChar = nil
			if Mouse.Target then
				local c = Mouse.Target.Parent:FindFirstChild("Humanoid") and Mouse.Target.Parent or Mouse.Target.Parent.Parent
				if c and c:FindFirstChild("Humanoid") then targetChar = c end
			end
			
			if targetChar then
				local p = Players:GetPlayerFromCharacter(targetChar)
				if p then
					if p == LocalPlayer then
						if activeTargetScanner then activeTargetScanner:Destroy() end
					else
						if activeTargetScanner then activeTargetScanner:Destroy() end
						activeTargetScanner = ScannerInstance.new(p, configTable, false)
					end
				end
			else
				if activeTargetScanner then activeTargetScanner:Destroy() end
			end
		end
	end)
end

function ObjectInteractionModule.RefreshLocal(configTable)
	if localPlayerScanner then localPlayerScanner:Destroy() end
	if LocalPlayer.Character then
		localPlayerScanner = ScannerInstance.new(LocalPlayer, configTable, true)
	end
end

function ObjectInteractionModule.Stop()
	if ObjectInteractionModule.clickConnection then
		ObjectInteractionModule.clickConnection:Disconnect()
		ObjectInteractionModule.clickConnection = nil
	end
	if ObjectInteractionModule.Connections then
		for _, conn in ipairs(ObjectInteractionModule.Connections) do if conn then conn:Disconnect() end end
		table.clear(ObjectInteractionModule.Connections)
	else
		ObjectInteractionModule.Connections = table.create(2)
	end
	if activeTargetScanner then activeTargetScanner:Destroy() activeTargetScanner = nil end
	if localPlayerScanner then localPlayerScanner:Destroy() localPlayerScanner = nil end
end

return ObjectInteractionModule