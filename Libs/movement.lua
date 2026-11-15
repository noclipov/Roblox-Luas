-- ============================================================
-- MovementRecorder.lua (Updated)
-- ============================================================
local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local MovementRecorder = {}
MovementRecorder.__index = MovementRecorder

local RECORD_HZ = 1 / 30
local PLAY_RADIUS = 10

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
    self.PlaybackPath = { parts = {}, active = false }
    
    self._connections = {}
    self:_SetupEvents()
    
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

-- ================= EXPOSED HELPERS =================
function MovementRecorder:GetMapName()
    return GetMapName()
end

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

function MovementRecorder:GetRecordings()
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
                        createdAt = decoded.createdAt
                    })
                end
            end
        end
    end
    table.sort(list, function(a, b) return (a.name or ""):lower() < (b.name or ""):lower() end)
    return list
end

function MovementRecorder:SaveToFile(name, frames, duration)
    self:EnsureFolder()
    local data = {version=1, name=name, mapName=GetMapName(), createdAt=os.time(), duration=duration, frameCount=#frames, frames=frames}
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok or not encoded then return false end
    return pcall(writefile, self.BaseFolder .. "/" .. GetMapName() .. "/" .. name .. ".json", encoded)
end

function MovementRecorder:DeleteFile(path)
    pcall(delfile, path)
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
    
    self:RefreshMarkers()
    return true
end

function MovementRecorder:StopRecording(saveToCache)
    if not self.RecState.IsRecording then return end
    self.RecState.IsRecording = false
    
    local frames = self.RecState.Frames
    self.RecState.Frames = {}
    self.RecState.FrameAccum = 0
    
    if saveToCache and #frames >= 2 then
        local trimmed = TrimLeadingStatic(frames, 1.0)
        if #trimmed > 0 then trimmed = TrimTrailingStatic(trimmed, 1.0) end
        
        if #trimmed < 2 then
            self.RecState.Cache = nil
            return false, "Too short"
        end
        
        local newDuration = trimmed[#trimmed].t
        self.RecState.Cache = { frames = trimmed, duration = newDuration, frameCount = #trimmed }
        self:CreateUnsavedMarker(trimmed)
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
function MovementRecorder:StartPlayback(recName, frames, duration)
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
    
    self:CreateStartMarker(p1)
    self:CreatePlaybackPath(frames, 50)
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
    self:DestroyStartMarker()
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

-- ================= PATH & MARKERS =================
function MovementRecorder:ClearPlaybackPath()
    for _, p in ipairs(self.PlaybackPath.parts) do pcall(function() p:Destroy() end) end
    table.clear(self.PlaybackPath.parts)
    self.PlaybackPath.active = false
end

function MovementRecorder:CreatePlaybackPath(frames, count)
    self:ClearPlaybackPath()
    if not frames or #frames < 2 then return end
    count = count or 50
    local total = #frames
    local theme = self.UI:GetTheme()
    
    for i = 1, count do
        local idx = math.clamp(math.floor((i - 1) / (count - 1) * (total - 1)) + 1, 1, total)
        local f = frames[idx]
        local p = Instance.new("Part")
        p.Name = "Noclipov_PlaybackPath_" .. i
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(0.22, 0.22, 0.22)
        p.Position = Vector3.new(f.px, f.py, f.pz)
        p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
        p.Material = Enum.Material.Neon
        p.Color = theme.Accent
        p.Transparency = 0.7
        p.Parent = Workspace
        p:SetAttribute("t", f.t)
        table.insert(self.PlaybackPath.parts, p)
    end
    self.PlaybackPath.active = true
end

function MovementRecorder:UpdatePlaybackPath(elapsed)
    if not self.PlaybackPath.active then return end
    local now = os.clock()
    for _, p in ipairs(self.PlaybackPath.parts) do
        if p.Parent then
            local t = p:GetAttribute("t") or 0
            if elapsed > t then
                local alpha = math.clamp((elapsed - t) / 1.2, 0, 1)
                p.Transparency = 0.7 + alpha * 0.3
                local s = 0.22 - alpha * 0.12
                p.Size = Vector3.new(s, s, s)
            else
                p.Transparency = 0.55 + (0.5 + 0.5 * math.sin(now * math.pi * 3 + t * 2)) * 0.15
            end
        end
    end
end

function MovementRecorder:ClearMarkers()
    for name, m in pairs(self.MarkerParts) do self:DestroyMarkerVisual(m) end
    table.clear(self.MarkerParts)
    if self.UnsavedMarker then self:DestroyMarkerVisual(self.UnsavedMarker); self.UnsavedMarker = nil end
    if self.StartMarker then self:DestroyMarkerVisual(self.StartMarker); self.StartMarker = nil end
end

function MovementRecorder:DestroyMarkerVisual(m)
    if not m then return end
    for _, key in ipairs({"root","halo","ring","ringInner","ringOuter","crystal","cap","glow"}) do
        if m[key] then pcall(function() m[key]:Destroy() end) end
    end
    if m.billboard then pcall(function() m.billboard:Destroy() end) end
end

function MovementRecorder:CreateStartMarker(pos)
    if self.StartMarker then self:DestroyMarkerVisual(self.StartMarker) end
    local p = Instance.new("Part")
    p.Name = "Noclipov_StartMarker"
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(1, 1, 1)
    p.Position = pos + Vector3.new(0, 1, 0)
    p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
    p.Material = Enum.Material.Neon
    p.Color = self.UI:GetTheme().Success
    p.Parent = Workspace
    self.StartMarker = { root = p, pos = pos }
end

function MovementRecorder:DestroyStartMarker()
    if self.StartMarker then
        self:DestroyMarkerVisual(self.StartMarker)
        self.StartMarker = nil
    end
end

function MovementRecorder:CreateUnsavedMarker(frames)
    if self.UnsavedMarker then self:DestroyMarkerVisual(self.UnsavedMarker) end
    if not frames or #frames < 1 then return end
    local f = frames[1]
    local pos = Vector3.new(f.px, f.py, f.pz)
    
    local p = Instance.new("Part")
    p.Name = "Noclipov_UnsavedMarker"
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(1, 1, 1)
    p.Position = pos + Vector3.new(0, 1, 0)
    p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
    p.Material = Enum.Material.Neon
    p.Color = self.UI:GetTheme().Warning
    p.Parent = Workspace
    self.UnsavedMarker = { root = p, pos = pos }
end

function MovementRecorder:RefreshMarkers()
    self:ClearMarkers()
end

-- ================= EVENTS =================
function MovementRecorder:_SetupEvents()
    self:AddConn(RunService.Heartbeat:Connect(function(dt)
        if self.RecState.IsRecording then self:UpdateRecording(dt) end
        if self.PlayState.Active then self:UpdatePlayback(dt) end
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