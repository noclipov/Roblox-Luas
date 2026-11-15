-- ============================================================
-- MovementRecorder.lua (Show only unsaved marker if cache exists)
-- ============================================================
local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local MovementRecorder = {}
MovementRecorder.__index = MovementRecorder

local RECORD_HZ = 1 / 30

local function GetMapName()
    local ok, name = pcall(function() 
        local map = Workspace:FindFirstChild("Map")
        return map and map:GetAttribute("MapName") 
    end)
    if ok and type(name) == "string" and name ~= "" then 
        return (name:gsub("[^%w_%-]", "_")) 
    end
    return "Unknown"
end

local function TrimLeadingStatic(frames, threshold)
    threshold = threshold or 1.0
    if #frames < 3 then return frames end
    local p0 = Vector3.new(frames[1].px, frames[1].py, frames[1].pz)
    local lastStaticIdx = 1
    local anyMoved = false
    for i = 2, #frames do
        local p = Vector3.new(frames[i].px, frames[i].py, frames[i].pz)
        if (p - p0).Magnitude > threshold then anyMoved = true; break end
        lastStaticIdx = i
    end
    if not anyMoved then return {} end
    if lastStaticIdx == 1 then return frames end
    local trimmed = {}
    local offsetT = frames[lastStaticIdx].t
    for i = lastStaticIdx, #frames do
        local f = frames[i]
        table.insert(trimmed, {t=f.t - offsetT, px=f.px, py=f.py, pz=f.pz, vx=f.vx, vy=f.vy, vz=f.vz, lx=f.lx, ly=f.ly, lz=f.lz})
    end
    return trimmed
end

