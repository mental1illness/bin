--!native
--!optimize 2

--# Aliases

local FromOffset, FromScale, UDim2New = UDim2.fromOffset, UDim2.fromScale, UDim2.new
local Atan2, Rad, Pi, Abs, Minimum, Maximum, Floor, Clamp = math.atan2, math.rad, math.pi, math.abs, math.min, math.max, math.floor, math.clamp
local NewVector, NewVector3, NewCFrame = vector.create, Vector3.new, CFrame.new
local Create, IsA = Instance.new, workspace.IsA
local Spawn, Wait = task.spawn, task.wait
local ForEach, Insert, RemoveTable, TableFind = table.foreach, table.insert, table.remove, table.find
local FindFirstChild, WaitForChild, Raycast = workspace.FindFirstChild, workspace.WaitForChild, workspace.Raycast
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
local Bridge = require(ReplicatedFirst.Client.Utility.Bridge)
local Particles = require(ReplicatedFirst.Client.Game.Particles)
local HumanoidInstanceWrapper = require(ReplicatedStorage.Modules.HumanoidInstanceWrapper)
local General = require(ReplicatedFirst.Client.Utility.General)
local GeneralFunctions = require(ReplicatedStorage.Modules.GeneralFunctions)

local PlayersCache = Players:GetPlayers()

--# Custom Modules

local Combat = moehack.load_module("moehack.net/modules/combat.luau")
local Utility = moehack.load_module("moehack.net/modules/utility.luau")

--# Cache

local Wkspc = ReplicatedStorage:WaitForChild("wkspc")
local Status = Wkspc:WaitForChild("Status")

local KnifebotOverlapParams = OverlapParams.new()
KnifebotOverlapParams.FilterType = Enum.RaycastFilterType.Exclude

local VisibilityParams = RaycastParams.new()
VisibilityParams.FilterType = Enum.RaycastFilterType.Exclude
VisibilityParams.IgnoreWater = true

local OriginParams = RaycastParams.new()
OriginParams.FilterType = Enum.RaycastFilterType.Exclude
OriginParams.IgnoreWater = true

local NAN = 0/0

local LastRootPos = nil
local LastRootTick = 0

local CanHitFXPls = false

local EmptyVec3 = NewVector3()

local OriginPresets = {
    NewVector3(0, 0, 0),

    NewVector3(0, 2, 0),
    NewVector3(0, -2, 0),

    NewVector3(2, 0, 0),
    NewVector3(-2, 0, 0),

    NewVector3(0, 0, 2),
    NewVector3(0, 0, -2),

    NewVector3(2, 2, 0),
    NewVector3(-2, 2, 0),

    NewVector3(2, -2, 0),
    NewVector3(-2, -2, 0),

    NewVector3(0, 2, 2),
    NewVector3(0, 2, -2),

    NewVector3(0, -2, 2),
    NewVector3(0, -2, -2)
}

local OriginCache = {}
local VisibilityCache = {}

local OriginCacheTime = 0.075
local VisibilityCacheTime = 0.05

--# Main

local Ragebot = { LastTimeFired = 0 }
Ragebot.__index = Ragebot

function Ragebot:Origin()
	local Character = LocalPlayer.Character
	local Root = Character and (Character.PrimaryPart or FindFirstChild(Character, "HumanoidRootPart"))
	local Origin = Camera.CFrame.Position

	if Root then
		local Now = tick()
		local Delta = Now - LastRootTick
		local Vel = Root.AssemblyLinearVelocity

		if LastRootPos and Delta > 0 and Delta < 1 then
			local Measured = (Root.Position - LastRootPos) / Delta
			if Measured.Magnitude > Vel.Magnitude then
				Vel = Measured
			end
		end

		LastRootPos = Root.Position
		LastRootTick = Now

		if Vel.Magnitude > 50 then
			local Ping = LocalPlayer:GetNetworkPing() or 0
			local Comp = Clamp(Ping + 0.03, 0.03, 0.25)
			Origin = Camera.CFrame.Position + Vel * Comp
		end
	end

	return Origin
end

