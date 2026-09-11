--!native
--!optimize 2

--# Aliases 

local Spawn, Wait = task.spawn, task.wait
local FindFirstChild, WaitForChild = workspace.FindFirstChild, workspace.WaitForChild
local GetService = Game.GetService

--# Services

local MarketplaceService = GetService(Game, "MarketplaceService")
local ReplicatedStorage  = GetService(Game, "ReplicatedStorage")
local RunService         = GetService(Game, "RunService")
local Stats              = GetService(Game, "Stats")
local DataPing           = Stats.Network.ServerStatsItem["Data Ping"]
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
local Library, SaveManager, ThemeManager = LoadModule("moehack.net/library.luau", true), LoadModule("moehack.net/SaveManager.lua", true), LoadModule("moehack.net/ThemeManager.lua", true) do
    local Window = Library:CreateWindow({ Title = 'moehack.net', Center = true, AutoShow = true, TabPadding = 1, MenuFadeTime = 0.2 })
    
    local Tabs = {
        ESP = Window:AddTab("ESP"),
        Visuals = Window:AddTab("Visuals"),
        Settings = Window:AddTab("Settings")
    }

    do
        do -- ESP
            local Main, Settings = Tabs.ESP:AddGroupbox({ Side = 1, Name = "Players" }), Tabs.ESP:AddGroupbox({ Side = 2, Name = "Settings" })
            do -- Players
                Main:AddToggle("esp/enabled", { Text = "Enabled", Default = false })
                Main:AddToggle("esp/box", { Text = "Bounding Box", Default = false }):AddColorPicker('esp/box/color', { Default = Color3.fromRGB(255, 255, 255), Title = 'Box Color' })
                local HealthBar = Main:AddToggle("esp/healthbar", { Text = "Health Bar", Default = false }) do

                    HealthBar:AddColorPicker('esp/healthbar/colora', { Default = Color3.fromRGB(255, 105, 180), Title = 'Health Bar A' })
                    HealthBar:AddColorPicker('esp/healthbar/colorb', { Default = Color3.fromRGB(255, 20, 147),  Title = 'Health Bar B' })

                    local HealthDepBox = Main:AddDependencyBox()
                    HealthDepBox:AddToggle("esp/healthtext", { Text = "Health Text", Default = false }):AddColorPicker('esp/healthtext/color', { Default = Color3.fromRGB(255, 255, 255), Title = 'Box Color' })
                    HealthDepBox:SetupDependencies({
                        { Toggles["esp/healthbar"], true } 
                    });

                end
                Main:AddToggle("esp/name", { Text = "Name", Default = false }):AddColorPicker('esp/name/color', { Default = Color3.fromRGB(255, 255, 255), Title = 'Name Color' })
            end

            do -- Settings
                Settings:AddSlider("esp/settings/renderhz", { Text = "Render Hertz", Min = 10, Max = 240, Rounding = 1, Default = 60 })
            end
        end
    end

    --# Managers

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

    ThemeManager:SetFolder('moehack')
    SaveManager:SetFolder('moehack/' .. makeKebabPls(MarketplaceService:GetProductInfo(game.PlaceId).Name))

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
            Library:SetWatermark("moehack.net" .. " » " .. FrameRate .. "fps" .. " » " .. Ping .. "ms" .. " » " .. string.lower(LocalPlayer.Name) .. " » "  .. "private (kawaii user)")
        end
    end)
end

--# Modules

Library:Notify("Loading modules...", 2)

LoadModule("moehack.net/modules/esp.luau", true)

--# Connections

Library:GiveSignal(
	RunService.RenderStepped:Connect(function(Delta)
		FrameRate = math.floor(1 / Delta)
		Ping = math.floor(DataPing:GetValue())
	end)
)

do -- Notification
    Spawn(function()
        Wait(.2)
        Library:Notify("Loaded sucessfully!", 3)
        Wait(.3)
        Library:Notify("Today's wordle's answer is " .. tostring(Game:HttpGet("https://bloxsense.vercel.app/api/WordleTodaysAnswer.js")), 4)
        Wait(.4)
        Library:Notify("Welcome to moehack.net, good luck and have fun being a moe" .. " " .. string.lower(LocalPlayer.Name) .. "!", 6)
    end)
end
