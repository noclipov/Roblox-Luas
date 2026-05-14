local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

local conv = loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/convs.lua"))()
local msg = loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/notify.lua"))()
local ObjectInteractionModule = {}
local activeTargetScanner = nil
local localPlayerScanner = nil

-- [[ ВСТРОЕННЫЕ СЛУЖЕБНЫЕ МЕТОДЫ ]]
local Utils = {}

-- Безопасная функция работы с буфером обмена эксплоитов
function Utils.CopyToClipboard(text)
    local setC = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setC then
        pcall(function()
            setC(tostring(text))
        end)
        return true
    end
    return false
end

-- [[ КЛАСС ВЗАИМОДЕЙСТВИЯ (SCANNER INSTANCE) ]]
local ScannerInstance = {}
ScannerInstance.__index = ScannerInstance

function ScannerInstance.new(targetPlayer, config, isLocalPlayer)
    local self = setmetatable({}, ScannerInstance)
    self.Target = targetPlayer
    self.Config = config
    self.IsLocal = isLocalPlayer or false
    self.Gui = Instance.new("ScreenGui", PlayerGui)
    self.Gui.Name = isLocalPlayer and "LocalNumericScanner" or "NumericScanner"
    self.Connections = {}
    
    local targetChar = targetPlayer.Character
    if not targetChar then return nil end

    -- 1. Рендерим выноски со статами
    for partName, data in pairs(config.StatsConfig) do
        local part = targetChar:FindFirstChild(partName)
        if part then
            self:CreateNumericCallout(part, data, targetPlayer)
        end
    end

    -- 2. Док-панель действий (Только для чужих игроков)
    if not self.IsLocal then
        local head = targetChar:FindFirstChild("Head")
        if head then
            self:CreateActionDock(head, targetPlayer)
        end

        -- Авто-закрытие чужого сканера при отдалении от игрока
        local distConn = RunService.Heartbeat:Connect(function()
            local myChar = LocalPlayer.Character
            if not targetChar or not myChar or not myChar.PrimaryPart then 
                self:Destroy() 
                return 
            end
            local dist = (targetChar.PrimaryPart.Position - myChar.PrimaryPart.Position).Magnitude
            if dist > config.Style.Distance then 
                self:Destroy() 
            end
        end)
        table.insert(self.Connections, distConn)
    else
        -- Если это локальный игрок, пересоздаем UI при респавне
        local respawnConn = targetPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            if localPlayerScanner == self then
                ObjectInteractionModule.RefreshLocal(config)
            end
        end)
        table.insert(self.Connections, respawnConn)
    end

    return self
end

