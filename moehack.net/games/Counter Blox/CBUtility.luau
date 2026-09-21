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

--# Variables

local EmptyVec3 = NewVector3()
local Camera    = workspace.CurrentCamera

local PlayerGui = LocalPlayer.PlayerGui

--# Main

local CBUtility = {}

CBUtility.Client     = getsenv(LocalPlayer.PlayerGui)
CBUtility.ClientData = filtergc("table", { Keys = { "DISABLED", "crouched", "ammocount2", "equipment2stored" } }, true)

function CBUtility.Wallbang()

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
        IsHeadshot,
        true,
        Camera.CFrame.Position,
        workspace:GetServerTimeNow(),
        EmptyVec3,
        PlayerGui.Blnd.Blind.BackgroundTransparency < 0.4 or Data.IsBlind,
        PlayerGui.GUI.Crosshairs.Scope.Visible or Data.IsScoped,
        false or Data.InSmoke,
        Humanoid:GetState() == Enum.HumanoidStateType.Freefall or Data.IsFreefall,
        true,
        nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
    )
end

return CBUtility