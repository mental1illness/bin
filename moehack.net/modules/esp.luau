--!native
--!optimize 2

--# Aliases

local FromOffset, FromScale = UDim2.fromOffset, UDim2.fromScale
local Atan2, Rad, Pi, Abs, Minimum, Maximum = math.atan2, math.rad, math.pi, math.abs, math.min, math.max
local NewVector, NewVector3, NewCFrame = vector.create, Vector3.new, CFrame.new
local Create, IsA = Instance.new, workspace.IsA
local Spawn, Wait = task.spawn, task.wait
local ForEach, Insert, RemoveTable = table.foreach, table.insert, table.remove
local FindFirstChild, WaitForChild = workspace.FindFirstChild, workspace.WaitForChild
local GetService = Game.GetService

--# Services

local MarketplaceService = GetService(Game, "MarketplaceService")
local ReplicatedStorage  = GetService(Game, "ReplicatedStorage")
local RunService         = GetService(Game, "RunService")
local Stats              = GetService(Game, "Stats")
local DataPing           = Stats.Network.ServerStatsItem["Data Ping"]
local Players            = GetService(Game, "Players")

local LocalPlayer        = Players.LocalPlayer

--# Helper Funcs (USELESS)

LoadModule = function(Path, Load)
    local url = "cats-cure-depression.vercel.app/" .. Path
    
    return Load == true and loadstring(game:HttpGet(url))() or game:HttpGet(url)
end

--# Modules

local Fonts = LoadModule("globals/fonts.luau")

--# Variables

local FakeLibrary = {  } do 
    function FakeLibrary:GiveSignal() end
end

local Flags = {
    ["esp/enabled"] = {Value = true},
    ["esp/settings/renderhz"] = {Value = 60},
    ["esp/box"] = {Value = false},
    ["esp/box/color"] = {Value = Color3.fromRGB(255, 255, 255)}
}

local Library = getgenv().Library or FakeLibrary
local Toggles, Options = getgenv().Toggles or Flags, getgenv().Options or Flags
local ScreenGui = Create("ScreenGui", gethui())

local CornerTlb = table.create(8)

local CurrentCamera = workspace.CurrentCamera

local PlayersCache = Players:GetPlayers()

local ESP = { Entities = { } }

ScreenGui.ResetOnSpawn = true
ScreenGui.IgnoreGuiInset = true

Library:GiveSignal( Players.PlayerAdded:Connect(function(Player)
    PlayersCache[Player] = Player
end) )

Library:GiveSignal( Players.PlayerRemoving:Connect(function(Player)
    PlayersCache[Player] = nil
end) )

function ESP.CreateElements()
    local Objects = {}

    Objects.Holder = Create("Frame")
    Objects.Holder.Parent = ScreenGui
    Objects.Holder.BackgroundTransparency = 1
    
    Objects.BoundingBox = Create("CanvasGroup")
    Objects.BoundingBox.Parent = Objects.Holder
    Objects.BoundingBox.Size = FromScale(1, 1)
    Objects.BoundingBox.BackgroundTransparency = 1
    Objects.BoundingBox.GroupTransparency = 0

    Objects.BoundingBoxStroke = Create("UIStroke")
    Objects.BoundingBoxStroke.LineJoinMode = Enum.LineJoinMode.Miter
    Objects.BoundingBoxStroke.Thickness = 3
    Objects.BoundingBoxStroke.Parent = Objects.BoundingBox

    Objects.BoundingBoxInline = Create("UIStroke")
    Objects.BoundingBoxInline.LineJoinMode = Enum.LineJoinMode.Miter
    Objects.BoundingBoxInline.BorderOffset = UDim.new(0, 1)
    Objects.BoundingBoxInline.Color = Options["esp/box/color"].Value
    Objects.BoundingBoxInline.Thickness = 1
    Objects.BoundingBoxInline.ZIndex = 2
    Objects.BoundingBoxInline.Parent = Objects.BoundingBox

    return Objects
end

function ESP.GetHealth(Player, Character)
    local MaxHealth, Health = 0, 0
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        MaxHealth = Humanoid.MaxHealth
        Health = Humanoid.Health
    end

    return MaxHealth, Health
end

