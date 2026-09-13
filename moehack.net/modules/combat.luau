--!native
--!optimize 2

--# Aliases

local FromOffset, FromScale, UDim2New = UDim2.fromOffset, UDim2.fromScale, UDim2.new
local Atan2, Rad, Pi, Abs, Minimum, Maximum, Floor, Clamp, Sqrt = math.atan2, math.rad, math.pi, math.abs, math.min, math.max, math.floor, math.clamp, math.sqrt
local NewVector, NewVector3, NewCFrame = vector.create, Vector3.new, CFrame.new
local Create, IsA = Instance.new, workspace.IsA
local Spawn, Wait = task.spawn, task.wait
local ForEach, Insert, RemoveTable = table.foreach, table.insert, table.remove
local FindFirstChild, WaitForChild, Raycast = workspace.FindFirstChild, workspace.WaitForChild, workspace.Raycast
local WorldToViewportPoint = workspace.CurrentCamera.WorldToViewportPoint
local GetService = Game.GetService

--# Services

local MarketplaceService = GetService(Game, "MarketplaceService")
local ReplicatedStorage = GetService(Game, "ReplicatedStorage")
local RunService = GetService(Game, "RunService")
local Stats = GetService(Game, "Stats")
local DataPing = Stats.Network.ServerStatsItem["Data Ping"]
local Players = GetService(Game, "Players")

local LocalPlayer = Players.LocalPlayer

--# Helper Funcs

LoadModule = function(Path, Load)
    local url = "https://cats-cure-depression.vercel.app/" .. Path
    return Load == true and loadstring(game:HttpGet(url))() or game:HttpGet(url)
end

--# Variables

local Utility = LoadModule("moehack.net/modules/utility.luau", true)
local EasingStyle = Utility.EasingStyle

local Toggles, Options = getgenv().Toggles, getgenv().Options
local Camera = workspace.CurrentCamera

local RaycastParams = RaycastParams.new()

--# Main

RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local Combat = {
    AimAssistTarget = nil,
    TriggerBotTarget = nil,
    TriggerBotTime = nil
}

function Combat.GetTarget(FOV: number, BestHitbox: boolean)
    local ViewportSize = Camera.ViewportSize

    local Center = NewVector(
        ViewportSize.X * 0.5,
        ViewportSize.Y * 0.5
    )

    local BestTarget = nil
    local BestHitboxPart = nil
    local BestDistance = FOV

    for _, Player in Players:GetPlayers() do
        if Player ~= LocalPlayer then
            local Character = Player.Character

            if Character then
                local Humanoid = FindFirstChild(Character, "Humanoid")
                local RootPart = Character.PrimaryPart

                if Humanoid and RootPart and Humanoid.Health > 0 then
                    if BestHitbox then
                        for _, Hitbox in Character:GetChildren() do
                            if Hitbox:IsA("BasePart") then
                                local Position, OnScreen =
                                    WorldToViewportPoint(Camera, Hitbox.Position)

                                if OnScreen and Position.Z > 0 then
                                    local Distance = (
                                        NewVector(Position.X, Position.Y) - Center
                                    ).Magnitude

                                    if Distance <= BestDistance then
                                        BestDistance = Distance
                                        BestTarget = Player
                                        BestHitboxPart = Hitbox
                                    end
                                end
                            end
                        end
                    else
                        local Position, OnScreen =
                            WorldToViewportPoint(Camera, RootPart.Position)

                        if OnScreen and Position.Z > 0 then
                            local Distance = (
                                NewVector(Position.X, Position.Y) - Center
                            ).Magnitude

                            if Distance <= BestDistance then
                                BestDistance = Distance
                                BestTarget = Player
                                BestHitboxPart = RootPart
                            end
                        end
                    end
                end
            end
        end
    end

    return BestTarget, BestHitboxPart
end

