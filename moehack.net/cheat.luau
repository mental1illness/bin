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
local DataPing           = Stats.Network.ServerStatsItem["Data Ping"]
local FrameRateManager   = Stats:FindFirstChild("FrameRateManager")
local RenderAverage      = FrameRateManager:FindFirstChild("RenderAverage")
local Players            = GetService(Game, "Players")

local LocalPlayer        = Players.LocalPlayer

--# Helper Funcs (USELESS)

LoadModule = function(Path, Load)
    local url = "https://cats-cure-depression.vercel.app/" .. Path
    
    return Load == true and loadstring(game:HttpGet(url))() or game:HttpGet(url)
end

local makeKebabPls = function(name)
    local s = name:lower(); s = s:gsub("[^%a%s]", ""); s = s:gsub("^%s+", ""):gsub("%s+$", ""); s = s:gsub("%s+", "-")
    return s
end

--# Variables

local FrameRate, Ping = 0, 0

--# UI Library
local Library, SaveManager, ThemeManager = LoadModule("moehack.net/interface/library.luau", true), LoadModule("moehack.net/interface/addons/SaveManager.lua", true), LoadModule("moehack.net/interface/addons/ThemeManager.lua", true) do
    local Window = Library:CreateWindow({ Title = 'moehack.net', Center = true, AutoShow = true, TabPadding = 1, MenuFadeTime = 0.2, BackgroundImage = "https://cats-cure-depression.vercel.app/images/izumi.png", BackgroundImageTransparency = 0.9, BackgroundImageScaleType = Enum.ScaleType.Fit })
    
    local Tabs = {
        Combat = Window:AddTab("Combat"),
        ESP = Window:AddTab("ESP"),
        Visuals = Window:AddTab("Visuals"),
        Misc = Window:AddTab("Misc"),
        Settings = Window:AddTab("Settings")
    }

    do

        do -- Combat
            local AimAssist, TriggerBot = Tabs.Combat:AddGroupbox({ Side = 1, Name = "Aim Assistance" }), Tabs.Combat:AddGroupbox({ Side = 1, Name = "Trigger Bot" })
           
            do -- Aim Assist
                AimAssist:AddToggle("combat/aimassist", { Text = "Enabled", Default = false }):AddKeyPicker("combat/aimassist/key", { Text = "Aim Assist Key", SyncToggleState = false, Mode = "Hold", Default = "MB2" })
                AimAssist:AddSlider("combat/aimassist/fov", { Text = "Field Of View", Min = 1, Max = 360, Rounding = 0, Default = 120 })
                AimAssist:AddDropdown("combat/aimassist/easingstyle", { Text = "Easing Style", Default = 1, Values = {
                    "Sine",
                    "Quad",
                    "Cubic",
                    "Quart",
                    "Quint",
                    "Exponential",
                    "Circular",
                    "Linear",
                } })
                AimAssist:AddToggle("combat/aimassist/usenearhitbox", { Text = "Use Nearest Hitbox", Default = false })
                AimAssist:AddToggle("combat/aimassist/stickyaim", { Text = "Sticky Aim", Default = false })
                AimAssist:AddDropdown("combat/aimassist/method", { Text = "Method", Default = 1, Values = {
                    "Camera",
                    "Mouse",
                } })
                AimAssist:AddToggle("combat/aimassist/instasnap", { Text = "Instant Snap", Default = false })
                AimAssist:AddSlider("combat/aimassist/speed", {Text = "Speed", Min = 1, Max = 40, Rounding = 1, Default = 12})

                AimAssist:AddToggle("combat/aimassist/ignorebehindwalls", { Text = "Ignore Behind Walls", Default = false })
            end

            do -- Trigger Bot
                TriggerBot:AddToggle("combat/triggerbot", { Text = "Enabled", Default = false }):AddKeyPicker("combat/triggerbot/key", { Text = "Triggerbot Key",  SyncToggleState = false, Mode = "Hold", Default = "MB2" })
                TriggerBot:AddSlider("combat/triggerbot/fov", { Text = "Field Of View", Min = 1, Max = 360, Rounding = 0, Default = 120 })
                TriggerBot:AddSlider("combat/triggerbot/reactiontime", { Text = "Reaction Time", Min = 1, Max = 360, Rounding = 0, Default = 12 })
                TriggerBot:AddToggle("combat/triggerbot/ignorebehindwalls", { Text = "Ignore Behind Walls", Default = false })
            end
        end

        do -- ESP
            local Main, Settings = Tabs.ESP:AddGroupbox({ Side = 1, Name = "Players" }), Tabs.ESP:AddGroupbox({ Side = 2, Name = "Settings" })
            do -- Players
                Main:AddToggle("esp/enabled", { Text = "Enabled", Default = false })
                Main:AddToggle("esp/box", { Text = "Bounding Box", Default = false }):AddColorPicker('esp/box/color', { Default = Color3.fromRGB(255, 255, 255), Title = 'Box Color' }) do
                    local DepBox = Main:AddDependencyBox()
                    DepBox:AddToggle("esp/box/fill", { Text = "Fill Box", Default = false }):AddColorPicker('esp/box/fillcolor', { Default = Color3.fromRGB(255, 255, 255), Title = 'Fill Color', Transparency = 0.5 })
                    DepBox:AddDropdown("esp/box/type", { Text = "Box Type", Default = 1, Values = {"Full", "Corner"} })
                    DepBox:SetupDependencies({
                        { Toggles["esp/box"], true } 
                    });
                end
                local HealthBar = Main:AddToggle("esp/healthbar", { Text = "Health Bar", Default = false }) do

                    HealthBar:AddColorPicker('esp/healthbar/colora', { Default = Color3.fromRGB(255, 105, 180), Title = 'Health Bar A' })
                    HealthBar:AddColorPicker('esp/healthbar/colorb', { Default = Color3.fromRGB(255, 20, 147),  Title = 'Health Bar B' })

                    local HealthDepBox = Main:AddDependencyBox()
                    HealthDepBox:AddToggle("esp/healthtext", { Text = "Health Text", Default = false }):AddColorPicker('esp/healthtext/color', { Default = Color3.fromRGB(255, 255, 255), Title = 'Health Text Color' })
                    HealthDepBox:AddSlider("esp/healthbar/thickness", { Text = "Health Bar Thickness", Min = 1, Max = 2, Rounding = 0, Default = 2, Compact = true })
                    HealthDepBox:SetupDependencies({
                        { Toggles["esp/healthbar"], true } 
                    });
                end
                Main:AddToggle("esp/name", { Text = "Name", Default = false }):AddColorPicker('esp/name/color', { Default = Color3.fromRGB(255, 255, 255), Title = 'Name Color' })
                Main:AddToggle("esp/distance", { Text = "Distance", Default = false }):AddColorPicker('esp/distance/color', { Default = Color3.fromRGB(255, 255, 255), Title = 'Distance Color' })
                Main:AddToggle("esp/tool", { Text = "Tool", Default = false }):AddColorPicker('esp/tool/color', { Default = Color3.fromRGB(255, 255, 255), Title = 'Tool Color' })

            end


            do -- Settings
                Settings:AddSlider("esp/settings/renderhz", { Text = "Render Hertz", Min = 10, Max = 240, Rounding = 0, Default = 60 })
                Settings:AddSlider("esp/settings/renderdist", { Text = "Render Distance", Min = 10, Max = 1000, Rounding = 0, Default = 500 })
            end
        end

        do -- Visuals
            local World, Player = Tabs.Visuals:AddGroupbox({ Side = 1, Name = "World" }), Tabs.Visuals:AddGroupbox({ Side = 2, Name = "Player" }) 

            do -- World
                local Ambient = World:AddToggle("visuals/world/ambient", { Text = "Ambient", Default = false }) do
                    Ambient:AddColorPicker('visuals/world/ambient/outdoorcolor', { Default = Color3.fromRGB(200, 100, 60), Title = 'Outdoor Color' })
                    Ambient:AddColorPicker('visuals/world/ambient/color', { Default = Color3.fromRGB(140, 90, 70), Title = 'Ambient Color' })
                end

                local Brightness = World:AddToggle("visuals/world/brightness", { Text = "Brightness", Default = false }) do

                    local DepBox = World:AddDependencyBox()

                    DepBox:AddSlider("visuals/world/brightness/level", { Text = "Brightness Level", Min = 0, Max = 10, Rounding = 1, Default = 1.6 })
                    DepBox:AddSlider("visuals/world/brightness/envdiffscale", { Text = "Environment Diffuse Scale", Min = 0, Max = 1, Rounding = 2, Default = 1 })
                    DepBox:AddSlider("visuals/world/brightness/envspecscale", { Text = "Environment Specular Scale", Min = 0, Max = 1, Rounding = 2, Default = 0.9 })
                    DepBox:AddSlider("visuals/world/brightness/exposure", { Text = "Exposure Compensation", Min = 0, Max = 1, Rounding = 2, Default = 0.15 })

                    DepBox:SetupDependencies({
                        { Toggles["visuals/world/brightness"], true } 
                    });
                end

                local Fog = World:AddToggle("visuals/world/fog", { Text = "Fog", Default = false }) do
                    Fog:AddColorPicker('visuals/world/fog/color', { Default = Color3.fromRGB(255, 255, 255), Title = 'Fog Color' })
                    local DepBox = World:AddDependencyBox()
                    DepBox:AddSlider("visuals/world/fog/near", { Text = "Fog Near", Min = 0, Max = 1000, Rounding = 1, Default = 0 })
                    DepBox:AddSlider("visuals/world/fog/far", { Text = "Fog Far", Min = 0, Max = 1000, Rounding = 1, Default = 1000 })
                    DepBox:SetupDependencies({
                        { Toggles["visuals/world/fog"], true }
                    });
                end

                local Shadow = World:AddToggle("visuals/world/shadow", { Text = "Shadow Modification", Default = false }) do
                    Shadow:AddColorPicker('visuals/world/shadow/color', { Default = Color3.fromRGB(0, 0, 0), Title = 'Shadow Color (theres a property for it not sure if it works)' })
                    local DepBox = World:AddDependencyBox()
                    DepBox:AddSlider("visuals/world/shadow/softness", { Text = "Shadow Softness", Min = 0, Max = 1, Rounding = 2, Default = 0.5 })
                    DepBox:AddToggle("visuals/world/shadow/globalshadows", { Text = "Enable Shadows", Default = true })
                    DepBox:SetupDependencies({
                        { Toggles["visuals/world/shadow"], true }
                    });
                end
                
	            local Lighting = World:AddToggle("visuals/world/lighting", { Text = "Lighting", Default = false }) do
                    local DepBox = World:AddDependencyBox()
                    DepBox:AddSlider("visuals/world/lighting/time", { Text = "Clock Time", Min = 0, Max = 23, Rounding = 2, Default = 1 })
                    DepBox:AddSlider("visuals/world/lighting/latitude", { Text = "Geographic Latitude", Min = -90, Max = 90, Rounding = 1, Default = 0 })
                    DepBox:AddLabel("ColorShift Bottom"):AddColorPicker('visuals/world/lighting/colorshiftbottom', { Default = Color3.fromRGB(255, 255, 255), Title = 'ColorShift Bottom' })
                    DepBox:AddLabel("ColorShift Top"):AddColorPicker('visuals/world/lighting/colorshifttop', { Default = Color3.fromRGB(255, 255, 255), Title = 'ColorShift Top' })
                    
                    DepBox:AddToggle("visuals/world/lighting/colorgrading", { Text = "Color Grading", Default = false }) do
                        local DepBox2 = DepBox:AddDependencyBox()
                    local TonemapOptions = {}
                    for _, EnumItem in Enum.TonemapperPreset:GetEnumItems() do 
                        Insert(TonemapOptions, EnumItem.Name)
                    end -- timothy

                    DepBox2:AddDropdown("visuals/world/lighting/colorgrading/tonemap", { Text = "Tone Map Preset", Default = 1, Values = TonemapOptions })

                    DepBox2:SetupDependencies({
                        { Toggles["visuals/world/lighting/colorgrading"], true }
                    });
                end

                    

                local CC = DepBox:AddToggle("visuals/world/lighting/cc", { Text = "Color Correction", Default = false }) do
                    local DepBox2 = DepBox:AddDependencyBox()
                    DepBox2:AddSlider("visuals/world/lighting/cc/saturation", { Text = "Saturation", Min = 0, Max = 1, Rounding = 2, Default = 0.5 })
                    DepBox2:AddSlider("visuals/world/lighting/cc/contrast", { Text = "Contrast", Min = 0, Max = 1, Rounding = 2, Default = 0.5 })
                    DepBox2:AddSlider("visuals/world/lighting/cc/brightness", { Text = "Brightness", Min = -1, Max = 1, Rounding = 2, Default = 0 })
                    
                    CC:AddColorPicker('visuals/world/lighting/cc/tint', { Default = Color3.fromRGB(255, 255, 255), Title = 'Tint Color' })

                    DepBox2:SetupDependencies({
                        { Toggles["visuals/world/lighting/cc"], true }
                    });
                end

                local Bloom = DepBox:AddToggle("visuals/world/lighting/bloom", { Text = "Bloom", Default = false }) do
                    local DepBox2 = DepBox:AddDependencyBox()
                    DepBox2:AddSlider("visuals/world/lighting/bloom/intensity", { Text = "Intensity", Min = 0, Max = 1, Rounding = 2, Default = 0.5 })
                    DepBox2:AddSlider("visuals/world/lighting/bloom/size", { Text = "Size", Min = 0, Max = 56, Rounding = 2, Default = 0.5 })
                    DepBox2:AddSlider("visuals/world/lighting/bloom/threshold", { Text = "Threshold", Min = 0, Max = 1, Rounding = 2, Default = 0.5 })

                    DepBox2:SetupDependencies({
                        { Toggles["visuals/world/lighting/bloom"], true }
                    });
                end

                local SunRays = DepBox:AddToggle("visuals/world/sunrays", { Text = "Sun Rays", Default = false }) do
                    local DepBox2 = DepBox:AddDependencyBox()
                    DepBox2:AddSlider("visuals/world/sunrays/intensity", { Text = "Intensity", Min = 0, Max = 1, Rounding = 2, Default = 0.1 })
                    DepBox2:AddSlider("visuals/world/sunrays/spread", { Text = "Spread", Min = 0, Max = 1, Rounding = 2, Default = 0.5 })

                    DepBox2:SetupDependencies({
                        { Toggles["visuals/world/sunrays"], true }
                    });
                end

                local Atmosphere = DepBox:AddToggle("visuals/world/atmosphere", { Text = "Atmosphere", Default = false }) do
                    local DepBox2 = DepBox:AddDependencyBox()
                    DepBox2:AddSlider("visuals/world/atmosphere/density", { Text = "Density", Min = 0, Max = 1, Rounding = 2, Default = 0.3 })
                    DepBox2:AddSlider("visuals/world/atmosphere/offset", { Text = "Offset", Min = -1, Max = 1, Rounding = 2, Default = 0 })
                    DepBox2:AddLabel("Color"):AddColorPicker("visuals/world/atmosphere/color", { Default = Color3.fromRGB(199, 170, 107), Title = "Atmosphere Color" })
                    DepBox2:AddLabel("Decay"):AddColorPicker("visuals/world/atmosphere/decay", { Default = Color3.fromRGB(106, 112, 125), Title = "Atmosphere Decay" })
                    DepBox2:AddSlider("visuals/world/atmosphere/glare", { Text = "Glare", Min = 0, Max = 1, Rounding = 2, Default = 0 })
                    DepBox2:AddSlider("visuals/world/atmosphere/haze", { Text = "Haze", Min = 0, Max = 1, Rounding = 2, Default = 0 })

                    DepBox2:SetupDependencies({
                        { Toggles["visuals/world/atmosphere"], true }
                    }); 
                end


                    local TechOptions = {}
                    for _, EnumItem in Enum.Technology:GetEnumItems() do 
                        Insert(TechOptions, EnumItem.Name)
                    end
                    DepBox:AddDropdown("visuals/world/lighting/technology", { Text = "Technology", Default = 1, Values = TechOptions })

                    DepBox:SetupDependencies({
                        { Toggles["visuals/world/lighting"], true }
                    });
                end


                local DepthOfField = World:AddToggle("visuals/world/dof", { Text = "Depth of Field", Default = false }) do
                    local DepBox = World:AddDependencyBox()
                    DepBox:AddSlider("visuals/world/dof/farintens", { Text = "Far Intensity", Min = 0, Max = 1, Rounding = 2, Default = 0.28 })
                    DepBox:AddSlider("visuals/world/dof/nearintens", { Text = "Near Intensity", Min = 0, Max = 1, Rounding = 2, Default = 0.7 })
                    DepBox:AddSlider("visuals/world/dof/focusdist", { Text = "Focus Distance", Min = 0, Max = 100, Rounding = 2, Default = 20 })
                    DepBox:AddSlider("visuals/world/dof/focusinradius", { Text = "In Focus Radius", Min = -100, Max = 100, Rounding = 2, Default = 20 })
                    DepBox:SetupDependencies({
                        { Toggles["visuals/world/dof"], true }
                    });
                end

                local Weather = World:AddToggle("visuals/world/weather", { Text = "Weather", Default = false }) do
                    local DepBox = World:AddDependencyBox()
                    DepBox:AddDropdown("visuals/world/weather/type", { Text = "Type", Default = 1, Values = {"Rain", "Snow"} })

                    DepBox:AddSlider("visuals/world/snow/rate", { Text = "Snow Rate", Min = 1, Max = 2000, Rounding = 0, Default = 1000 })

                    DepBox:SetupDependencies({  
                        { Toggles["visuals/world/weather"], true }
                    });
                end
                World:AddToggle("visuals/world/its,driving,me,crazy,i,just,need,your,affection", { Text = "Use 2022 Materials", Default = gethiddenproperty(GetService(Game, "MaterialService"), "Use2022Materials"),  Callback = function(Var)
                    sethiddenproperty(GetService(Game, "MaterialService"), "Use2022Materials", Var)
                end})
            end

            do -- Player
                Player:AddToggle("visuals/player/chinesehat", { Text = "Chinese Hat", Default = false }):AddColorPicker('visuals/player/chinesehat/color', { Default = Color3.fromRGB(255, 255, 255), Title = 'Chinese Hat Color' }) do
                    local DepBox = Player:AddDependencyBox()

                    DepBox:AddSlider("visuals/player/chinesehat/glowfac", { Text = "Glow Factor", Min = 5, Max = 20, Rounding = 0, Default = 5 })
                    DepBox:AddSlider("visuals/player/chinesehat/radius", { Text = "Radius", Min = 0, Max = 2, Rounding = 1, Default = 1.5 })
                    DepBox:AddSlider("visuals/player/chinesehat/height", { Text = "Height", Min = 0, Max = 2, Rounding = 1 ,Default = 1 })

                    DepBox:AddToggle("visuals/player/chinesehat/alwaysontop", { Text = "Always On Top", Default = false })

                    DepBox:SetupDependencies({
                        { Toggles["visuals/player/chinesehat"], true } 
                    });
                end

                Player:AddToggle("visuals/player/appearance", { Text = "Appearance Changer", Default = false })
                Player:AddInput("visuals/player/appearance/id", { Numeric = true, Finished = true, Text = "UserId" })
            end

            

        end

        do -- Misc
            local Movement, Exploits = Tabs.Misc:AddGroupbox({ Side = 1, Name = "Movement" }), Tabs.Misc:AddGroupbox({ Side = 1, Name = "Exploits" })

            do -- Movement
                Movement:AddToggle("misc/movement/speed", { Text = "Speed Hack", Default = false })
                Movement:AddSlider("misc/movement/speed/value", {Text = "Speed Hack Value", Min = 1, Max = 500, Rounding = 0, Default = 12})

                Movement:AddToggle("misc/movement/autojump", { Text = "Auto Jump", Default = false })
                Movement:AddDropdown("misc/movement/autojump/method", { Text = "Auto Jump Method", Default = 1, Values = {"Humanoid", "Velocity"} })

                Movement:AddToggle("misc/movement/pixelsurf", { Text = "Pixel Surf", Default = false }):AddKeyPicker("misc/movement/pixelsurf/key", { Text = "Pixel Surf Key",  SyncToggleState = false, Mode = "Hold", Default = "F" })
                
            end

            do -- Exploits
                Exploits:AddToggle("misc/exploits/antifling", { Text = "Anti Fling", Default = false })
            end
        end
    end

    --# Managers

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

    ThemeManager:SetFolder('moehack')
    SaveManager:SetFolder('moehack/' .. makeKebabPls(MarketplaceService:GetProductInfo(Game.PlaceId).Name))

    SaveManager:BuildConfigSection(Tabs.Settings)
    ThemeManager:ApplyToTab(Tabs.Settings)

    SaveManager:LoadAutoloadConfig()

    --# UI Loop (useless)
    local CurrentQuote = "moehack.net"
    Spawn(function() -- Window
        local Titles = {
            "im a moe.. always a moe!",
            "moehack.net",
            "ive been moe.,,",
            "meow",
            "moe-chan moe-chan",
            "affectionhack.net",
            "*gives you moe*",
            "Hello, I'm moe. Your personal affectionate friend!",
            "what?"
        }
        local TitleIndexes = #Titles
        while Wait(5) do
            local titties = Titles[math.random(1, TitleIndexes)]
            Window:SetWindowTitle(titties)
            CurrentQuote = titties
        end
    end)

    Spawn(function() -- Watermark
        while Wait(1) do
            Library:SetWatermark("moehack.net" .. " » " .. FrameRate .. "fps" .. " » " .. Ping .. "ms" .. " » " .. string.lower(LocalPlayer.Name) .. " » "  .. "definetly dev build")
        end
    end)
end

--# Modules

Library:Notify("Loading modules...", 2)

local ESP = LoadModule("moehack.net/modules/esp.luau", true)
local Visuals = LoadModule("moehack.net/modules/visuals.luau", true)
local Combat = LoadModule("moehack.net/modules/combat.luau", true)
local Misc = LoadModule("moehack.net/modules/misc.luau", true)

--# Hooks

--# Connections

Library:GiveSignal(
	RunService.PreRender:Connect(function(Delta)
		FrameRate = Floor(1000 / RenderAverage:GetValue())
		Ping = Floor(DataPing:GetValue())

        Visuals.Tick(Delta)
        Combat.Tick(Delta)
        ESP.Update(Delta)
        Misc.Tick(Delta)
    end)
)

do -- Notification
    Spawn(function()
        Wait(.2)
        Library:Notify("Loaded sucessfully!", 3)
        Wait(.2)
        Library:Notify("Today's wordle's answer is " .. tostring(Game:HttpGet("https://bloxsense.vercel.app/api/WordleTodaysAnswer.js")), 4)
        Wait(.2)
        Library:Notify("Welcome to moehack.net, good luck and have fun being a moe" .. " " .. string.lower(LocalPlayer.Name) .. "!", 6)
    end)
end
