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

local Toggles, Options = getgenv().Toggles, getgenv().Options

--# Main

local Misc = {}

Misc.Movement = {} do
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

    end
end

function Misc.Tick(Delta)
    Misc.Movement.Tick(Delta)
end

return Misc