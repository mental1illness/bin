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
local InputService       = GetService(Game, "UserInputService")
local Players            = GetService(Game, "Players")
local Lighting           = GetService(Game, "Lighting")
local TweenService       = GetService(Game, "TweenService")
local LocalPlayer        = Players.LocalPlayer

--# Helper Funcs (USELESS)

--# Modules

local Utility = moehack.load_module("moehack.net/modules/utility.luau")
local Skyboxes = moehack.load_module("moehack.net/modules/skyboxes.luau")
local GifRenderer = loadstring(Game:HttpGet("https://raw.githubusercontent.com/mental1illness/modules/refs/heads/main/GifRenderer.luau"))()
local GifDecoder = loadstring(Game:HttpGet("https://raw.githubusercontent.com/mental1illness/modules/refs/heads/main/GifDecoder.luau"))()

--# Variables

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

local Rain, IsRainEnabled = moehack.load_module("moehack.net/modules/rain.luau", true), false

Rain:SetColor(Color3.fromRGB(220, 225, 235))
Rain:SetTransparency(0.05)
Rain:SetSpeedRatio(0.85)
Rain:SetIntensityRatio(0.55)
Rain:SetLightEmission(0.05)
Rain:SetLightInfluence(0.85)
Rain:SetVolume(0.35)
Rain:SetDirection(NewVector3(0.15, -1, 0.05))

const SNOW_OFFSET  = NewCFrame(0, 10, 0) -- why do ppl think this is ai
const BREADCRUMBS_SIZE = NewVector3(0.05, 0.05, 0.05)

local OldAppearanceId, OldAppearanceCharacter = 0, nil
local LastPosition = NewVector3()
local LastBreadcrumbPosition

local LastLinkData = {
    Link = nil,
    Extension = nil, -- DAMN!!!
    CurrentImageLabel = nil,
    GifHandler = nil,
    Resolution = nil,
    Loading = false
}

local GifDataCache = {}

local ScreenGui = Create("ScreenGui", gethui())
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

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

            if WeatherType == "Snow" then
                if not Visuals.World.Snow then
                    Visuals.World.Snow = Create("Part")
                    Visuals.World.Snow.Transparency = 1
                    Visuals.World.Snow.Name = "\0"
                    Visuals.World.Snow.CanCollide = false
                    Visuals.World.Snow.Size = Vector3.new(127, 1, 144)
                    Visuals.World.Snow.Anchored = true
                    Visuals.World.Snow.Parent = nil

                    Visuals.World.SnowParticles = Create("ParticleEmitter")
                    Visuals.World.SnowParticles.Rate = 1000
                    Visuals.World.SnowParticles.Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(0.984, 0.043749988079071045),
                        NumberSequenceKeypoint.new(1, 1)
                    }

                    Visuals.World.SnowParticles.Texture = "http://www.roblox.com/asset/?id=99851851"
                    Visuals.World.SnowParticles.LightEmission = 0.5
                    Visuals.World.SnowParticles.SpreadAngle = Vector2.new(50, 50)
                    Visuals.World.SnowParticles.Speed = NumberRange.new(30, 30)
                    Visuals.World.SnowParticles.EmissionDirection = Enum.NormalId.Bottom
                    Visuals.World.SnowParticles.Size = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 0.33096909523010254),
                        NumberSequenceKeypoint.new(0.551, 0.40189146995544434),
                        NumberSequenceKeypoint.new(1, 0.33096909523010254)
                    }
                    Visuals.World.SnowParticles.Parent = Visuals.World.Snow

                    return
                end
            
                if Visuals.World.Snow and Visuals.World.Snow.Parent == nil then
                    Visuals.World.Snow.Parent = Camera
                end
                Visuals.World.Snow.CFrame = Camera.CFrame  * SNOW_OFFSET

                if Visuals.World.Snow and Visuals.World.SnowParticles.Rate ~= Options["visuals/world/snow/rate"].Value then Visuals.World.SnowParticles.Rate = Options["visuals/world/snow/rate"].Value end
            else
                if Visuals.World.Snow and Visuals.World.Snow.Parent ~= nil then
                    Visuals.World.Snow.Parent = nil
                end
            end

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
            if Visuals.World.Snow and Visuals.World.Snow.Parent ~= nil then
                Visuals.World.Snow.Parent = nil
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

        if not Visuals.World.Sky then
            Visuals.World.Sky = Create("Sky")
            Visuals.World.Sky.Name = "\0"
            Visuals.World.Sky.Parent = nil
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

        if Toggles["visuals/world/customskybox"].Value then
            local Type = Options["visuals/world/customskybox/type"].Value
            local SkyData = Skyboxes.Skies[Type]
            if Visuals.World.Sky.Parent ~= Lighting then
                Visuals.World.Sky.Parent = Lighting
            end
            if SkyData then
                for Key, Value in SkyData do
                    if Visuals.World.Sky[Key] ~= Value then Visuals.World.Sky[Key] = Value end
                end
            end
        else
            if Visuals.World.Sky.Parent ~= nil then
                Visuals.World.Sky.Parent = nil
            end
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
        local BloomEnabled = Toggles["visuals/world/lighting/bloom"].Value
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
        local ColorGradingEnabled = Toggles["visuals/world/lighting/colorgrading"].Value
        if ColorGrading.Enabled ~= ColorGradingEnabled then ColorGrading.Enabled = ColorGradingEnabled end
        if ColorGradingEnabled then
            local TonemapperPreset = Enum.TonemapperPreset[Options["visuals/world/lighting/colorgrading/tonemap"].Value]
            if TonemapperPreset and ColorGrading.TonemapperPreset ~= TonemapperPreset then
                ColorGrading.TonemapperPreset = TonemapperPreset
            end
        end

        local SunRays = Visuals.World.SunRays
        local SunRaysEnabled = Toggles["visuals/world/sunrays"].Value
        if SunRays.Enabled ~= SunRaysEnabled then SunRays.Enabled = SunRaysEnabled end
        if SunRaysEnabled then
            local Intensity = Options["visuals/world/sunrays/intensity"].Value
            local Spread = Options["visuals/world/sunrays/spread"].Value
            if SunRays.Intensity ~= Intensity then SunRays.Intensity = Intensity end
            if SunRays.Spread ~= Spread then SunRays.Spread = Spread end
        end

        local Atmosphere = Visuals.World.Atmosphere
        local AtmosphereEnabled = Toggles["visuals/world/atmosphere"].Value
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

