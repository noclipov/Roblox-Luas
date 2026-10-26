-- ================= SHADER MODULE v4 =================
local LocalPlayer = game.Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

local Shaders = {}
Shaders.PREFIX     = "Noclipov_"
Shaders.GLOBAL_KEY = "__Noclipov_Shaders_v4"
Shaders.Debug      = false
local function dbg(...) if Shaders.Debug then print("[Shaders]", ...) end end

-- ====== ГЛОБАЛЬНЫЙ КЛИН-АП ПРИ ПЕРЕЗАПУСКЕ СКРИПТА ======
do
    local old = env[Shaders.GLOBAL_KEY]
    if type(old) == "table" and type(old.Shutdown) == "function" then
        pcall(function() old:Shutdown() end)
    end
    env[Shaders.GLOBAL_KEY] = nil
end

-- ================= STATE =================
Shaders.Config, Shaders.Lighting = nil, nil
Shaders.PostEffects      = {}
Shaders.FogSaved         = nil
Shaders.GuardLock        = false
Shaders.Connections      = {}
Shaders.CharacterConn    = nil
Shaders.WatchdogInterval = 1
Shaders._watchdogRunning = false
Shaders._watchdogThread  = nil

Shaders.WeatherPart      = nil
Shaders.WeatherEmitters  = {}
Shaders.WeatherType      = "none"
Shaders.Wind             = Vector3.zero

Shaders.ManagedClasses = {
    BloomEffect = true, ColorCorrectionEffect = true, BlurEffect = true,
    SunRaysEffect = true, DepthOfFieldEffect = true, Atmosphere = true,
}

local function withGuard(fn)
    local prev = Shaders.GuardLock
    Shaders.GuardLock = true
    local ok, err = pcall(fn)
    Shaders.GuardLock = prev
    return ok, err
end

function Shaders.IsOwned(inst)
    return typeof(inst) == "Instance"
       and string.sub(inst.Name, 1, #Shaders.PREFIX) == Shaders.PREFIX
end
function Shaders.IsConflict(inst)
    return inst and typeof(inst) == "Instance"
       and not Shaders.IsOwned(inst)
       and Shaders.ManagedClasses[inst.ClassName] == true
end

-- ================= EFFECT DEFS =================
Shaders.EffectDefs = {
    { name="Bloom", class="BloomEffect", enabledKey="BloomEnabled", hasEnabled=true,
      configure=function(c,e)
          e.Intensity=c.BloomIntensity or 0.6; e.Size=c.BloomSize or 24
          e.Threshold=c.BloomThreshold or 0.95
      end },
    { name="ColorCorrection", class="ColorCorrectionEffect",
      enabledKey="ColorCorrectionEnabled", hasEnabled=true,
      configure=function(c,e)
          e.Brightness=c.CC_Brightness or 0; e.Contrast=c.CC_Contrast or 0
          e.Saturation=c.CC_Saturation or 0; e.TintColor=Color3.fromRGB(255,255,255)
      end },
    { name="Atmosphere", class="Atmosphere",
      enabledKey="AtmosphereEnabled", hasEnabled=false,
      configure=function(c,e)
          e.Density=c.AtmosDensity or 0.3; e.Haze=c.AtmosHaze or 1.5
          e.Offset=0.25; e.Color=Color3.fromRGB(199,199,199)
          e.Decay=Color3.fromRGB(106,112,125); e.Glare=0
      end },
    { name="SunRays", class="SunRaysEffect", enabledKey="SunRaysEnabled", hasEnabled=true,
      configure=function(c,e) e.Intensity=0.15; e.Spread=1 end },
    { name="DepthOfField", class="DepthOfFieldEffect", enabledKey="DOFEnabled", hasEnabled=true,
      configure=function(c,e)
          e.FarIntensity=0.15; e.FocusDistance=50
          e.InFocusRadius=8; e.NearIntensity=0
      end },
}

-- ================= WEATHER =================
Shaders.WEATHER_CONFIGS = {
    snow = {
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Color   = ColorSequence.new(Color3.fromRGB(245,245,255)),
        PartSize = Vector3.new(120,2,120), PartOffset = Vector3.new(0,15,0),
        SpreadAngle = Vector2.new(20,20), EmissionDirection = Enum.NormalId.Bottom,
        Wind = Vector3.new(2,0,1),
        Layers = {
            { Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.18),
                                       NumberSequenceKeypoint.new(1,0.42)}),
              Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.15),
                                               NumberSequenceKeypoint.new(1,1)}),
              Lifetime=NumberRange.new(5,8), Speed=NumberRange.new(3,6),
              Rotation=NumberRange.new(0,360), RotSpeed=NumberRange.new(-90,90),
              Rate=150, Acceleration=Vector3.new(0,-3,0),
              Drag=0.3, LightEmission=0.1, LightInfluence=0.6 },
        },
    },
    rain = {
        Texture = "", Color = ColorSequence.new(Color3.fromRGB(170,200,240)),
        PartSize = Vector3.new(120,2,120), PartOffset = Vector3.new(0,22,0),
        SpreadAngle = Vector2.new(4,4), EmissionDirection = Enum.NormalId.Bottom,
        Wind = Vector3.new(2,0,0),
        Layers = {
            { Size=NumberSequence.new(0.15),
              Transparency=NumberSequence.new(0.4),
              Lifetime=NumberRange.new(0.55,0.75), Speed=NumberRange.new(70,95),
              Rotation=NumberRange.new(0), RotSpeed=NumberRange.new(0),
              Rate=650, Acceleration=Vector3.new(0,-120,0),
              Drag=0, LightEmission=0.1, LightInfluence=0.2 },
        },
    },
    sakura = {
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Color = ColorSequence.new(Color3.fromRGB(255,165,195)),
        PartSize = Vector3.new(120,2,120), PartOffset = Vector3.new(0,15,0),
        SpreadAngle = Vector2.new(25,25), EmissionDirection = Enum.NormalId.Bottom,
        Wind = Vector3.new(3,0,2),
        Layers = {
            { Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.25),
                                       NumberSequenceKeypoint.new(1,0.5)}),
              Transparency=NumberSequence.new(0.1),
              Lifetime=NumberRange.new(5,8), Speed=NumberRange.new(2.5,4.5),
              Rotation=NumberRange.new(0,360), RotSpeed=NumberRange.new(-150,150),
              Rate=100, Acceleration=Vector3.new(0,-2,0),
              Drag=0.4, LightEmission=0.05, LightInfluence=0.7 },
        },
    },
}

