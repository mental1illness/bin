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
local RunService = GetService(Game, "RunService")

--# Variables

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local NetClient = require(ReplicatedFirst.Client.Utility.NetClient)
local Events = require(ReplicatedStorage.Modules.Events)
local State = require(ReplicatedFirst.Client.Utility.State)
local Particles = require(game.ReplicatedFirst.Client.Game.Particles)
local HumanoidInstanceWrapper = require(game.ReplicatedStorage.Modules.HumanoidInstanceWrapper)

local PlayersCache = Players:GetPlayers()

--# Helper Funcs

LoadModule = function(Path)
    local FuckYouCacheBitch = getgenv().FuckYouCacheBitch


    if not isfile("current_sha_moehack.txt") then
        writefile("current_sha_moehack.txt", moehack.current_sha)
    end

    if not FuckYouCacheBitch then
        FuckYouCacheBitch = {}
        getgenv().FuckYouCacheBitch = FuckYouCacheBitch
    end

    if FuckYouCacheBitch[Path] ~= nil then
        return FuckYouCacheBitch[Path]
    end

    local url = "https://cats-cure-depression.vercel.app/" .. Path
    local CleanedPath = string.gsub(Path, "/", "")

    if readfile("current_sha_moehack.txt") ~= moehack.current_sha then
        writefile("current_sha_moehack.txt", moehack.current_sha)
        writefile(CleanedPath, Game:HttpGet(url))
    end

    local Result = loadstring(readfile(CleanedPath))()
    FuckYouCacheBitch[Path] = Result

    return Result
end

--# Custom Modules

local Combat = LoadModule("moehack.net/modules/combat.luau")
local Utility = LoadModule("moehack.net/modules/utility.luau")

--# Main
local Ragebot = { LastTimeFired = 0 }
Ragebot.__index = Ragebot

function Ragebot:Hit(Character)
    if not Character then return end
    local Head = FindFirstChild(Character, "HeadHB") or FindFirstChild(Character, "Head")
    if not Head then return end

    local Gun = State.gun
    if not Gun then return end
    local GunId = Gun:GetAttribute("Id") or 4
    local GunName = Gun.Name

    if Gun == nil or FindFirstChild(Gun, "Projectile") ~= nil then return end
    if FindFirstChild(Gun, "Melee") ~= nil then return end
    if State.ammocount ~= nil and State.ammocount <= 0 then return end
    if State.DISABLED == true then return end

    local Origin = Camera.CFrame.Position
    local Spoofed = CFrame.new(Origin, Head.Position)
    local Cx, Cy, Cz, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Spoofed:GetComponents()
    local Flags = bit32.replace(bit32.replace(bit32.bor(0, State.ads and 2 or 0, State.jumping and 4 or 0), State.currentSpell or 1, 3, 3), 2, 6, 2)
    local DeltaTime = (State.btick == 0 and 0.1 or (tick() - State.btick))

    local ProjectileHolder = FindFirstChild(Gun, "Projectile")
    if ProjectileHolder then
        local ProjectileName = nil
        if FindFirstChild(ProjectileHolder, "Arrow") then ProjectileName = "Arrow"
        elseif FindFirstChild(ProjectileHolder, "Rocket") then ProjectileName = "Rocket"
        elseif FindFirstChild(ProjectileHolder, "Grenade") then ProjectileName = "Grenade"
        elseif FindFirstChild(ProjectileHolder, "Baseball") then ProjectileName = "Baseball"
        elseif #ProjectileHolder:GetChildren() > 0 then ProjectileName = ProjectileHolder:GetChildren()[1].Name
        end

        if ProjectileName then
            local Speed = FindFirstChild(Gun, "Speed") and Gun.Speed.Value * 0.07 or 100
            if Speed == 0 then Speed = 0.01 end
            local Muzzle = Camera.CFrame.Position
            local Aim = Head.Position
            NetClient.lock()
            NetClient.u16(Events.ReplicateProjectile)
            NetClient.str(ProjectileName)
            NetClient.f32(Speed)
            NetClient.f32(Aim.X) NetClient.f32(Aim.Y) NetClient.f32(Aim.Z)
            NetClient.f32(Muzzle.X) NetClient.f32(Muzzle.Y) NetClient.f32(Muzzle.Z)
            NetClient.str(GunName)
            NetClient.f32(0)
            NetClient.u8(State.currentSpell or 1)
            NetClient.u8(bit32.bor(State.jumping and 1 or 0, State.ads and 2 or 0))
            NetClient.unlock()
        end
    end

    NetClient.lock()
    NetClient.u16(Events.HitPart)
    NetClient.inst(Head)
    NetClient.u8(GunId)
    NetClient.u8(Flags)
    NetClient.u8(0)
    NetClient.f32(Cx) NetClient.f32(Cy) NetClient.f32(Cz)
    NetClient.f32(R00) NetClient.f32(R01) NetClient.f32(R02)
    NetClient.f32(R10) NetClient.f32(R11) NetClient.f32(R12)
    NetClient.f32(R20) NetClient.f32(R21) NetClient.f32(R22)
    NetClient.f32(Head.Position.X) NetClient.f32(Head.Position.Y) NetClient.f32(Head.Position.Z)
    NetClient.f32(DeltaTime)
    NetClient.unlock()