Visuals.Camera = {} do
    
    function Visuals.Camera.Tick()


        if moehack.data.game_name == "Arsenal" then
            if Toggles["visuals/camera/thirdperson"].Value then
                local Dist = Options["visuals/camera/thirdperson/dist"].Value
                if Options["visuals/camera/thirdperson/key"]:GetState() then
                    if not LocalPlayer:GetAttribute("thirdy") then
                        LocalPlayer:SetAttribute("thirdy", true)
                    end
                    LocalPlayer.CameraMode = Enum.CameraMode.Classic
                    InputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                    LocalPlayer.CameraMinZoomDistance = Dist
                    LocalPlayer.CameraMaxZoomDistance = Dist
                else
                    if LocalPlayer:GetAttribute("thirdy") then
                        LocalPlayer:SetAttribute("thirdy", nil)
                        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
                        LocalPlayer.CameraMinZoomDistance = 8
                        LocalPlayer.CameraMaxZoomDistance = 8
                    end
                end
            else
                if LocalPlayer:GetAttribute("thirdy") then
                    LocalPlayer:SetAttribute("thirdy", nil)
                    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
                    LocalPlayer.CameraMinZoomDistance = 8
                    LocalPlayer.CameraMaxZoomDistance = 8
                end
            end
        end

        if Toggles["visuals/camera/waifu"].Value then
            local Link = Options["visuals/camera/waifu/link"].Value

            if Link and Link ~= "" and LastLinkData.Link ~= Link and not LastLinkData.Loading and string.match(Link, "^https://") then
                LastLinkData.Link = Link
                LastLinkData.Loading = true

                if LastLinkData.CurrentImageLabel then
                    LastLinkData.CurrentImageLabel:Destroy()
                    LastLinkData.CurrentImageLabel = nil
                end

                if LastLinkData.GifHandler then
                    LastLinkData.GifHandler:Destroy()
                    LastLinkData.GifHandler = nil
                end

                Spawn(function()
                    local Success, Bytes = pcall(Game.HttpGet, Game, Link)

                    if not Success or not Bytes or LastLinkData.Link ~= Link then
                        LastLinkData.Loading = false
                        return
                    end

                    local FileData = Utility.DetectFileType(Bytes)

                    if FileData.Extension == "png" then
                        writefile("temp.png", Bytes)

                        local ResolutionData = Utility.GetImageResolution(Bytes)
                        local NewImageLabel = Create("ImageLabel")

                        NewImageLabel.Parent = ScreenGui
                        NewImageLabel.BackgroundTransparency = 1
                        NewImageLabel.ImageTransparency = Options["visuals/camera/waifu/transparency"].Value
                        NewImageLabel.Image = getcustomasset("temp.png")

                        if ResolutionData.Width and ResolutionData.Height then
                            NewImageLabel.Size = FromOffset(
                                ResolutionData.Width,
                                ResolutionData.Height
                            )

                            LastLinkData.Resolution = ResolutionData
                        end

                        LastLinkData.Extension = FileData.Extension
                        LastLinkData.CurrentImageLabel = NewImageLabel
                    elseif FileData.Extension == "gif" then
                        local ResolutionData = Utility.GetImageResolution(Bytes)
                        local NewImageLabel = Create("ImageLabel")
                        if not GifDataCache[Link] then
                            GifDataCache[Link] = GifDecoder.decode(Bytes)
                        end
                        local DecodedGif = GifDataCache[Link]
                        
                        NewImageLabel.Parent = ScreenGui
                        NewImageLabel.BackgroundTransparency = 1
                        NewImageLabel.ImageTransparency = Options["visuals/camera/waifu/transparency"].Value

                        local GifRenderHandler = GifRenderer.new({
                            ImageLabel = NewImageLabel,
                            Size = Vector2.new(DecodedGif.Width, DecodedGif.Height),
                            Frames = DecodedGif.Frames,
                            Looped = DecodedGif.LoopCount == nil or DecodedGif.LoopCount == 0,
                            AutoPlay = true,
                        })

                        if DecodedGif.Width and DecodedGif.Height then
                            NewImageLabel.Size = FromOffset(
                                DecodedGif.Width,
                                DecodedGif.Height
                            )

                            LastLinkData.Resolution = {
                                Width = DecodedGif.Width,
                                Height = DecodedGif.Height
                            }
                        end

                        LastLinkData.Extension = FileData.Extension
                        LastLinkData.CurrentImageLabel = NewImageLabel
                        LastLinkData.GifHandler = GifRenderHandler
                    end

                    LastLinkData.Loading = false
                end)
            end

            local ImageLabel = LastLinkData.CurrentImageLabel

            if ImageLabel then
                local X = Options["visuals/camera/waifu/x"].Value
                local Y = Options["visuals/camera/waifu/y"].Value
                local Transparency = Options["visuals/camera/waifu/transparency"].Value
                local Scale = Options["visuals/camera/waifu/scale"].Value
            
                ImageLabel.Position = FromScale(X, Y)
                ImageLabel.AnchorPoint = Vector2.new(X, Y)
                ImageLabel.ImageTransparency = Transparency
            
                if LastLinkData.Resolution then
                    ImageLabel.Size = FromOffset(
                        LastLinkData.Resolution.Width * Scale,
                        LastLinkData.Resolution.Height * Scale
                    )
                end
            end
        else
            if LastLinkData.CurrentImageLabel then
                LastLinkData.CurrentImageLabel:Destroy()
                LastLinkData.CurrentImageLabel = nil
            end

            if LastLinkData.GifHandler then
                LastLinkData.GifHandler:Destroy()
                LastLinkData.GifHandler = nil
            end

            LastLinkData.Link = nil
            LastLinkData.Extension = nil
            LastLinkData.Resolution = nil
            LastLinkData.Loading = false
        end
    end

