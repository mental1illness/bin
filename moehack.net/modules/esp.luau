--!native
--!optimize 2

--# Aliases

local FromOffset, FromScale, UDim2New = UDim2.fromOffset, UDim2.fromScale, UDim2.new
local Atan2, Rad, Pi, Abs, Minimum, Maximum, Floor = math.atan2, math.rad, math.pi, math.abs, math.min, math.max, math.floor
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
    local url = "https://cats-cure-depression.vercel.app/" .. Path
    
    return Load == true and loadstring(game:HttpGet(url))() or game:HttpGet(url)
end

--# Modules

local Fonts = LoadModule("globals/fonts.luau", true)

--# Variables

local FakeLibrary = {  } do 
    function FakeLibrary:GiveSignal() end
end

local Flags = {
    ["esp/enabled"] = {Value = true},
    ["esp/settings/renderhz"] = {Value = 60},
    ["esp/box"] = {Value = true},
    ["esp/box/color"] = {Value = Color3.fromRGB(255, 255, 255)},
    ["esp/healthbar"] = {Value = true},
    ["esp/healthbar/colora"] = {Value = Color3.fromRGB(255, 105, 180)},
    ["esp/healthbar/colorb"] = {Value = Color3.fromRGB(255, 20, 147)},
    ["esp/healthbar/thickness"] = {Value = 2},
    ["esp/healthtext"] = {Value = true},
    ["esp/healthtext/color"] = {Value = Color3.fromRGB(255, 255, 255)},
    ["esp/name"] = {Value = true},
    ["esp/name/color"] = {Value = Color3.fromRGB(255, 255, 255)},
    ["esp/box/fill"] = {Value = true},
    ["esp/box/fillcolor"] = {Value = Color3.fromRGB(255, 255, 255), Transparency = 0.5}
}

local Library = getgenv().Library or FakeLibrary
local Toggles, Options = getgenv().Toggles or Flags, getgenv().Options or Flags
local ScreenGui = Create("ScreenGui", gethui())

local Corners = {
    { 1,  1,  1},
    {-1,  1,  1},
    { 1,  1, -1},
    {-1,  1, -1},
    { 1, -1,  1},
    {-1, -1,  1},
    { 1, -1, -1},
    {-1, -1, -1},
}
local Accumulator = 0

local CurrentCamera = workspace.CurrentCamera

local PlayersCache = Players:GetPlayers()

local ESP = { Entities = { } }

