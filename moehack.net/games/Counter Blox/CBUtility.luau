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
local Raycast = workspace.Raycast

--# Services

local MarketplaceService = GetService(Game, "MarketplaceService")
local ReplicatedStorage  = GetService(Game, "ReplicatedStorage")
local RunService         = GetService(Game, "RunService")
local Stats              = GetService(Game, "Stats")
local DataPing           = Stats.Network.ServerStatsItem["Data Ping"]
local Players            = GetService(Game, "Players")

local LocalPlayer        = Players.LocalPlayer

--# Variables

local EmptyVec3 = NewVector3()
local Camera    = workspace.CurrentCamera

local PlayerGui = LocalPlayer.PlayerGui

local NormalParam = RaycastParams.new()
NormalParam.FilterType = Enum.RaycastFilterType.Exclude
NormalParam.IgnoreWater = true

local ThicknessParams = RaycastParams.new()
ThicknessParams.FilterType = Enum.RaycastFilterType.Include
ThicknessParams.IgnoreWater = true

local SmokeParams = RaycastParams.new()
SmokeParams.FilterType = Enum.RaycastFilterType.Include
SmokeParams.FilterDescendantsInstances = { workspace.Ray_Ignore.Smokes }
SmokeParams.IgnoreWater = false

--# Main

local CBUtility = {}

CBUtility.Client     = getsenv(LocalPlayer.PlayerGui.Client)
CBUtility.ClientData = filtergc("table", { Keys = { "DISABLED", "crouched", "ammocount2", "equipment2stored" } }, true)
CBUtility.Hitboxes = {
    "HeadHB",
	"Head",
	"UpperTorso",
	"LowerTorso",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
	"HumanoidRootPart"
}

function CBUtility.Wallbang(Origin, Direction, IgnoreList)
	local PenetrationUsed = 0
	local Penetration = CBUtility.Client.fgun.Penetration.Value * 0.01
	local HitPart, HitPosition, HitNormal
	local UnitDirection = Direction.Unit

	IgnoreList = IgnoreList or {}

	for _ = 1, 10 do
		NormalParam.FilterDescendantsInstances = IgnoreList

		local Result = Raycast(workspace, Origin, Direction, NormalParam)

		if not Result then
			return false, 1, HitPart, HitPosition, HitNormal
		end

		HitPart = Result.Instance
		HitPosition = Result.Position
		HitNormal = Result.Normal

		local Modifier = 1

		if HitPart.Material == Enum.Material.DiamondPlate then
			Modifier = 3
		elseif HitPart.Material == Enum.Material.CorrodedMetal
			or HitPart.Material == Enum.Material.Metal
			or HitPart.Material == Enum.Material.Concrete
			or HitPart.Material == Enum.Material.Brick
		then
			Modifier = 2
		elseif HitPart.Name == "Grate"
			or HitPart.Material == Enum.Material.Wood
			or HitPart.Material == Enum.Material.WoodPlanks
			or (HitPart.Parent and FindFirstChildOfClass(HitPart.Parent, "Humanoid"))
		then
			Modifier = 0.1
		elseif HitPart.Transparency == 1
			or not HitPart.CanCollide
			or HitPart.Name == "Glass"
			or HitPart.Name == "Cardboard"
			or HitPart:IsDescendantOf(workspace.Ray_Ignore)
			or HitPart:IsDescendantOf(workspace.Debris)
			or (HitPart.Parent and HitPart.Parent.Name == "Hitboxes")
		then
			Modifier = 0
		end

		if HitPart.Name == "nowallbang" then
			Modifier = 100
		end

		local PartModifier = FindFirstChild(HitPart, "PartModifier")

		if PartModifier then
			Modifier = PartModifier.Value
		end

		ThicknessParams.FilterDescendantsInstances = { HitPart }

		local ExitStart = HitPosition + UnitDirection
		local ExitDirection = UnitDirection * -2
		local ExitResult = Raycast(workspace, ExitStart, ExitDirection, ThicknessParams)
		local ExitPosition = ExitResult and ExitResult.Position or ExitStart + ExitDirection

		local Thickness = (ExitPosition - HitPosition).Magnitude
		PenetrationUsed += Thickness * Modifier

		local DamageModifier = Clamp(1 - PenetrationUsed / Penetration, 0, 1)

		if PenetrationUsed >= Penetration then
			return false, DamageModifier, HitPart, HitPosition, HitNormal
		end

		Insert(IgnoreList, HitPart)
		Origin = ExitPosition + UnitDirection * 0.01
	end

	return false, Clamp(1 - PenetrationUsed / Penetration, 0, 1), HitPart, HitPosition, HitNormal
end

function CBUtility.IsInSmoke()
    local Direction = Camera.CFrame.LookVector * 1000
    local SmokeHit = Raycast(workspace, Camera.CFrame.Position, Direction, SmokeParams)

    return (SmokeHit and SmokeHit.Instance:GetAttribute("Enabled") == true) or PlayerGui.SmokeGUI.SmokeScreen.BackgroundTransparency < 0.1
end

function CBUtility.HitPart(Data)

    local Character = LocalPlayer.Character -- doesn't require a Utility.GetCharacter
    if not Character then return end

    local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
    if not Humanoid then return end

    local Gun = FindFirstChild(Character, "Gun")
    if not Gun then return end

    local IsHeadshot = (Data.HitPart.Name == "Head" or Data.HitPart.Name == "FakeHead" or Data.HitPart.Name == "HeadHB") and true or false
    local EncodedPosition = NewVector3(((Data.HitPosition.X - 156325) * 13 + 17854) * 16, (Data.HitPosition.Y + 64000) * 7 - 142657, (Data.HitPosition.Z * 9 - 47000) * 6)

    ReplicatedStorage.Events.HitParl:FireServer(
        Data.HitPart,
        EncodedPosition,
        CBUtility.Client.fgun.Name,
        CBUtility.Client.fgun.Range.Value,
        Gun,
        nil,
        Data.DamageModifier,
        CBUtility.Client.fgun.Range.Value,
        true,
        Camera.CFrame.Position,
        workspace:GetServerTimeNow(),
        EmptyVec3,
        PlayerGui.Blnd.Blind.BackgroundTransparency < 0.4 or Data.IsBlind,
        PlayerGui.GUI.Crosshairs.Scope.Visible or Data.IsScoped,
        CBUtility.IsInSmoke() or Data.InSmoke,
        Humanoid:GetState() == Enum.HumanoidStateType.Freefall or Data.IsFreefall,
        true,
        nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
    )
end

for _, Player in Players:GetPlayers() do
    if Player ~= LocalPlayer then
        local Character = Player.Character
        local Head = Character and Character:FindFirstChild("Head")

        if Head then
            CBUtility.HitPart({
                HitPart = Head,
                HitPosition = Head.Position,
                DamageModifier = 1
            })
        end
    end
end


return CBUtility