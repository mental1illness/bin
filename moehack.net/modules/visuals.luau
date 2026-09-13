--!native
--!optimize 2

--# Aliases

local FromOffset, FromScale, UDim2New = UDim2.fromOffset, UDim2.fromScale, UDim2.new
local Atan2, Rad, Pi, Abs, Minimum, Maximum, Floor, Clamp = math.atan2, math.rad, math.pi, math.abs, math.min, math.max, math.floor, math.clamp
local NewVector, NewVector3, NewCFrame = vector.create, Vector3.new, CFrame.new
local Create, IsA = Instance.new, workspace.IsA
local Spawn, Wait = task.spawn, task.wait
local ForEach, Insert, RemoveTable = table.foreach, table.insert, table.remove
local FindFirstChild, WaitForChild = workspace.FindFirstChild, workspace.WaitForChild
local WorldToViewportPoint = workspace.CurrentCamera.WorldToViewportPoint
local GetService = Game.GetService

--# Services
local MarketplaceService = GetService(Game, "MarketplaceService")
local ReplicatedStorage  = GetService(Game, "ReplicatedStorage")
local RunService         = GetService(Game, "RunService")
local Stats              = GetService(Game, "Stats")
local Players            = GetService(Game, "Players")
local Lighting           = GetService(Game, "Lighting")
local LocalPlayer        = Players.LocalPlayer

--# Helper Funcs (USELESS)
LoadModule = function(Path, Load)
    local url = "https://cats-cure-depression.vercel.app/" .. Path
    return Load == true and loadstring(game:HttpGet(url))() or game:HttpGet(url)
end

--# Variables
local FakeLibrary = {} do
    function FakeLibrary:GiveSignal() end
end

local Flags = {
    ["visuals/world/ambient"] = {Value = true},
    ["visuals/world/ambient/outdoorcolor"] = {Value = Color3.fromRGB(200, 100, 60)},
    ["visuals/world/ambient/color"] = {Value = Color3.fromRGB(200, 100, 60)},
    ["visuals/world/brightness"] = {Value = true},
    ["visuals/world/brightness/level"] = {Value = 1.6},
    ["visuals/world/brightness/envdiffscale"] = {Value = 1},
    ["visuals/world/brightness/envspecscale"] = {Value = 0.9},
    ["visuals/world/brightness/exposure"] = {Value = 0.15},
    ["visuals/world/fog"] = {Value = true},
    ["visuals/world/fog/color"] = {Value = Color3.fromRGB(200, 100, 60)},
    ["visuals/world/fog/near"] = {Value = 0},
    ["visuals/world/fog/far"] = {Value = 100000},
    ["visuals/world/shadow"] = {Value = true},
    ["visuals/world/shadow/color"] = {Value = Color3.fromRGB(200, 100, 60)},
    ["visuals/world/shadow/softness"] = {Value = 0.5},
    ["visuals/world/shadow/globalshadows"] = {Value = true},
    ["visuals/world/lighting"] = {Value = true},
    ["visuals/world/lighting/time"] = {Value = 14},
    ["visuals/world/lighting/latitude"] = {Value = 0},
    ["visuals/world/lighting/colorshiftbottom"] = {Value = Color3.fromRGB(200, 100, 60)},
    ["visuals/world/lighting/colorshifttop"] = {Value = Color3.fromRGB(200, 100, 60)},
    ["visuals/world/lighting/colorgrading"] = {Value = true},
    ["visuals/world/lighting/colorgrading/tonemap"] = {Value = "Retro"},
    ["visuals/world/lighting/cc"] = {Value = false},
    ["visuals/world/lighting/cc/saturation"] = {Value = 0.5},
    ["visuals/world/lighting/cc/contrast"] = {Value = 0.5},
    ["visuals/world/lighting/cc/brightness"] = {Value = 0},
    ["visuals/world/lighting/cc/tint"] = {Value = Color3.fromRGB(255, 255, 255)},
    ["visuals/world/lighting/bloom"] = {Value = true},
    ["visuals/world/lighting/bloom/intensity"] = {Value = 1},
    ["visuals/world/lighting/bloom/size"] = {Value = 56},
    ["visuals/world/lighting/bloom/threshold"] = {Value = 0.5},
    ["visuals/world/lighting/technology"] = {Value = "Future"},
    ["visuals/world/sunrays"] = {Value = false},
    ["visuals/world/sunrays/intensity"] = {Value = 0.1},
    ["visuals/world/sunrays/spread"] = {Value = 0.5},
    ["visuals/world/atmosphere"] = {Value = false},
    ["visuals/world/atmosphere/density"] = {Value = 0.3},
    ["visuals/world/atmosphere/offset"] = {Value = 0},
    ["visuals/world/atmosphere/color"] = {Value = Color3.fromRGB(199, 170, 107)},
    ["visuals/world/atmosphere/decay"] = {Value = Color3.fromRGB(106, 112, 125)},
    ["visuals/world/atmosphere/glare"] = {Value = 0},
    ["visuals/world/atmosphere/haze"] = {Value = 0},
    ["visuals/world/dof"] = {Value = true},
    ["visuals/world/dof/farintens"] = {Value = 0},
    ["visuals/world/dof/nearintens"] = {Value = 0.7},
    ["visuals/world/dof/focusdist"] = {Value = 20},
    ["visuals/world/dof/focusinradius"] = {Value = 20},

    ["visuals/world/weather"] = {Value=true},
    ["visuals/world/weather/type"] = {Value = "Rain"},

    ["visuals/player/chinesehat"] = {Value=true},
    ["visuals/player/chinesehat/glowfac"] = {Value = 5},
    ["visuals/player/chinesehat/radius"] = {Value = 1.5},
    ["visuals/player/chinesehat/height"] = {Value = 1},
    ["visuals/player/chinesehat/alwaysontop"] = {Value=true},
    ['visuals/player/chinesehat/color'] = {Value = Color3.fromRGB(255, 255, 255)}
}