-- ================= INIT =================
function Shaders.Init(cfg, lighting)
    Shaders.Config, Shaders.Lighting = cfg, lighting
    if cfg.DeleteOtherEffects == nil then cfg.DeleteOtherEffects = true end
    env[Shaders.GLOBAL_KEY] = Shaders
    Shaders.CleanupOrphans()
    Shaders.StartGuard()
    Shaders.StartCharacterTracking()
end

-- Чистим остатки от прошлых запусков (на случай если Shutdown не отработал)
function Shaders.CleanupOrphans()
    if Shaders.Lighting then
        for _, inst in ipairs(Shaders.Lighting:GetChildren()) do
            if Shaders.IsOwned(inst) then pcall(function() inst:Destroy() end) end
        end
    end
    for _, inst in ipairs(workspace:GetChildren()) do
        if inst.Name == Shaders.PREFIX.."WeatherPart" then
            pcall(function() inst:Destroy() end)
        end
    end
end

-- ================= EFFECTS =================
function Shaders.EnsurePostEffect(name, className)
    local cur = Shaders.PostEffects[name]
    if cur and cur.Parent then return cur end
    local existing = Shaders.Lighting:FindFirstChild(Shaders.PREFIX..name)
    if existing then withGuard(function() existing:Destroy() end) end
    local inst = Instance.new(className)
    inst.Name   = Shaders.PREFIX..name
    inst.Parent = Shaders.Lighting
    Shaders.PostEffects[name] = inst
    return inst
end

function Shaders.RemovePostEffect(name)
    local inst = Shaders.PostEffects[name]
    Shaders.PostEffects[name] = nil
    if not inst and Shaders.Lighting then
        inst = Shaders.Lighting:FindFirstChild(Shaders.PREFIX..name)
    end
    if inst then withGuard(function() inst:Destroy() end) end
end

function Shaders.ApplyEffect(def)
    local cfg = Shaders.Config
    if not cfg then return end
    if cfg[def.enabledKey] == true then
        local e = Shaders.EnsurePostEffect(def.name, def.class)
        def.configure(cfg, e)
        if def.hasEnabled ~= false then e.Enabled = true end
    else
        Shaders.RemovePostEffect(def.name)
    end
end

