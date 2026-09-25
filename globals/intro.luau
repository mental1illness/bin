--!native
--!optimize 2

--# Aliases

local Spawn = task.spawn
local FromOffset, FromScale, UDim2New = UDim2.fromOffset, UDim2.fromScale, UDim2.new
local Create, IsA = Instance.new, workspace.IsA
local GetService = game.GetService

--# Services

local RunService = GetService(Game, "RunService")

--# Helper

LoadModule = function(Path)
    local FuckYouCacheBitch = getgenv().FuckYouCacheBitch

    if not FuckYouCacheBitch then
        FuckYouCacheBitch = {}
        getgenv().FuckYouCacheBitch = FuckYouCacheBitch
    end

    if FuckYouCacheBitch[Path] ~= nil then
        return FuckYouCacheBitch[Path]
    end

    local url = "https://cats-cure-depression.vercel.app/" .. Path
    local Result = loadstring(game:HttpGet(url))()

    FuckYouCacheBitch[Path] = Result

    return Result
end

--# Modules

local Fonts = LoadModule("globals/fonts.luau")

--# Main

local Intro = {
    Messages = {
        { Text = "This cheat is not suitable for children that are easily beatable.", Weight = 80 },
        { Text = "This cheat is not suitable for children that are easily breedable?", Weight = 50 },
        { Text = "Moehack is a yuri.love revival", Weight = 15 },
        { Text = "Fuck you", Weight = 50 },
    }
}

function Intro.GetRandomMessages()
    local TotalWeight = 0

    for _, Message in Intro.Messages do
        TotalWeight += Message.Weight
    end

    local Roll = math.random() * TotalWeight

    for _, Message in Intro.Messages do
        Roll -= Message.Weight

        if Roll <= 0 then
            return Message.Text
        end
    end
end

function Intro.Create()
    local MyFuckingIntro = {}

    local ScreenGui = Create("ScreenGui", gethui and gethui() or GetService(Game, "CoreGui"))
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 9e9

    local Background = Create("Frame", ScreenGui)
    Background.Size = FromScale(1, 1)
    Background.BackgroundTransparency = 1
    Background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

    local WarningText = Create("TextLabel", Background)
    WarningText.Text = Intro.GetRandomMessages()
    WarningText.FontFace = Fonts.Aller
    WarningText.TextSize = 32
    WarningText.TextColor3 = Color3.fromRGB(35, 35, 35)
    WarningText.TextXAlignment = Enum.TextXAlignment.Center
    WarningText.Position = FromScale(0.5, 0.5)
    WarningText.AnchorPoint = Vector2.new(0.5, 0.5)
    WarningText.TextTransparency = 1
    WarningText.BackgroundTransparency = 1

    function MyFuckingIntro:FadeIn(Duration)
        Duration = Duration or 0.5

        Background.BackgroundTransparency = 1
        WarningText.TextTransparency = 1

        local Start = os.clock()
        Spawn(function()
            while true do
                local Alpha = math.clamp((os.clock() - Start) / Duration, 0, 1)

                Background.BackgroundTransparency = 1 - Alpha
                WarningText.TextTransparency = 1 - Alpha

                if Alpha >= 1 then
                    break
                end

                RunService.RenderStepped:Wait()
            end
        end)
    end

    function MyFuckingIntro:FadeOut(Duration)
        Duration = Duration or 0.5

        local Start = os.clock()
        Spawn(function()
            while true do
                local Alpha = math.clamp((os.clock() - Start) / Duration, 0, 1)

                Background.BackgroundTransparency = Alpha
                WarningText.TextTransparency = Alpha

                if Alpha >= 1 then
                    break
                end

                RunService.RenderStepped:Wait()
            end
        end)


        ScreenGui:Destroy()
    end

    return MyFuckingIntro
end

return Intro