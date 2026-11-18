--[[ ════════════════════════════════════════════════════════════
  Noclipov · movement (MovementRecorder) · v3.0
  Запись и воспроизведение маршрута персонажа (30 Гц), маркеры, JSON-файлы.
  API: Recorder.new(UI, opts?) → экземпляр      (UI: Noclipov UI; нужен :GetTheme(), опц. .GUI.ThemeSystem)
    запись     :StartRecording() :StopRecording(saveToCache) :UpdateRecording(dt)
    воспроизв. :PlayUnsaved() :StartPlayback(name, frames, duration) :StopPlayback(silent)
    файлы      :GetRecordings(force?) :SaveToFile(name, frames, duration) :DeleteFile(path)
               :ReadFirstFrame(path) :EnsureFolder()
    маркеры    :SetMarkersEnabled(bool) :RefreshMarkers()
    состояние  :IsRecording() :HasCache() :IsPlaying() :GetMapName() · PlayState.Speed (множитель)
    :Destroy()
  opts: BaseFolder = "Noclipov/evade/movement"
  Формат кадра (совместим с v1/v2): { t, px,py,pz, vx,vy,vz, lx,ly,lz }
════════════════════════════════════════════════════════════ ]]

-- [1] SERVICES
local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local Players     = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- [2] CONFIG
local RECORD_STEP     = 1 / 30
local TRIM_THRESHOLD  = 1.0  -- studs: статичные хвосты записи обрезаются
local CACHE_TTL       = 10   -- сек: кэш списка файлов (сбрасывается при Save/Delete)
local PATH_DOTS       = 50
local DOT_FADE        = 1.5
local MAX_START_SPEED = 2    -- макс. скорость при старте записи (studs/s)

local FALLBACK_THEME = {
	Accent = Color3.fromRGB(140, 100, 255), Success = Color3.fromRGB(80, 220, 120),
	Warning = Color3.fromRGB(255, 190, 60), BgDarkest = Color3.fromRGB(12, 12, 16),
	TextMuted = Color3.fromRGB(150, 150, 160),
}

-- [3] HELPERS
local function getMapName(): string
	local ok, name = pcall(function()
		local map = Workspace:FindFirstChild("Map")
		return map and map:GetAttribute("MapName")
	end)
	if ok and type(name) == "string" and name ~= "" then
		return (name:gsub("[^%w_%-]", "_"))
	end
	return "Unknown"
end

local function char(): (Model?, Humanoid?, BasePart?)
	local c = LocalPlayer.Character
	return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local function dist2(a, b): number
	local dx, dy, dz = a.px - b.px, a.py - b.py, a.pz - b.pz
	return dx * dx + dy * dy + dz * dz
end