end

Visuals.Players = {} do

    function Visuals.Players.ChangeAvatar(id: number) -- i used ai for this btw
        local Character = LocalPlayer.Character
        if not Character then return false end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local PrimaryPart = Character.PrimaryPart
        if not Humanoid or not PrimaryPart then return false end

        Visuals.Players.AvatarCache = Visuals.Players.AvatarCache or {}

        local Description = Visuals.Players.AvatarCache[id]
        if not Description then
            Description = Players:GetHumanoidDescriptionFromUserIdAsync(id)
            if not Description then return false end
            Visuals.Players.AvatarCache[id] = Description
        end

        local RigType = Humanoid.RigType
        local Rig = Players:CreateHumanoidModelFromDescriptionAsync(Description, RigType)
        if not Rig then return false end

        local RigHumanoid = Rig:FindFirstChildOfClass("Humanoid")
        if not RigHumanoid then
            Rig:Destroy()
            return false
        end

        Rig:PivotTo(Character:GetPivot())
        local RigDescendants = Rig:GetDescendants()
        local CharacterDescendants = Character:GetDescendants()

        if RigType == Enum.HumanoidRigType.R15 then
            for _, Object in RigDescendants do
                local IsOk, BodyPart = pcall(RigHumanoid.GetBodyPartR15, RigHumanoid, Object)
                if not IsOk then continue end
                if BodyPart ~= Enum.BodyPartR15.Unknown and Character:FindFirstChild(Object.Name) then
                    Humanoid:ReplaceBodyPartR15(BodyPart, Object)
                end
            end
        elseif RigType == Enum.HumanoidRigType.R6 then
            for _, Object in CharacterDescendants do
                if Object:IsA("CharacterMesh") then
                    Object:Destroy()
                end
            end

            for _, Object in RigDescendants do
                if Object:IsA("CharacterMesh") then
                    Object.Parent = Character
                elseif Object:IsA("SpecialMesh")
                    and not Object:FindFirstAncestorOfClass("Accessory") then
                    local SourcePart = Object.Parent
                    local TargetPart = SourcePart and SourcePart:IsA("BasePart")
                        and Character:FindFirstChild(SourcePart.Name, true)
                    if TargetPart then
                        Object.Parent = TargetPart
                    end
                end
            end
        end

        local RigBodyColors = Rig:FindFirstChildOfClass("BodyColors")
        if RigBodyColors then
            local CharacterBodyColors = Character:FindFirstChildOfClass("BodyColors")
            if CharacterBodyColors then CharacterBodyColors:Destroy() end
            RigBodyColors.Parent = Character
        end

        for _, Object in CharacterDescendants do
            if Object:IsA("Shirt") or Object:IsA("Pants") or Object:IsA("ShirtGraphic") then
                Object:Destroy()
            end
        end

        for _, Object in RigDescendants do
            if Object:IsA("Shirt") or Object:IsA("Pants") or Object:IsA("ShirtGraphic") then
                Object.Parent = Character
            end
        end

        Humanoid:RemoveAccessories()
        for _, Accessory in RigHumanoid:GetAccessories() do
            local Clone = Accessory:Clone()
            if RigType == Enum.HumanoidRigType.R15 then
                Humanoid:AddAccessory(Clone)
            else
                Clone.Parent = Character
                local Weld = Clone:FindFirstChild("AccessoryWeld", true)
                local Part = Weld and Weld.Part1
                local TargetPart = Part and Character:FindFirstChild(Part.Name, true)
                if Weld and TargetPart then
                    Weld.Part1 = TargetPart
                end
            end
        end

        -- Rig:Destroy()
        return true
    end

    function Visuals.Players.MakeBreadcrumbs(pos, parent)
        local PreviousPosition = LastBreadcrumbPosition
        LastBreadcrumbPosition = pos

        local Part = Create("Part")

        Part.Anchored = true
        Part.CanCollide = false
        Part.CanTouch = false
        Part.CanQuery = false
        Part.CastShadow = false
        Part.Transparency = 1
        Part.Name = "\0"

        if PreviousPosition then
            local Direction = pos - PreviousPosition
            local Distance = Direction.Magnitude
            local Center = (PreviousPosition + pos) * 0.5

            Part.Size = Vector3.new(
                BREADCRUMBS_SIZE.X,
                BREADCRUMBS_SIZE.Y,
                Distance
            )

            Part.CFrame = CFrame.lookAt(Center, pos)
        else
            Part.Size = BREADCRUMBS_SIZE
            Part.Position = pos
        end

        Part.Parent = HiddenFolder

        local Color = Options["visuals/player/breadcrumbs/color"].Value
        local GlowFactor = Options["visuals/player/breadcrumbs/glowfac"].Value
        local Lifetime = Options["visuals/player/breadcrumbs/lifetime"].Value
        local FadeTime = Options["visuals/player/breadcrumbs/fadetime"].Value

        local GlowTypeSh = Create("BoxHandleAdornment")

        GlowTypeSh.AlwaysOnTop = true
        GlowTypeSh.Shading = Enum.AdornShading.XRayShaded
        GlowTypeSh.Size = Part.Size
        GlowTypeSh.Transparency = -1
        GlowTypeSh.Color3 = Color3.new(
            Color.R * GlowFactor,
            Color.G * GlowFactor,
            Color.B * GlowFactor
        )
        GlowTypeSh.AdornCullingMode = Enum.AdornCullingMode.Never
        GlowTypeSh.ZIndex = 9e9
        GlowTypeSh.Adornee = Part
        GlowTypeSh.Parent = HiddenFolder

        task.delay(Lifetime, function()
            if not GlowTypeSh.Parent then
                return
            end

            TweenService:Create(
                GlowTypeSh,
                TweenInfo.new(FadeTime, Enum.EasingStyle.Cubic),
                {
                    Transparency = 1
                }
            ):Play()

            task.delay(FadeTime, function()
                if GlowTypeSh.Parent then
                    GlowTypeSh:Destroy()
                end

                if Part.Parent then
                    Part:Destroy()
                end
            end)
        end)
    end

    function Visuals.Players.Tick()

        if Toggles["visuals/player/appearance"].Value then
            local Character = Utility.GetCharacter(LocalPlayer)
            local AppearanceId = tonumber(Options["visuals/player/appearance/id"].Value)

            if Character and AppearanceId then
                local Humanoid = Character:FindFirstChildOfClass("Humanoid")

                if Humanoid and Character.PrimaryPart
                    and (OldAppearanceId ~= AppearanceId or OldAppearanceCharacter ~= Character) then

                    if Visuals.Players.ChangeAvatar(AppearanceId) then
                        OldAppearanceId = AppearanceId
                        OldAppearanceCharacter = Character
                    end
                end
            end
        else
            OldAppearanceId = 0
            OldAppearanceCharacter = nil
        end

        if Toggles["visuals/player/chinesehat"].Value then
            if not Visuals.Players.ChineseHat then
                Visuals.Players.ChineseHat = Create("ConeHandleAdornment")
                Visuals.Players.ChineseHat.Shading = Enum.AdornShading.Shaded
                Visuals.Players.ChineseHat.Radius = 1.5
                Visuals.Players.ChineseHat.Transparency = -1
                Visuals.Players.ChineseHat.CFrame = NewCFrame(0, 0.25, 0) * CFrame.Angles(Rad(90), 0, 0)
                Visuals.Players.ChineseHat.Color3 = Color3.fromRGB(255, 255, 255)
                Visuals.Players.ChineseHat.Hollow = true
                Visuals.Players.ChineseHat.Height = 1
                Visuals.Players.ChineseHat.AdornCullingMode = Enum.AdornCullingMode.Never
                Visuals.Players.ChineseHat.ZIndex = 9e9
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

            local Character = Utility.GetCharacter(LocalPlayer)
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

        if Toggles["visuals/player/breadcrumbs"].Value then
            local Character = Utility.GetCharacter(LocalPlayer)
            if Character then
                local PrimaryPart = Character.PrimaryPart
                if PrimaryPart and PrimaryPart.Position ~= LastPosition then
                    LastPosition = PrimaryPart.Position -- Thx
                    Visuals.Players.MakeBreadcrumbs(PrimaryPart.Position, PrimaryPart)
                end
            end
        else
            LastBreadcrumbPosition = nil
        end
        
    end

