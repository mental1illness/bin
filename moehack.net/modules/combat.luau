--!native
--!optimize 2

--# Aliases

local FromOffset, FromScale, UDim2New = UDim2.fromOffset, UDim2.fromScale, UDim2.new
local Atan2, Rad, Pi, Abs, Minimum, Maximum, Floor, Clamp, Sqrt, Asin = math.atan2, math.rad, math.pi, math.abs, math.min, math.max, math.floor, math.clamp, math.sqrt, math.asin
local NewVector, NewVector3, NewCFrame = vector.create, Vector3.new, CFrame.new
local Create, IsA, IsDescendantOf, GetChildren, QueryDescendants = Instance.new, workspace.IsA, workspace.IsDescendantOf, workspace.GetChildren, workspace.QueryDescendants
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
local VirtualInputManager = Create("VirtualInputManager")
local UserInputService = GetService(Game, "UserInputService")
local Players = GetService(Game, "Players")

local UserGameSettings = UserSettings():GetService("UserGameSettings")

local LocalPlayer = Players.LocalPlayer

--# Helper Funcs

LoadModule = function(Path, Load)
    local url = "https://cats-cure-depression.vercel.app/" .. Path
    return Load == true and loadstring(game:HttpGet(url))() or game:HttpGet(url)
end

local function ExpSmoothing(Rate, DeltaTime)
    return 1 - math.exp(-Rate * DeltaTime)
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
    TriggerBotTime = nil,
    RCSLastPitch = nil,
    RCSMouseSensitivity = 0.0025,
    RCSRecoil = 0,
    RCSCorrection = 0,
}

function Combat.IsBehindWalls(Target, Hitbox)
    local Character = Target and Target.Character

    if not Character or not Hitbox or not Hitbox:IsDescendantOf(Character) then
        return true
    end

    local Origin = Camera.CFrame.Position
    local Direction = Hitbox.Position - Origin

    local IgnoreList = {
        LocalPlayer.Character
    }

    for _ = 1, 20 do
        RaycastParams.FilterDescendantsInstances = IgnoreList

        local Result = Raycast(
            workspace,
            Origin,
            Direction,
            RaycastParams
        )

        if not Result then
            return false
        end

        local Part = Result.Instance

        if IsDescendantOf(Part, Character) then
            return false
        end

        if Part.Transparency >= 1 or not Part.CanCollide then
            Insert(IgnoreList, Part)

            Origin = Result.Position + Direction.Unit * 0.01
            Direction = Hitbox.Position - Origin
        else
            return true
        end
    end

    return true
end

function Combat.GetCharacter(Player)
    if PlaceId == 72920620366355 then
        if not StateObject then
            StateObject = require(ReplicatedStorage.Modules.StateObject)
        end
        if not Player.Character then return nil end
        local Data = StateObject.get("Character", Player.Character)
        return Data.values.viewmodels
    end
    return Player.Character
end