end

function Ragebot:ReplicateShoot()
    local Character = LocalPlayer.Character
    if Character == nil then
        return
    end

    local Gun = HumanoidInstanceWrapper.Get(Character, "Gun")
    if Gun == nil then
        return
    end

    local Anims = State.anims
    local FireTrack = Anims.fireani or Anims.afireani or Anims.gfireani or Anims.efireani or Anims.cfireani or Anims.fire2ani or Anims.fire
    if FireTrack ~= nil then
        FireTrack:Play()
    end

    local Arms = Camera ~= nil and FindFirstChild(Camera, "Arms") or nil
    if Arms ~= nil then
        local Flash = FindFirstChild(Arms, "Flash")
        if Flash ~= nil then
            Particles.CreateMuzzleFlash(Flash)
        end

        local SecondFlash = FindFirstChild(Arms, "2Flash")
        if SecondFlash ~= nil then
            Particles.CreateMuzzleFlash(SecondFlash)
        end
    end

    local FlashAttachment = FindFirstChild(Gun, "Flash")
    NetClient.lock()
    NetClient.u16(Events.MuzzleParticleBounce)
    NetClient.inst(FlashAttachment ~= nil and FlashAttachment or Gun)
    NetClient.unlock()

    local SecondGun = HumanoidInstanceWrapper.Get(Character, "Gun2")
    if SecondGun ~= nil then
        local SecondModel = FindFirstChild(SecondGun, "Model2")
        local SecondAttachment = nil
        if SecondModel ~= nil then
            SecondAttachment = FindFirstChild(SecondModel, "Flash")
        end
        if SecondAttachment == nil then
            SecondAttachment = FindFirstChild(SecondGun, "Flash")
        end

        NetClient.lock()
        NetClient.u16(Events.MuzzleParticleBounce)
        if SecondModel ~= nil and SecondAttachment ~= nil then
            NetClient.inst(SecondAttachment)
        elseif SecondAttachment ~= nil then
            NetClient.inst(SecondAttachment)
        else
            NetClient.inst(SecondGun)
        end
        NetClient.unlock()
    end
end

function Ragebot:Scan()

    if not Toggles["combat/ragebot"].Value then return end

    local Gun = State.gun
    if not Gun then return end
    local FireRate = Gun and FindFirstChild(Gun, "FireRate") and Gun.FireRate.Value or 0
    if not FireRate then return end
    if FindFirstChild(Gun, "Projectile") ~= nil then return end
    if FindFirstChild(Gun, "Melee") ~= nil then return end
    if State.ammocount ~= nil and State.ammocount <= 0 then return end
    if State.DISABLED == true then return end

    local Target = nil
    for _, Player in PlayersCache do
        if Player == LocalPlayer then continue end
        local Character = Player.Character
        if Character and not Utility.IsTeammate(LocalPlayer, Player) then
            local MaxHealth, Health = Utility.GetHealth(Player, Character)
            if Health and Health > 0 then
                local Head = FindFirstChild(Character, "HeadHB") or FindFirstChild(Character, "Head")
                if not Head then continue end

                if not Combat.IsBehindWalls(Player.Character, Head) then
                    Target = Player.Character
                    break
                end
            end
        end
    end

    local Now = tick()
    if Target and Now - (self.LastTimeFired or 0) >= FireRate then
        self.LastTimeFired = Now
        self:Hit(Target)
        self:ReplicateShoot()
    end
end

Library:GiveSignal(RunService.Stepped:Connect(function()
    Ragebot:Scan()
end))

Library:GiveSignal( Players.PlayerAdded:Connect(function(Player)
    PlayersCache = Players:GetPlayers()
end) )

Library:GiveSignal(Players.PlayerRemoving:Connect(function(Player)
	PlayersCache = Players:GetPlayers()
end))

return Ragebot