local HiddenFolder = Create("Folder", gethui and gethui() or GetService(Game, "CoreGui"))
local Library = getgenv().Library or FakeLibrary
local Toggles, Options = getgenv().Toggles or Flags, getgenv().Options or Flags
local Camera = workspace.CurrentCamera

local DefaultLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    ExposureCompensation = Lighting.ExposureCompensation,
    ClockTime = Lighting.ClockTime,
    FogColor = Lighting.FogColor,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    ShadowSoftness = Lighting.ShadowSoftness,
    TimeOfDay = Lighting.TimeOfDay,
    GeographicLatitude = Lighting.GeographicLatitude,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    ColorShift_Top = Lighting.ColorShift_Top,
    Technology = Lighting.Technology,
    SunRaysIntensity = 0.1,
    SunRaysSpread = 0.5,
    AtmosphereDensity = 0,
    AtmosphereOffset = 0,
    AtmosphereColor = Color3.fromRGB(199, 170, 107),
    AtmosphereDecay = Color3.fromRGB(106, 112, 125),
    AtmosphereGlare = 0,
    AtmosphereHaze = 0,
}

local Rain, IsRainEnabled = LoadModule("moehack.net/rain.luau", true), false

Rain:SetColor(Color3.fromRGB(220, 225, 235))
Rain:SetTransparency(0.05)
Rain:SetSpeedRatio(0.85)
Rain:SetIntensityRatio(0.55)
Rain:SetLightEmission(0.05)
Rain:SetLightInfluence(0.85)
Rain:SetVolume(0.35)
Rain:SetDirection(Vector3.new(0.15, -1, 0.05))

--# Main
local Visuals = {}