ScreenGui.ResetOnSpawn = true
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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
    
    --# Bounding Box

    Objects.BoundingBox = Create("CanvasGroup")
    Objects.BoundingBox.Parent = Objects.Holder
    Objects.BoundingBox.Size = FromScale(1, 1)
    Objects.BoundingBox.BackgroundTransparency = 1
    Objects.BoundingBox.GroupTransparency = 0

    local BoundingBoxStroke = Create("UIStroke")
    BoundingBoxStroke.LineJoinMode = Enum.LineJoinMode.Miter
    BoundingBoxStroke.Thickness = 3
    BoundingBoxStroke.Parent = Objects.BoundingBox

    Objects.BoundingBoxInline = Create("UIStroke")
    Objects.BoundingBoxInline.LineJoinMode = Enum.LineJoinMode.Miter
    Objects.BoundingBoxInline.BorderOffset = UDim.new(0, 1)
    Objects.BoundingBoxInline.Color = Options["esp/box/color"].Value
    Objects.BoundingBoxInline.Thickness = 1
    Objects.BoundingBoxInline.ZIndex = 2
    Objects.BoundingBoxInline.Parent = Objects.BoundingBox

    Objects.BoundingBoxFill = Create("Frame")
    Objects.BoundingBoxFill.Parent = Objects.BoundingBox
    Objects.BoundingBoxFill.Size = FromScale(1, 1)
    Objects.BoundingBoxFill.BackgroundColor3 = Options["esp/box/fillcolor"].Value
    Objects.BoundingBoxFill.BackgroundTransparency = Options["esp/box/fillcolor"].Transparency
    Objects.BoundingBoxFill.BorderSizePixel = 0
    Objects.BoundingBoxFill.ZIndex = 1

    --# Health Bar

    Objects.HealthBar = Create("CanvasGroup")
    Objects.HealthBar.Parent = Objects.Holder
    Objects.HealthBar.Size = UDim2New(0, Options["esp/healthbar/thickness"].Value, 1, 4)
    Objects.HealthBar.Position = UDim2New(0,-5 - Options["esp/healthbar/thickness"].Value, 0, -2)
    Objects.HealthBar.BackgroundTransparency = 1
    Objects.HealthBar.BorderSizePixel = 0
    Objects.HealthBar.GroupTransparency = 0

    local HealthBarOutline = Create("UIStroke")
    HealthBarOutline.LineJoinMode = Enum.LineJoinMode.Miter
    HealthBarOutline.Thickness = 1
    HealthBarOutline.ZIndex = 4
    HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    HealthBarOutline.Parent = Objects.HealthBar

    Objects.HealthBarBackground = Create("Frame")
    Objects.HealthBarBackground.Parent = Objects.HealthBar
    Objects.HealthBarBackground.Size = FromScale(1, 1)
    Objects.HealthBarBackground.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Objects.HealthBarBackground.BorderSizePixel = 0
    Objects.HealthBarBackground.ZIndex = 1

    Objects.HealthBarCover = Create("Frame")
    Objects.HealthBarCover.Parent = Objects.HealthBar
    Objects.HealthBarCover.Size = UDim2New(1, 0, 0, 0)
    Objects.HealthBarCover.BorderSizePixel = 0
    Objects.HealthBarCover.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Objects.HealthBarCover.ZIndex = 3

    Objects.HealthBarFill = Create("Frame")
    Objects.HealthBarFill.Parent = Objects.HealthBar
    Objects.HealthBarFill.Size = UDim2New(1, 0, 1, 0)
    Objects.HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Objects.HealthBarFill.BorderSizePixel = 0
    Objects.HealthBarFill.ZIndex = 2

    Objects.HealthBarGradient = Create("UIGradient")
    Objects.HealthBarGradient.Parent = Objects.HealthBarFill
    Objects.HealthBarGradient.Rotation = 90
    Objects.HealthBarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Options["esp/healthbar/colora"].Value),
        ColorSequenceKeypoint.new(1, Options["esp/healthbar/colorb"].Value)
    })

    --# Health Text

    Objects.HealthTextHolder = Create("CanvasGroup")
    Objects.HealthTextHolder.Parent = Objects.Holder
    Objects.HealthTextHolder.Size = FromOffset(11, 10)
    Objects.HealthTextHolder.BackgroundTransparency = 1
    Objects.HealthTextHolder.GroupTransparency = 1
    Objects.HealthTextHolder.AnchorPoint = Vector2.new(0, 0.5)

    Objects.HealthText = Create("TextLabel")
    Objects.HealthText.Parent = Objects.HealthTextHolder
    Objects.HealthText.Size = FromOffset(9, 9)
    Objects.HealthText.BackgroundTransparency = 1
    Objects.HealthText.Position = FromOffset(1, 0)
    Objects.HealthText.Text = "100"
    Objects.HealthText.TextXAlignment = Enum.TextXAlignment.Center
    Objects.HealthText.FontFace = Fonts.SmallestPixel7
    Objects.HealthText.TextColor3 = Options["esp/healthtext/color"].Value
    Objects.HealthText.TextSize = 9
    Objects.HealthText.ZIndex = 5

    local HealthTextStroke = Create("UIStroke")
    HealthTextStroke.Parent = Objects.HealthText
    HealthTextStroke.LineJoinMode = Enum.LineJoinMode.Miter
    HealthTextStroke.Thickness = 1
    HealthTextStroke.Color = Color3.new(0, 0, 0)

    --# Name

    Objects.NameHolder = Create("CanvasGroup")
    Objects.NameHolder.Parent = Objects.Holder
    Objects.NameHolder.BackgroundTransparency = 1
    Objects.NameHolder.Size = FromOffset(500, 14)
    Objects.NameHolder.AnchorPoint = Vector2.new(0.5, 1)
    Objects.NameHolder.Position = UDim2New(0.5, 0, 0, -3)
    Objects.NameHolder.GroupTransparency = 0
    Objects.NameHolder.Visible = false
    Objects.NameHolder.ZIndex = 6

    Objects.Name = Create("TextLabel")
    Objects.Name.Parent = Objects.NameHolder
    Objects.Name.Size = FromScale(1, 1)
    Objects.Name.BackgroundTransparency = 1
    Objects.Name.Text = "Player"
    Objects.Name.TextColor3 = Options["esp/name/color"].Value
    Objects.Name.TextSize = 12
    Objects.Name.TextXAlignment = Enum.TextXAlignment.Center
    Objects.Name.TextYAlignment = Enum.TextYAlignment.Center
    Objects.Name.FontFace = Fonts.Tahoma
    Objects.Name.ZIndex = 6

    local NameStroke = Create("UIStroke")
    NameStroke.Parent = Objects.Name
    NameStroke.LineJoinMode = Enum.LineJoinMode.Miter
    NameStroke.Thickness = 1
    NameStroke.Color = Color3.new(0, 0, 0)

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