function Combat.Tick(Delta)
    if Toggles["combat/aimassist"].Value and Options["combat/aimassist/key"]:GetState() then
        local FOV = Options["combat/aimassist/fov"].Value
        local UseNearestHitbox = Toggles["combat/aimassist/usenearhitbox"].Value
        local StickyAim = Toggles["combat/aimassist/stickyaim"].Value
        local IgnoreBehindWalls = Toggles["combat/aimassist/ignorebehindwalls"].Value
        local Method = Options["combat/aimassist/method"].Value
        local InstantSnap = Toggles["combat/aimassist/instasnap"].Value
        local EasingName = Options["combat/aimassist/easingstyle"].Value
        local Speed = Options["combat/aimassist/speed"].Value

        local Target
        local Hitbox

        if StickyAim and Combat.AimAssistTarget then
            local Character = Combat.AimAssistTarget.Character
            local Humanoid = Character and FindFirstChild(Character, "Humanoid")

            if Humanoid and Humanoid.Health > 0 then
                if UseNearestHitbox then
                    local BestDistance = FOV
                    local ViewportSize = Camera.ViewportSize

                    local Center = NewVector(ViewportSize.X * 0.5, ViewportSize.Y * 0.5)

                    for _, Part in Character:GetChildren() do
                        if Part:IsA("BasePart") then
                            local Position, OnScreen = WorldToViewportPoint(Camera, Part.Position)

                            if OnScreen and Position.Z > 0 then
                                local Distance = (NewVector(Position.X, Position.Y) - Center).Magnitude

                                if Distance <= BestDistance then
                                    BestDistance = Distance
                                    Hitbox = Part
                                end
                            end
                        end
                    end
                else
                    Hitbox = Character.PrimaryPart
                end

                Target = Combat.AimAssistTarget
            else
                Combat.AimAssistTarget = nil
            end
        end

        if not Target then
            Target, Hitbox = Combat.GetTarget(FOV, UseNearestHitbox)

            if Target then
                Combat.AimAssistTarget = Target
            end
        end

        if Target and Hitbox then
            local Position, OnScreen = WorldToViewportPoint(Camera, Hitbox.Position)

            if OnScreen and Position.Z > 0 then
                local ViewportSize = Camera.ViewportSize
                local CenterX = ViewportSize.X * 0.5
                local CenterY = ViewportSize.Y * 0.5

                local OffsetX = Position.X - CenterX
                local OffsetY = Position.Y - CenterY

                local Distance = Sqrt(OffsetX * OffsetX + OffsetY * OffsetY)

                if Distance <= FOV then
                    local Visible = true

                    if not IgnoreBehindWalls then
                        local Origin = Camera.CFrame.Position
                        local Direction = Hitbox.Position - Origin
                        local IgnoreList = {
                            LocalPlayer.Character
                        }

                        for _ = 1, 10 do
                            AimRaycastParams.FilterDescendantsInstances = IgnoreList

                            local Result = workspace:Raycast(Origin, Direction, AimRaycastParams)

                            if not Result then
                                break
                            end

                            local Part = Result.Instance

                            if Part.Parent == Target.Character then
                                break
                            end

                            if Part.Transparency >= 1 or not Part.CanCollide then
                                table.insert(IgnoreList, Part)

                                Origin = Result.Position + Direction.Unit * 0.01
                                Direction = Hitbox.Position - Origin
                            else
                                Visible = false
                                break
                            end
                        end
                    end

                    if Visible then
                        local Alpha

                        if InstantSnap then
                            Alpha = 1
                        else
                            Alpha = Clamp(Speed * Delta, 0, 1)

                            local Easing = EasingStyle[EasingName]

                            if Easing then
                                Alpha = Easing(Alpha)
                            end
                        end

                        if Method == "Camera" then
                            local AimCFrame = CFrame.lookAt(Camera.CFrame.Position, Hitbox.Position)

                            Camera.CFrame = Camera.CFrame:Lerp(AimCFrame, Alpha)
                        elseif Method == "Mouse" then
                            local MoveX = OffsetX * Alpha
                            local MoveY = OffsetY * Alpha

                            if Abs(MoveX) < 1 and Abs(OffsetX) > 0.5 then
                                MoveX = OffsetX > 0 and 1 or -1
                            end

                            if Abs(MoveY) < 1 and Abs(OffsetY) > 0.5 then
                                MoveY = OffsetY > 0 and 1 or -1
                            end

                            mousemoverel(MoveX, MoveY)
                        end
                    end
                elseif not StickyAim then
                    Combat.AimAssistTarget = nil
                end
            elseif not StickyAim then
                Combat.AimAssistTarget = nil
            end
        end
    else
        Combat.AimAssistTarget = nil
    end

    if Toggles["combat/triggerbot"].Value then
        local FOV = Options["combat/triggerbot/fov"].Value
        local ReactionTime = Options["combat/triggerbot/reactiontime"].Value / 1000
        local IgnoreBehindWalls = Toggles["combat/triggerbot/ignorebehindwalls"].Value

        local Target, Hitbox = Combat.GetTarget(FOV, false)

        if Target and Hitbox then
            local Visible = true

            if not IgnoreBehindWalls then
                local Origin = Camera.CFrame.Position
                local Direction = Hitbox.Position - Origin

                for _ = 1, 5 do
                    RaycastParams.FilterDescendantsInstances = {
                        LocalPlayer.Character
                    }


                    local Result = workspace:Raycast(Origin, Direction, RaycastParams)

                    if not Result then
                        break
                    end

                    local Part = Result.Instance

                    if Part.Parent == Target.Character then
                        break
                    end

                    if Part.Transparency >= 1 or not Part.CanCollide then
                        table.insert(IgnoreList, Part)

                        Origin = Result.Position + Direction.Unit * 0.01
                        Direction = Hitbox.Position - Origin
                    else
                        Visible = false
                        break
                    end
                end
            end

            if Visible then
                if Combat.TriggerBotTarget ~= Target then
                    Combat.TriggerBotTarget = Target
                    Combat.TriggerBotTime = os.clock()
                end

                if os.clock() - Combat.TriggerBotTime >= ReactionTime then
                    print("TriggerBot: Shoot", Target.Name, Hitbox.Name)
                end
            else
                Combat.TriggerBotTarget = nil
                Combat.TriggerBotTime = nil
            end
        else
            Combat.TriggerBotTarget = nil
            Combat.TriggerBotTime = nil
        end
    end
end

return Combat