-- Обрезка неподвижного начала/конца без лишних аллокаций (кадры правятся на месте)
local function trimStatic(frames, threshold: number)
	local n = #frames
	if n < 3 then return frames end
	local th2 = threshold * threshold

	local first, moved = 1, false
	for i = 2, n do
		if dist2(frames[i], frames[1]) > th2 then moved = true break end
		first = i
	end
	if not moved then return {} end

	local last = n
	for i = n - 1, 1, -1 do
		if dist2(frames[i], frames[n]) > th2 then break end
		last = i
	end
	if last == n or last <= first + 1 then last = n end

	if first == 1 and last == n then return frames end
	local offset = first > 1 and frames[first].t or 0
	local out = table.create(last - first + 1)
	for i = first, last do
		local f = frames[i]
		f.t -= offset
		out[#out + 1] = f
	end
	return out
end

local Fs = {}
function Fs.ensure(path: string)
	if type(isfolder) ~= "function" or type(makefolder) ~= "function" then return end
	local acc = ""
	for part in path:gmatch("[^/\\]+") do
		acc = acc == "" and part or (acc .. "/" .. part)
		if not isfolder(acc) then pcall(makefolder, acc) end
	end
end
function Fs.readJson(path: string): any?
	if type(readfile) ~= "function" then return nil end
	local ok, content = pcall(readfile, path)
	if not ok or not content then return nil end
	local okDecode, data = pcall(HttpService.JSONDecode, HttpService, content)
	return okDecode and data or nil
end

-- Универсальный «отключатель»: connection | {Disconnect} | function
local function release(x)
	pcall(function()
		if typeof(x) == "RBXScriptConnection" then x:Disconnect()
		elseif type(x) == "table" and x.Disconnect then x:Disconnect()
		elseif type(x) == "function" then x() end
	end)
end

-- [4] MARKER
-- kind = "full"  : шар + кольцо + свечение + подпись (SAVED / UNSAVED)
-- kind = "start" : одна пульсирующая сфера с подписью START POINT
local Marker = {}
Marker.__index = Marker

local function part(parent: Instance, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end

function Marker.new(pos: Vector3, role: string, theme, title: string, sub: string?, kind: string)
	local color = theme[role] or FALLBACK_THEME[role]
	local full = kind == "full"
	local self = setmetatable({ role = role, kind = kind }, Marker)

	local model = Instance.new("Model")
	model.Name = (full and "Noclipov_Marker_" .. title) or "Noclipov_StartMarker"

	local lift = full and 2 or 1.5
	self.basePos = pos + Vector3.new(0, lift, 0)
	self.baseSize = full and 0.6 or 0.8

	self.core = part(model, {
		Name = "Core", Shape = Enum.PartType.Ball, Size = Vector3.one * self.baseSize, Position = self.basePos,
		Material = Enum.Material.Neon, Color = color, Transparency = full and 0.1 or 0.2,
	})
	if full then
		self.ring = part(model, {
			Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.04, 1.6, 1.6),
			CFrame = CFrame.new(self.basePos) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.Neon, Color = color, Transparency = 0.5,
		})
		self.glow = part(model, {
			Name = "Glow", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.4, Position = self.basePos,
			Material = Enum.Material.ForceField, Color = color, Transparency = 0.9,
		})
	end

	self.light = Instance.new("PointLight")
	self.light.Color, self.light.Range, self.light.Brightness, self.light.Shadows = color, full and 4 or 5, full and 0.3 or 0.5, false
	self.light.Parent = self.core

	local board = Instance.new("BillboardGui")
	board.Size = full and UDim2.fromOffset(140, 36) or UDim2.fromOffset(110, 24)
	board.StudsOffset = Vector3.new(0, full and 1.8 or 1.5, 0)
	board.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = theme.BgDarkest or FALLBACK_THEME.BgDarkest
	frame.BackgroundTransparency = 0.15
	frame.Parent = board
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness, stroke.Transparency = color, 1.2, 0.3
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = title
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextSize = full and 12 or 11
	if full then
		label.Size, label.Position = UDim2.new(1, -10, 0, 18), UDim2.fromOffset(5, 2)
		label.TextTruncate = Enum.TextTruncate.AtEnd
		local subLbl = Instance.new("TextLabel")
		subLbl.Size, subLbl.Position = UDim2.new(1, -10, 0, 12), UDim2.fromOffset(5, 20)
		subLbl.BackgroundTransparency = 1
		subLbl.Text = sub or ""
		subLbl.TextColor3 = theme.TextMuted or FALLBACK_THEME.TextMuted
		subLbl.Font = Enum.Font.Gotham
		subLbl.TextSize = 9
		subLbl.Parent = frame
	else
		label.Size = UDim2.fromScale(1, 1)
	end
	label.Parent = frame

	board.Parent = self.core
	model.Parent = Workspace

	self.model, self.titleLbl, self.billboardFrame, self.stroke = model, label, frame, stroke
	return self
end

function Marker:Recolor(color: Color3)
	if self.core.Parent then self.core.Color = color end
	if self.ring then self.ring.Color = color end
	if self.glow then self.glow.Color = color end
	self.light.Color = color
	self.stroke.Color = color
	self.titleLbl.TextColor3 = color
end

function Marker:Animate(now: number)
	if not self.core.Parent then return end
	if self.kind == "full" then
		local p = self.basePos + Vector3.new(0, math.sin(now * 2) * 0.1, 0)
		local s = 0.6 + math.sin(now * 3) * 0.03
		self.core.Size = Vector3.one * s
		self.core.Position = p
		self.glow.Position = p
		self.ring.CFrame = CFrame.new(p) * CFrame.Angles(0, now * 2, math.rad(90))
	else
		self.core.Size = Vector3.one * (0.8 + math.sin(now * 5) * 0.15)
	end
end

function Marker:Destroy()
	self.model:Destroy()
end

-- [5] CLASS
local Recorder = { Version = "3.0" }
Recorder.__index = Recorder

function Recorder.new(UI, opts)
	opts = opts or {}
	local self = setmetatable({
		UI = UI,
		BaseFolder = opts.BaseFolder or "Noclipov/evade/movement",
		RecState = { IsRecording = false, StartTime = 0, Frames = {}, FrameAccum = 0, Cache = nil },
		PlayState = { Active = false, Frames = nil, Duration = 0, Elapsed = 0, Started = false, Cursor = 1, RecName = nil, Speed = 1.0 },
		MarkerParts = {},
		UnsavedMarker = nil,
		StartMarker = nil,
		PlaybackPath = { dots = {}, done = 0, active = false },
		MarkersEnabled = true,
		_RecordingStartPos = nil,
		_recordingsCache = nil,
		_cacheTime = 0,
		_animTime = 0,
		_connections = {},
		_destroyed = false,
	}, Recorder)

	self:_setupEvents()
	self:_setupThemeListener()
	return self
end

function Recorder:AddConn(conn)
	table.insert(self._connections, conn)
	return conn
end

function Recorder:_theme()
	local ok, t = pcall(function() return self.UI:GetTheme() end)
	if ok and type(t) == "table" then return t end
	return FALLBACK_THEME
end

function Recorder:Destroy()
	self._destroyed = true -- блокирует RefreshMarkers из Stop*()
	for _, c in ipairs(self._connections) do release(c) end
	table.clear(self._connections)
	self:StopPlayback(true)
	self:StopRecording(false)
	self:ClearMarkers()
	self:ClearPlaybackPath()
end

-- ── Тема ────────────────────────────────────────────────────
function Recorder:_setupThemeListener()
	local ts = self.UI and self.UI.GUI and self.UI.GUI.ThemeSystem
	if not ts or not ts.Subscribe then return end
	self:AddConn(ts.Subscribe(function(theme)
		local accent = theme.Accent or FALLBACK_THEME.Accent
		for _, d in ipairs(self.PlaybackPath.dots) do
			if d.part.Parent then d.part.Color = accent end
		end
		for _, m in pairs(self.MarkerParts) do m:Recolor(accent) end
		if self.StartMarker then self.StartMarker:Recolor(theme.Success or FALLBACK_THEME.Success) end
		if self.UnsavedMarker then self.UnsavedMarker:Recolor(theme.Warning or FALLBACK_THEME.Warning) end
	end))
end

-- ── Состояние ───────────────────────────────────────────────
function Recorder:GetMapName() return getMapName() end
function Recorder:IsRecording() return self.RecState.IsRecording end
function Recorder:HasCache() return self.RecState.Cache ~= nil end
function Recorder:IsPlaying() return self.PlayState.Active end

-- ── Файлы ───────────────────────────────────────────────────
function Recorder:_mapFolder(): string
	return self.BaseFolder .. "/" .. getMapName()
end

function Recorder:EnsureFolder()
	pcall(Fs.ensure, self:_mapFolder())
end

function Recorder:GetRecordings(forceRefresh: boolean?)
	local now = os.clock()
	if not forceRefresh and self._recordingsCache and now - self._cacheTime < CACHE_TTL then
		return self._recordingsCache
	end

	self:EnsureFolder()
	local folder = self:_mapFolder()
	local files = {}
	if type(listfiles) == "function" and type(isfolder) == "function" and isfolder(folder) then
		pcall(function() files = listfiles(folder) end)
	end

	local list = {}
	for _, path in ipairs(files) do
		if type(path) == "string" and path:match("%.json$") then
			local d = Fs.readJson(path)
			if d then
				list[#list + 1] = {
					name = path:match("([^/\\]+)%.json$") or "unknown", path = path,
					duration = d.duration or 0, frameCount = d.frameCount or #(d.frames or {}),
					mapName = d.mapName or "", createdAt = d.createdAt, firstFrame = d.frames and d.frames[1],
				}
			end
		end
	end
	table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)

	self._recordingsCache, self._cacheTime = list, now
	return list