function Ragebot:IsVisible(Target: BasePart, Origin: Vector3?): boolean
	if not Target or not Target.Parent then return false end

	Origin = Origin or Camera.CFrame.Position

	local Character = Target:FindFirstAncestorOfClass("Model")
	if not Character then return false end

	local Now = tick()
	local Cached = VisibilityCache[Target]

	if Cached and Now - Cached.Time < VisibilityCacheTime and Cached.Origin == Origin then
		return Cached.Visible
	end

	VisibilityParams.FilterDescendantsInstances = GeneralFunctions.gethitlist()

	local Result = Raycast(workspace, Origin, Target.Position - Origin, VisibilityParams)
	local Visible = not Result or Result.Instance:IsDescendantOf(Character)

	VisibilityCache[Target] = {
		Time = Now,
		Origin = Origin,
		Visible = Visible
	}

	return Visible
end

function Ragebot:HitFX(Head: BasePart, Origin: Vector3, HeadBits: number)
	if not CanHitFXPls then return end
	if not Head or not Origin then return end

	local Gun = State.gun
	if not Gun then return end

	local Normal = (Head.Position - Origin).Unit

	Bridge.HitObject:Fire(Head, Head.Position, Normal, Gun, HeadBits or 1, false, false, false)

	local Override = GeneralFunctions.getTrailColorOverride(LocalPlayer, Gun)
	Particles.CreateTrail(Origin, Head.Position, Override)

	CanHitFXPls = false
end