ESP.GetBoundingBox = function(Model: {})
    local LowestX, HighestX = 1e6, -1e6
    local LowestY, HighestY = 1e6, -1e6
    local OnScreen = false

    local Camera = CurrentCamera
    local WorldToViewportPoint = Camera.WorldToViewportPoint
    local Min = Minimum
    local Max = Maximum
    local Vector3New = NewVector3

    for _, Part in Model do
        if Part.Transparency < 0.99 then
            local PartCFrame = Part.CFrame
            local HalfSize = Part.Size * 0.5
            local X, Y, Z = HalfSize.X, HalfSize.Y, HalfSize.Z

            for i = 1, 8 do
                local Signs = Corners[i]
                local ScreenPoint, Visible = WorldToViewportPoint(
                    Camera,
                    PartCFrame * Vector3New(
                        X * Signs[1],
                        Y * Signs[2],
                        Z * Signs[3]
                    )
                )

                OnScreen = OnScreen or Visible
                LowestX = Min(LowestX, ScreenPoint.X)
                HighestX = Max(HighestX, ScreenPoint.X)
                LowestY = Min(LowestY, ScreenPoint.Y)
                HighestY = Max(HighestY, ScreenPoint.Y)
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

        if Toggles["esp/box/fill"].Value then
            if not Objects.BoundingBoxFill.Visible then
                Objects.BoundingBoxFill.Visible = true
            end
            if Objects.BoundingBoxFill.BackgroundColor3 ~= Options["esp/box/fillcolor"].Value or Objects.BoundingBoxFill.BackgroundTransparency ~= Options["esp/box/fillcolor"].Transparency then
                Objects.BoundingBoxFill.BackgroundColor3 = Options["esp/box/fillcolor"].Value
                Objects.BoundingBoxFill.BackgroundTransparency = Options["esp/box/fillcolor"].Transparency
            end
        else
            if Objects.BoundingBoxFill.Visible then
                Objects.BoundingBoxFill.Visible = false
            end
        end
    else
        if Objects.BoundingBox.Visible then
            Objects.BoundingBox.Visible = false
        end
    end

    if Toggles["esp/name"].Value then
        if not Objects.NameHolder.Visible then
            Objects.NameHolder.Visible = true
        end

        local Name = Player.DisplayName
        if Name == "" then
            Name = Player.Name
        end

        if Objects.Name.Text ~= Name then
            Objects.Name.Text = Name
        end

        local NameColor = Options["esp/name/color"].Value
        if Objects.Name.TextColor3 ~= NameColor then
            Objects.Name.TextColor3 = NameColor
        end
    elseif Objects.NameHolder.Visible then
        Objects.NameHolder.Visible = false
    end

    if Toggles["esp/healthbar"].Value then
        if not Objects.HealthBar.Visible then
            Objects.HealthBar.Visible = true
        end

        local HealthPercent = Health / MaxHealth
        local HealthHeight = (HighY - LowY) * HealthPercent

        if Objects.HealthBar.Size.X.Offset ~= Options["esp/healthbar/thickness"].Value then
            Objects.HealthBar.Size = UDim2New(0, Options["esp/healthbar/thickness"].Value, 1, 4)
            Objects.HealthBar.Position = UDim2New(0,-5 - Options["esp/healthbar/thickness"].Value, 0, -2)
        end
        
        if Objects.HealthBarCover.Size.Y.Scale ~= (1 - HealthPercent) then
            Objects.HealthBarCover.Size = UDim2New(1, 0, 1 - HealthPercent, 0)
        end

        if Toggles["esp/healthtext"].Value  then

            if not Objects.HealthTextHolder.Visible then
                Objects.HealthTextHolder.Visible = true
            end

            if Objects.HealthText.TextColor3 ~= Options["esp/healthtext/color"].Value then
                Objects.HealthText.TextColor3 = Options["esp/healthtext/color"].Value
            end

            if Objects.HealthText.Text ~= tostring(Floor(Health)) then
                Objects.HealthText.Text = tostring(Floor(Health))
            end

            if Health == MaxHealth then
                Objects.HealthTextHolder.GroupTransparency = 1
            else
                local HealthTextY = (HighY - LowY) * (1 - HealthPercent)

                Objects.HealthTextHolder.GroupTransparency = 0
                Objects.HealthTextHolder.Position = UDim2New(
                    0, -10 - Options["esp/healthbar/thickness"].Value,
                    0, HealthTextY
                )
            end
        else
            if Objects.HealthTextHolder.Visible then
                Objects.HealthTextHolder.Visible = false
            end
        end

        if Objects.HealthBarGradient.Color.Keypoints[1].Value ~= Options["esp/healthbar/colora"].Value or Objects.HealthBarGradient.Color.Keypoints[2].Value ~= Options["esp/healthbar/colorb"].Value then
            Objects.HealthBarGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Options["esp/healthbar/colora"].Value),
                ColorSequenceKeypoint.new(1, Options["esp/healthbar/colorb"].Value)
            })
        end
    else
        if Objects.HealthBar.Visible then
            Objects.HealthBar.Visible = false
        end
        if Objects.HealthTextHolder.Visible then
            Objects.HealthTextHolder.Visible = false
        end
    end
    

    Objects.Holder.Position = FromOffset(LowX, LowY)
    Objects.Holder.Size = FromOffset(HighX - LowX, HighY - LowY)
    Objects.Holder.Visible = true

end

function ESP.Update(DeltaTime)

    if not Toggles["esp/enabled"].Value then
        Accumulator = 0
        for _, Entity in ESP.Entities do
            if Entity.Objects.Holder.Visible then
                Entity.Objects.Holder.Visible = false
            end
        end
        return 
    end

    ESP.ApplyAllPlayer()

    do -- dumb perf fix for low end pc
        local Hertz = math.max(1, Options["esp/settings/renderhz"].Value)
        local Interval = 1 / Hertz

        Accumulator += DeltaTime
        if Accumulator < Interval then
            return
        end
        Accumulator -= Interval
    end

    for _, Entity in ESP.Entities do Spawn(ESP.Render, Entity) end
end 

RunService.RenderStepped:Connect(ESP.Update)

return ESP