-- ================= SHADER MODULE =================
local Shaders = {}
Shaders.PostEffects = {}
Shaders.FogSaved = nil
Shaders.WeatherPart = nil
Shaders.WeatherEmitter = nil
Shaders.SuppressWeatherToggle = false
Shaders.Config = nil
Shaders.Lighting = nil

function Shaders.Init(cfg, lighting)
    Shaders.Config = cfg
    Shaders.Lighting = lighting
end

function Shaders.EnsurePostEffect(name, className)
    if Shaders.PostEffects[name] and Shaders.PostEffects[name].Parent then
        return Shaders.PostEffects[name]
    end
    local existing = Shaders.Lighting:FindFirstChild("Noclipov_"..name)
    if existing then existing:Destroy() end
    local inst = Instance.new(className)
    inst.Name = "Noclipov_"..name
    inst.Parent = Shaders.Lighting
    Shaders.PostEffects[name] = inst
    return inst
end

function Shaders.RemovePostEffect(name)
    if Shaders.PostEffects[name] then
        pcall(function() Shaders.PostEffects[name]:Destroy() end)
        Shaders.PostEffects[name] = nil
    end
end

function Shaders.ApplyBloom()
    local cfg = Shaders.Config
    if cfg.BloomEnabled then
        local b = Shaders.EnsurePostEffect("Bloom", "BloomEffect")
        b.Intensity = cfg.BloomIntensity
        b.Size = cfg.BloomSize
        b.Threshold = cfg.BloomThreshold
        b.Enabled = true
    else Shaders.RemovePostEffect("Bloom") end
end

function Shaders.ApplyColorCorrection()
    local cfg = Shaders.Config
    if cfg.ColorCorrectionEnabled then
        local cc = Shaders.EnsurePostEffect("ColorCorrection", "ColorCorrectionEffect")
        cc.Brightness = cfg.CC_Brightness
        cc.Contrast = cfg.CC_Contrast
        cc.Saturation = cfg.CC_Saturation
        cc.TintColor = Color3.fromRGB(255, 255, 255)
        cc.Enabled = true
    else Shaders.RemovePostEffect("ColorCorrection") end
end

function Shaders.ApplyFog()
    local cfg = Shaders.Config
    local l = Shaders.Lighting
    if cfg.FogEnabled then
        if not Shaders.FogSaved then
            Shaders.FogSaved = {
                FogStart = l.FogStart,
                FogEnd = l.FogEnd,
                FogColor = l.FogColor,
            }
        end
        l.FogStart = cfg.FogStart
        l.FogEnd = cfg.FogEnd
        l.FogColor = Color3.fromRGB(200, 200, 220)
    elseif Shaders.FogSaved then
        l.FogStart = Shaders.FogSaved.FogStart
        l.FogEnd = Shaders.FogSaved.FogEnd
        l.FogColor = Shaders.FogSaved.FogColor
        Shaders.FogSaved = nil
    end
end

function Shaders.ApplyAtmosphere()
    local cfg = Shaders.Config
    if cfg.AtmosphereEnabled then
        local a = Shaders.EnsurePostEffect("Atmosphere", "Atmosphere")
        a.Density = cfg.AtmosDensity
        a.Haze = cfg.AtmosHaze
        a.Offset = 0.25
        a.Color = Color3.fromRGB(199, 199, 199)
        a.Decay = Color3.fromRGB(106, 112, 125)
        a.Glare = 0
        a.Enabled = true
    else Shaders.RemovePostEffect("Atmosphere") end
end

function Shaders.ApplySunRays()
    if Shaders.Config.SunRaysEnabled then
        local s = Shaders.EnsurePostEffect("SunRays", "SunRaysEffect")
        s.Intensity = 0.15
        s.Spread = 1
        s.Enabled = true
    else Shaders.RemovePostEffect("SunRays") end
end

function Shaders.ApplyDepthOfField()
    if Shaders.Config.DOFEnabled then
        local d = Shaders.EnsurePostEffect("DepthOfField", "DepthOfFieldEffect")
        d.FarIntensity = 0.15
        d.FocusDistance = 50
        d.InFocusRadius = 8
        d.NearIntensity = 0
        d.Enabled = true
    else Shaders.RemovePostEffect("DepthOfField") end
end