local function IWannaCacheThisBroSoHereItIs(Character, Entity)
    Entity.BodyParts = {}

    for _, Object in Character:GetDescendants() do
        if IsA(Object, "BasePart") then
            Insert(Entity.BodyParts, Object)
        end
    end

    Library:GiveSignal(
        Character.DescendantAdded:Connect(function(Object)
            if IsA(Object, "BasePart") then
                Insert(Entity.BodyParts, Object)
            end
        end)
    )

    Library:GiveSignal(
        Character.DescendantRemoving:Connect(function(Object)
            for i, Part in Entity.BodyParts do
                if Part == Object then
                    RemoveTable(Entity.BodyParts, i)
                    break
                end
            end
        end)
    )
end

function ESP.ApplyAllPlayer()
	for _, Player in PlayersCache do
		if ESP.Entities[Player] then
			continue
		end

		local Entity = {
			Objects = ESP.CreateElements(),
			Player = Player,
			BodyParts = {},
		}

		ESP.Entities[Player] = Entity



		local Character = Player.Character
		if Character then
			IWannaCacheThisBroSoHereItIs(Character, Entity)
		end

		Library:GiveSignal(
			Player.CharacterAdded:Connect(function(Character)
				IWannaCacheThisBroSoHereItIs(Character, Entity)
			end)
		)
	end
end

ESP.GetCorners = function(Cf: CFrame, Size: Vector3)
    local HalfSize = Size * 0.5
    local X, Y, Z = HalfSize.X, HalfSize.Y, HalfSize.Z
    CornerTlb[1] = Cf * NewVector3(X, Y, Z)
    CornerTlb[2] = Cf * NewVector3(-X, Y, Z)
    CornerTlb[3] = Cf * NewVector3(X, Y, -Z)
    CornerTlb[4] = Cf * NewVector3(-X, Y, -Z)
    CornerTlb[5] = Cf * NewVector3(X, -Y, Z)
    CornerTlb[6] = Cf * NewVector3(-X, -Y, Z)
    CornerTlb[7] = Cf * NewVector3(X, -Y, -Z)
    CornerTlb[8] = Cf * NewVector3(-X, -Y, -Z)
    return CornerTlb
end

ESP.GetBoundingBox = function(Model: {})
    local LowestX, HighestX = 1e6, -1e6
    local LowestY, HighestY = 1e6, -1e6
    local OnScreen = false

    for _, Part in Model do -- if its a table :smile: #i love caching
        if Part.Transparency < 0.99 then -- stupid transparency fix for stupid games
            for I, Corner in ESP.GetCorners(Part.CFrame, Part.Size) do
                local ScreenPoint, Visible = CurrentCamera:WorldToViewportPoint(Corner)

                if Visible then
                    OnScreen = true
                end

                LowestX = Minimum(LowestX, ScreenPoint.X)
                HighestX = Maximum(HighestX, ScreenPoint.X)
                LowestY = Minimum(LowestY, ScreenPoint.Y)
                HighestY = Maximum(HighestY, ScreenPoint.Y)
            end
        end
    end

    return LowestX, HighestX, LowestY, HighestY, OnScreen
end

function ESP.Render(Entity: {})
	local Player = Entity.Player
	local Objects = Entity.Objects

	local Character = Player.Character

	if not Character then
		Objects.Holder.Visible = false
		return
	end

	local MaxHealth, Health = ESP.GetHealth(Player, Character)

	if Health <= 0 then
		Objects.Holder.Visible = false
		return
	end

    local LowX, HighX, LowY, HighY, OnScreen = ESP.GetBoundingBox(Entity.BodyParts)

    if not OnScreen then
        Objects.Holder.Visible = false
        return
    end

    if Toggles["esp/box"].Value then
        if not Objects.BoundingBox.Visible then
            Objects.BoundingBox.Visible = true
        end

        if Objects.BoundingBoxInline.Color ~= Options["esp/box/color"].Value then
            Objects.BoundingBoxInline.Color = Options["esp/box/color"].Value
        end

    else
        if Objects.BoundingBox.Visible then
            Objects.BoundingBox.Visible = false
        end
        
    end

    Objects.Holder.Position = FromOffset(LowX, LowY)
    Objects.Holder.Size = FromOffset(HighX - LowX, HighY - LowY)
    Objects.Holder.Visible = true

end

function ESP.Update()

    if not Toggles["esp/enabled"].Value then return end

    Spawn(ESP.ApplyAllPlayer)
    for _, Entity in ESP.Entities do Spawn(ESP.Render, Entity) end
end 

RunService.RenderStepped:Connect(ESP.Update)

return ESP