end

function Recorder:SaveToFile(name: string, frames, duration: number): boolean
	if type(writefile) ~= "function" then return false end
	self:EnsureFolder()
	local safe = tostring(name):gsub('[/\\:*?"<>|]', "_")
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, {
		version = 1, name = safe, mapName = getMapName(), createdAt = os.time(),
		duration = duration, frameCount = #frames, frames = frames,
	})
	if not ok then return false end
	local saved = pcall(writefile, self:_mapFolder() .. "/" .. safe .. ".json", encoded)
	if saved then self._recordingsCache = nil end
	return saved
end

function Recorder:DeleteFile(path: string)
	if type(delfile) == "function" then pcall(delfile, path) end
	self._recordingsCache = nil
end

function Recorder:ReadFirstFrame(path: string)
	local d = Fs.readJson(path)
	local f = d and d.frames and d.frames[1]
	if not (f and f.px and f.py and f.pz) then return nil end
	return Vector3.new(f.px, f.py, f.pz), d
end

-- ── Запись ──────────────────────────────────────────────────
function Recorder:CanStartRecording()
	local c, hum, hrp = char()
	if not c then return false, "No character" end
	if not hum or not hrp then return false, "No humanoid" end
	if hum.FloorMaterial == Enum.Material.Air then return false, "Player in air" end
	if hrp.AssemblyLinearVelocity.Magnitude > MAX_START_SPEED then return false, "Player is moving" end
	return true
