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

--# Main

local Utility = {}

Utility.EasingStyle = {
    Linear = function(t)
        return t
    end,

    Sine = function(t)
        return 1 - math.cos(t * math.pi * 0.5)
    end,

    Quad = function(t)
        return t * t
    end,

    Cubic = function(t)
        return t * t * t
    end,

    Quart = function(t)
        return t * t * t * t
    end,

    Quint = function(t)
        return t * t * t * t * t
    end,

    Exponential = function(t)
        return t == 0 and 0 or 2 ^ (10 * (t - 1))
    end,

    Circular = function(t)
        return 1 - math.sqrt(1 - t * t)
    end,

    SmoothStep = function(t)
        return t * t * (3 - 2 * t)
    end,

    SmootherStep = function(t)
        return t * t * t * (t * (t * 6 - 15) + 10)
    end,

    Back = function(t)
        local s = 1.70158
        return t * t * ((s + 1) * t - s)
    end,

    Elastic = function(t)
        if t == 0 or t == 1 then
            return t
        end

        local c4 = (2 * math.pi) / 3
        return -(2 ^ (10 * t - 10))
            * math.sin((t * 10 - 10.75) * c4)
    end,

    Bounce = function(t)
        local n1 = 7.5625
        local d1 = 2.75

        if t < 1 / d1 then
            return n1 * t * t
        elseif t < 2 / d1 then
            t = t - 1.5 / d1
            return n1 * t * t + 0.75
        elseif t < 2.5 / d1 then
            t = t - 2.25 / d1
            return n1 * t * t + 0.9375
        else
            t = t - 2.625 / d1
            return n1 * t * t + 0.984375
        end
    end,
}

Utility.EasingStylesKey = {
    "Sine",
    "Quad",
    "Cubic",
    "Quart",
    "Quint",
    "Exponential",
    "Circular",
    "Linear",
    "SmoothStep",
    "SmootherStep",
    "Back",
    "Elastic",
    "Bounce",
}

Utility.EasingDirection = {
    In = function(EasingFunction, t)
        return EasingFunction(t)
    end,

    Out = function(EasingFunction, t)
        return 1 - EasingFunction(1 - t)
    end,

    InOut = function(EasingFunction, t)
        if t < 0.5 then
            return EasingFunction(t * 2) * 0.5
        end
        return 1 - EasingFunction((1 - t) * 2) * 0.5
    end,
}

Utility.EasingDirectionsKey = {
    "In",
    "Out",
    "InOut",
}

function Utility.GetCharacter(Player)
    if moehack.data.game_name == "Operation One" then
        if not StateObject then
            StateObject = require(ReplicatedStorage.Modules.StateObject)
        end
        if not Player.Character then return nil end
        local Data = StateObject.get("Character", Player.Character)
        if not Data then return end
        if not Data.values or not Data.values.viewmodels then return end
        return Data.values.viewmodels
    end
    return Player.Character
end

function Utility.IsTeammate(Player1, Player2)
    if moehack.data.game_name == "Blox Strike" then
        return Player1:GetAttribute("Team") == Player2:GetAttribute("Team")
    end
    return Player1.Team == Player2.Team
end

function Utility.GetHealth(Player, Character)

    if moehack.data.game_name == "Blox Strike" then
        return Character:GetAttribute("MaxHealth"), Character:GetAttribute("Health")
    end

    local MaxHealth, Health = 0, 0
    local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
    if Humanoid then
        MaxHealth = Humanoid.MaxHealth
        Health = Humanoid.Health
    end

    return MaxHealth, Health
end

function Utility.GetTool(Player, Character)

    if moehack.data.game_name == "Operation One" then
        if not StateObject then
            StateObject = require(ReplicatedStorage.Modules.StateObject)
        end
        if not Player.Character then return nil end
        local Data = StateObject.get("Character", Player.Character)
        return Data.values.equipped and Data.values.equipped.Name or "NONE"
    end

    local Tool = FindFirstChildOfClass(Character, "Tool")
    if Tool then return Tool.Name end
    return "none"
end


function Utility.GetHumanoid(Entity) -- for ESP only
    if Entity.Humanoid and Entity.Humanoid.Parent then
        return Entity.Humanoid
    end

    local Character = Entity.IsCustom and Entity.Target or (Entity.Player and Entity.Player.Character)
    if not Character then
        return nil
    end

    local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
    Entity.Humanoid = Humanoid

    return Humanoid
end

return Utility