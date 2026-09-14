--!optimize 2

--# Aliases

local FromOffset, FromScale, UDim2New = UDim2.fromOffset, UDim2.fromScale, UDim2.new
local Atan2, Rad, Pi, Abs, Minimum, Maximum, Floor, Clamp = math.atan2, math.rad, math.pi, math.abs, math.min, math.max, math.floor, math.clamp
local NewVector, NewVector3, NewCFrame = vector.create, Vector3.new, CFrame.new
local Create, IsA, QueryDescendants = Instance.new, workspace.IsA, workspace.QueryDescendants
local Spawn, Wait = task.spawn, task.wait
local ForEach, Insert, RemoveTable = table.foreach, table.insert, table.remove
local FindFirstChild, WaitForChild, FindFirstChildOfClass, Raycast  = workspace.FindFirstChild, workspace.WaitForChild, workspace.FindFirstChildOfClass, workspace.Raycast
local WorldToViewportPoint = workspace.CurrentCamera.WorldToViewportPoint
local GetService, IsKeyDown = Game.GetService, cloneref(Game:GetService("UserInputService")).IsKeyDown

--# Services

local MarketplaceService = GetService(Game, "MarketplaceService")
local ReplicatedStorage  = GetService(Game, "ReplicatedStorage")
local RunService         = GetService(Game, "RunService")
local InputService       = GetService(Game, "UserInputService")
local Stats              = GetService(Game, "Stats")
local DataPing           = Stats.Network.ServerStatsItem["Data Ping"]
local FrameRateManager   = Stats:FindFirstChild("FrameRateManager")
local RenderAverage      = FrameRateManager:FindFirstChild("RenderAverage")
local Players            = GetService(Game, "Players")

local LocalPlayer        = Players.LocalPlayer

--# Variables

local Params = RaycastParams.new()
Params.FilterType = Enum.RaycastFilterType.Exclude
Params.IgnoreWater = true
local Toggles, Options = getgenv().Toggles, getgenv().Options
local Camera = workspace.CurrentCamera

local PlayersCache = Players:GetPlayers()
Library:GiveSignal(Players.PlayerAdded:Connect(function()
    PlayersCache = Players:GetPlayers()
end))
Library:GiveSignal(Players.PlayerRemoving:Connect(function()
    PlayersCache = Players:GetPlayers()
end))

local EmptyVec3 = NewVector3()
local EmptyPhysicProp = PhysicalProperties.new(0,0,0,0,0)

--# Main

local Misc = {}

Misc.Movement = {} do

    function Misc.Movement.GetNearestWall()

        local Character = LocalPlayer.Character
        if not Character then return end

        local RootPart = Character.PrimaryPart
        if not RootPart then return end

        local Origin = RootPart.Position

        local Directions = {
            -RootPart.CFrame.LookVector,
            RootPart.CFrame.RightVector,
            -RootPart.CFrame.RightVector,
        }

        local NearestResult
        local NearestDistance = math.huge
        
        Params.FilterDescendantsInstances = { Character }

        for _, Direction in Directions do
            local Result = Raycast(workspace, Origin, Direction * 5, Params)

            if Result then
                local Distance = (Result.Position - Origin).Magnitude

                if Distance < NearestDistance then
                    NearestDistance = Distance
                    NearestResult = Result
                end
            end
        end

        if not NearestResult then
            return
        end

        return NearestResult.Position, NearestDistance, NearestResult
    end

    function Misc.Movement.Tick()
        local Character = LocalPlayer.Character
        if not Character then return end

        local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
        if not Humanoid then return end

        local RootPart = Character.PrimaryPart
        if not RootPart then return end

        if Toggles["misc/movement/speed"].Value then
            local Speed = Options["misc/movement/speed/value"].Value
            local MoveDir = Humanoid.MoveDirection

            if MoveDir.Magnitude > 0 then
                if RootPart then
                    local CurrentY = RootPart.AssemblyLinearVelocity.Y
                    RootPart.AssemblyLinearVelocity = NewVector3(MoveDir.X, 0, MoveDir.Z).Unit * Speed + NewVector3(0, CurrentY, 0)
                end
            end
        end

        if Toggles["misc/movement/autojump"].Value and IsKeyDown(InputService, "Space") then
            local Method = Options["misc/movement/autojump/method"].Value
            if Method == "Humanoid" then
                Humanoid.Jump = true
            elseif Method == "Velocity" then
                local State = Humanoid:GetState()
                if State == Enum.HumanoidStateType.Running or State == Enum.HumanoidStateType.RunningNoPhysics then
                    local RootPart = Character:FindFirstChild("HumanoidRootPart")
                    if RootPart then
                        local JumpPower = Humanoid.UseJumpPower and Humanoid.JumpPower or math.sqrt(2 * workspace.Gravity * Humanoid.JumpHeight)
                        local CurrentVelocity = RootPart.AssemblyLinearVelocity
                        RootPart.AssemblyLinearVelocity = NewVector3(CurrentVelocity.X, JumpPower, CurrentVelocity.Z)
                    end
                end
            end
        end

        if Toggles["misc/movement/pixelsurf"].Value and Options["misc/movement/pixelsurf/key"]:GetState() then

            local WallPos, Dist, Result = Misc.Movement.GetNearestWall()

            if Result and RootPart then
                local WallNormal = Result.Normal
                local FlatNormal = NewVector3(WallNormal.X, 0, WallNormal.Z)

                if FlatNormal.Magnitude > 0 then
                    FlatNormal = FlatNormal.Unit

                    local Velocity = RootPart.AssemblyLinearVelocity
                    local HorizontalVelocity = NewVector3(Velocity.X, 0, Velocity.Z)

                    local SurfVelocity = HorizontalVelocity - FlatNormal * HorizontalVelocity:Dot(FlatNormal)

                    RootPart.AssemblyLinearVelocity = NewVector3(SurfVelocity.X, 0, SurfVelocity.Z)
                end
            end
        end

    end
end

Misc.Exploits = {  } do
    function Misc.Exploits.Tick()
        if Toggles["misc/exploits/antifling"].Value then
            for _, Player in PlayersCache do
                if Player == LocalPlayer then continue end
                local Character = Player.Character
                if Character then
                    for _, Part in QueryDescendants(Character, "BasePart") do
                        Part.CustomPhysicalProperties = EmptyPhysicProp
                        Part.Velocity = EmptyVec3
                        Part.RotVelocity = EmptyVec3
                        Part.CanCollide = false
                    end
                end
            end
        end
    end
end

function Misc.Tick(Delta)
    Misc.Movement.Tick(Delta)
    Misc.Exploits.Tick(Delta)
end

return Misc