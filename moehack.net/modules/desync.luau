--!native
--!optimize 2

--# Aliases

local FromOffset, FromScale, UDim2New = UDim2.fromOffset, UDim2.fromScale, UDim2.new
local Atan2, Rad, Pi, Abs, Minimum, Maximum, Floor, Clamp = math.atan2, math.rad, math.pi, math.abs, math.min, math.max, math.floor, math.clamp
local NewVector, NewVector3, NewCFrame = vector.create, Vector3.new, CFrame.new
local Create, IsA = Instance.new, workspace.IsA
local Spawn, Wait = task.spawn, task.wait
local ForEach, Insert, RemoveTable = table.foreach, table.insert, table.remove
local FindFirstChild, WaitForChild, FindFirstChildOfClass = workspace.FindFirstChild, workspace.WaitForChild, workspace.FindFirstChildOfClass
local WorldToViewportPoint = workspace.CurrentCamera.WorldToViewportPoint
local GetService = Game.GetService

--# Services

local MarketplaceService = GetService(Game, "MarketplaceService")
local ReplicatedStorage  = GetService(Game, "ReplicatedStorage")
local RunService         = GetService(Game, "RunService")
local Stats              = GetService(Game, "Stats")
local DataPing           = Stats.Network.ServerStatsItem["Data Ping"]
local Players            = GetService(Game, "Players")

local LocalPlayer        = Players.LocalPlayer

--# Helper Funcs

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

--# Variables

local LastPositionCFrame = NewCFrame()
local TargetCFrame = NewCFrame()

local RotationThingly = Rad(0.005)
local RotationFlip = false

--# Modules

local Utility = LoadModule("moehack.net/modules/utility.luau")
local Handler = LoadModule("globals/desync_handler.luau")

--# Main

local Desync = {}

function Desync.Tick(DeltaTime)
    local Character = Utility.GetCharacter(LocalPlayer)
    
    if Toggles["misc/desync"].Value then
        if not Handler.IsDesyncing then
            Handler.Activate()

            if Character then
                LastPositionCFrame = Character.PrimaryPart.CFrame
            end

            TargetCFrame = Handler.Real.CFrame
        end

        local EasingStyle = Options["misc/desync/easingstyle"].Value
        local EasingDirection = Options["misc/desync/easingdirection"].Value
        local EasingStyleFunction = Utility.EasingStyle[EasingStyle]
        local EasingDirectionFunction = Utility.EasingDirection[EasingDirection]
        local CurrentCFrame = Character.PrimaryPart.CFrame

        if Toggles["misc/desync/freezepos"].Value and Options["misc/desync/freezepos/key"]:GetState() then
            CurrentCFrame = LastPositionCFrame
        end

        if Toggles["misc/desync/randompos"].Value and Options["misc/desync/randompos/key"]:GetState() then
            local X, Y, Z = Options["misc/desync/randompos/x"].Value, Options["misc/desync/randompos/y"].Value, Options["misc/desync/randompos/z"].Value

            CurrentCFrame *= NewCFrame(
                math.random() * (X * 2) - X,
                math.random() * (Y * 2) - Y,
                math.random() * (Z * 2) - Z
            )
        end

        if Toggles["misc/desync/offset"].Value then
            local X, Y, Z = Options["misc/desync/offset/x"].Value, Options["misc/desync/offset/y"].Value, Options["misc/desync/offset/z"].Value

            CurrentCFrame *= NewCFrame(X, Y, Z)
        end

        if Toggles["misc/desync/jitter"].Value then
            local X = Options["misc/desync/jitter/x"].Value
            local Y = Options["misc/desync/jitter/y"].Value
            local Z = Options["misc/desync/jitter/z"].Value
            local Speed = Options["misc/desync/jitter/speed"].Value

            local Time = os.clock() * Speed

            CurrentCFrame *= NewCFrame(
                math.sin(Time) * X,
                math.sin(Time * 1.17) * Y,
                math.sin(Time * 0.83) * Z
            )
        end

        if Toggles["misc/desync/rotation"].Value then
            local Pitch = Options["misc/desync/rotation/x"].Value
            local Yaw = Options["misc/desync/rotation/y"].Value
            local Roll = Options["misc/desync/rotation/z"].Value

            CurrentCFrame *= CFrame.Angles(
                Rad(Pitch),
                Rad(Yaw),
                Rad(Roll)
            )
        end

        if EasingStyleFunction and EasingDirectionFunction and Toggles["misc/desync/useeasingstyle"].Value then
            local Speed = Options["misc/desync/speed"].Value
            local Alpha = Clamp(DeltaTime * Speed, 0, 1)

            Alpha = EasingDirectionFunction(EasingStyleFunction, Alpha)

            TargetCFrame = TargetCFrame:Lerp(CurrentCFrame, Alpha)
            CurrentCFrame = TargetCFrame
        else
            TargetCFrame = CurrentCFrame
        end

        Handler.ChangePosition(CurrentCFrame)
        RotationFlip = not RotationFlip

        Character.PrimaryPart.CFrame *= CFrame.Angles(0, RotationFlip and RotationThingly or -RotationThingly, 0)
        return
    end

    if Handler.IsDesyncing then
        Handler.Deactivate()
    end

end

return Desync