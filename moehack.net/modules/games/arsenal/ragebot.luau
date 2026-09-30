--!native
--!optimize 2

--# Aliases

local FromOffset, FromScale, UDim2New = UDim2.fromOffset, UDim2.fromScale, UDim2.new
local Atan2, Rad, Pi, Abs, Minimum, Maximum, Floor, Clamp = math.atan2, math.rad, math.pi, math.abs, math.min, math.max, math.floor, math.clamp
local NewVector, NewVector3, NewCFrame = vector.create, Vector3.new, CFrame.new
local Create, IsA = Instance.new, workspace.IsA
local Spawn, Wait = task.spawn, task.wait
local ForEach, Insert, RemoveTable, TableFind = table.foreach, table.insert, table.remove, table.find
local FindFirstChild, WaitForChild = workspace.FindFirstChild, workspace.WaitForChild
local WorldToViewportPoint = workspace.CurrentCamera.WorldToViewportPoint
local Lower = string.lower
local GetService = Game.GetService

--# Services
local Players = GetService(Game, "Players")
local ReplicatedStorage = GetService(Game, "ReplicatedStorage")
local ReplicatedFirst = GetService(Game, "ReplicatedFirst")

--# Variables

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local NetClient = require(ReplicatedFirst.Client.Utility.NetClient)
local Events = require(ReplicatedStorage.Modules.Events)
local State = require(ReplicatedFirst.Client.Utility.State)

local PlayersCache = Players:GetPlayers()

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

--# Custom Modules

local Combat = LoadModule("moehack.net/modules/combat.luau")
local Utility = LoadModule("moehack.net/modules/utility.luau")

--# Main
local Ragebot = {}
Ragebot.__index = Ragebot

function Ragebot:Hit(Character)
    if not Character then return end
    local Head = Character:FindFirstChild("HeadHB") or Character:FindFirstChild("Head")
    if not Head then return end

    local GunId = State.gun and State.gun:GetAttribute("Id") or 4
    if not GunId then return end

    local Origin = Camera.CFrame.Position
    local Spoofed = CFrame.new(Origin, Head.Position)
    local Cx, Cy, Cz, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Spoofed:GetComponents()
    local Flags = bit32.replace(bit32.replace(bit32.bor(0, State.ads and 2 or 0, State.jumping and 4 or 0), State.currentSpell or 1, 3, 3), 2, 6, 2)
    local DeltaTime = (State.btick == 0 and 0.1 or (tick() - State.btick))

    NetClient.lock()
    NetClient.u16(Events.HitPart)
    NetClient.inst(Head)
    NetClient.u8(GunId)
    NetClient.u8(Flags)
    NetClient.u8(0)
    NetClient.f32(Cx) 
    NetClient.f32(Cy) 
    NetClient.f32(Cz)
    NetClient.f32(R00) 
    NetClient.f32(R01)
    NetClient.f32(R02)
    NetClient.f32(R10) 
    NetClient.f32(R11) 
    NetClient.f32(R12)
    NetClient.f32(R20) 
    NetClient.f32(R21)
    NetClient.f32(R22)
    NetClient.f32(Head.Position.X) NetClient.f32(Head.Position.Y) NetClient.f32(Head.Position.Z)
    NetClient.f32(DeltaTime)
    NetClient.unlock()
end

function Ragebot:Scan()
    local Targets = {}
    for _, Player in PlayersCache do
        if Player.Character then
            local MaxHealth, Health = Utility.GetHealth(Player, Player.Character)
            if Health and Health > 0 then
                local Head = Character:FindFirstChild("HeadHB") or Character:FindFirstChild("Head")
                if not Head then continue end

                if not Combat.IsBehindWalls(Player.Character, Head) then
                    
                end
            end
        end
    end
end

Library:GiveSignal( Players.PlayerAdded:Connect(function(Player)
    PlayersCache[Player] = Player
end) )

Library:GiveSignal(Players.PlayerRemoving:Connect(function(Player)
	PlayersCache[Player] = nil
end))

return Ragebot