function Combat.GetTarget(FOV: number, BestHitbox: boolean)
    local ViewportSize = Camera.ViewportSize
    local Center = NewVector(ViewportSize.X * 0.5, ViewportSize.Y * 0.5)
    local BestTarget = nil
    local BestHitboxPart = nil
    local BestDistance = FOV

    for _, Player in Players:GetPlayers() do
        if Player ~= LocalPlayer then
            local Character = Combat.GetCharacter(Player)
            local RealCharacter = Player.Character

            if Character then
                local Humanoid = FindFirstChild(Character, "Humanoid")
                local RootPart = PlaceId == 72920620366355 and FindFirstChild(Character, "head", true) or Character.PrimaryPart

                if Humanoid and RootPart and Humanoid.Health > 0 then
                    if BestHitbox then
                        for _, Hitbox in QueryDescendants(Character, "BasePart") do
                            --if IsA(Hitbox, "BasePart") then
                                local Position, OnScreen = WorldToViewportPoint(Camera, Hitbox.Position)

                                if OnScreen and Position.Z > 0 then
                                    local Distance = (NewVector(Position.X, Position.Y) - Center).Magnitude

                                    if Distance <= BestDistance then
                                        BestDistance = Distance
                                        BestTarget = Player
                                        BestHitboxPart = Hitbox
                                    end
                                end
                            --end
                        end
                    else
                        local Position, OnScreen = WorldToViewportPoint(Camera, RootPart.Position)

                        if OnScreen and Position.Z > 0 then
                            local Distance = (NewVector(Position.X, Position.Y) - Center).Magnitude

                            if Distance <= BestDistance then
                                BestDistance = Distance
                                BestTarget = Player
                                print(RootPart)
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

                    if IgnoreBehindWalls then
                        Visible = not Combat.IsBehindWalls(Target, Hitbox)
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

    if Toggles["combat/triggerbot"].Value and Options["combat/triggerbot/key"]:GetState() then
        local FOV = Options["combat/triggerbot/fov"].Value
        local ReactionTime = Options["combat/triggerbot/reactiontime"].Value / 1000
        local IgnoreBehindWalls = Toggles["combat/triggerbot/ignorebehindwalls"].Value

        local Target, Hitbox = Combat.GetTarget(FOV, true)

        if Target and Hitbox then
            local Visible = true

            if IgnoreBehindWalls then
                Visible = not Combat.IsBehindWalls(Target, Hitbox)
            end

            if Visible then
                if Combat.TriggerBotTarget ~= Target then
                    Combat.TriggerBotTarget = Target
                    Combat.TriggerBotTime = os.clock()
                end

                if Combat.TriggerBotTime and os.clock() - Combat.TriggerBotTime >= ReactionTime then
                    local Middle = Camera.ViewportSize / 2

                    VirtualInputManager:SendMouseButtonEvent(Middle.X, Middle.Y, 0, true, Game, 0)
                    VirtualInputManager:SendMouseButtonEvent(Middle.X, Middle.Y, 0, false, Game, 0)
                end
            else
                Combat.TriggerBotTarget = nil
                Combat.TriggerBotTime = nil
            end
        else
            Combat.TriggerBotTarget = nil
            Combat.TriggerBotTime = nil
        end
    else
        Combat.TriggerBotTarget = nil
        Combat.TriggerBotTime = nil
    end

    if Toggles["combat/rcs"].Value and Options["combat/rcs/key"]:GetState() then
        local DeltaTime = Clamp(Delta, 1 / 240, 1 / 30)
        local MouseY = UserInputService:GetMouseDelta().Y

        local LookVector = Camera.CFrame.LookVector
        local CurrentPitch = Asin(Clamp(-LookVector.Y, -1, 1))

        if not Combat.RCSLastPitch then
            Combat.RCSLastPitch = CurrentPitch
            Combat.RCSRecoil = 0
            Combat.RCSCorrection = 0
        else
            local CameraDelta = CurrentPitch - Combat.RCSLastPitch
            Combat.RCSLastPitch = CurrentPitch

            local Sensitivity = Combat.RCSMouseSensitivity or 0.003
            local PreviousCorrection = Combat.RCSCorrection or 0

            local StableInput =
                Abs(MouseY) >= 2
                and Abs(MouseY) <= 80
                and Abs(PreviousCorrection) < 0.1
                and Abs(CameraDelta) < 0.05

            if StableInput then
                local MeasuredSensitivity = CameraDelta / MouseY

                if MeasuredSensitivity > 0.0001
                    and MeasuredSensitivity < 0.02 then

                    local LearnAlpha = ExpSmoothing(3, DeltaTime)

                    Combat.RCSMouseSensitivity =
                        Sensitivity
                        + (MeasuredSensitivity - Sensitivity) * LearnAlpha

                    Sensitivity = Combat.RCSMouseSensitivity
                end
            end

            local ExpectedMouseDelta = MouseY * Sensitivity
            local Residual = CameraDelta - ExpectedMouseDelta

            if Abs(Residual) < 0.0005 then
                Residual = 0
            end

            Residual = math.clamp(Residual, -0.025, 0.025)

            local RecoilContribution = 0

            if Residual > 0 then
                RecoilContribution = Residual
            elseif Residual < 0 and MouseY < 0 then
                RecoilContribution = Residual
            end

            local RecoilDecay = math.exp(-7 * DeltaTime)

            Combat.RCSRecoil =
                Combat.RCSRecoil * RecoilDecay
                + RecoilContribution

            Combat.RCSRecoil =
                math.clamp(Combat.RCSRecoil, -0.35, 0.35)

            if math.abs(Sensitivity) > 0.0001 then
                local DesiredCorrection =
                    -(Combat.RCSRecoil / Sensitivity)

                DesiredCorrection = math.clamp(DesiredCorrection, -30, 30)

                local CorrectionAlpha =
                    ExpSmoothing(
                        math.max(1, Options["combat/rcs/speed"].Value * 8),
                        DeltaTime
                    )

                local Correction =
                    Combat.RCSCorrection
                    + (DesiredCorrection - Combat.RCSCorrection)
                    * CorrectionAlpha

                if math.abs(Correction) >= 0.1 then
                    mousemoverel(0, Correction)

                    Combat.RCSCorrection = Correction

                    Combat.RCSRecoil =
                        Combat.RCSRecoil
                        + Correction * Sensitivity
                else
                    Combat.RCSCorrection = 0
                end
            else
                Combat.RCSCorrection = 0
            end
        end
    else
        Combat.RCSLastPitch = nil
        Combat.RCSMouseSensitivity = Combat.RCSMouseSensitivity or 0.003
        Combat.RCSRecoil = 0
        Combat.RCSCorrection = 0
    end

    
end

return Combat