function ScannerInstance:CreateNumericCallout(part, data, targetPlayer)
    local config = self.Config
    local bgu = Instance.new("BillboardGui", self.Gui)
    bgu.Adornee = part
    bgu.AlwaysOnTop = true
    bgu.Active = true
    bgu.Size = UDim2.fromOffset(100, 45)

    -- Проверяем кастомные настройки смещения (Offsets) для локального игрока
    if self.IsLocal and config.LocalSetup and config.LocalSetup.Offsets and config.LocalSetup.Offsets[part.Name] then
        bgu.StudsOffset = config.LocalSetup.Offsets[part.Name]
    else
        bgu.StudsOffset = data.Offset -- Обычный оффсет для остальных игроков
    end

    local f = Instance.new("Frame", bgu)
    f.Size = UDim2.fromScale(1, 1)
    f.BackgroundColor3 = config.Style.Bg
    f.BackgroundTransparency = 0.2
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = data.Color
    stroke.Thickness = 1.5

    local title = Instance.new("TextLabel", f)
    title.Size = UDim2.new(1, 0, 0, 18)
    title.Position = UDim2.fromOffset(0, 4)
    title.Text = data.Emoji .. " " .. data.Name
    title.TextColor3 = Color3.fromRGB(200, 200, 200)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 10
    title.BackgroundTransparency = 1
    title.ZIndex = 2

    local valueLabel = Instance.new("TextLabel", f)
    valueLabel.Size = UDim2.new(1, 0, 0, 20)
    valueLabel.Position = UDim2.fromOffset(0, 18)
    valueLabel.Text = "0"
    valueLabel.TextColor3 = data.Color
    valueLabel.Font = Enum.Font.GothamBlack
    valueLabel.TextSize = 14
    valueLabel.BackgroundTransparency = 1
    valueLabel.ZIndex = 2

    local clickBtn = Instance.new("TextButton", f)
    clickBtn.Size = UDim2.fromScale(1, 1)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 5

    -- Определение дистанции затухания камеры (Индивидуально для себя / для других)
    local maxVisibleDist = config.Style.MaxUiVisibleDistance
    if self.IsLocal and config.LocalSetup and config.LocalSetup.MaxUiVisibleDistance then
        maxVisibleDist = config.LocalSetup.MaxUiVisibleDistance
    end
    
	-- Форматирование внешней функцией
    local function updateValue()
        local rawValue = targetPlayer:GetAttribute(data.Attr) or 0
		valueLabel.Text = conv.ToLetters(rawValue)
        
        valueLabel.TextSize = 18
        TweenService:Create(valueLabel, TweenInfo.new(0.3), {TextSize = 14}):Play()
    end

    -- Эффекты Hover
    table.insert(self.Connections, clickBtn.MouseEnter:Connect(function()
        local camDist = (part.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
		if camDist > maxVisibleDist-5 then clickBtn.Active = false return else clickBtn.Active = true end
        TweenService:Create(stroke, TweenInfo.new(0.15), {
            Thickness = 2.5,
            Color = data.Color:Lerp(Color3.new(1, 1, 1), 0.25)
        }):Play()
        TweenService:Create(f, TweenInfo.new(0.15), {BackgroundTransparency = 0.05}):Play()
    end))

    table.insert(self.Connections, clickBtn.MouseLeave:Connect(function()
        local camDist = (part.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
		if camDist > maxVisibleDist-5 then clickBtn.Active = false return else clickBtn.Active = true end
        TweenService:Create(stroke, TweenInfo.new(0.15), {
            Thickness = 1.5,
            Color = data.Color
        }):Play()
        TweenService:Create(f, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
    end))

    -- Плавное затухание по дистанции камеры
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        if not bgu.Parent or not workspace.CurrentCamera then return end
        local camDist = (part.Position - workspace.CurrentCamera.CFrame.Position).Magnitude

        if camDist > maxVisibleDist then
            f.BackgroundTransparency = 1; title.TextTransparency = 1; valueLabel.TextTransparency = 1; stroke.Transparency = 1
        elseif camDist > (maxVisibleDist - 15) then
            local alpha = math.clamp((maxVisibleDist - camDist) / 15, 0, 1)
            f.BackgroundTransparency = 1 - (alpha * 0.8)
            title.TextTransparency = 1 - alpha
            valueLabel.TextTransparency = 1 - alpha
            stroke.Transparency = 1 - alpha
        else
            f.BackgroundTransparency = 0.2; title.TextTransparency = 0; valueLabel.TextTransparency = 0; stroke.Transparency = 0
        end
    end))

    -- Копирование значения по клику
    table.insert(self.Connections, clickBtn.MouseButton1Click:Connect(function()
		local camDist = (part.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
		if camDist > maxVisibleDist-5 then clickBtn.Active = false return else clickBtn.Active = true end
        local copied = Utils.CopyToClipboard(valueLabel.Text)
        
        if copied then
            msg.Mini("Mint", ("%s скопировано в буфер!"):format(valueLabel.Text), 3)
        else
            msg.Mini("Coral", "Ошибка доступа к буферу обмена", 3)
		end

        local originalColor = stroke.Color
        TweenService:Create(stroke, TweenInfo.new(0.08), {Color = config.Style.Success, Thickness = 3}):Play()
        task.delay(0.2, function()
            if stroke.Parent then
                TweenService:Create(stroke, TweenInfo.new(0.3), {Color = originalColor, Thickness = 1.5}):Play()
            end
        end)
    end))

    table.insert(self.Connections, targetPlayer:GetAttributeChangedSignal(data.Attr):Connect(updateValue))
    updateValue()
end

function ScannerInstance:CreateActionDock(head, targetPlayer)
    local config = self.Config
    local availableActions = {}
    
    for _, action in ipairs(config.Interactions) do
        if not action.Condition or action.Condition(targetPlayer) == true then
            table.insert(availableActions, action)
        end
    end

    if #availableActions == 0 then return end

    local bgu = Instance.new("BillboardGui", self.Gui)
    bgu.Adornee = head
    bgu.StudsOffset = Vector3.new(0, 5.0, 0)
    bgu.AlwaysOnTop = true
    bgu.Active = true

    local buttonWidth = 85
    local spacing = 6
    local totalWidth = (#availableActions * buttonWidth) + ((#availableActions - 1) * spacing) + 16
    bgu.Size = UDim2.fromOffset(totalWidth, 40)

    local mainFrame = Instance.new("Frame", bgu)
    mainFrame.Size = UDim2.fromScale(1, 1)
    mainFrame.BackgroundColor3 = config.Style.Bg
    mainFrame.BackgroundTransparency = 0.25
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = config.Style.Accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.4

    local list = Instance.new("UIListLayout", mainFrame)
    list.FillDirection = Enum.FillDirection.Horizontal
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.Padding = UDim.new(0, spacing)

    local createdButtons = {}

    for _, action in ipairs(availableActions) do
        local btn = Instance.new("TextButton", mainFrame)
        btn.Size = UDim2.fromOffset(buttonWidth, 28)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.BackgroundTransparency = 0.3
        btn.Text = action.Emoji .. " " .. action.Name
        btn.TextColor3 = config.Style.Text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.AutoButtonColor = false
        
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 6)
        
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = config.Style.Text
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.85

        table.insert(self.Connections, btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = config.Style.Accent, BackgroundTransparency = 0.1}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0.4}):Play()
        end))

        table.insert(self.Connections, btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 40), BackgroundTransparency = 0.3}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0.85}):Play()
        end))

        table.insert(self.Connections, btn.MouseButton1Click:Connect(function()
            action.Callback(targetPlayer)
            self:Destroy()
        end))

        table.insert(createdButtons, {btn = btn, stroke = btnStroke})
    end

    -- Прозрачность кнопок действий по камере
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        if not bgu.Parent or not workspace.CurrentCamera then return end
        local camDist = (head.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
        
        if camDist > config.Style.MaxUiVisibleDistance then
            mainFrame.BackgroundTransparency = 1; stroke.Transparency = 1
            for _, item in ipairs(createdButtons) do
                item.btn.BackgroundTransparency = 1; item.btn.TextTransparency = 1; item.stroke.Transparency = 1
            end
        elseif camDist > (config.Style.MaxUiVisibleDistance - 15) then
            local alpha = math.clamp((config.Style.MaxUiVisibleDistance - camDist) / 15, 0, 1)
            mainFrame.BackgroundTransparency = 1 - (alpha * 0.75)
            stroke.Transparency = 1 - (alpha * 0.6)
            for _, item in ipairs(createdButtons) do
                item.btn.BackgroundTransparency = 1 - (alpha * 0.7)
                item.btn.TextTransparency = 1 - alpha
                item.stroke.Transparency = 1 - (alpha * 0.15)
            end
        else
            mainFrame.BackgroundTransparency = 0.25; stroke.Transparency = 0.4
            for _, item in ipairs(createdButtons) do
                local isHovering = (UserInputService:GetMouseLocation() - item.btn.AbsolutePosition).Magnitude < 30
                if not isHovering then
                    item.btn.BackgroundTransparency = 0.3; item.btn.TextTransparency = 0; item.stroke.Transparency = 0.85
                end
            end
        end
    end))