function Shaders.ApplyAllEffects()
    for _, def in ipairs(Shaders.EffectDefs) do
        withGuard(function() Shaders.ApplyEffect(def) end)
    end
    withGuard(Shaders.ApplyFog)
end

function Shaders.ApplyFog()
    local cfg, l = Shaders.Config, Shaders.Lighting
    if cfg.FogEnabled then
        if not Shaders.FogSaved then
            Shaders.FogSaved = {FogStart=l.FogStart, FogEnd=l.FogEnd, FogColor=l.FogColor}
        end
        l.FogStart, l.FogEnd = cfg.FogStart, cfg.FogEnd
        l.FogColor = Color3.fromRGB(200,200,220)
    elseif Shaders.FogSaved then
        l.FogStart, l.FogEnd = Shaders.FogSaved.FogStart, Shaders.FogSaved.FogEnd
        l.FogColor = Shaders.FogSaved.FogColor
        Shaders.FogSaved = nil
    end
end

-- ================= WEATHER =================
function Shaders.StopWeather()
    for _, e in ipairs(Shaders.WeatherEmitters) do pcall(function() e:Destroy() end) end
    Shaders.WeatherEmitters = {}
    if Shaders.WeatherPart then
        pcall(function() Shaders.WeatherPart:Destroy() end)
        Shaders.WeatherPart = nil
    end
    Shaders.WeatherType = "none"
end

local function getTrackPosition()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position end
    local cam = workspace.CurrentCamera
    if cam then return cam.CFrame.Position end
    return Vector3.new(0, 50, 0)
end

function Shaders.SetWeather(weatherType)
    Shaders.StopWeather()
    if weatherType == "none" or not Shaders.WEATHER_CONFIGS[weatherType] then return end
    local cfg = Shaders.WEATHER_CONFIGS[weatherType]
    local pos = getTrackPosition()

    local part = Instance.new("Part")
    part.Name         = Shaders.PREFIX.."WeatherPart"
    part.Size         = cfg.PartSize or Vector3.new(120,2,120)
    part.CFrame       = CFrame.new(pos + (cfg.PartOffset or Vector3.new(0,20,0)))
    part.Transparency = 1
    part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
    part.Anchored     = true
    part.Parent       = workspace

    local intensity = Shaders.Config.WeatherIntensity or 1.0
    local wind      = (cfg.Wind or Vector3.zero) + Shaders.Wind

    for i, layer in ipairs(cfg.Layers) do
        local e = Instance.new("ParticleEmitter")
        local ok, err = pcall(function()
            e.Name = Shaders.PREFIX.."WeatherEmitter"
            e.Texture = cfg.Texture or ""
            e.Color = cfg.Color
            e.Size = layer.Size
            e.Transparency = layer.Transparency
            e.Lifetime = layer.Lifetime
            e.Speed    = layer.Speed
            e.Rotation = layer.Rotation
            e.RotSpeed = layer.RotSpeed
            e.Rate     = layer.Rate * intensity
            e.Acceleration = (layer.Acceleration or Vector3.zero) + wind
            e.Drag = layer.Drag or 0
            e.SpreadAngle = cfg.SpreadAngle or Vector2.new(15,15)
            e.EmissionDirection = cfg.EmissionDirection or Enum.NormalId.Bottom
            e.Shape = Enum.ParticleEmitterShape.Box
            e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
            e.LightEmission = layer.LightEmission or 0
            e.LightInfluence = layer.LightInfluence or 1
            e.LockedToPart = false
            e.Enabled = true
            e.Parent = part
        end)
        if ok then table.insert(Shaders.WeatherEmitters, e)
        else warn("[Shaders] weather layer "..i.." failed: "..tostring(err)); e:Destroy() end
    end

    if #Shaders.WeatherEmitters == 0 then part:Destroy(); return end
    Shaders.WeatherPart = part
    Shaders.WeatherType = weatherType
end

function Shaders.SetWeatherIntensity(v)
    Shaders.Config.WeatherIntensity = v or 1.0
    local wt = Shaders.WeatherType
    if wt == "none" then return end
    local cfg = Shaders.WEATHER_CONFIGS[wt]
    if not cfg then return end
    for i, e in ipairs(Shaders.WeatherEmitters) do
        local layer = cfg.Layers[i]
        if layer then e.Rate = layer.Rate * Shaders.Config.WeatherIntensity end
    end
end