end

function Recorder:StartRecording()
	if self.RecState.IsRecording or self.PlayState.Active then return false, "Busy" end
	local ok, reason = self:CanStartRecording()
	if not ok then return false, reason end

	local rs = self.RecState
	rs.IsRecording, rs.StartTime, rs.Frames, rs.FrameAccum, rs.Cache = true, os.clock(), {}, 0, nil

	local _, _, hrp = char()
	self._RecordingStartPos = hrp and hrp.Position
	self:RefreshMarkers()
	return true
end

function Recorder:StopRecording(saveToCache: boolean?)
	local rs = self.RecState
	if not rs.IsRecording then return end
	rs.IsRecording = false
	self._RecordingStartPos = nil

	local frames = rs.Frames
	rs.Frames, rs.FrameAccum = {}, 0

	if not (saveToCache and #frames >= 2) then
		rs.Cache = nil
		self:RefreshMarkers()
		return false
	end

	local trimmed = trimStatic(frames, TRIM_THRESHOLD)
	if #trimmed < 2 then
		rs.Cache = nil
		self:RefreshMarkers()
		return false, "Too short"
	end

	local duration = trimmed[#trimmed].t
	rs.Cache = { frames = trimmed, duration = duration, frameCount = #trimmed }
	self:RefreshMarkers()
	return true, duration
end

function Recorder:UpdateRecording(dt: number)
	local rs = self.RecState
	if not rs.IsRecording then return end
	rs.FrameAccum += dt
	if rs.FrameAccum < RECORD_STEP then return end
	rs.FrameAccum -= RECORD_STEP

	local _, _, hrp = char()
	if not hrp then return end
	local cf, v = hrp.CFrame, hrp.AssemblyLinearVelocity
	local look = cf.LookVector
	rs.Frames[#rs.Frames + 1] = {
		t = os.clock() - rs.StartTime, px = cf.X, py = cf.Y, pz = cf.Z,
		vx = v.X, vy = v.Y, vz = v.Z, lx = look.X, ly = look.Y, lz = look.Z,
	}
end

-- ── Воспроизведение ─────────────────────────────────────────
function Recorder:PlayUnsaved()
	local cache = self.RecState.Cache
	if not cache then return false, "No cache" end
	return self:StartPlayback("Unsaved", cache.frames, cache.duration)
end

-- Пока есть несохранённый кэш, разрешено запускать только его
function Recorder:StartPlayback(recName: string, frames, duration: number?)
	if self.RecState.Cache and recName ~= "Unsaved" then
		return false, "You have an unsaved cache. Save or cancel it first!"
	end
	if self.PlayState.Active then self:StopPlayback() end
	if not frames or #frames < 2 or self.RecState.IsRecording then return false end

	local c, hum, hrp = char()
	if not c or not hum or not hrp or hum.Health <= 0 then return false end

	local ps = self.PlayState
	ps.Saved = {
		AutoRotate = hum.AutoRotate, WalkSpeed = hum.WalkSpeed, JumpPower = hum.JumpPower,
		JumpHeight = hum.JumpHeight, HrpCollide = hrp.CanCollide,
	}

	hum.AutoRotate, hum.WalkSpeed = false, 0
	pcall(function() hum.JumpPower, hum.JumpHeight = 0, 0 end)
	hrp.CanCollide = false

	ps.TrackedLV = nil
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("LinearVelocity") and d.Attachment0 and d.RelativeTo == Enum.ActuatorRelativeTo.World then
			ps.TrackedLV, ps.Saved.LVEnabled = d, d.Enabled
			d.Enabled = false
			break
		end
	end

	local f1 = frames[1]
	local p1 = Vector3.new(f1.px, f1.py, f1.pz)
	local look = Vector3.new(f1.lx, f1.ly, f1.lz)
	if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end
	pcall(function()
		hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		hrp.CFrame = CFrame.lookAt(p1, p1 + look.Unit)
	end)

	ps.Active, ps.RecName, ps.Frames = true, recName, frames
	ps.Duration = math.max(duration or frames[#frames].t, 0.01)
	ps.Speed = ps.Speed or 1.0
	ps.Elapsed, ps.Started, ps.Cursor = 0, false, 1

	self:CreatePlaybackPath(frames)
	self:RefreshMarkers()
	return true
end

function Recorder:StopPlayback(silent: boolean?)
	local ps = self.PlayState
	if not ps.Active then return end
	ps.Active = false

	local _, hum, hrp = char()
	local s = ps.Saved
	if s then
		if hum then
			hum.AutoRotate = s.AutoRotate
			hum.WalkSpeed = s.WalkSpeed
			pcall(function() hum.JumpPower, hum.JumpHeight = s.JumpPower, s.JumpHeight end)
		end
		if hrp then hrp.CanCollide = s.HrpCollide end
		if ps.TrackedLV and ps.TrackedLV.Parent and s.LVEnabled ~= nil then ps.TrackedLV.Enabled = s.LVEnabled end
	end
	ps.Saved, ps.TrackedLV, ps.Frames, ps.RecName = nil, nil, nil, nil

	self:ClearPlaybackPath()
	self:RefreshMarkers()
end

function Recorder:UpdatePlayback(dt: number)
	local ps = self.PlayState
	if not ps.Active then return end

	local _, hum, hrp = char()
	local frames = ps.Frames
	if not hrp or not hum or hum.Health <= 0 or not frames or #frames < 2 then
		return self:StopPlayback()
	end

	-- Накапливаем время (смена Speed на лету не даёт скачка позиции)
	if ps.Started then ps.Elapsed += dt * ps.Speed else ps.Started = true end
	local elapsed = ps.Elapsed
	if elapsed >= ps.Duration then return self:StopPlayback() end

	-- Курсор только движется вперёд: O(1) вместо бинарного поиска каждый кадр
	local n, i = #frames, ps.Cursor
	while i < n - 1 and frames[i + 1].t <= elapsed do i += 1 end
	ps.Cursor = i

	local A, B = frames[i], frames[i + 1]
	local span = B.t - A.t
	local a = span > 0 and math.clamp((elapsed - A.t) / span, 0, 1) or 0

	local pos = Vector3.new(A.px + (B.px - A.px) * a, A.py + (B.py - A.py) * a, A.pz + (B.pz - A.pz) * a)
	local look = Vector3.new(A.lx + (B.lx - A.lx) * a, A.ly + (B.ly - A.ly) * a, A.lz + (B.lz - A.lz) * a)
	if look.Magnitude < 0.01 then look = Vector3.new(0, 0, -1) end

	hrp.CFrame = CFrame.lookAt(pos, pos + look.Unit)
	hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	if ps.TrackedLV and ps.TrackedLV.Parent and ps.TrackedLV.Enabled then ps.TrackedLV.Enabled = false end

	self:UpdatePlaybackPath(elapsed)
end

-- ── Маркеры ─────────────────────────────────────────────────
function Recorder:CreateSavedMarker(recName: string, pos: Vector3)
	self.MarkerParts[recName] = Marker.new(pos, "Accent", self:_theme(), recName, "SAVED ROUTE", "full")
end

function Recorder:CreateUnsavedMarker(frames)
	if self.UnsavedMarker then self.UnsavedMarker:Destroy() self.UnsavedMarker = nil end
	if not frames or #frames < 1 then return end
	local f = frames[1]
	self.UnsavedMarker = Marker.new(Vector3.new(f.px, f.py, f.pz), "Warning", self:_theme(),
		"UNSAVED CACHE", "PRESS PLAYBACK HOTKEY", "full")
end

function Recorder:CreateStartMarker(pos: Vector3)
	if self.StartMarker then self.StartMarker:Destroy() end
	self.StartMarker = Marker.new(pos, "Success", self:_theme(), "START POINT", nil, "start")
end

function Recorder:ClearMarkers()
	for _, m in pairs(self.MarkerParts) do m:Destroy() end
	table.clear(self.MarkerParts)
	if self.UnsavedMarker then self.UnsavedMarker:Destroy() self.UnsavedMarker = nil end
	if self.StartMarker then self.StartMarker:Destroy() self.StartMarker = nil end
end

function Recorder:SetMarkersEnabled(enabled: boolean)
	self.MarkersEnabled = enabled
	if enabled then self:RefreshMarkers() else self:ClearMarkers() end
end

function Recorder:RefreshMarkers()
	if self._destroyed then return end
	self:ClearMarkers()
	if not self.MarkersEnabled then return end

	if self.RecState.Cache then
		self:CreateUnsavedMarker(self.RecState.Cache.frames) -- при наличии кэша показываем только его
	else
		for _, rec in ipairs(self:GetRecordings()) do
			local f = rec.firstFrame
			if f and f.px then self:CreateSavedMarker(rec.name, Vector3.new(f.px, f.py, f.pz)) end
		end
	end

	if self.RecState.IsRecording and self._RecordingStartPos then
		self:CreateStartMarker(self._RecordingStartPos)
	end
end

-- ── Пунктир маршрута ────────────────────────────────────────
function Recorder:ClearPlaybackPath()
	if self._pathFolder then self._pathFolder:Destroy() self._pathFolder = nil end
	self.PlaybackPath = { dots = {}, done = 0, active = false }
end

function Recorder:CreatePlaybackPath(frames)
	self:ClearPlaybackPath()
	if not frames or #frames < 2 then return end

	local folder = Instance.new("Folder")
	folder.Name = "Noclipov_PlaybackPath"
	local color = self:_theme().Accent or FALLBACK_THEME.Accent
	local total, dots = #frames, table.create(PATH_DOTS)

	for i = 1, PATH_DOTS do
		local idx = math.clamp(math.floor((i - 1) / (PATH_DOTS - 1) * (total - 1)) + 1, 1, total)
		local f = frames[idx]
		dots[i] = {
			t = f.t,
			part = part(folder, {
				Name = "Noclipov_PathDot", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.25,
				Position = Vector3.new(f.px, f.py, f.pz), Material = Enum.Material.Neon, Color = color, Transparency = 0.3,
			}),
		}
	end
	folder.Parent = Workspace
	self._pathFolder = folder
	self.PlaybackPath = { dots = dots, done = 0, active = true }
end

function Recorder:UpdatePlaybackPath(elapsed: number)
	local P = self.PlaybackPath
	if not P.active then return end
	local dots = P.dots

	-- Полностью погасшие точки (они идут подряд с начала) больше не трогаем
	while P.done < #dots and elapsed - dots[P.done + 1].t >= DOT_FADE do
		P.done += 1
		local p = dots[P.done].part
		p.Transparency, p.Size = 1, Vector3.one * 0.1
	end

	local pulseBase = self._animTime * math.pi * 3
	for i = P.done + 1, #dots do
		local d = dots[i]
		if elapsed > d.t then
			local a = math.clamp((elapsed - d.t) / DOT_FADE, 0, 1)
			d.part.Transparency = 0.3 + a * 0.7
			d.part.Size = Vector3.one * (0.25 - a * 0.15)
		else
			d.part.Transparency = 0.2 + (0.5 + 0.5 * math.sin(pulseBase + d.t * 2)) * 0.2
		end
	end
end

-- ── События ─────────────────────────────────────────────────
function Recorder:_setupEvents()
	self:AddConn(RunService.Heartbeat:Connect(function(dt)
		self._animTime += dt
		if self.RecState.IsRecording then self:UpdateRecording(dt) end
		if self.PlayState.Active then self:UpdatePlayback(dt) end

		if self.MarkersEnabled then
			local now = self._animTime
			for _, m in pairs(self.MarkerParts) do m:Animate(now) end
			if self.UnsavedMarker then self.UnsavedMarker:Animate(now) end
			if self.StartMarker then self.StartMarker:Animate(now) end
		end
	end))

	local function reset()
		self:StopPlayback(true)
		self:StopRecording(false)
	end
	self:AddConn(LocalPlayer.CharacterRemoving:Connect(reset))
	self:AddConn(LocalPlayer.CharacterAdded:Connect(reset))
end

return Recorder