Shaders.WEATHER_CONFIGS = {
    snow = {
        Color = ColorSequence.new(Color3.fromRGB(255,255,255)),
        Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.3)}),
        Transparency = NumberSequence.new(0.15),
        Lifetime = NumberRange.new(3, 6), Speed = NumberRange.new(2, 5),
        Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-30, 30),
        Rate = 80, Acceleration = Vector3.new(0, -3, 0), Drag = 0.5,
        SpreadAngle = Vector2.new(15, 15), EmissionDirection = Enum.NormalId.Bottom,
        Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
    },
    rain = {
        Color = ColorSequence.new(Color3.fromRGB(180, 200, 255)),
        Size = NumberSequence.new(0.15), Transparency = NumberSequence.new(0.4),
        Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(60, 80),
        Rotation = NumberRange.new(0), RotSpeed = NumberRange.new(0),
        Rate = 200, Acceleration = Vector3.new(0, -100, 0), Drag = 0,
        SpreadAngle = Vector2.new(5, 5), EmissionDirection = Enum.NormalId.Bottom,
        Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
    },
    sakura = {
        Color = ColorSequence.new(Color3.fromRGB(255, 183, 197)),
        Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.5)}),
        Transparency = NumberSequence.new(0.1),
        Lifetime = NumberRange.new(4, 8), Speed = NumberRange.new(1, 3),
        Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60),
        Rate = 40, Acceleration = Vector3.new(2, -1.5, 1), Drag = 0.3,
        SpreadAngle = Vector2.new(30, 30), EmissionDirection = Enum.NormalId.Bottom,
        Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
    },
}

function Shaders.StopWeather()
    if Shaders.WeatherPart then pcall(function() Shaders.WeatherPart:Destroy() end) end
    Shaders.WeatherPart = nil
    Shaders.WeatherEmitter = nil
end

function Shaders.SetWeather(weatherType)
    Shaders.StopWeather()
    if weatherType == "none" or not Shaders.WEATHER_CONFIGS[weatherType] then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local cfg = Shaders.WEATHER_CONFIGS[weatherType]

    local part = Instance.new("Part")
    part.Name = "Noclipov_WeatherPart"
    part.Size = Vector3.new(120, 2, 120)
    part.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 40, 0))
    part.Transparency = 1
    part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
    part.Anchored = true; part.Parent = Workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "Noclipov_WeatherEmitter"
    emitter.Color = cfg.Color
    emitter.Size = cfg.Size
    emitter.Transparency = cfg.Transparency
    emitter.Lifetime = cfg.Lifetime
    emitter.Speed = cfg.Speed
    emitter.Rotation = cfg.Rotation
    emitter.RotSpeed = cfg.RotSpeed
    emitter.Rate = cfg.Rate * (Shaders.Config.WeatherIntensity or 1.0)
    emitter.Acceleration = cfg.Acceleration
    emitter.Drag = cfg.Drag
    emitter.SpreadAngle = cfg.SpreadAngle
    emitter.EmissionDirection = cfg.EmissionDirection
    emitter.Shape = cfg.Shape
    emitter.ShapeStyle = cfg.ShapeStyle
    emitter.LockedToPart = false
    emitter.Enabled = true
    emitter.Parent = part

    Shaders.WeatherPart = part
    Shaders.WeatherEmitter = emitter
end

function Shaders.UpdateWeatherRate()
    if Shaders.WeatherEmitter then
        local currentType = Shaders.GetActiveWeather()
        if currentType and Shaders.WEATHER_CONFIGS[currentType] then
            Shaders.WeatherEmitter.Rate = Shaders.WEATHER_CONFIGS[currentType].Rate * (Shaders.Config.WeatherIntensity or 1.0)
        end
    end
end

function Shaders.GetActiveWeather()
    if Shaders.Config.WeatherSnow then return "snow" end
    if Shaders.Config.WeatherRain then return "rain" end
    if Shaders.Config.WeatherSakura then return "sakura" end
    return "none"
end

function Shaders.ApplyAll()
    Shaders.ApplyBloom()
    Shaders.ApplyColorCorrection()
    Shaders.ApplyFog()
    Shaders.ApplyAtmosphere()
    Shaders.ApplySunRays()
    Shaders.ApplyDepthOfField()
    Shaders.SetWeather(Shaders.GetActiveWeather())
end

function Shaders.UpdatePosition()
    if Shaders.WeatherPart and Shaders.WeatherPart.Parent then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            Shaders.WeatherPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 40, 0))
        end
    end
end

function Shaders.Cleanup()
    Shaders.StopWeather()
    for name in pairs(Shaders.PostEffects) do
        pcall(function() Shaders.RemovePostEffect(name) end)
    end
    if Shaders.FogSaved then
        pcall(function()
            Shaders.Lighting.FogStart = Shaders.FogSaved.FogStart
            Shaders.Lighting.FogEnd = Shaders.FogSaved.FogEnd
            Shaders.Lighting.FogColor = Shaders.FogSaved.FogColor
        end)
        Shaders.FogSaved = nil
    end
end

return Shaders