function Shaders.SetWind(v)
    Shaders.Wind = v or Vector3.zero
    local wt = Shaders.WeatherType
    if wt == "none" then return end
    local cfg = Shaders.WEATHER_CONFIGS[wt]
    if not cfg then return end
    local wind = (cfg.Wind or Vector3.zero) + Shaders.Wind
    for i, e in ipairs(Shaders.WeatherEmitters) do
        local layer = cfg.Layers[i]
        if layer then e.Acceleration = (layer.Acceleration or Vector3.zero) + wind end
    end
end

function Shaders.GetActiveWeather()
    local c = Shaders.Config
    if not c then return "none" end
    if c.WeatherSnow   or c.Snow   or c.SnowEnabled   then return "snow"   end
    if c.WeatherRain   or c.Rain   or c.RainEnabled   then return "rain"   end
    if c.WeatherSakura or c.Sakura or c.SakuraEnabled then return "sakura" end
    return "none"
end

function Shaders.UpdatePosition()
    if not Shaders.WeatherPart or not Shaders.WeatherPart.Parent then return end
    local cfg = Shaders.WEATHER_CONFIGS[Shaders.WeatherType]
    if not cfg then return end
    local pos = getTrackPosition()
    Shaders.WeatherPart.CFrame = CFrame.new(pos + (cfg.PartOffset or Vector3.new(0,20,0)))
end

function Shaders.StartCharacterTracking()
    if Shaders.CharacterConn then
        pcall(function() Shaders.CharacterConn:Disconnect() end)
    end
    Shaders.CharacterConn = LocalPlayer.CharacterAdded:Connect(function(char)
        local wt = Shaders.GetActiveWeather()
        if wt == "none" then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then
            task.wait(0.2)
            Shaders.WeatherType = "none"
            Shaders.SetWeather(wt)
        end
    end)
end

-- ================= ВОТЧЕР: ЧИСТИМ ЧУЖИХ =================
function Shaders.PurgeForeign()
    if not Shaders.Config or not Shaders.Lighting then return end
    if Shaders.Config.DeleteOtherEffects == false then return end
    for _, child in ipairs(Shaders.Lighting:GetChildren()) do
        if Shaders.IsConflict(child) then
            withGuard(function() child:Destroy() end)
        end
    end
end

-- ================= ВОТЧЕР: ВОССТАНАВЛИВАЕМ СВОИ =================
function Shaders.VerifyEffects()
    local cfg, l = Shaders.Config, Shaders.Lighting
    if not cfg or not l then return end
    for _, def in ipairs(Shaders.EffectDefs) do
        local inst = l:FindFirstChild(Shaders.PREFIX..def.name)
        local want = cfg[def.enabledKey] == true
        if want then
            if not inst or inst.ClassName ~= def.class then
                withGuard(function() Shaders.ApplyEffect(def) end)
            elseif def.hasEnabled ~= false
               and inst:IsA("PostEffect") and inst.Enabled == false then
                inst.Enabled = true
            end
        elseif inst then
            withGuard(function() Shaders.RemovePostEffect(def.name) end)
        end
    end
    if cfg.FogEnabled and (l.FogStart ~= cfg.FogStart or l.FogEnd ~= cfg.FogEnd) then
        withGuard(Shaders.ApplyFog)
    end
end

function Shaders.VerifyWeather()
    local active = Shaders.GetActiveWeather()
    if active == "none" then
        if Shaders.WeatherType ~= "none" then Shaders.StopWeather() end
        return
    end
    local partOk = Shaders.WeatherPart and Shaders.WeatherPart.Parent
    local alive  = 0
    for _, e in ipairs(Shaders.WeatherEmitters) do
        if e.Parent then alive += 1 end
    end
    if not partOk or Shaders.WeatherType ~= active or alive == 0 then
        Shaders.WeatherType = "none"
        Shaders.SetWeather(active)
    end
end

-- ================= EVENTS =================
function Shaders.OnLightingChildAdded(inst)
    if Shaders.GuardLock then return end
    if not Shaders.Config or Shaders.Config.DeleteOtherEffects == false then return end
    if Shaders.IsConflict(inst) then
        withGuard(function() inst:Destroy() end)
    end
end

