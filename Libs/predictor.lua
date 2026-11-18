--[[
    local Predictor = require(path)

    local p = Predictor.Track(player)
    local p = Predictor.Track(player, { Horizon = 1.5, Color = Color3.new(0, 1, 1), DangerColor = Color3.new(1, 0, 0) })
    p:Destroy()

    local pos, result = Predictor.PredictPosition(player, 2)
    result.Future.Position, result.Landing

Track(target, options): target — Player | Model | Humanoid | BasePart | function.
Свой источник состояния: Track({ GetState = function() return { Position = v3, Velocity = v3 } end }).
Свой менеджер: Predictor.new({ Color, DangerColor, Parent, AutoUpdate, Defaults }):
    :Add([id,] options) :Get(id) :Remove(id) :SetEnabled(id, bool) :SetColors(colors [, id]) :Update(dt) :Destroy()
Экземпляр: .Result, :PositionAt(t), :SetOptions(patch), :SetColors(colors), :SetEnabled(bool), :IsVisible(), :Destroy()

Mode: "Walk" (по умолчанию с target) | "Ballistic" (по умолчанию с GetState) | "Linear"

Опции [по умолчанию]:
    Horizon [3]            на сколько секунд вперёд считать позицию
    UntilLanding           если цель в воздухе — досчитать путь до земли [Walk, Ballistic: true]
    MaxAirTime [8]         предел для UntilLanding
    Step [0.05]            шаг симуляции
    Gravity                "World" | число | Vector3 | false
    Acceleration, Drag     Vector3 | function(pos, vel, t) -> Vector3; сопротивление 1/сек
    Bounces, Restitution [0.5], Friction [0.2]
    Radius [0]             > 0: Spherecast вместо Raycast
    Slide                  скользить вдоль стен [Walk]
    GroundSnap, GroundOffset   прилипание к земле [Walk]
    LandingOnly            показывать только при наличии приземления
    ShowOnMiss             показывать конец пути без приземления [Walk, Linear]
    MinDist                не показывать, если цель почти не двигается
    DangerTime [2]         за сколько секунд до земли начинается смена цвета
    Interval [0]           пересчёт не чаще раза в N секунд
    VelocitySmooth [0]     сглаживание скорости, сек
    VelocitySource         "Physics" | "Intent"
    Ignore, CollisionGroup, OnResult(result, inst)
    Color                  основной цвет
    DangerColor            необязательно; false — выключить
    Visual                 { Marker, Trail, Beacon, Light, Future, TrailCount, TrailStyle = "Dots" | "Line", Scale }

Result: Points, Times, Length, Extent, Hit, Kind, Position, Normal, Time, Bounces,
    Future { Position, Normal, Time, Grounded }, Landing { Position, Normal, Time, HitPart }
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Predictor = { Version = "2.1" }
Predictor.__index = Predictor

local Prediction = {}
Prediction.__index = Prediction

export type State = {
	Position: Vector3,
	Velocity: Vector3,
	Acceleration: Vector3?,
	Ignore: { Instance }?,
	Radius: number?,
	GroundOffset: number?,
}

export type Point = {
	Position: Vector3,
	Normal: Vector3,
	Time: number,
	Grounded: boolean?,
	HitPart: BasePart?,
}

export type Result = {
	Points: { Vector3 },
	Times: { number },
	Cumulative: { number },
	Length: number,
	Extent: number,
	Hit: boolean,
	Kind: string,
	Position: Vector3,
	Normal: Vector3,
	Time: number,
	Bounces: number,
	Future: Point,
	Landing: Point?,
	HitPart: BasePart?,
	HitMaterial: Enum.Material?,
}

local MAX_STEPS = 400
local GROUND_Y = 0.5
local SNAP_RISE = 20
local REST_SPEED = 1.5
local FADE_IN, FADE_OUT = 10, 14
local SMOOTH, SNAP_DIST = 18, 30
local BEACON_HEIGHT = 20
local GRACE = 0.25
local AXIS_FIX = CFrame.Angles(0, 0, math.rad(90))

local DEFAULT_COLORS = { Color = Color3.new(1, 1, 1), DangerColor = false }

local BASE = {
	Horizon = 3,
	Step = 0.05,
	MaxAirTime = 8,
	UntilLanding = false,
	Drag = 0,
	Bounces = 0,
	Restitution = 0.5,
	Friction = 0.2,
	Radius = 0,
	DangerTime = 2,
	Interval = 0,
	MinDist = 0,
	VelocitySmooth = 0,
	Visual = {
		Marker = true,
		Trail = true,
		Beacon = true,
		Light = true,
		Future = false,
		TrailCount = 20,
		TrailStyle = "Dots",
		Scale = 1,
	},
}

local MODES = {
	Ballistic = { Gravity = "World", StopOnGround = true, UntilLanding = true, MinDist = 15 },
	Linear = {
		Gravity = false,
		StopOnGround = true,
		ShowOnMiss = true,
		MinDist = 2,
		Visual = { Beacon = false },
	},
	Walk = {
		Gravity = "World",
		UntilLanding = true,
		Slide = true,
		GroundSnap = 2.5,
		ShowOnMiss = true,
		MinDist = 2,
		Visual = { Beacon = false, Future = true },
	},
}

local function Merge(dst, src)
	if src then
		for k, v in pairs(src) do
			if k == "Visual" and type(v) == "table" then
				dst.Visual = Merge(Merge({}, dst.Visual), v)
			else
				dst[k] = v
			end
		end
	end
	return dst
end

local function BuildOptions(mode, defaults, user)
	local preset = assert(MODES[mode], "Predictor: неизвестный Mode " .. tostring(mode))
	local o = Merge(Merge(Merge(Merge({}, BASE), preset), defaults), user)
	o.Mode = mode
	if user and user.MaxTime and user.Horizon == nil then
		o.Horizon = user.MaxTime
	end
	return o
end

local function ParseColors(input, fallback)
	input = input or {}
	local danger = input.DangerColor
	if danger == nil then
		danger = fallback.DangerColor
	end
	return {
		Color = input.Color or input.BaseColor or fallback.Color,
		DangerColor = danger or false,
	}
end

local function Append(dst, list)
	if list then
		for _, v in ipairs(list) do
			dst[#dst + 1] = v
		end
	end
end

local function ResolveGravity(g)
	if g == nil or g == "World" then
		return Vector3.new(0, -Workspace.Gravity, 0)
	elseif g == false then
		return Vector3.zero
	elseif type(g) == "number" then
		return Vector3.new(0, -g, 0)
	end
	return g
end

local function Classify(n)
	if n.Y >= GROUND_Y then
		return "Ground"
	elseif n.Y <= -GROUND_Y then
		return "Ceiling"
	end
	return "Wall"
end

local function Cast(origin, dir, radius, params)
	if dir.Magnitude < 1e-4 then
		return nil
	end
	if radius > 0 then
		return Workspace:Spherecast(origin, radius, dir, params)
	end
	return Workspace:Raycast(origin, dir, params)
end

local function NewRayParams(o)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.IgnoreWater = true
	rp.RespectCanCollide = true
	if o.CollisionGroup then
		rp.CollisionGroup = o.CollisionGroup
	end
	return rp
end

local function SurfaceFrame(pos, n)
	local ref = math.abs(n.Y) > 0.99 and Vector3.xAxis or Vector3.yAxis
	local x = ref:Cross(n).Unit
	return CFrame.fromMatrix(pos, x, n, x:Cross(n))
end

local function FadeT(base, alpha)
	return 1 - (1 - base) * alpha
end

local function Simulate(state, o, rayParams, velOverride)
	local dt = math.max(o.Step, 1 / 120)
	local nearSteps = math.min(math.max(1, math.ceil(o.Horizon / dt)), MAX_STEPS)
	local farDt = dt * 2
	local farSteps = o.UntilLanding and math.ceil(math.max(o.MaxAirTime - o.Horizon, 0) / farDt) or 0

	local gravity = ResolveGravity(o.Gravity)
	local acc0 = state.Acceleration or Vector3.zero
	local accel = o.Acceleration
	local accelFn = nil
	if type(accel) == "function" then
		accelFn = accel
	elseif accel then
		acc0 = acc0 + accel
	end
	local accFull = acc0 + gravity

	local drag = o.Drag
	local radius = state.Radius or o.Radius
	local voidY = Workspace.FallenPartsDestroyHeight
	local bounces = o.Bounces
	local slide = o.Slide

	local pos, vel = state.Position, velOverride or state.Velocity
	local start = pos
	local points, times, cum = { pos }, { 0 }, { 0 }
	local result = {
		Points = points,
		Times = times,
		Cumulative = cum,
		Length = 0,
		Extent = 0,
		Hit = false,
		Kind = "Horizon",
		Position = pos,
		Normal = Vector3.yAxis,
		Time = 0,
		Bounces = 0,
	}

	local function push(p, tt)
		cum[#cum + 1] = cum[#cum] + (p - points[#points]).Magnitude
		points[#points + 1] = p
		times[#times + 1] = tt
		result.Length = cum[#cum]
		local d = (p - start).Magnitude
		if d > result.Extent then
			result.Extent = d
		end
	end

	local snap = o.GroundSnap
	local offset = state.GroundOffset or o.GroundOffset or 3
	local grounded = false
	local groundNormal = Vector3.yAxis
	if snap then
		local probe = Cast(pos, Vector3.new(0, -(offset + 0.75), 0), 0, rayParams)
		if probe and probe.Normal.Y >= GROUND_Y and vel.Y <= SNAP_RISE then
			grounded = true
			groundNormal = probe.Normal
			vel = Vector3.new(vel.X, 0, vel.Z)
		end
	end

	local function setFuture()
		if result.Future then
			return
		end
		local p = points[#points]
		local fp, fn = p, Vector3.yAxis
		if snap and grounded then
			fp = p - Vector3.new(0, offset - 0.02, 0)
			fn = groundNormal
		end
		result.Future = { Position = fp, Normal = fn, Time = times[#times], Grounded = grounded }
	end

	local function setLanding(position, normal, tt, part)
		if not result.Landing then
			result.Landing = { Position = position, Normal = normal, Time = tt, HitPart = part }
		end
	end

	local t = 0
	for step = 1, nearSteps + farSteps do
		local far = step > nearSteps
		if far and grounded then
			break
		end
		if pos.Y < voidY then
			if not result.Landing then
				result.Kind = "Void"
			end
			break
		end

		local h = far and farDt or dt
		local acc = grounded and acc0 or accFull
		if accelFn then
			acc = acc + (accelFn(pos, vel, t) or Vector3.zero)
		end

		local move = vel * h + acc * (0.5 * h * h)
		local nextVel = vel + acc * h
		if drag > 0 then
			nextVel = nextVel * math.exp(-drag * h)
		end
		local hit = Cast(pos, move, radius, rayParams)

		if hit then
			local frac = math.clamp(hit.Distance / math.max(move.Magnitude, 1e-4), 0, 1)
			local center = pos + move * frac
			local tHit = t + h * frac
			local n = hit.Normal
			local kind = Classify(n)
			local vHit = vel + acc * (h * frac)

			if kind == "Ground" and not o.StopOnGround then
				local wasAir = not grounded
				grounded = true
				groundNormal = n
				pos = snap and Vector3.new(center.X, hit.Position.Y + offset, center.Z) or center
				vel = vHit - n * vHit:Dot(n)
				t += h
				push(pos, t)
				if wasAir then
					setLanding(hit.Position, n, tHit, hit.Instance)
				end
			elseif slide and kind ~= "Ground" then
				vel = vHit - n * math.min(vHit:Dot(n), 0)
				t += h
				push(center, t)
				pos = center + n * 0.02
			elseif bounces > 0 and vHit:Dot(n) < -REST_SPEED then
				bounces -= 1
				result.Bounces += 1
				if kind == "Ground" then
					setLanding(hit.Position, n, tHit, hit.Instance)
				end
				local vn = n * vHit:Dot(n)
				vel = (vHit - vn) * (1 - o.Friction) - vn * o.Restitution
				push(center, tHit)
				pos = center + n * 0.02
				t = tHit
			else
				push(center, tHit)
				result.Hit = true
				result.Kind = kind
				result.Position = hit.Position
				result.Normal = n
				result.HitPart = hit.Instance
				result.HitMaterial = hit.Material
				result.Time = tHit
				if kind == "Ground" then
					setLanding(hit.Position, n, tHit, hit.Instance)
				end
				result.Future = result.Future
					or { Position = hit.Position, Normal = n, Time = tHit, Grounded = kind == "Ground" }
				return result
			end
		else
			local wasGrounded = grounded
			pos = pos + move
			vel = nextVel
			t += h

			if snap then
				grounded = false
				if (wasGrounded and vel.Y <= SNAP_RISE) or vel.Y <= 0 then
					local g = Cast(
						pos + Vector3.new(0, snap, 0),
						Vector3.new(0, -(2 * snap + offset), 0),
						0,
						rayParams
					)
					if g and g.Normal.Y >= GROUND_Y then
						pos = Vector3.new(pos.X, g.Position.Y + offset, pos.Z)
						vel = Vector3.new(vel.X, 0, vel.Z)
						grounded = true
						groundNormal = g.Normal
						if not wasGrounded then
							setLanding(g.Position, g.Normal, t, g.Instance)
						end
					end
				end
			end
			push(pos, t)
		end

		if step == nearSteps then
			setFuture()
		end
	end

	setFuture()
	local main = result.Landing or result.Future
	result.Position, result.Normal, result.Time = main.Position, main.Normal, main.Time
	if result.Landing then
		result.Kind = "Ground"
		result.HitPart = result.Landing.HitPart
	end
	return result
end

function Predictor.Simulate(state, options)
	options = options or {}
	local o = BuildOptions(options.Mode or "Ballistic", nil, options)
	local rp = NewRayParams(o)
	local ignore = {}
	Append(ignore, o.Ignore)
	Append(ignore, state.Ignore)
	rp.FilterDescendantsInstances = ignore
	return Simulate(state, o, rp)
end

function Predictor.PositionAt(result, t)
	local pts, times = result.Points, result.Times
	local n = #pts
	if t <= 0 then
		return pts[1]
	end
	if t >= times[n] then
		return pts[n]
	end
	for i = 2, n do
		if times[i] >= t then
			local t0 = times[i - 1]
			return pts[i - 1]:Lerp(pts[i], (t - t0) / math.max(times[i] - t0, 1e-6))
		end
	end
	return pts[n]
end

function Predictor.Intercept(shooterPos, speed, targetPos, targetVel)
	local r = targetPos - shooterPos
	local a = targetVel:Dot(targetVel) - speed * speed
	local b = 2 * r:Dot(targetVel)
	local c = r:Dot(r)
	local t

	if math.abs(a) < 1e-6 then
		if math.abs(b) < 1e-6 then
			return nil
		end
		t = -c / b
	else
		local disc = b * b - 4 * a * c
		if disc < 0 then
			return nil
		end
		local sq = math.sqrt(disc)
		local t1, t2 = (-b - sq) / (2 * a), (-b + sq) / (2 * a)
		if t1 > 0 and t2 > 0 then
			t = math.min(t1, t2)
		elseif t1 > 0 then
			t = t1
		elseif t2 > 0 then
			t = t2
		end
	end

	if not t or t <= 0 then
		return nil
	end
	return targetPos + targetVel * t, t
end

local function ResolveTarget(target)
	if type(target) == "function" then
		target = target()
	end
	if typeof(target) ~= "Instance" then
		return nil
	end
	if target:IsA("Player") then
		target = target.Character
	end
	if target and target:IsA("Humanoid") then
		target = target.Parent
	end
	if not target then
		return nil
	end
	if target:IsA("BasePart") then
		return target, nil, nil
	end
	if target:IsA("Model") then
		local root = target.PrimaryPart
			or target:FindFirstChild("HumanoidRootPart")
			or target:FindFirstChildWhichIsA("BasePart")
		return root, target, target:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

local function MakeStateProvider(opts)
	local state, ignore, ignoreOwner = {}, nil, nil
	return function()
		local root, model, hum = ResolveTarget(opts.Target)
		if not root then
			return nil
		end

		local owner = model or root
		if owner ~= ignoreOwner then
			ignoreOwner, ignore = owner, { owner }
		end

		local vel = root.AssemblyLinearVelocity
		if opts.VelocitySource == "Intent" and hum then
			local flat = hum.MoveDirection * hum.WalkSpeed
			vel = Vector3.new(flat.X, vel.Y, flat.Z)
		end

		state.Position = root.Position
		state.Velocity = vel
		state.Ignore = ignore
		state.GroundOffset = hum
			and (hum.RigType == Enum.HumanoidRigType.R6 and 3 or hum.HipHeight + root.Size.Y / 2)
		return state
	end
end

function Predictor.PredictPosition(target, seconds, options)
	options = options or {}
	local state = MakeStateProvider({ Target = target, VelocitySource = options.VelocitySource })()
	if not state then
		return nil
	end
	local o = Merge({ Mode = "Walk" }, options)
	o.Horizon = seconds
	local result = Predictor.Simulate(state, o)
	return Predictor.PositionAt(result, seconds), result
end

local shared

function Predictor.Track(target, options)
	if type(target) == "table" and options == nil then
		target, options = nil, target
	end
	local o = Merge({}, options)
	if target ~= nil then
		o.Target = target
	end
	if not shared or not shared.Folder then
		shared = Predictor.new({ AutoUpdate = true })
	end
	return shared:Add(o)
end

-- Полностью останавливает общий менеджер Track() и удаляет все его визуалы
function Predictor.Shutdown()
	if shared then
		shared:Destroy()
		shared = nil
	end
end

function Predictor.new(config)
	config = config or {}
	local self = setmetatable({}, Predictor)
	self.Colors = ParseColors(config, DEFAULT_COLORS)
	self.Defaults = config.Defaults or {}
	self.Active = {}
	self._autoId = 0

	local folder = Instance.new("Folder")
	folder.Name = "PredictorVisuals"
	folder.Parent = config.Parent or Workspace
	self.Folder = folder

	if config.AutoUpdate then
		self:Start()
	end
	return self
end

function Predictor:Start()
	if not self._conn then
		local signal = RunService:IsClient() and RunService.RenderStepped or RunService.Heartbeat
		self._conn = signal:Connect(function(dt)
			self:Update(dt)
		end)
	end
end

function Predictor:Stop()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
end

function Predictor:Add(id, options)
	if type(id) == "table" then
		options, id = id, nil
	end
	options = options or {}
	if id == nil then
		self._autoId += 1
		id = "predictor_" .. self._autoId
	end
	self:Remove(id)
	local inst = Prediction._new(self, id, options)
	self.Active[id] = inst
	return inst
end

function Predictor:Get(id)
	return self.Active[id]
end

function Predictor:Remove(id)
	local inst = self.Active[id]
	if inst then
		inst:Destroy()
		self.Active[id] = nil
	end
end

function Predictor:SetEnabled(id, enabled)
	local inst = self.Active[id]
	if inst then
		inst:SetEnabled(enabled)
	end
end

function Predictor:SetColors(colors, id)
	if id ~= nil then
		local inst = self.Active[id]
		if inst then
			inst:SetColors(colors)
		end
	else
		self.Colors = ParseColors(colors, self.Colors)
		for _, inst in pairs(self.Active) do
			inst:SetColors(colors)
		end
	end
end

function Predictor:Update(dt)
	for _, inst in pairs(self.Active) do
		local ok, err = pcall(inst.Update, inst, dt)
		if not ok then
			inst:_Warn(err)
		end
	end
end

function Predictor:Destroy()
	self:Stop()
	for id in pairs(self.Active) do
		self:Remove(id)
	end
	if self.Folder then
		self.Folder:Destroy()
		self.Folder = nil
	end
end

function Prediction._new(owner, id, options)
	local mode = options.Mode or owner.Defaults.Mode or (options.GetState and "Ballistic" or "Walk")
	local opts = BuildOptions(mode, owner.Defaults, options)
	if not (opts.GetState or opts.Target) then
		error("Predictor: нужен Target или GetState", 3)
	end

	local self = setmetatable({
		Id = id,
		Owner = owner,
		Opts = opts,
		Colors = ParseColors(options, owner.Colors),
		Enabled = options.Enabled ~= false,
		Result = nil,
		Objects = {},
		_getState = opts.GetState or MakeStateProvider(opts),
		_rayParams = NewRayParams(opts),
		_time = 0,
		_clock = math.huge,
		_alpha = 0,
		_want = false,
		_snap = true,
		_ignore = false,
	}, Prediction)

	self:_Build()
	return self
end

function Prediction:_Warn(msg)
	if not self._warned then
		self._warned = true
		warn(("[Predictor:%s] %s"):format(tostring(self.Id), tostring(msg)))
	end
end

function Prediction:SetEnabled(enabled)
	self.Enabled = enabled
	if enabled then
		self._clock = math.huge
	else
		self._want, self._alpha, self._cache = false, 0, nil
		self:_Hide()
	end
end

function Prediction:SetColors(colors)
	self.Colors = ParseColors(colors, self.Colors)
end

function Prediction:SetOptions(patch)
	assert(patch.Mode == nil or patch.Mode == self.Opts.Mode, "Predictor: Mode нельзя менять — пересоздайте")
	Merge(self.Opts, patch)
	if patch.MaxTime and patch.Horizon == nil then
		self.Opts.Horizon = patch.MaxTime
	end
	if patch.GetState then
		self._getState = patch.GetState
	end
	if patch.Color or patch.BaseColor or patch.DangerColor ~= nil then
		self.Colors = ParseColors(patch, self.Colors)
	end
	self._rayParams = NewRayParams(self.Opts)
	self._ignore, self._lastPos, self._clock = false, nil, math.huge
	if patch.Visual then
		self:_Build()
	end
end

function Prediction:PositionAt(t)
	return self.Result and Predictor.PositionAt(self.Result, t)
end

function Prediction:IsVisible()
	return self._alpha > 0
end

function Prediction:Destroy()
	if self.Folder then
		self.Folder:Destroy()
		self.Folder = nil
	end
	self.Objects, self._trail = {}, {}
	self.Enabled = false
end

function Prediction:Update(dt)
	if not self.Enabled then
		return
	end
	local o = self.Opts
	self._time += dt
	self._clock += dt

	if self._clock >= o.Interval then
		local elapsed = self._clock
		self._clock = 0
		self:_Resimulate(elapsed)
	end

	if self._want then
		if self._alpha <= 0 then
			self._snap = true
		end
		self._alpha = math.min(1, self._alpha + dt * FADE_IN)
	elseif self._alpha > 0 then
		self._alpha = math.max(0, self._alpha - dt * FADE_OUT)
		if self._alpha <= 0 then
			self:_Hide()
		end
	end

	self:_Render(dt)
end

function Prediction:_Lose()
	self._lastPos = nil
	if not (self._cache and self._time - self._cacheTime < GRACE) then
		self._want, self._cache = false, nil
	end
end

function Prediction:_Resimulate(elapsed)
	local o = self.Opts

	local ok, state = pcall(self._getState)
	if not ok then
		self:_Warn(state)
		state = nil
	end
	if type(state) ~= "table" or not state.Position or not state.Velocity then
		self.Result = nil
		return self:_Lose()
	end

	local vel = state.Velocity
	if o.VelocitySmooth > 0 then
		local a = 1 - math.exp(-math.max(elapsed, 1 / 240) / o.VelocitySmooth)
		self._vel = self._vel and self._vel:Lerp(vel, a) or vel
		vel = self._vel
	end

	if
		self._lastReason ~= "miss"
		and not o.Acceleration
		and state.Position == self._lastPos
		and vel == self._lastVel
	then
		return
	end
	self._lastPos, self._lastVel = state.Position, vel

	local ignore = state.Ignore or false
	if ignore ~= self._ignore then
		self._ignore = ignore
		local list = {}
		Append(list, o.Ignore)
		Append(list, ignore)
		self._rayParams.FilterDescendantsInstances = list
	end

	local okSim, result = pcall(Simulate, state, o, self._rayParams, vel)
	if not okSim then
		self:_Warn(result)
		return self:_Lose()
	end
	self.Result = result

	if o.OnResult then
		local okCb, err = pcall(o.OnResult, result, self)
		if not okCb then
			self:_Warn(err)
		end
	end

	local reason = "ok"
	if
		(o.LandingOnly and not result.Landing)
		or result.Kind == "Void"
		or not (result.Hit or result.Landing or o.ShowOnMiss)
	then
		reason = "miss"
	elseif result.Extent < o.MinDist then
		reason = "near"
	end
	self._lastReason = reason

	if reason == "ok" then
		self._cache, self._cacheTime = result, self._time
		self._shown, self._want = result, true
		self:_PrepareTrail(result)
	elseif not (reason == "miss" and self._cache and self._time - self._cacheTime < GRACE) then
		self._want, self._cache = false, nil
	end
end

function Prediction:_PrepareTrail(r)
	self._trailDirty = true
	local n = #self._trail
	if n == 0 or #r.Points < 2 or r.Length < 0.1 then
		self._trailPts = nil
		return
	end

	local pts = self._trailPts or {}
	local list, cum = r.Points, r.Cumulative
	local np, idx = #list, 1
	for i = 0, n do
		local d = r.Length * i / n
		while idx < np - 1 and cum[idx + 1] < d do
			idx += 1
		end
		local c0 = cum[idx]
		local seg = cum[idx + 1] - c0
		local a = seg > 1e-6 and math.clamp((d - c0) / seg, 0, 1) or 0
		pts[i + 1] = list[idx]:Lerp(list[idx + 1], a)
	end
	self._trailPts = pts
end

function Prediction:_Build()
	if self.Folder then
		self.Folder:Destroy()
	end

	local v = self.Opts.Visual
	local col = self.Colors.Color
	local scale = v.Scale

	local folder = Instance.new("Folder")
	folder.Name = "Pred_" .. tostring(self.Id)
	folder.Parent = self.Owner.Folder
	self.Folder = folder

	local O, paint, trail = {}, {}, {}
	self.Objects, self._paint, self._trail = O, paint, trail
	self._trailPts, self._color, self._futureShown, self._trailAlpha = nil, nil, false, nil
	self._trailDirty = true

	local function part(name, shape, size, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = shape
		p.Size = size
		p.Material = material
		p.Color = col
		p.Transparency = 1
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = folder
		paint[#paint + 1] = p
		return p
	end

	local cyl, ball, block = Enum.PartType.Cylinder, Enum.PartType.Ball, Enum.PartType.Block
	local neon, ff = Enum.Material.Neon, Enum.Material.ForceField

	O.root = part("Root", block, Vector3.new(0.1, 0.1, 0.1), Enum.Material.SmoothPlastic)

	if v.Light then
		local light = Instance.new("PointLight")
		light.Range = 6 * scale
		light.Shadows = false
		light.Enabled = false
		light.Parent = O.root
		O.light = light
	end

	if v.Beacon then
		local att0, att1 = Instance.new("Attachment"), Instance.new("Attachment")
		att1.Position = Vector3.new(0, BEACON_HEIGHT, 0)
		att0.Parent, att1.Parent = O.root, O.root

		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = att0, att1
		beam.Width0, beam.Width1 = 0.15, 0
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.5, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Enabled = false
		beam.Parent = O.root
		O.beam = beam
	end

	if v.Marker then
		O.ringOuter = part("RingOuter", cyl, Vector3.new(0.02, 6, 6), ff)
		O.ringMain = part("RingMain", cyl, Vector3.new(0.06, 4, 4), neon)
		O.ringInner = part("RingInner", cyl, Vector3.new(0.06, 2, 2), neon)
		O.dot = part("Dot", ball, Vector3.new(0.4, 0.4, 0.4), neon)
		O.dotGlow = part("DotGlow", ball, Vector3.new(1, 1, 1), ff)
	end

	if v.Future then
		O.futureRing = part("FutureRing", cyl, Vector3.new(0.04, 2.4, 2.4), neon)
		O.futureDot = part("FutureDot", ball, Vector3.new(0.35, 0.35, 0.35), neon)
	end

	local line = v.TrailStyle == "Line"
	local n = v.Trail and v.TrailCount or 0
	local width, base, on, cfs = {}, {}, {}, {}
	for i = 1, n do
		local t = (i - 1) / math.max(n - 1, 1)
		local size = (line and 0.05 + (1 - t) * 0.08 or 0.1 + (1 - t) * 0.15) * scale
		width[i], base[i], on[i], cfs[i] = size, math.max(0.1, 0.6 - t * 0.3), false, CFrame.identity
		trail[i] = part("Trail", line and block or ball, Vector3.new(size, size, size), neon)
	end
	self._trailW, self._trailT, self._trailOn, self._trailCF = width, base, on, cfs
end

function Prediction:_Hide()
	for _, obj in pairs(self.Objects) do
		if obj:IsA("BasePart") then
			obj.Transparency = 1
		else
			obj.Enabled = false
		end
	end
	for _, p in ipairs(self._trail) do
		p.Transparency = 1
	end
	self._futureShown, self._trailAlpha = false, nil
end

function Prediction:_Paint(color)
	if color == self._color then
		return
	end
	self._color = color
	for _, p in ipairs(self._paint) do
		p.Color = color
	end
	local O = self.Objects
	if O.light then
		O.light.Color = color
	end
	if O.beam then
		O.beam.Color = ColorSequence.new(color)
	end
end

function Prediction:_Smooth(key, target, dt, force)
	local cur = self[key]
	if force or not cur or (cur.Position - target.Position).Magnitude > SNAP_DIST then
		cur = target
	else
		cur = cur:Lerp(target, math.clamp(dt * SMOOTH, 0, 1))
	end
	self[key] = cur
	return cur
end

function Prediction:_RenderTrail(alpha)
	local trail = self._trail
	local n = #trail
	if n == 0 then
		return
	end

	local dirty = self._trailDirty
	if dirty then
		self._trailDirty = false
		local pts, on, cfs, width = self._trailPts, self._trailOn, self._trailCF, self._trailW
		local line = self.Opts.Visual.TrailStyle == "Line"
		for i = 1, n do
			if not pts then
				on[i] = false
			else
				local a, b = pts[i], pts[i + 1]
				if line then
					local len = (b - a).Magnitude
					on[i] = len > 0.02
					if on[i] then
						local up = math.abs((b.Y - a.Y) / len) > 0.99 and Vector3.xAxis or Vector3.yAxis
						cfs[i] = CFrame.lookAt(a, b, up) * CFrame.new(0, 0, -len / 2)
						trail[i].Size = Vector3.new(width[i], width[i], len)
					end
				else
					on[i] = true
					cfs[i] = CFrame.new((a + b) * 0.5)
				end
			end
		end
		Workspace:BulkMoveTo(trail, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end

	if dirty or alpha ~= self._trailAlpha then
		self._trailAlpha = alpha
		local on, base = self._trailOn, self._trailT
		for i = 1, n do
			trail[i].Transparency = on[i] and FadeT(base[i], alpha) or 1
		end
	end
end

function Prediction:_Render(dt)
	local r, alpha = self._shown, self._alpha
	if not r or alpha <= 0 then
		return
	end

	local o, v, c, O = self.Opts, self.Opts.Visual, self.Colors, self.Objects
	local scale = v.Scale

	local urgency = 0
	if c.DangerColor and (r.Landing or r.Hit) then
		urgency = math.clamp(1 - r.Time / o.DangerTime, 0, 1)
	end
	self:_Paint(c.DangerColor and c.Color:Lerp(c.DangerColor, urgency) or c.Color)

	local pulse = 0.5 + 0.5 * math.sin(self._time * math.pi * (2 + urgency * 4))
	local frame = self:_Smooth("_frame", SurfaceFrame(r.Position + r.Normal * 0.05, r.Normal), dt, self._snap)
	O.root.CFrame = frame

	if O.ringOuter then
		local outer = (6 + pulse * (0.3 + urgency * 0.5)) * scale
		local main = (4 + pulse * (0.2 + urgency * 0.3)) * scale
		local inner = (2 - urgency * 0.5 + pulse * 0.1) * scale
		local dot = (0.4 + urgency * 0.3 + pulse * 0.1) * scale
		local aura = (1 + pulse * (0.3 + urgency * 0.6)) * scale

		O.ringOuter.CFrame = frame * AXIS_FIX * CFrame.Angles(self._time * 1.5, 0, 0)
		O.ringOuter.Size = Vector3.new(0.02, outer, outer)
		O.ringOuter.Transparency = FadeT(0.6 - pulse * 0.1 - urgency * 0.2, alpha)

		O.ringMain.CFrame = frame * AXIS_FIX
		O.ringMain.Size = Vector3.new(0.06, main, main)
		O.ringMain.Transparency = FadeT(0.1 + pulse * 0.1 + urgency * 0.1, alpha)

		O.ringInner.CFrame = frame * AXIS_FIX
		O.ringInner.Size = Vector3.new(0.06, inner, inner)
		O.ringInner.Transparency = FadeT(0.2 + pulse * 0.2, alpha)

		local up = frame * CFrame.new(0, 0.1, 0)
		O.dot.CFrame = up
		O.dot.Size = Vector3.new(dot, dot, dot)
		O.dot.Transparency = FadeT(0.05, alpha)

		O.dotGlow.CFrame = up
		O.dotGlow.Size = Vector3.new(aura, aura, aura)
		O.dotGlow.Transparency = FadeT(0.8 - pulse * 0.2, alpha)
	end

	if O.futureDot then
		local f = r.Future
		if f and (f.Position - r.Position).Magnitude > 1.5 then
			local ff = self:_Smooth(
				"_futureFrame",
				SurfaceFrame(f.Position + f.Normal * 0.05, f.Normal),
				dt,
				self._snap or not self._futureShown
			)
			self._futureShown = true
			local ring, dot = (2.4 + pulse * 0.2) * scale, 0.35 * scale

			O.futureRing.CFrame = ff * AXIS_FIX
			O.futureRing.Size = Vector3.new(0.04, ring, ring)
			O.futureRing.Transparency = FadeT(0.35, alpha)
			O.futureDot.CFrame = ff * CFrame.new(0, 0.1, 0)
			O.futureDot.Size = Vector3.new(dot, dot, dot)
			O.futureDot.Transparency = FadeT(0.1, alpha)
		else
			O.futureRing.Transparency = 1
			O.futureDot.Transparency = 1
			self._futureShown = false
		end
	end

	if O.light then
		O.light.Enabled = true
		O.light.Brightness = (0.2 + pulse * 0.1) * alpha
	end
	if O.beam then
		O.beam.Enabled = true
		O.beam.Width0 = (0.1 + urgency * 0.1) * scale * alpha
	end

	self:_RenderTrail(alpha)
	self._snap = false
end

return Predictor