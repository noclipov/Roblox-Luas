local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local conv = loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/convs.lua"))()
local ObjectInteractionModule = table.create(4)

-- [[ КЛАСС ОДИНОЧНОГО ОКОШКА СТАТИСТИКИ (НА ЧАСТЯХ ТЕЛА) ]]
local StatBubble = {}
StatBubble.__index = StatBubble

function StatBubble.new(player, partName, data, config, isLocal)
    local self = setmetatable({}, StatBubble)
    self.Player = player
    self.PartName = partName
    self.Data = data
    self.IsLocal = isLocal
    self.Config = config
    self.Connections = {}
    self:CreateUI()
    self:StartTracking()
    return self
end

function StatBubble:CreateUI()
    local bb = Instance.new("BillboardGui")
    bb.Name = "Stat_" .. self.Data.Attr
    bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false
    bb.Size = UDim2.new(0, 100, 0, 22)
    bb.Parent = PlayerGui

    local frame = Instance.new("CanvasGroup")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = self.Config.Style.Bg
    frame.BorderSizePixel = 0
    frame.Parent = bb

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = self.Data.Color or self.Config.Style.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.RichText = true
    label.Parent = frame

    self.Gui = bb
    self.Card = frame
    self.Label = label

    local function update()
        local val = self.Player:GetAttribute(self.Data.Attr) or 0
        self.Label.Text = string.format("%s <font color='#%s'>%s</font>", 
            self.Data.Emoji or "", self.Data.Color:ToHex(), conv.ToLetters(val))
    end
    update()
    table.insert(self.Connections, self.Player:GetAttributeChangedSignal(self.Data.Attr):Connect(update))
end

function StatBubble:StartTracking()
    local maxDist = self.IsLocal and (self.Config.LocalSetup.MaxUiVisibleDistance or 25) or (self.Config.Style.MaxUiVisibleDistance or 80)
    table.insert(self.Connections, RunService.Heartbeat:Connect(function()
        local char = self.Player.Character
        local part = char and char:FindFirstChild(self.PartName)
        if not part then self.Gui.Enabled = false return end

        local distance = self.IsLocal and (Camera.CFrame.Position - part.Position).Magnitude or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and (LocalPlayer.Character.Head.Position - part.Position).Magnitude or 999)

        if distance > maxDist then self.Gui.Enabled = false return end

        self.Gui.Adornee = part
        self.Gui.StudsOffset = (self.IsLocal and self.Config.LocalSetup.Offsets[self.PartName]) or Vector3.new(0, 0, 0)
        self.Gui.Enabled = true

        local fadeStart = maxDist * 0.7
        self.Card.GroupTransparency = (distance > fadeStart) and math.clamp((distance - fadeStart) / (maxDist - fadeStart), 0, 1) or 0
    end))
end

function StatBubble:Destroy()
    for _, v in ipairs(self.Connections) do v:Disconnect() end
    if self.Gui then self.Gui:Destroy() end
end

-- [[ КЛАСС КОНТЕЙНЕРА КНОПОК (НАД ГОЛОВОЙ) ]]
local InteractionPanel = {}
InteractionPanel.__index = InteractionPanel

function InteractionPanel.new(player, config)
    local self = setmetatable({}, InteractionPanel)
    self.Player = player
    self.Config = config
    self.Connections = {}
    self:CreateUI()
    self:StartTracking()
    return self
end

function InteractionPanel:CreateUI()
    local bb = Instance.new("BillboardGui")
    bb.Name = "InteractionPanel"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 180, 0, 30)
    bb.Parent = PlayerGui

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = bb

    local layout = Instance.new("UIListLayout", container)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 4)

    for _, inter in ipairs(self.Config.Interactions or {}) do
        if not inter.Condition or inter.Condition(self.Player) then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 50, 0, 24)
            btn.BackgroundColor3 = self.Config.Style.Bg
            btn.Text = inter.Emoji and (inter.Emoji .. " " .. inter.Name) or inter.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSansBold
            btn.TextSize = 12
            btn.Parent = container
            
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            local s = Instance.new("UIStroke", btn)
            s.Color = self.Config.Style.Accent
            s.Transparency = 0.7

            btn.MouseButton1Click:Connect(function() inter.Callback(self.Player) end)
        end
    end
    self.Gui = bb
end

function InteractionPanel:StartTracking()
    table.insert(self.Connections, RunService.Heartbeat:Connect(function()
        local char = self.Player.Character
        local head = char and char:FindFirstChild("Head")
        if not head then self.Gui.Enabled = false return end
        
        self.Gui.Adornee = head
        -- Позиционируем панель кнопок ВЫШЕ всех стат на голове
        self.Gui.StudsOffset = Vector3.new(0, 4.5, 0) 
        self.Gui.Enabled = true
    end))
end

function InteractionPanel:Destroy()
    for _, v in ipairs(self.Connections) do v:Disconnect() end
    if self.Gui then self.Gui:Destroy() end
end

-- [[ МЕНЕДЖЕР ]]
local PlayerScanner = {}
PlayerScanner.__index = PlayerScanner

function PlayerScanner.new(player, config, isLocal)
    local self = setmetatable({}, PlayerScanner)
    self.Elements = {}
    -- Статы по частям тела
    for partName, data in pairs(config.StatsConfig) do
        table.insert(self.Elements, StatBubble.new(player, partName, data, config, isLocal))
    end
    -- Кнопки только для других игроков
    if not isLocal then
        table.insert(self.Elements, InteractionPanel.new(player, config))
    end
    return self
end

function PlayerScanner:Destroy()
    for _, el in ipairs(self.Elements) do el:Destroy() end
end

-- [[ ЭКСПОРТ ]]
local activeTargetScanner = nil
local localPlayerScanner = nil

function ObjectInteractionModule.Init(config)
    ObjectInteractionModule.Stop()
    local function setupLocal()
        if localPlayerScanner then localPlayerScanner:Destroy() end
        localPlayerScanner = PlayerScanner.new(LocalPlayer, config, true)
    end
    setupLocal()
    table.insert(ObjectInteractionModule.Connections, LocalPlayer.CharacterAdded:Connect(setupLocal))

    ObjectInteractionModule.clickConnection = UserInputService.InputBegan:Connect(function(input, proc)
        if proc then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local target = Mouse.Target
            local char = target and (target.Parent:FindFirstChild("Humanoid") and target.Parent or target.Parent.Parent)
            if char and char:FindFirstChild("Humanoid") then
                local p = Players:GetPlayerFromCharacter(char)
                if p and p ~= LocalPlayer then
                    if activeTargetScanner then activeTargetScanner:Destroy() end
                    activeTargetScanner = PlayerScanner.new(p, config, false)
                end
            else
                if activeTargetScanner then activeTargetScanner:Destroy() end
            end
        end
    end)
end

function ObjectInteractionModule.Stop()
    if ObjectInteractionModule.clickConnection then ObjectInteractionModule.clickConnection:Disconnect() end
    if ObjectInteractionModule.Connections then for _, c in ipairs(ObjectInteractionModule.Connections) do c:Disconnect() end end
    if activeTargetScanner then activeTargetScanner:Destroy() end
    if localPlayerScanner then localPlayerScanner:Destroy() end
end
ObjectInteractionModule.Connections = {}

return ObjectInteractionModule