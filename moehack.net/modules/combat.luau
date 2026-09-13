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
local Players            = GetService(Game, "Players")

local LocalPlayer        = Players.LocalPlayer

--# Variable

local Camera = workspace.CurrentCamera

--# Main

local Combat = {}

function Combat.GetTarget(FOV: number)
    local ViewportSize = Camera.ViewportSize
    local Center = NewVector(
        ViewportSize.X * 0.5,
        ViewportSize.Y * 0.5
    )

    local BestTarget = nil
    local BestDistance = FOV

    for _, Player in Players:GetPlayers() do
        if Player ~= LocalPlayer then
            local Character = Player.Character

            if Character then
                local Humanoid = FindFirstChild(Character, "Humanoid")
                local RootPart = Character.PrimaryPart

                if Humanoid and RootPart and Humanoid.Health > 0 then
                    local Position, OnScreen = WorldToViewportPoint(
                        Camera,
                        RootPart.Position
                    )

                    if OnScreen and Position.Z > 0 then
                        local Distance = (
                            NewVector(Position.X, Position.Y) - Center
                        ).Magnitude

                        if Distance <= BestDistance then
                            BestDistance = Distance
                            BestTarget = Player
                        end
                    end
                end
            end
        end
    end

    return BestTarget
end

return Combat