function Shaders.OnLightingChildRemoved(inst)
    if Shaders.GuardLock then return end
    if not Shaders.IsOwned(inst) then return end
    local key = string.sub(inst.Name, #Shaders.PREFIX + 1)
    for _, def in ipairs(Shaders.EffectDefs) do
        if def.name == key then
            task.defer(function()
                if Shaders.GuardLock then return end
                withGuard(function() Shaders.ApplyEffect(def) end)
            end)
            return
        end
    end
end

-- ================= WATCHDOG =================
function Shaders.StartWatchdog()
    if Shaders._watchdogRunning then return end
    Shaders._watchdogRunning = true
    Shaders._watchdogThread = task.spawn(function()
        while Shaders._watchdogRunning do
            task.wait(Shaders.WatchdogInterval)
            if not Shaders._watchdogRunning then break end
            if not Shaders.Config or not Shaders.Lighting then continue end
            pcall(Shaders.PurgeForeign)
            pcall(Shaders.VerifyEffects)
            pcall(Shaders.VerifyWeather)
            pcall(Shaders.UpdatePosition)
        end
        Shaders._watchdogRunning = false
    end)
end

function Shaders.StopWatchdog()
    Shaders._watchdogRunning = false
    if Shaders._watchdogThread then
        pcall(function() task.cancel(Shaders._watchdogThread) end)
        Shaders._watchdogThread = nil
    end
end

function Shaders.StartGuard()
    Shaders.StopGuard()
    if not Shaders.Lighting then return end
    table.insert(Shaders.Connections,
        Shaders.Lighting.ChildAdded:Connect(Shaders.OnLightingChildAdded))
    table.insert(Shaders.Connections,
        Shaders.Lighting.ChildRemoved:Connect(Shaders.OnLightingChildRemoved))
    Shaders.StartWatchdog()
end

function Shaders.StopGuard()
    for _, c in ipairs(Shaders.Connections) do
        pcall(function() c:Disconnect() end)
    end
    Shaders.Connections = {}
    Shaders.StopWatchdog()
end

-- ================= MAIN =================
function Shaders.ApplyAll()
    Shaders.PurgeForeign()
    Shaders.ApplyAllEffects()
    Shaders.SetWeather(Shaders.GetActiveWeather())
end

function Shaders.SetDeleteOtherEffects(enabled)
    Shaders.Config.DeleteOtherEffects = enabled and true or false
    if enabled then Shaders.PurgeForeign() end
end

-- ================= SHUTDOWN / CLEANUP =================
function Shaders.Shutdown()
    Shaders._watchdogRunning = false
    Shaders.StopWatchdog()
    for _, c in ipairs(Shaders.Connections) do
        pcall(function() c:Disconnect() end)
    end
    Shaders.Connections = {}
    if Shaders.CharacterConn then
        pcall(function() Shaders.CharacterConn:Disconnect() end)
        Shaders.CharacterConn = nil
    end
    Shaders.StopWeather()

    local names = {}
    for n in pairs(Shaders.PostEffects) do table.insert(names, n) end
    for _, n in ipairs(names) do
        withGuard(function() Shaders.RemovePostEffect(n) end)
    end

    if Shaders.FogSaved and Shaders.Lighting then
        pcall(function()
            Shaders.Lighting.FogStart = Shaders.FogSaved.FogStart
            Shaders.Lighting.FogEnd   = Shaders.FogSaved.FogEnd
            Shaders.Lighting.FogColor = Shaders.FogSaved.FogColor
        end)
        Shaders.FogSaved = nil
    end

    if env[Shaders.GLOBAL_KEY] == Shaders then
        env[Shaders.GLOBAL_KEY] = nil
    end
end

Shaders.Cleanup = Shaders.Shutdown  -- алиас для обратной совместимости

-- ================= DEBUG =================
function Shaders.GetDebug()
    local l = Shaders.Lighting
    local own = 0
    if l then
        for _, c in ipairs(l:GetChildren()) do
            if Shaders.IsOwned(c) then own += 1 end
        end
    end
    return {
        activeWeather = Shaders.GetActiveWeather(),
        weatherType   = Shaders.WeatherType,
        weatherPart   = Shaders.WeatherPart,
        weatherAlive  = Shaders.WeatherPart and Shaders.WeatherPart.Parent ~= nil,
        emitters      = #Shaders.WeatherEmitters,
        ownPostEffects = own,
        globalSet     = env[Shaders.GLOBAL_KEY] == Shaders,
        watchdogAlive = Shaders._watchdogRunning,
        connections   = #Shaders.Connections,
    }
end

return Shaders