Visuals.World = {} do
    function Visuals.World.GetDefaultLighting()
        return DefaultLighting
    end

    function Visuals.World.Tick()
        local DefaultLighting = Visuals.World.GetDefaultLighting()

        if Toggles["visuals/world/weather"].Value then
            local WeatherType = Options["visuals/world/weather/type"].Value
            if WeatherType == "Rain" then
                if not IsRainEnabled then
                    IsRainEnabled = true
                    Rain:Enable(TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
                end
            else
                if IsRainEnabled then
                    Rain:Disable(TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
                    IsRainEnabled = false
                end
            end
        else
            if IsRainEnabled then
                Rain:Disable(TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
                IsRainEnabled = false
            end
        end

        if not Visuals.World.ColorCorrection then
            Visuals.World.ColorCorrection = Create("ColorCorrectionEffect")
            Visuals.World.ColorCorrection.Enabled = false
            Visuals.World.ColorCorrection.Name = "\0"
            Visuals.World.ColorCorrection.Parent = Lighting
        end
        if not Visuals.World.Bloom then
            Visuals.World.Bloom = Create("BloomEffect")
            Visuals.World.Bloom.Enabled = false
            Visuals.World.Bloom.Name = "\0"
            Visuals.World.Bloom.Parent = Lighting
        end
        if not Visuals.World.DepthOfField then
            Visuals.World.DepthOfField = Create("DepthOfFieldEffect")
            Visuals.World.DepthOfField.Enabled = false
            Visuals.World.DepthOfField.Name = "\0"
            Visuals.World.DepthOfField.Parent = Lighting
        end
        if not Visuals.World.ColorGrading then
            Visuals.World.ColorGrading = Create("ColorGradingEffect")
            Visuals.World.ColorGrading.Enabled = false
            Visuals.World.ColorGrading.Name = "\0"
            Visuals.World.ColorGrading.Parent = Lighting
        end
        if not Visuals.World.SunRays then
            Visuals.World.SunRays = Create("SunRaysEffect")
            Visuals.World.SunRays.Enabled = false
            Visuals.World.SunRays.Name = "\0"
            Visuals.World.SunRays.Parent = Lighting
        end
        
        if not Visuals.World.Atmosphere then
            Visuals.World.Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Create("Atmosphere")
            Visuals.World.Atmosphere.Name = "\0"
            Visuals.World.Atmosphere.Parent = Lighting
        end

        local Ambient = Options["visuals/world/ambient/color"].Value
        local OutdoorAmbient = Options["visuals/world/ambient/outdoorcolor"].Value
        if Toggles["visuals/world/ambient"].Value then
            if Lighting.Ambient ~= Ambient then Lighting.Ambient = Ambient end
            if Lighting.OutdoorAmbient ~= OutdoorAmbient then Lighting.OutdoorAmbient = OutdoorAmbient end
        else
            if Lighting.Ambient ~= DefaultLighting.Ambient then Lighting.Ambient = DefaultLighting.Ambient end
            if Lighting.OutdoorAmbient ~= DefaultLighting.OutdoorAmbient then Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient end
        end

        if Toggles["visuals/world/brightness"].Value then
            local ClockTime = Options["visuals/world/lighting/time"].Value
            local Brightness = Options["visuals/world/brightness/level"].Value
            local DiffuseScale = Options["visuals/world/brightness/envdiffscale"].Value
            local SpecularScale = Options["visuals/world/brightness/envspecscale"].Value
            local Exposure = Options["visuals/world/brightness/exposure"].Value

            if Lighting.Brightness ~= Brightness then Lighting.Brightness = Brightness end
            if Lighting.ClockTime ~= ClockTime then Lighting.ClockTime = ClockTime end
            if Lighting.EnvironmentDiffuseScale ~= DiffuseScale then Lighting.EnvironmentDiffuseScale = DiffuseScale end
            if Lighting.EnvironmentSpecularScale ~= SpecularScale then Lighting.EnvironmentSpecularScale = SpecularScale end
            if Lighting.ExposureCompensation ~= Exposure then Lighting.ExposureCompensation = Exposure end
        else
            if Lighting.Brightness ~= DefaultLighting.Brightness then Lighting.Brightness = DefaultLighting.Brightness end
            if Lighting.ClockTime ~= DefaultLighting.ClockTime then Lighting.ClockTime = DefaultLighting.ClockTime end
            if Lighting.EnvironmentDiffuseScale ~= DefaultLighting.EnvironmentDiffuseScale then Lighting.EnvironmentDiffuseScale = DefaultLighting.EnvironmentDiffuseScale end
            if Lighting.EnvironmentSpecularScale ~= DefaultLighting.EnvironmentSpecularScale then Lighting.EnvironmentSpecularScale = DefaultLighting.EnvironmentSpecularScale end
            if Lighting.ExposureCompensation ~= DefaultLighting.ExposureCompensation then Lighting.ExposureCompensation = DefaultLighting.ExposureCompensation end
            if Lighting.Technology ~= DefaultLighting.Technology then Lighting.Technology = DefaultLighting.Technology end
        end

        if Toggles["visuals/world/fog"].Value then
            local FogColor = Options["visuals/world/fog/color"].Value
            local FogStart = Options["visuals/world/fog/near"].Value
            local FogEnd = Options["visuals/world/fog/far"].Value


            if Lighting.FogColor ~= FogColor then Lighting.FogColor = FogColor end
            if Lighting.FogStart ~= FogStart then Lighting.FogStart = FogStart end
            if Lighting.FogEnd ~= FogEnd then Lighting.FogEnd = FogEnd end
        else
            if Lighting.FogColor ~= DefaultLighting.FogColor then Lighting.FogColor = DefaultLighting.FogColor end
            if Lighting.FogStart ~= DefaultLighting.FogStart then Lighting.FogStart = DefaultLighting.FogStart end
            if Lighting.FogEnd ~= DefaultLighting.FogEnd then Lighting.FogEnd = DefaultLighting.FogEnd end
        end

        if Toggles["visuals/world/shadow"].Value then
            local GlobalShadows = Toggles["visuals/world/shadow/globalshadows"].Value
            local ShadowSoftness = Options["visuals/world/shadow/softness"].Value
            if Lighting.GlobalShadows ~= GlobalShadows then Lighting.GlobalShadows = GlobalShadows end
            if Lighting.ShadowSoftness ~= ShadowSoftness then Lighting.ShadowSoftness = ShadowSoftness end
        else
            if Lighting.GlobalShadows ~= DefaultLighting.GlobalShadows then Lighting.GlobalShadows = DefaultLighting.GlobalShadows end
            if Lighting.ShadowSoftness ~= DefaultLighting.ShadowSoftness then Lighting.ShadowSoftness = DefaultLighting.ShadowSoftness end
        end

        if Toggles["visuals/world/lighting"].Value then
            local TimeOfDay = Options["visuals/world/lighting/time"].Value
            local Latitude = Options["visuals/world/lighting/latitude"].Value
            local Bottom = Options["visuals/world/lighting/colorshiftbottom"].Value
            local Top = Options["visuals/world/lighting/colorshifttop"].Value
            local Technology = Enum.Technology[Options["visuals/world/lighting/technology"].Value]

            if Lighting.TimeOfDay ~= TimeOfDay then Lighting.TimeOfDay = TimeOfDay end
            if Lighting.GeographicLatitude ~= Latitude then Lighting.GeographicLatitude = Latitude end
            if Lighting.ColorShift_Bottom ~= Bottom then Lighting.ColorShift_Bottom = Bottom end
            if Lighting.ColorShift_Top ~= Top then Lighting.ColorShift_Top = Top end
            if Technology and Lighting.Technology ~= Technology then Lighting.Technology = Technology end
        else
            if Lighting.TimeOfDay ~= DefaultLighting.TimeOfDay then Lighting.TimeOfDay = DefaultLighting.TimeOfDay end
            if Lighting.GeographicLatitude ~= DefaultLighting.GeographicLatitude then Lighting.GeographicLatitude = DefaultLighting.GeographicLatitude end
            if Lighting.ColorShift_Bottom ~= DefaultLighting.ColorShift_Bottom then Lighting.ColorShift_Bottom = DefaultLighting.ColorShift_Bottom end
            if Lighting.ColorShift_Top ~= DefaultLighting.ColorShift_Top then Lighting.ColorShift_Top = DefaultLighting.ColorShift_Top end
        end

        local ColorCorrection = Visuals.World.ColorCorrection
        local ColorCorrectionEnabled = Toggles["visuals/world/lighting/cc"].Value
            and Toggles["visuals/world/lighting"].Value

        ColorCorrection.Parent = Lighting
        if ColorCorrection.Enabled ~= ColorCorrectionEnabled then
            ColorCorrection.Enabled = ColorCorrectionEnabled
        end
        
        if ColorCorrectionEnabled then
            local Saturation = Options["visuals/world/lighting/cc/saturation"].Value
            local Contrast = Options["visuals/world/lighting/cc/contrast"].Value
            local Brightness = Options["visuals/world/lighting/cc/brightness"].Value
            local TintColor = Options["visuals/world/lighting/cc/tint"].Value
            if ColorCorrection.Saturation ~= Saturation then ColorCorrection.Saturation = Saturation end
            if ColorCorrection.Contrast ~= Contrast then ColorCorrection.Contrast = Contrast end
            if ColorCorrection.Brightness ~= Brightness then ColorCorrection.Brightness = Brightness end
            if ColorCorrection.TintColor ~= TintColor then ColorCorrection.TintColor = TintColor end
        end

        local Bloom = Visuals.World.Bloom
        local BloomEnabled = Toggles["visuals/world/lighting/bloom"].Value and Toggles["visuals/world/lighting"].Value
        if Bloom.Enabled ~= BloomEnabled then Bloom.Enabled = BloomEnabled end
        if BloomEnabled then
            local Intensity = Options["visuals/world/lighting/bloom/intensity"].Value
            local Size = Options["visuals/world/lighting/bloom/size"].Value
            local Threshold = Options["visuals/world/lighting/bloom/threshold"].Value
            if Bloom.Intensity ~= Intensity then Bloom.Intensity = Intensity end
            if Bloom.Size ~= Size then Bloom.Size = Size end
            if Bloom.Threshold ~= Threshold then Bloom.Threshold = Threshold end
        end

        local DepthOfField = Visuals.World.DepthOfField
        local DepthOfFieldEnabled = Toggles["visuals/world/dof"].Value
        if DepthOfField.Enabled ~= DepthOfFieldEnabled then DepthOfField.Enabled = DepthOfFieldEnabled end
        if DepthOfFieldEnabled then
            local FarIntensity = Options["visuals/world/dof/farintens"].Value
            local NearIntensity = Options["visuals/world/dof/nearintens"].Value
            local FocusDistance = Options["visuals/world/dof/focusdist"].Value
            local InFocusRadius = Options["visuals/world/dof/focusinradius"].Value
            if DepthOfField.FarIntensity ~= FarIntensity then DepthOfField.FarIntensity = FarIntensity end
            if DepthOfField.NearIntensity ~= NearIntensity then DepthOfField.NearIntensity = NearIntensity end
            if DepthOfField.FocusDistance ~= FocusDistance then DepthOfField.FocusDistance = FocusDistance end
            if DepthOfField.InFocusRadius ~= InFocusRadius then DepthOfField.InFocusRadius = InFocusRadius end
        end

        local ColorGrading = Visuals.World.ColorGrading
        local ColorGradingEnabled = Toggles["visuals/world/lighting/colorgrading"].Value and Toggles["visuals/world/lighting"].Value
        if ColorGrading.Enabled ~= ColorGradingEnabled then ColorGrading.Enabled = ColorGradingEnabled end
        if ColorGradingEnabled then
            local TonemapperPreset = Enum.TonemapperPreset[Options["visuals/world/lighting/colorgrading/tonemap"].Value]
            if TonemapperPreset and ColorGrading.TonemapperPreset ~= TonemapperPreset then
                ColorGrading.TonemapperPreset = TonemapperPreset
            end
        end

        local SunRays = Visuals.World.SunRays
        local SunRaysEnabled = Toggles["visuals/world/sunrays"].Value
            and Toggles["visuals/world/lighting"].Value
        if SunRays.Enabled ~= SunRaysEnabled then SunRays.Enabled = SunRaysEnabled end
        if SunRaysEnabled then
            local Intensity = Options["visuals/world/sunrays/intensity"].Value
            local Spread = Options["visuals/world/sunrays/spread"].Value
            if SunRays.Intensity ~= Intensity then SunRays.Intensity = Intensity end
            if SunRays.Spread ~= Spread then SunRays.Spread = Spread end
        end

        local Atmosphere = Visuals.World.Atmosphere
        local AtmosphereEnabled = Toggles["visuals/world/atmosphere"].Value
            and Toggles["visuals/world/lighting"].Value
        Atmosphere.Density = AtmosphereEnabled
            and Options["visuals/world/atmosphere/density"].Value
            or DefaultLighting.AtmosphereDensity
        Atmosphere.Offset = AtmosphereEnabled
            and Options["visuals/world/atmosphere/offset"].Value
            or DefaultLighting.AtmosphereOffset
        Atmosphere.Color = AtmosphereEnabled
            and Options["visuals/world/atmosphere/color"].Value
            or DefaultLighting.AtmosphereColor
        Atmosphere.Decay = AtmosphereEnabled
            and Options["visuals/world/atmosphere/decay"].Value
            or DefaultLighting.AtmosphereDecay
        Atmosphere.Glare = AtmosphereEnabled
            and Options["visuals/world/atmosphere/glare"].Value
            or DefaultLighting.AtmosphereGlare
        Atmosphere.Haze = AtmosphereEnabled
            and Options["visuals/world/atmosphere/haze"].Value
            or DefaultLighting.AtmosphereHaze
    end
end

function Visuals.GetClientCharacter()
    return LocalPlayer.Character or nil
end

Visuals.Players = {} do

    function Visuals.Players.Tick()
        if Toggles["visuals/player/chinesehat"].Value then
            if not Visuals.Players.ChineseHat then
                Visuals.Players.ChineseHat = Create("ConeHandleAdornment")
                Visuals.Players.ChineseHat.Shading = Enum.AdornShading.Shaded
                Visuals.Players.ChineseHat.Radius = 1.5
                Visuals.Players.ChineseHat.CFrame = NewCFrame(0, 0.25, 0) * CFrame.Angles(Rad(90), 0, 0)
                Visuals.Players.ChineseHat.Color3 = Color3.fromRGB(255, 255, 255)
                Visuals.Players.ChineseHat.Hollow = true
                Visuals.Players.ChineseHat.Height = 1
                Visuals.Players.ChineseHat.AdornCullingMode = Enum.AdornCullingMode.Never
                Visuals.Players.ChineseHat.Parent = HiddenFolder
            end

            if Visuals.Players.ChineseHat.Height ~= Options["visuals/player/chinesehat/height"].Value then
                Visuals.Players.ChineseHat.Height = Options["visuals/player/chinesehat/height"].Value
            end

            if Visuals.Players.ChineseHat.Radius ~= Options["visuals/player/chinesehat/radius"].Value then
                Visuals.Players.ChineseHat.Radius = Options["visuals/player/chinesehat/radius"].Value
            end

            if Toggles["visuals/player/chinesehat/alwaysontop"].Value == true then
                if Visuals.Players.ChineseHat.Shading ~= Enum.AdornShading.XRayShaded then
                    Visuals.Players.ChineseHat.Shading = Enum.AdornShading.XRayShaded
                end
            else
                if Visuals.Players.ChineseHat.Shading ~= Enum.AdornShading.Shaded then
                    Visuals.Players.ChineseHat.Shading = Enum.AdornShading.Shaded
                end
            end

            local LastColorThatShouldBeBroImSoScaredMeSOSALYOU= Color3.fromRGB(
                Options['visuals/player/chinesehat/color'].Value.R * (100 * Options["visuals/player/chinesehat/glowfac"].Value),
                Options['visuals/player/chinesehat/color'].Value.G * (100 * Options["visuals/player/chinesehat/glowfac"].Value),
                Options['visuals/player/chinesehat/color'].Value.B * (100 * Options["visuals/player/chinesehat/glowfac"].Value)
            )

            if Visuals.Players.ChineseHat.Color3 ~= LastColorThatShouldBeBroImSoScaredMeSOSALYOU then
                Visuals.Players.ChineseHat.Color3 = LastColorThatShouldBeBroImSoScaredMeSOSALYOU
            end

            local Character = Visuals.GetClientCharacter()
            if Character then
                local Head = FindFirstChild(Character, "Head")
                if Head then
                    if Visuals.Players.ChineseHat.Adornee ~= Head then
                        Visuals.Players.ChineseHat.Adornee = Head
                    end

                    if not Visuals.Players.ChineseHat.Visible then
                        Visuals.Players.ChineseHat.Visible = true
                    end
                else
                    Visuals.Players.ChineseHat.Adornee = nil
                    Visuals.Players.ChineseHat.Visible = false
                end
            else
                Visuals.Players.ChineseHat.Adornee = nil
                Visuals.Players.ChineseHat.Visible = false
            end
            
        else
            if Visuals.Players.ChineseHat and Visuals.Players.ChineseHat.Visible then
                Visuals.Players.ChineseHat.Visible = false
                Visuals.Players.ChineseHat.Adornee = nil
            end
        end
        
    end

end

function Visuals.Tick()
    Visuals.Players.Tick()
    Visuals.World.Tick()
end

return Visuals