end

function ScannerInstance:Destroy()
    for _, conn in ipairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    if self.Gui then self.Gui:Destroy() end
    if activeTargetScanner == self then activeTargetScanner = nil end
    if localPlayerScanner == self then localPlayerScanner = nil end
end


-- [[ МЕТОДЫ ИНИЦИАЛИЗАЦИИ МОДУЛЯ ]]
local clickConnection = nil

function ObjectInteractionModule.Init(configTable)
    ObjectInteractionModule.Stop()

    -- 1. Создаем постоянный сканер для Самого Себя (LocalPlayer)
    if LocalPlayer.Character then
        localPlayerScanner = ScannerInstance.new(LocalPlayer, configTable, true)
    end

    -- 2. Слушатель кликов по другим игрокам
    clickConnection = UserInputService.InputBegan:Connect(function(input, proc)
        if proc then return end 

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local targetChar = nil
            if Mouse.Target and Mouse.Target.Parent then
                local c = Mouse.Target.Parent:FindFirstChild("Humanoid") and Mouse.Target.Parent or Mouse.Target.Parent.Parent
                if c and c:FindFirstChild("Humanoid") then
                    targetChar = c
                end
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
                if activeTargetScanner then
                    activeTargetScanner:Destroy()
                end
            end
        end
    end)
end

function ObjectInteractionModule.RefreshLocal(configTable)
    if localPlayerScanner then
        localPlayerScanner:Destroy()
    end
    if LocalPlayer.Character then
        localPlayerScanner = ScannerInstance.new(LocalPlayer, configTable, true)
    end
end

function ObjectInteractionModule.Stop()
    if clickConnection then
        clickConnection:Disconnect()
        clickConnection = nil
    end
    if activeTargetScanner then activeTargetScanner:Destroy() end
    if localPlayerScanner then localPlayerScanner:Destroy() end
end

return ObjectInteractionModule