local function TrimTrailingStatic(frames, threshold)
    threshold = threshold or 1.0
    if #frames < 3 then return frames end
    local pEnd = Vector3.new(frames[#frames].px, frames[#frames].py, frames[#frames].pz)
    local firstStaticIdx = #frames
    for i = #frames - 1, 1, -1 do
        local p = Vector3.new(frames[i].px, frames[i].py, frames[i].pz)
        if (p - pEnd).Magnitude > threshold then break end
        firstStaticIdx = i
    end
    if firstStaticIdx == #frames or firstStaticIdx <= 2 then return frames end
    local trimmed = {}
    for i = 1, firstStaticIdx do table.insert(trimmed, frames[i]) end
    return trimmed
end

function MovementRecorder.new(UI)
    local self = setmetatable({}, MovementRecorder)
    self.UI = UI
    self.BaseFolder = "Noclipov/evade/movement"
    
    self.RecState = { IsRecording = false, StartTime = 0, Frames = {}, FrameAccum = 0, Cache = nil }
    self.PlayState = {
        Active = false, Frames = nil, Duration = 0, StartTime = nil, RecName = nil, Speed = 1.0,
        OriginalAutoRotate = nil, OriginalHrpCollide = nil, OriginalWalkSpeed = nil,
        OriginalJumpPower = nil, OriginalJumpHeight = nil, OriginalLVEnabled = nil, TrackedLV = nil
    }
    
    self.MarkerParts = {} 
    self.UnsavedMarker = nil
    self.StartMarker = nil
    self.PlaybackPath = { dots = {}, active = false }
    
    self.MarkersEnabled = true
    self._RecordingStartPos = nil 
    
    self._recordingsCache = nil
    self._cacheTime = 0
    self._animTime = 0
    
    self._connections = {}
    self:_SetupEvents()
    self:_SetupThemeListener()
    
    return self
end

function MovementRecorder:AddConn(conn)
    table.insert(self._connections, conn)
    return conn
end

function MovementRecorder:Destroy()
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}
    self:ClearMarkers()
    self:ClearPlaybackPath()
    self:StopPlayback(true)
    self:StopRecording(false)
end

-- ================= TOGGLE MARKERS =================
function MovementRecorder:SetMarkersEnabled(enabled)
    self.MarkersEnabled = enabled
    if not enabled then
        self:ClearMarkers()
    else
        self:RefreshMarkers()
    end
end

-- ================= THEME HANDLING =================
function MovementRecorder:_SetupThemeListener()
    if self.UI and self.UI.GUI and self.UI.GUI.ThemeSystem then
        self:AddConn(self.UI.GUI.ThemeSystem.Subscribe(function(newTheme, oldTheme)
            local col = newTheme.Accent
            local successCol = newTheme.Success
            local warnCol = newTheme.Warning
            
            for _, dot in ipairs(self.PlaybackPath.dots) do
                if dot.Parent then dot.Color = col end
            end
            
            for _, m in pairs(self.MarkerParts) do
                if m.core and m.core.Parent then m.core.Color = col end
                if m.ring and m.ring.Parent then m.ring.Color = col end
                if m.glow and m.glow.Parent then m.glow.Color = col end
                if m.light and m.light.Parent then m.light.Color = col end
                if m.billboardFrame then m.billboardFrame.UIStroke.Color = col end
                if m.titleLbl then m.titleLbl.TextColor3 = col end
            end
            
            if self.StartMarker then
                if self.StartMarker.core and self.StartMarker.core.Parent then self.StartMarker.core.Color = successCol end
                if self.StartMarker.billboardFrame then self.StartMarker.billboardFrame.UIStroke.Color = successCol end
                if self.StartMarker.titleLbl then self.StartMarker.titleLbl.TextColor3 = successCol end
            end
            
            if self.UnsavedMarker then
                if self.UnsavedMarker.core then self.UnsavedMarker.core.Color = warnCol end
                if self.UnsavedMarker.ring then self.UnsavedMarker.ring.Color = warnCol end
                if self.UnsavedMarker.glow then self.UnsavedMarker.glow.Color = warnCol end
                if self.UnsavedMarker.light then self.UnsavedMarker.light.Color = warnCol end
                if self.UnsavedMarker.billboardFrame then self.UnsavedMarker.billboardFrame.UIStroke.Color = warnCol end
                if self.UnsavedMarker.titleLbl then self.UnsavedMarker.titleLbl.TextColor3 = warnCol end
            end
        end))
    end
end

-- ================= EXPOSED HELPERS =================
function MovementRecorder:GetMapName() return GetMapName() end
function MovementRecorder:IsRecording() return self.RecState.IsRecording end
function MovementRecorder:HasCache() return self.RecState.Cache ~= nil end
function MovementRecorder:IsPlaying() return self.PlayState.Active end

-- ================= FILES =================
function MovementRecorder:EnsureFolder()
    pcall(function()
        if isfolder and not isfolder("Noclipov") then makefolder("Noclipov") end
        if isfolder and not isfolder("Noclipov/evade") then makefolder("Noclipov/evade") end
        if isfolder and not isfolder(self.BaseFolder) then makefolder(self.BaseFolder) end
        local folder = self.BaseFolder .. "/" .. GetMapName()
        if isfolder and not isfolder(folder) then makefolder(folder) end
    end)
end

function MovementRecorder:GetRecordings(forceRefresh)
    local now = os.clock()
    if not forceRefresh and self._recordingsCache and (now - self._cacheTime < 2) then
        return self._recordingsCache
    end
    
    self:EnsureFolder()
    local folder = self.BaseFolder .. "/" .. GetMapName()
    local files = {}
    pcall(function()
        if listfiles and isfolder and isfolder(folder) then files = listfiles(folder) end
    end)
    
    local list = {}
    for _, path in ipairs(files) do
        if type(path) == "string" and path:match("%.json$") then
            local content; pcall(function() content = readfile(path) end)
            if content then
                local decoded; pcall(function() decoded = HttpService:JSONDecode(content) end)
                if decoded then
                    local fname = path:match("([^/\\]+)%.json$") or "unknown"
                    table.insert(list, {
                        name = fname, path = path,
                        duration = decoded.duration or 0,
                        frameCount = decoded.frameCount or #(decoded.frames or {}),
                        mapName = decoded.mapName or "",
                        createdAt = decoded.createdAt,
                        firstFrame = decoded.frames and decoded.frames[1] or nil
                    })
                end
            end
        end
    end
    table.sort(list, function(a, b) return (a.name or ""):lower() < (b.name or ""):lower() end)
    
    self._recordingsCache = list
    self._cacheTime = now
    return list
end

function MovementRecorder:SaveToFile(name, frames, duration)
    self:EnsureFolder()
    local data = {version=1, name=name, mapName=GetMapName(), createdAt=os.time(), duration=duration, frameCount=#frames, frames=frames}
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok or not encoded then return false end
    local success = pcall(writefile, self.BaseFolder .. "/" .. GetMapName() .. "/" .. name .. ".json", encoded)
    if success then self._recordingsCache = nil end
    return success
end

function MovementRecorder:DeleteFile(path)
    pcall(delfile, path)
    self._recordingsCache = nil
end

function MovementRecorder:ReadFirstFrame(path)
    local content; pcall(function() content = readfile(path) end)
    if not content then return nil end
    local decoded; pcall(function() decoded = HttpService:JSONDecode(content) end)
    if not decoded or not decoded.frames or not decoded.frames[1] then return nil end
    local f = decoded.frames[1]
    if not (f.px and f.py and f.pz) then return nil end
    return Vector3.new(f.px, f.py, f.pz), decoded
end

-- ================= RECORDING =================
function MovementRecorder:CanStartRecording()
    local char = LocalPlayer.Character; if not char then return false, "No character" end
    local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false, "No humanoid" end
    if hum.FloorMaterial == Enum.Material.Air then return false, "Player in air" end
    if hrp.AssemblyLinearVelocity.Magnitude > 2 then return false, "Player is moving" end
    return true
end

function MovementRecorder:StartRecording()
    if self.RecState.IsRecording or self.PlayState.Active then return false, "Busy" end
    local ok, reason = self:CanStartRecording()
    if not ok then return false, reason end
    
    self.RecState.IsRecording = true
    self.RecState.StartTime = os.clock()
    self.RecState.Frames = {}
    self.RecState.FrameAccum = 0
    self.RecState.Cache = nil
    
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        self._RecordingStartPos = hrp.Position
    end
    
    self:RefreshMarkers()
    return true
end

function MovementRecorder:StopRecording(saveToCache)
    if not self.RecState.IsRecording then return end
    self.RecState.IsRecording = false
    
    self._RecordingStartPos = nil
    
    local frames = self.RecState.Frames
    self.RecState.Frames = {}
    self.RecState.FrameAccum = 0
    
    if saveToCache and #frames >= 2 then
        local trimmed = TrimLeadingStatic(frames, 1.0)
        if #trimmed > 0 then trimmed = TrimTrailingStatic(trimmed, 1.0) end
        
        if #trimmed < 2 then
            self.RecState.Cache = nil
            self:RefreshMarkers()
            return false, "Too short"
        end
        
        local newDuration = trimmed[#trimmed].t
        self.RecState.Cache = { frames = trimmed, duration = newDuration, frameCount = #trimmed }
        self:RefreshMarkers()
        return true, newDuration
    else
        self.RecState.Cache = nil
        self:RefreshMarkers()
        return false
    end
end

function MovementRecorder:UpdateRecording(dt)
    if not self.RecState.IsRecording then return end
    self.RecState.FrameAccum = self.RecState.FrameAccum + dt
    if self.RecState.FrameAccum >= RECORD_HZ then
        self.RecState.FrameAccum = self.RecState.FrameAccum - RECORD_HZ
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local t = os.clock() - self.RecState.StartTime
            local cf = hrp.CFrame
            local v = hrp.AssemblyLinearVelocity
            table.insert(self.RecState.Frames, {
                t=t, px=cf.X, py=cf.Y, pz=cf.Z, vx=v.X, vy=v.Y, vz=v.Z,
                lx=cf.LookVector.X, ly=cf.LookVector.Y, lz=cf.LookVector.Z
            })
        end
    end
end

-- ================= PLAYBACK =================
function MovementRecorder:PlayUnsaved()
    if not self.RecState.Cache then return false, "No cache" end
    return self:StartPlayback("Unsaved", self.RecState.Cache.frames, self.RecState.Cache.duration)
end

-- ⚡ Блокируем запуск сохраненных записей, если есть кеш
function MovementRecorder:StartPlayback(recName, frames, duration)
    -- Если есть кеш, разрешаем запускать ТОЛЬКО его
    if self.RecState.Cache and recName ~= "Unsaved" then 
        return false, "You have an unsaved cache. Save or cancel it first!" 
    end

    if self.PlayState.Active then self:StopPlayback() end
    if not frames or #frames < 2 or self.RecState.IsRecording then return false end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hum or hum.Health <= 0 then return false end
    
    self.PlayState.RecName = recName
    self.PlayState.OriginalAutoRotate = hum.AutoRotate
    self.PlayState.OriginalHrpCollide = hrp.CanCollide
    self.PlayState.OriginalWalkSpeed = hum.WalkSpeed
    self.PlayState.OriginalJumpPower = hum.JumpPower
    self.PlayState.OriginalJumpHeight = hum.JumpHeight
    
    hum.AutoRotate = false
    hum.WalkSpeed = 0
    pcall(function() hum.JumpPower = 0; hum.JumpHeight = 0 end)
    hrp.CanCollide = false
    
    local lv
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("LinearVelocity") and d.Attachment0 and d.RelativeTo == Enum.ActuatorRelativeTo.World then
            lv = d; break
        end
    end
    if lv then
        self.PlayState.OriginalLVEnabled = lv.Enabled
        self.PlayState.TrackedLV = lv
        lv.Enabled = false
    end
    
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end)
    
    local f1 = frames[1]
    local p1 = Vector3.new(f1.px, f1.py, f1.pz)
    local look1 = Vector3.new(f1.lx, f1.ly, f1.lz)
    if look1.Magnitude < 0.01 then look1 = Vector3.new(0, 0, -1) end
    pcall(function() hrp.CFrame = CFrame.lookAt(p1, p1 + look1.Unit) end)
    
    self.PlayState.Active = true
    self.PlayState.Frames = frames
    self.PlayState.Duration = math.max(duration or frames[#frames].t, 0.01)
    self.PlayState.Speed = self.PlayState.Speed or 1.0
    self.PlayState.StartTime = nil
    
    self:CreatePlaybackPath(frames)
    self:RefreshMarkers()
    return true
end

function MovementRecorder:StopPlayback(silent)
    if not self.PlayState.Active then return end
    self.PlayState.Active = false
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hum then
        if self.PlayState.OriginalAutoRotate ~= nil then hum.AutoRotate = self.PlayState.OriginalAutoRotate end
        if self.PlayState.OriginalWalkSpeed ~= nil then hum.WalkSpeed = self.PlayState.OriginalWalkSpeed end
        if self.PlayState.OriginalJumpPower ~= nil then hum.JumpPower = self.PlayState.OriginalJumpPower end
        if self.PlayState.OriginalJumpHeight ~= nil then hum.JumpHeight = self.PlayState.OriginalJumpHeight end
    end
    if hrp and self.PlayState.OriginalHrpCollide ~= nil then
        hrp.CanCollide = self.PlayState.OriginalHrpCollide
    end
    if self.PlayState.TrackedLV and self.PlayState.TrackedLV.Parent then
        if self.PlayState.OriginalLVEnabled ~= nil then self.PlayState.TrackedLV.Enabled = self.PlayState.OriginalLVEnabled end
    end
    
    self.PlayState.OriginalAutoRotate = nil; self.PlayState.OriginalHrpCollide = nil
    self.PlayState.OriginalWalkSpeed = nil; self.PlayState.OriginalJumpPower = nil; self.PlayState.OriginalJumpHeight = nil
    self.PlayState.OriginalLVEnabled = nil; self.PlayState.TrackedLV = nil; self.PlayState.StartTime = nil
    self.PlayState.Frames = nil; self.PlayState.RecName = nil
    
    self:ClearPlaybackPath()
    self:RefreshMarkers()
end

function MovementRecorder:UpdatePlayback(dt)
    if not self.PlayState.Active then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hum or hum.Health <= 0 then self:StopPlayback(); return end
    
    local frames = self.PlayState.Frames
    if not frames or #frames < 2 then self:StopPlayback(); return end
    
    if not self.PlayState.StartTime then self.PlayState.StartTime = os.clock() end
    local elapsed = (os.clock() - self.PlayState.StartTime) * self.PlayState.Speed
    if elapsed >= self.PlayState.Duration then self:StopPlayback(); return end
    
    local lo, hi = 1, #frames
    while hi - lo > 1 do
        local mid = math.floor((lo + hi) / 2)
        if frames[mid].t <= elapsed then lo = mid else hi = mid end
    end
    
    local A, B = frames[lo], frames[hi]
    local dtAB = B.t - A.t
    local alpha = dtAB > 0 and math.clamp((elapsed - A.t) / dtAB, 0, 1) or 0
    
    local targetPos = Vector3.new(A.px + (B.px - A.px) * alpha, A.py + (B.py - A.py) * alpha, A.pz + (B.pz - A.pz) * alpha)
    local lookVec = Vector3.new(A.lx + (B.lx - A.lx) * alpha, A.ly + (B.ly - A.ly) * alpha, A.lz + (B.lz - A.lz) * alpha)
    if lookVec.Magnitude < 0.01 then lookVec = Vector3.new(0, 0, -1) end
    
    pcall(function()
        hrp.CFrame = CFrame.lookAt(targetPos, targetPos + lookVec.Unit)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    
    if self.PlayState.TrackedLV and self.PlayState.TrackedLV.Parent and self.PlayState.TrackedLV.Enabled then
        self.PlayState.TrackedLV.Enabled = false
    end
    
    self:UpdatePlaybackPath(elapsed)
end

-- ================= MARKERS =================
function MovementRecorder:CreateMarkerBase(pos, color, nameText, subText)
    local theme = self.UI:GetTheme()
    local model = Instance.new("Model")
    model.Name = "Noclipov_Marker_" .. nameText
    
    local core = Instance.new("Part")
    core.Name = "Core"
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(0.6, 0.6, 0.6)
    core.Position = pos + Vector3.new(0, 2, 0)
    core.Anchored = true; core.CanCollide = false; core.CanQuery = false; core.CanTouch = false
    core.Material = Enum.Material.Neon
    core.Color = color
    core.Transparency = 0.1
    core.Parent = model
    
    local ring = Instance.new("Part")
    ring.Name = "Ring"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.04, 1.6, 1.6)
    ring.Position = core.Position
    ring.Anchored = true; ring.CanCollide = false; ring.CanQuery = false; ring.CanTouch = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = 0.5
    ring.CFrame = CFrame.new(core.Position) * CFrame.Angles(0, 0, math.rad(90))
    ring.Parent = model
    
    local glow = Instance.new("Part")
    glow.Name = "Glow"
    glow.Shape = Enum.PartType.Ball
    glow.Size = Vector3.new(1.4, 1.4, 1.4)
    glow.Position = core.Position
    glow.Anchored = true; glow.CanCollide = false; glow.CanQuery = false; glow.CanTouch = false
    glow.Material = Enum.Material.ForceField
    glow.Color = color
    glow.Transparency = 0.9
    glow.Parent = model
    
    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = 4
    light.Brightness = 0.3
    light.Shadows = false
    light.Parent = core
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 140, 0, 36)
    billboard.StudsOffset = Vector3.new(0, 1.8, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = core
    
    local uiFrame = Instance.new("Frame") 
    uiFrame.Size = UDim2.fromScale(1, 1)
    uiFrame.BackgroundColor3 = theme.BgDarkest
    uiFrame.BackgroundTransparency = 0.15
    uiFrame.Parent = billboard
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = uiFrame
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = color
    uiStroke.Thickness = 1.2
    uiStroke.Transparency = 0.3
    uiStroke.Parent = uiFrame
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -10, 0, 18)
    titleLbl.Position = UDim2.fromOffset(5, 2)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = nameText
    titleLbl.TextColor3 = color
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    titleLbl.Parent = uiFrame
    
    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(1, -10, 0, 12)
    subLbl.Position = UDim2.fromOffset(5, 20)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = subText
    subLbl.TextColor3 = theme.TextMuted
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextSize = 9
    subLbl.Parent = uiFrame

    model.Parent = Workspace
    return { model = model, core = core, ring = ring, glow = glow, light = light, titleLbl = titleLbl, billboardFrame = uiFrame }
end

function MovementRecorder:CreateSavedMarker(recName, pos)
    local col = self.UI:GetTheme().Accent
    self.MarkerParts[recName] = self:CreateMarkerBase(pos, col, recName, "SAVED ROUTE")
end

function MovementRecorder:CreateUnsavedMarker(frames)
    if self.UnsavedMarker and self.UnsavedMarker.model then self.UnsavedMarker.model:Destroy() end
    if not frames or #frames < 1 then return end
    local f = frames[1]
    local pos = Vector3.new(f.px, f.py, f.pz)
    local col = self.UI:GetTheme().Warning
    self.UnsavedMarker = self:CreateMarkerBase(pos, col, "UNSAVED CACHE", "PRESS PLAYBACK HOTKEY")
end

function MovementRecorder:CreateStartMarker(pos)
    if self.StartMarker and self.StartMarker.model then self.StartMarker.model:Destroy() end
    local theme = self.UI:GetTheme()
    local col = theme.Success
    
    local model = Instance.new("Model")
    model.Name = "Noclipov_StartMarker"

    local p = Instance.new("Part")
    p.Name = "Core"
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(0.8, 0.8, 0.8)
    p.Position = pos + Vector3.new(0, 1.5, 0)
    p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
    p.Material = Enum.Material.Neon
    p.Color = col
    p.Transparency = 0.2
    p.Parent = model
    
    local light = Instance.new("PointLight")
    light.Color = col
    light.Range = 5
    light.Brightness = 0.5
    light.Shadows = false
    light.Parent = p

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 110, 0, 24)
    billboard.StudsOffset = Vector3.new(0, 1.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = p

    local uiFrame = Instance.new("Frame")
    uiFrame.Size = UDim2.fromScale(1, 1)
    uiFrame.BackgroundColor3 = theme.BgDarkest
    uiFrame.BackgroundTransparency = 0.15
    uiFrame.Parent = billboard

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = uiFrame

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = col
    uiStroke.Thickness = 1.2
    uiStroke.Transparency = 0.3
    uiStroke.Parent = uiFrame

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.fromScale(1, 1)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "START POINT"
    titleLbl.TextColor3 = col
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.Parent = uiFrame

    model.Parent = Workspace
    self.StartMarker = { model = model, core = p, billboardFrame = uiFrame, titleLbl = titleLbl }
end

function MovementRecorder:ClearMarkers()
    for _, m in pairs(self.MarkerParts) do 
        if m.model then m.model:Destroy() end 
    end
    table.clear(self.MarkerParts)
    if self.UnsavedMarker and self.UnsavedMarker.model then self.UnsavedMarker.model:Destroy(); self.UnsavedMarker = nil end
    if self.StartMarker and self.StartMarker.model then self.StartMarker.model:Destroy(); self.StartMarker = nil end
end

function MovementRecorder:RefreshMarkers()
    self:ClearMarkers()
    if not self.MarkersEnabled then return end

    if self.RecState.Cache then
        -- Строго только кеш, никаких сохраненных маркеров
        self:CreateUnsavedMarker(self.RecState.Cache.frames)
    else
        -- Если кеша нет, рисуем все сохраненные
        local saved = self:GetRecordings()
        for _, rec in ipairs(saved) do
            if rec.firstFrame and rec.firstFrame.px then
                local pos = Vector3.new(rec.firstFrame.px, rec.firstFrame.py, rec.firstFrame.pz)
                self:CreateSavedMarker(rec.name, pos)
            end
        end
    end

    -- Восстанавливаем маркер старта, если идет запись
    if self.RecState.IsRecording and self._RecordingStartPos then
        self:CreateStartMarker(self._RecordingStartPos)
    end
end

-- ================= PLAYBACK PATH (Dotted) =================
function MovementRecorder:ClearPlaybackPath()
    for _, dot in ipairs(self.PlaybackPath.dots) do if dot.Parent then dot:Destroy() end end
    self.PlaybackPath = { dots = {}, active = false }
end

function MovementRecorder:CreatePlaybackPath(frames)
    self:ClearPlaybackPath()
    if not frames or #frames < 2 then return end
    local theme = self.UI:GetTheme()
    local col = theme.Accent
    local total = #frames
    
    local count = 50
    for i = 1, count do
        local idx = math.clamp(math.floor((i - 1) / (count - 1) * (total - 1)) + 1, 1, total)
        local f = frames[idx]
        local p = Instance.new("Part")
        p.Name = "Noclipov_PathDot"
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(0.25, 0.25, 0.25)
        p.Position = Vector3.new(f.px, f.py, f.pz)
        p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
        p.Material = Enum.Material.Neon
        p.Color = col
        p.Transparency = 0.3
        p.Parent = Workspace
        p:SetAttribute("t", f.t)
        table.insert(self.PlaybackPath.dots, p)
    end
    self.PlaybackPath.active = true
end

function MovementRecorder:UpdatePlaybackPath(elapsed)
    if not self.PlaybackPath.active then return end
    
    for _, dot in ipairs(self.PlaybackPath.dots) do
        if dot.Parent then
            local t = dot:GetAttribute("t") or 0
            if elapsed > t then
                local alpha = math.clamp((elapsed - t) / 1.5, 0, 1)
                dot.Transparency = 0.3 + alpha * 0.7
                local s = 0.25 - alpha * 0.15
                dot.Size = Vector3.new(s, s, s)
            else
                dot.Transparency = 0.2 + (0.5 + 0.5 * math.sin(self._animTime * math.pi * 3 + t * 2)) * 0.2
                dot.Size = Vector3.new(0.25, 0.25, 0.25)
            end
        end
    end
end

-- ================= ANIMATIONS & EVENTS =================
function MovementRecorder:_SetupEvents()
    self:AddConn(RunService.Heartbeat:Connect(function(dt)
        if self.RecState.IsRecording then self:UpdateRecording(dt) end
        if self.PlayState.Active then self:UpdatePlayback(dt) end
        
        if self.MarkersEnabled then
            self._animTime = self._animTime + dt
            local now = self._animTime
            
            local function animMarker(m)
                if m and m.core and m.core.Parent then
                    local baseY = m.core:GetAttribute("BaseY") or m.core.Position.Y
                    if not m.core:GetAttribute("BaseY") then m.core:SetAttribute("BaseY", baseY) end
                    m.core.Position = Vector3.new(m.core.Position.X, baseY + math.sin(now * 2) * 0.1, m.core.Position.Z)
                    if m.glow then m.glow.Position = m.core.Position end
                    if m.ring then m.ring.CFrame = CFrame.new(m.core.Position) * CFrame.Angles(0, now * 2, math.rad(90)) end
                    local scale = 0.6 + math.sin(now * 3) * 0.03
                    m.core.Size = Vector3.new(scale, scale, scale)
                end
            end
            
            for _, m in pairs(self.MarkerParts) do animMarker(m) end
            animMarker(self.UnsavedMarker)
            
            if self.StartMarker and self.StartMarker.core and self.StartMarker.core.Parent then
                local scale = 0.8 + math.sin(now * 5) * 0.15
                self.StartMarker.core.Size = Vector3.new(scale, scale, scale)
            end
        end
    end))

    self:AddConn(LocalPlayer.CharacterRemoving:Connect(function()
        self:StopPlayback(true)
        self:StopRecording(false)
    end))
    
    self:AddConn(LocalPlayer.CharacterAdded:Connect(function()
        self:StopPlayback(true)
        self:StopRecording(false)
    end))
end

return MovementRecorder