end

do -- Other funcs
    function Visuals:BulletTracers(Origin, HitPos)
        local Direction = HitPos - Origin
        local Distance = Direction.Magnitude
    
        if Distance <= 0 then
            return
        end
    
        Direction = Direction.Unit
    
        local Mode = Options["visuals/world/bullettracers/mode"].Value
        local Color = Options["visuals/world/bullettracers/color"].Value
        local Thickness = Options["visuals/world/bullettracers/thickness"].Value
        local Segments = Options["visuals/world/bullettracers/quality"].Value
        local Radius = Distance * (Options["visuals/world/bullettracers/radius"].Value / 1000)
        local Turns = Options["visuals/world/bullettracers/turns"].Value
        local Waves = Options["visuals/world/bullettracers/waves"].Value
        local LightningJitter = Distance * (Options["visuals/world/bullettracers/lightning"].Value / 100)
        local AlwaysOnTop = Options["visuals/world/bullettracers/alwaysontop"].Value
        local DynamicThickness = Options["visuals/world/bullettracers/dynamicthickness"].Value
        local Animated = Options["visuals/world/bullettracers/animated"].Value
        local LifeTime = Options["visuals/world/bullettracers/lifetime"].Value
        local FadeTime = Options["visuals/world/bullettracers/fadetime"].Value
        local TravelTime = Options["visuals/world/bullettracers/traveltime"].Value
    
        local Tracer = Utility.Create("Part", {
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            Transparency = 1,
            Size = Vector3.one,
            CFrame = NewCFrame(Origin),
            Parent = Camera
        })
    
        local Lines = {}
        local Up = Abs(Direction:Dot(Vector3.yAxis)) > 0.98 and Vector3.xAxis or Vector3.yAxis
        local Right = Direction:Cross(Up).Unit
        Up = Right:Cross(Direction).Unit
    
        Segments = Clamp(Segments, 16, 256)
    
        if Mode == "Default" then
            local Line = Utility.Create("LineHandleAdornment", {
                Adornee = Tracer,
                AlwaysOnTop = AlwaysOnTop,
                ZIndex = 10,
                Thickness = Thickness,
                Color3 = Color,
                Length = Distance,
                CFrame = NewCFrame(Vector3.zero, Direction),
                Parent = Tracer
            })
    
            Lines[#Lines + 1] = { Object = Line, Length = Distance }
    
        elseif Mode == "Spiral" then
            for Index = 1, Segments do
                local Alpha1 = (Index - 1) / Segments
                local Alpha2 = Index / Segments
                local Angle1 = Alpha1 * Turns * Pi * 2
                local Angle2 = Alpha2 * Turns * Pi * 2
    
                local Position1 = Direction * (Distance * Alpha1) + (Right * math.cos(Angle1) + Up * math.sin(Angle1)) * Radius
                local Position2 = Direction * (Distance * Alpha2) + (Right * math.cos(Angle2) + Up * math.sin(Angle2)) * Radius
    
                local SegmentDirection = Position2 - Position1
                local Length = SegmentDirection.Magnitude
    
                if Length > 0 then
                    local Line = Utility.Create("LineHandleAdornment", {
                        Adornee = Tracer,
                        AlwaysOnTop = AlwaysOnTop,
                        ZIndex = 10,
                        Thickness = DynamicThickness and Maximum(0.5, Thickness * (1 - Alpha1)) or Thickness,
                        Color3 = Color,
                        Length = Length,
                        CFrame = NewCFrame(Position1, Position2),
                        Parent = Tracer
                    })
    
                    Lines[#Lines + 1] = { Object = Line, Length = Length }
                end
            end
    
        elseif Mode == "Wave" or Mode == "ZigZag" then
            for Index = 1, Segments do
                local Alpha1 = (Index - 1) / Segments
                local Alpha2 = Index / Segments
    
                local Offset1 = math.sin(Alpha1 * Waves * Pi * 2) * Radius
                local Offset2 = math.sin(Alpha2 * Waves * Pi * 2) * Radius
    
                local Position1 = Direction * (Distance * Alpha1) + Right * Offset1
                local Position2 = Direction * (Distance * Alpha2) + Right * Offset2
    
                local SegmentDirection = Position2 - Position1
                local Length = SegmentDirection.Magnitude
    
                if Length > 0 then
                    local Line = Utility.Create("LineHandleAdornment", {
                        Adornee = Tracer,
                        AlwaysOnTop = AlwaysOnTop,
                        ZIndex = 10,
                        Thickness = DynamicThickness and Maximum(0.5, Thickness * (1 - Alpha1)) or Thickness,
                        Color3 = Color,
                        Length = Length,
                        CFrame = NewCFrame(Position1, Position2),
                        Parent = Tracer
                    })
    
                    Lines[#Lines + 1] = { Object = Line, Length = Length }
                end
            end
    
        elseif Mode == "Double" then
            for Side = -1, 1, 2 do
                local Offset = Right * Radius * Side
    
                local Line = Utility.Create("LineHandleAdornment", {
                    Adornee = Tracer,
                    AlwaysOnTop = AlwaysOnTop,
                    ZIndex = 10,
                    Thickness = Thickness,
                    Color3 = Color,
                    Length = Distance,
                    CFrame = NewCFrame(Offset, Offset + Direction),
                    Parent = Tracer
                })
    
                Lines[#Lines + 1] = { Object = Line, Length = Distance }
            end
    
        elseif Mode == "Cross" then
            for Side = -1, 1, 2 do
                local Offset = (Right + Up * Side).Unit * Radius
    
                local Line = Utility.Create("LineHandleAdornment", {
                    Adornee = Tracer,
                    AlwaysOnTop = AlwaysOnTop,
                    ZIndex = 10,
                    Thickness = Thickness,
                    Color3 = Color,
                    Length = Distance,
                    CFrame = NewCFrame(Offset, Offset + Direction),
                    Parent = Tracer
                })
    
                Lines[#Lines + 1] = { Object = Line, Length = Distance }
            end
    
        elseif Mode == "Dash" then
            local DashLength = Radius
            local GapLength = Radius
            local Step = DashLength + GapLength
    
            for Position = 0, Distance, Step do
                local Length = Minimum(DashLength, Distance - Position)
    
                if Length > 0 then
                    local Start = Direction * Position
                    local Finish = Start + Direction * Length
    
                    local Line = Utility.Create("LineHandleAdornment", {
                        Adornee = Tracer,
                        AlwaysOnTop = AlwaysOnTop,
                        ZIndex = 10,
                        Thickness = Thickness,
                        Color3 = Color,
                        Length = Length,
                        CFrame = NewCFrame(Start, Finish),
                        Parent = Tracer
                    })
    
                    Lines[#Lines + 1] = { Object = Line, Length = Length }
                end
            end
    
        elseif Mode == "Pulse" then
            local Line = Utility.Create("LineHandleAdornment", {
                Adornee = Tracer,
                AlwaysOnTop = AlwaysOnTop,
                ZIndex = 10,
                Thickness = Thickness,
                Color3 = Color,
                Length = Distance,
                CFrame = NewCFrame(Vector3.zero, Direction),
                Parent = Tracer
            })
    
            Lines[#Lines + 1] = { Object = Line, Length = Distance }
    
        elseif Mode == "Taper" then
            for Index = 1, Segments do
                local Alpha1 = (Index - 1) / Segments
                local Alpha2 = Index / Segments
    
                local Position1 = Direction * (Distance * Alpha1)
                local Position2 = Direction * (Distance * Alpha2)
    
                local SegmentDirection = Position2 - Position1
                local Length = SegmentDirection.Magnitude
    
                if Length > 0 then
                    local Line = Utility.Create("LineHandleAdornment", {
                        Adornee = Tracer,
                        AlwaysOnTop = AlwaysOnTop,
                        ZIndex = 10,
                        Thickness = Maximum(0.5, Thickness * (1 - Alpha1)),
                        Color3 = Color,
                        Length = Length,
                        CFrame = NewCFrame(Position1, Position2),
                        Parent = Tracer
                    })
    
                    Lines[#Lines + 1] = { Object = Line, Length = Length }
                end
            end
    
        elseif Mode == "Helix" then
            for Index = 1, Segments do
                local Alpha1 = (Index - 1) / Segments
                local Alpha2 = Index / Segments
    
                local Angle1 = Alpha1 * Turns * Pi * 2
                local Angle2 = Alpha2 * Turns * Pi * 2
    
                local Position1 = Direction * (Distance * Alpha1) + (Right * math.cos(Angle1) + Up * math.sin(Angle1)) * Radius
                local Position2 = Direction * (Distance * Alpha2) + (Right * math.cos(Angle2) + Up * math.sin(Angle2)) * Radius
    
                local SegmentDirection = Position2 - Position1
                local Length = SegmentDirection.Magnitude
    
                if Length > 0 then
                    local Line = Utility.Create("LineHandleAdornment", {
                        Adornee = Tracer,
                        AlwaysOnTop = AlwaysOnTop,
                        ZIndex = 10,
                        Thickness = DynamicThickness and Maximum(0.5, Thickness * (1 - Alpha1)) or Thickness,
                        Color3 = Color,
                        Length = Length,
                        CFrame = NewCFrame(Position1, Position2),
                        Parent = Tracer
                    })
    
                    Lines[#Lines + 1] = { Object = Line, Length = Length }
                end
            end
    
        elseif Mode == "Lightning" then
            local PreviousPosition = Vector3.zero
    
            for Index = 1, Segments do
                local Alpha = Index / Segments
                local Position = Direction * (Distance * Alpha)
    
                if Index < Segments then
                    local Falloff = math.sin(Alpha * Pi)
    
                    Position += (
                        Right * math.sin(Alpha * Waves * Pi * 2) +
                        Up * math.cos(Alpha * Waves * Pi * 2)
                    ) * LightningJitter * Falloff
                end
    
                local SegmentDirection = Position - PreviousPosition
                local Length = SegmentDirection.Magnitude
    
                if Length > 0 then
                    local Line = Utility.Create("LineHandleAdornment", {
                        Adornee = Tracer,
                        AlwaysOnTop = AlwaysOnTop,
                        ZIndex = 10,
                        Thickness = Thickness,
                        Color3 = Color,
                        Length = Length,
                        CFrame = NewCFrame(PreviousPosition, Position),
                        Parent = Tracer
                    })
    
                    Lines[#Lines + 1] = { Object = Line, Length = Length }
                end
    
                PreviousPosition = Position
            end
    
        elseif Mode == "Scatter" then
            for Shot = 1, 4 do
                local Alpha = (Shot - 1) / 3
                local Offset = Right * ((Alpha - 0.5) * Radius * 2) + Up * math.sin(Alpha * Pi) * Radius
    
                local Line = Utility.Create("LineHandleAdornment", {
                    Adornee = Tracer,
                    AlwaysOnTop = AlwaysOnTop,
                    ZIndex = 10,
                    Thickness = Thickness,
                    Color3 = Color,
                    Length = Distance,
                    CFrame = NewCFrame(Offset, Offset + Direction),
                    Parent = Tracer
                })
    
                Lines[#Lines + 1] = { Object = Line, Length = Distance }
            end
        end
    
        local StartTime = os.clock()
    
        while Tracer.Parent do
            local Alpha = TravelTime <= 0 and 1 or Clamp((os.clock() - StartTime) / TravelTime, 0, 1)
    
            if Animated then
                if Mode == "Pulse" then
                    local Pulse = 0.5 + math.sin(os.clock() * Waves * 2) * 0.5
                    Lines[1].Object.Length = Distance * Pulse * Alpha
                elseif Mode == "Default" then
                    Lines[1].Object.Length = Distance * Alpha
                else
                    local Progress = #Lines * Alpha
                    local FullSegments = Floor(Progress)
                    local Partial = Progress - FullSegments
    
                    for Index = 1, #Lines do
                        local Data = Lines[Index]
    
                        if Index <= FullSegments then
                            Data.Object.Length = Data.Length
                        elseif Index == FullSegments + 1 then
                            Data.Object.Length = Data.Length * Partial
                        else
                            Data.Object.Length = 0
                        end
                    end
                end
            else
                for Index = 1, #Lines do
                    Lines[Index].Object.Length = Lines[Index].Length * Alpha
                end
            end
    
            if Alpha >= 1 then
                break
            end
    
            RunService.PreRender:Wait()
        end
    
        local LifeStart = os.clock()
    
        while Tracer.Parent and os.clock() - LifeStart < LifeTime do
            RunService.PreRender:Wait()
        end
    
        if FadeTime > 0 then
            local FadeStart = os.clock()
    
            while Tracer.Parent do
                local Alpha = Clamp((os.clock() - FadeStart) / FadeTime, 0, 1)
    
                for Index = 1, #Lines do
                    Lines[Index].Object.Transparency = Alpha
                end
    
                if Alpha >= 1 then
                    break
                end
    
                RunService.PreRender:Wait()
            end
        end
    
        Tracer:Destroy()
    end
end

Library:GiveSignal(Lighting.ChildAdded:Connect(function(Object)
    if Visuals.World.Sky then
        Visuals.World.Sky:Remove()
    end
end))

if moehack.data.game_name == "Arsenal" then
    local NetLogger = moehack.load_module("moehack.net/modules/games/arsenal/netlogger.luau")

    local function GetMuzzlePos(Fallback)
        local Arms = FindFirstChild(Camera, "Arms")
        if Arms then
            local Part = FindFirstChild(Arms, "Particles") or FindFirstChild(Arms, "Flash")
            if Part and IsA(Part, "BasePart") then return Part.Position end
        end
        return Fallback
    end
    local CanSex = false
    NetLogger:On("Outgoing", "HitPart", function(Target, GunId, Flags, Pen, CamPos, HitPos, Dt)
        if Toggles["visuals/world/bullettracers"].Value and CanSex then
            Visuals:BulletTracers(
                GetMuzzlePos(CamPos), HitPos,
                Options["visuals/world/bullettracers/lifetime"].Value,
                Options["visuals/world/bullettracers/fadetime"].Value,
                Options["visuals/world/bullettracers/traveltime"].Value,
                Options["visuals/world/bullettracers/mode"].Value,
                Options["visuals/world/bullettracers/color"].Value
            )
        end
    end)

    Library:GiveSignal(
        LocalPlayer.Damage.Changed:Connect(function()
            CanSex = true
        end)
    )
end

function Visuals.Tick()
    Visuals.Players.Tick()
    Visuals.World.Tick()
    Visuals.Camera.Tick()
end

return Visuals