function Ragebot:OriginScan(TargetCharacter)
	local Character = LocalPlayer.Character
	local RootPart = Character and Character.PrimaryPart
	local Head = TargetCharacter and (FindFirstChild(TargetCharacter, "HeadHB") or FindFirstChild(TargetCharacter, "Head"))

	if not RootPart or not Head then return nil end

	local Now = tick()
	local Cached = OriginCache[TargetCharacter]

	if Cached and Now - Cached.Time < OriginCacheTime then
		return Cached.Origin
	end

	OriginParams.FilterDescendantsInstances = { Character }

	local MaxOrigins = Minimum(Options["combat/originscan/maxorigin"].Value, #OriginPresets)
	local MaxDistance = Options["combat/originscan/maxdist"].Value
	local MaxDistanceSq = MaxDistance * MaxDistance
	local RootCFrame = RootPart.CFrame
	local RootPosition = RootPart.Position
	local TargetPosition = Head.Position

	for Index = 1, MaxOrigins do
		local Offset = OriginPresets[Index]
		local WorldOffset = RootCFrame:VectorToWorldSpace(Offset)

		if WorldOffset:Dot(WorldOffset) <= MaxDistanceSq then
			local Origin = RootPosition + WorldOffset
			local Direction = TargetPosition - Origin
			local Result = Raycast(workspace, Origin, Direction, OriginParams)

			if not Result or Result.Instance:IsDescendantOf(TargetCharacter) then
				OriginCache[TargetCharacter] = {
					Time = Now,
					Origin = Origin
				}

				return Origin
			end
		end
	end

	OriginCache[TargetCharacter] = {
		Time = Now,
		Origin = nil
	}

	return nil
end

function Ragebot:GetOrigin(TargetCharacter)
	if Toggles["combat/originscan"] and Toggles["combat/originscan"].Value and TargetCharacter then
		local Scanned = self:OriginScan(TargetCharacter)
		if Scanned then return Scanned end
	end

	return self:Origin()
end

function Ragebot:Hit(Character, PenIndex, SharedCFrame, ForcedOrigin)
	if not Character then return end

	local Self = self
	local Head = FindFirstChild(Character, "HeadHB") or FindFirstChild(Character, "Head")
	if not Head then return end

	local Gun = State.gun
	if not Gun then return end
	if FindFirstChild(Gun, "Melee") ~= nil then return end
	if FindFirstChild(Gun, "DK") ~= nil then return end
	if FindFirstChild(Gun, "Lunchbox") ~= nil then return end
	if State.ammocount ~= nil and State.ammocount <= 0 then return end
	if State.DISABLED == true then return end
	if State.equipping == true then return end

	local GunName = Gun.Name
	local ProjectileHolder = FindFirstChild(Gun, "Projectile")

	if ProjectileHolder then
		local ProjectileName = nil

		if FindFirstChild(ProjectileHolder, "Arrow") then
			ProjectileName = "Arrow"
		elseif FindFirstChild(ProjectileHolder, "Rocket") then
			ProjectileName = "Rocket"
		elseif FindFirstChild(ProjectileHolder, "Grenade") then
			ProjectileName = "Grenade"
		elseif FindFirstChild(ProjectileHolder, "Baseball") then
			ProjectileName = "Baseball"
		elseif #ProjectileHolder:GetChildren() > 0 then
			ProjectileName = ProjectileHolder:GetChildren()[1].Name
		end

		if not ProjectileName then return end
		if FindFirstChild(ProjectileHolder, "Rocket") and LocalPlayer:FindFirstChild("RocketDebounce") then return end

		local GunId = Gun:GetAttribute("Id") or 4
		local Speed = FindFirstChild(Gun, "Speed") and Gun.Speed.Value * 0.07 or 100

		if Speed == 0 then
			Speed = 0.01
		end

		Speed *= Options["combat/ragebot/projectilespeedmult"].Value

		local Origin = ForcedOrigin or self:GetOrigin(Character)
		local Aim = Head.Position
		local LegitTarget = Camera.CFrame.Position + Camera.CFrame.LookVector * 1000
		local Muzzle = (Camera.CFrame * NewCFrame(1.5, -0.65, 0)).Position

		NetClient.lock()
		NetClient.u16(Events.ReplicateProjectile)
		NetClient.str(ProjectileName)
		NetClient.f32(Speed)
		NetClient.f32(LegitTarget.X) NetClient.f32(LegitTarget.Y) NetClient.f32(LegitTarget.Z)
		NetClient.f32(Muzzle.X) NetClient.f32(Muzzle.Y) NetClient.f32(Muzzle.Z)
		NetClient.str(GunName)
		NetClient.f32(0)
		NetClient.u8(State.currentSpell or 1)
		NetClient.u8(bit32.bor(State.jumping and 1 or 0, State.ads and 2 or 0))
		NetClient.unlock()

		local Travel = (Aim - Origin).Magnitude / Speed
		local FireAds = State.ads
		local FireJump = State.jumping
		local FireSpell = State.currentSpell or 1

		task.delay(Travel, function()
			if Head.Parent == nil then return end

			local Spoofed = NewCFrame(Origin, Head.Position)
			local Cx, Cy, Cz, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Spoofed:GetComponents()
			local HeadBits = ProjectileName == "Arrow" and 2 or 0
			local Flags = bit32.replace(bit32.replace(bit32.bor(0, FireAds and 2 or 0, FireJump and 4 or 0), FireSpell, 3, 3), HeadBits, 6, 2)
			local N = (Head.Position - Origin).Unit

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
			NetClient.f32(0)
			NetClient.unlock()

			NetClient.lock()
			NetClient.u16(Events.ImpactParticleBounce)
			NetClient.u8(GunId)
			NetClient.inst(Head)
			NetClient.f32(Head.Position.X) NetClient.f32(Head.Position.Y) NetClient.f32(Head.Position.Z)
			NetClient.f32(N.X) NetClient.f32(N.Y) NetClient.f32(N.Z)
			NetClient.unlock()

			Self:HitFX(Head, Origin, HeadBits)
		end)

		return
	end

	local GunId = Gun:GetAttribute("Id") or 4
	local Origin = ForcedOrigin or self:GetOrigin(Character)
	local Spoofed = SharedCFrame or NewCFrame(Origin, Head.Position)
	local Cx, Cy, Cz, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Spoofed:GetComponents()
	local IsCrit = FindFirstChild(Gun, "Scoped") or FindFirstChild(Gun, "Crit")
	local HeadBits = IsCrit and 2 or 1
	local Flags = bit32.replace(bit32.replace(bit32.bor(0, State.ads and 2 or 0, State.jumping and 4 or 0), State.currentSpell or 1, 3, 3), HeadBits, 6, 2)
	local DeltaTime = (State.btick == 0 and 0 or (tick() - State.btick))
	local Bullets = FindFirstChild(Gun, "Bullets") and Gun.Bullets.Value or 1

	Bullets = Clamp(Bullets, 1, 10)

	local Pen = Clamp(PenIndex or 1, 1, 3)

	for _ = 1, Bullets do
		NetClient.lock()
		NetClient.u16(Events.HitPart)
		NetClient.inst(Head)
		NetClient.u8(GunId)
		NetClient.u8(Flags)
		NetClient.u8(Pen)
		NetClient.f32(Cx) NetClient.f32(Cy) NetClient.f32(Cz)
		NetClient.f32(R00) NetClient.f32(R01) NetClient.f32(R02)
		NetClient.f32(R10) NetClient.f32(R11) NetClient.f32(R12)
		NetClient.f32(R20) NetClient.f32(R21) NetClient.f32(R22)
		NetClient.f32(Head.Position.X) NetClient.f32(Head.Position.Y) NetClient.f32(Head.Position.Z)
		NetClient.f32(DeltaTime)
		NetClient.unlock()

		self:HitFX(Head, Origin, HeadBits)
	end

	if FindFirstChild(Gun, "ThrowWeapon") then
		local TSpeed = FindFirstChild(Gun, "Speed") and Gun.Speed.Value * 0.07 or 100

		if TSpeed == 0 then
			TSpeed = 0.01
		end

		local LegitTarget = Camera.CFrame.Position + Camera.CFrame.LookVector * 1000
		local Muzzle = (Camera.CFrame * NewCFrame(1.5, -0.65, 0)).Position

		NetClient.lock()
		NetClient.u16(Events.ReplicateProjectile)
		NetClient.str("Baseball")
		NetClient.f32(TSpeed)
		NetClient.f32(LegitTarget.X) NetClient.f32(LegitTarget.Y) NetClient.f32(LegitTarget.Z)
		NetClient.f32(Muzzle.X) NetClient.f32(Muzzle.Y) NetClient.f32(Muzzle.Z)
		NetClient.str(GunName)
		NetClient.f32(0)
		NetClient.u8(State.currentSpell or 1)
		NetClient.u8(bit32.bor(State.jumping and 1 or 0, State.ads and 2 or 0))
		NetClient.unlock()
	end
end

function Ragebot:ReplicateShoot()
	local Character = LocalPlayer.Character
	if Character == nil then return end

	local Gun = HumanoidInstanceWrapper.Get(Character, "Gun")
	if Gun == nil then return end

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

	local ViewGun = State.gun

	if ViewGun then
		local Model = FindFirstChild(ViewGun, "Model")
		local ShootVal = Model and FindFirstChild(Model, "Shoot") or FindFirstChild(ViewGun, "Shoot")

		if ShootVal then
			General.PlayLocalSound(ShootVal)
		end
	end
end

function Ragebot:Stab(Character, ForcedOrigin)
	if not Character then return end

	local Head = FindFirstChild(Character, "HeadHB") or FindFirstChild(Character, "Head") or FindFirstChild(Character, "Hitbox")
	if not Head then return end

	local Gun = State.gun
	if not Gun then return end
	if FindFirstChild(Gun, "Melee") == nil then return end
	if State.DISABLED == true then return end
	if State.equipping == true then return end

	local Range = FindFirstChild(Gun, "Range") and Gun.Range.Value + 1 or 7
	local RealOrigin = self:Origin()

	if (Head.Position - RealOrigin).Magnitude > Range + 1 then return end

	local Origin = ForcedOrigin or self:GetOrigin(Character)
	local FakeOrigin = Origin
	local Root = Character.PrimaryPart

	if Root then
		FakeOrigin = Head.Position - Root.CFrame.LookVector * 4
	end

	local GunId = Gun:GetAttribute("Id") or 125
	local Spoofed = NewCFrame(FakeOrigin, Head.Position)
	local Cx, Cy, Cz, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Spoofed:GetComponents()
	local Flags = bit32.replace(bit32.replace(bit32.bor(1, State.ads and 2 or 0, State.jumping and 4 or 0), State.currentSpell or 1, 3, 3), 0, 6, 2)
	local DeltaTime = (State.btick == 0 and 0 or (tick() - State.btick))

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

	self:HitFX(Head, Origin, 0, true)
end

function Ragebot:Knifebot()
	if not Toggles["combat/knifebot"].Value then return end
	if Toggles["combat/ragebot/removeextrachecks"].Value then return end

	local Gun = State.gun
	if not Gun then return end
	if FindFirstChild(Gun, "Melee") == nil then return end

	local Character = LocalPlayer.Character
	local RootPart = Character and Character.PrimaryPart

	if not RootPart then return end

	local Range = FindFirstChild(Gun, "Range") and Gun.Range.Value + 1 or 7
	local Parts = workspace:GetPartBoundsInRadius(RootPart.Position, Range, KnifebotOverlapParams)

	for _, Part in Parts do
		local TargetCharacter = Part:FindFirstAncestorOfClass("Model")
		if not TargetCharacter then continue end

		local Player = Players:GetPlayerFromCharacter(TargetCharacter)
		if not Player or Player == LocalPlayer then continue end
		if Utility.IsTeammate(LocalPlayer, Player) then continue end

		local MaxHealth, Health = Utility.GetHealth(Player, TargetCharacter)
		if Health <= 0 then continue end
		if TargetCharacter:FindFirstChildOfClass("ForceField") then continue end

		self:Stab(TargetCharacter)

		if not Toggles["combat/ragebot/multitarget"].Value then
			break
		end
	end
end

function Ragebot:Scan()
	local Now = tick()

	if Status.Preparation.Value then return end
	if not Toggles["combat/ragebot"].Value then return end

	local Gun = State.gun
	if not Gun then return end

	local FireRate = FindFirstChild(Gun, "FireRate") and Gun.FireRate.Value or 0
	if not FireRate then return end

	if not Toggles["combat/ragebot/removeextrachecks"].Value then
		if FindFirstChild(Gun, "Melee") ~= nil then return end
		if State.ammocount ~= nil and State.ammocount <= 0 then return end
		if State.DISABLED == true then return end
	end

	local HasPen = FindFirstChild(Gun, "Penetration") ~= nil
	local Sorted = {}
	local HitList = GeneralFunctions.gethitlist()

	for _, Player in PlayersCache do
		if Player == LocalPlayer then continue end

		local Character = Player.Character

		if Character and not Utility.IsTeammate(LocalPlayer, Player) then
			local MaxHealth, Health = Utility.GetHealth(Player, Character)

			if Health and Health > 0 then
				local Head = FindFirstChild(Character, "HeadHB") or FindFirstChild(Character, "Head")

				if not Head then continue end
				if Character:FindFirstChildOfClass("ForceField") then continue end

				local Origin = self:GetOrigin(Character)

				if self:IsVisible(Head, Origin) then
					Insert(Sorted, {
						Character = Character,
						Head = Head,
						Dist = (Head.Position - Origin).Magnitude,
						Origin = Origin
					})
				end
			end
		end
	end

	table.sort(Sorted, function(A, B)
		return A.Dist < B.Dist
	end)

	for _, Entry in Sorted do
		local Target = Entry.Character
		local Now = tick()

		if Target then
			if not Toggles["combat/ragebot/rapidfire"].Value and Now - (self.LastTimeFired or 0) < FireRate then
				continue
			end

			if not Toggles["combat/ragebot/rapidfire"].Value then
				self.LastTimeFired = Now
			end

			if HasPen then
				local Found = { Entry }

				for Index = 2, #Sorted do
					if #Found >= 3 then break end

					local Behind = Sorted[Index]

					VisibilityParams.FilterDescendantsInstances = HitList

					local Result = Raycast(workspace, Entry.Origin, Behind.Head.Position - Entry.Origin, VisibilityParams)

					if Result and Result.Instance:IsDescendantOf(Behind.Character) then
						Insert(Found, Behind)
						Insert(HitList, Behind.Character)
					end
				end

				for Pen, Pierce in Found do
					if FindFirstChild(Gun, "Melee") ~= nil then
						self:Stab(Pierce.Character, Pierce.Origin)
					else
						self:Hit(Pierce.Character, Pen, NewCFrame(Pierce.Origin, Pierce.Head.Position), Pierce.Origin)
					end
				end

				break
			else
				if FindFirstChild(Gun, "Melee") ~= nil then
					self:Stab(Target, Entry.Origin)
				else
					self:Hit(Target, nil, nil, Entry.Origin)
				end

				if not Toggles["combat/ragebot/multitarget"].Value then
					break
				end
			end
		end
	end
end

Library:GiveSignal(LocalPlayer.Damage.Changed:Connect(function()
	Ragebot:ReplicateShoot()
	CanHitFXPls = true
end))

Library:GiveSignal(RunService.Stepped:Connect(function()
	Ragebot:Scan()
	Ragebot:Knifebot()
end))

Library:GiveSignal(Players.PlayerAdded:Connect(function(Player)
	PlayersCache = Players:GetPlayers()
end))

Library:GiveSignal(Players.PlayerRemoving:Connect(function(Player)
	PlayersCache = Players:GetPlayers()
	OriginCache[Player.Character] = nil
end))

return Ragebot