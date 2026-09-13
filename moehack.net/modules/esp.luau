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

--# Helper Funcs (USELESS)

LoadModule = function(Path, Load)
    local url = "https://cats-cure-depression.vercel.app/" .. Path
    
    return Load == true and loadstring(game:HttpGet(url))() or game:HttpGet(url)
end

--# Modules

local Fonts = LoadModule("globals/fonts.luau", true)

--# Variables

local PlaceId = Game.PlaceId
local FakeLibrary = {  } do 
    function FakeLibrary:GiveSignal() end
end

local Flags = {
    ["esp/enabled"] = {Value = true},
    ["esp/settings/renderhz"] = {Value = 60},

    ["esp/box"] = {Value = true},
    ["esp/box/color"] = {Value = Color3.fromRGB(255, 255, 255)},
    ["esp/box/type"] = {Value = "Corner"},

    ["esp/healthbar"] = {Value = true},
    ["esp/healthbar/colora"] = {Value = Color3.fromRGB(255, 105, 180)},
    ["esp/healthbar/colorb"] = {Value = Color3.fromRGB(255, 20, 147)},
    ["esp/healthbar/thickness"] = {Value = 2},
    ["esp/healthtext"] = {Value = true},
    ["esp/healthtext/color"] = {Value = Color3.fromRGB(255, 255, 255)},
    ["esp/name"] = {Value = true},
    ["esp/name/color"] = {Value = Color3.fromRGB(255, 255, 255)},
    ["esp/box/fill"] = {Value = true},
    ["esp/box/fillcolor"] = {Value = Color3.fromRGB(255, 255, 255), Transparency = 0.5},

    ["esp/distance"] = {Value = true},
    ["esp/distance/color"] = {Value = Color3.fromRGB(255, 255, 255)},

    ["esp/tool"] = {Value = true},
    ["esp/tool/color"] = {Value = Color3.fromRGB(255, 255, 255)},
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
local LastHz = 0

local CurrentCamera = workspace.CurrentCamera
local PlayersCache = Players:GetPlayers()

if PlaceId == 72920620366355 then
    StateObject = require(ReplicatedStorage.Modules.StateObject)
end

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

    --# Corner Box / Thank you claude i only had to jailbreak you twice just for  you to store them in objects table

    Objects.CornerBox = Create("CanvasGroup")
    Objects.CornerBox.BackgroundTransparency = 1
    Objects.CornerBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Objects.CornerBox.Size = UDim2New(1, 6, 1, 6)
    Objects.CornerBox.Position = UDim2New(0, -3, 0, -3)
    Objects.CornerBox.BorderSizePixel = 0
    Objects.CornerBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Objects.CornerBox.Visible = false
    Objects.CornerBox.Parent = Objects.Holder

    -- Bottom Right
    Objects.BottomRight = Create("Frame")
    Objects.BottomRight.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Objects.BottomRight.Rotation = 180
    Objects.BottomRight.Name = "BottomRight"
    Objects.BottomRight.BackgroundTransparency = 1
    Objects.BottomRight.Position = UDim2.new(1, -1, 1, -1)
    Objects.BottomRight.AnchorPoint = Vector2.new(1, 1)
    Objects.BottomRight.Size = UDim2.new(0, 10, 0, 10)
    Objects.BottomRight.BorderSizePixel = 0
    Objects.BottomRight.BackgroundColor3 = Options["esp/box/color"].Value
    Objects.BottomRight.Parent = Objects.CornerBox

    Objects.BottomRightInlineHorizontal = Create("Frame")
    Objects.BottomRightInlineHorizontal.Name = "InlineHorizontal"
    Objects.BottomRightInlineHorizontal.Size = UDim2.new(1, 0, 0, 1)
    Objects.BottomRightInlineHorizontal.BorderSizePixel = 0
    Objects.BottomRightInlineHorizontal.BackgroundColor3 = Options["esp/box/color"].Value
    Objects.BottomRightInlineHorizontal.ZIndex = 2
    Objects.BottomRightInlineHorizontal.Parent = Objects.BottomRight

    Objects.BottomRightInlineVertical = Create("Frame")
    Objects.BottomRightInlineVertical.Name = "InlineVertical"
    Objects.BottomRightInlineVertical.Size = UDim2.new(0, 1, 1, 0)
    Objects.BottomRightInlineVertical.BorderSizePixel = 0
    Objects.BottomRightInlineVertical.BackgroundColor3 = Options["esp/box/color"].Value
    Objects.BottomRightInlineVertical.ZIndex = 5
    Objects.BottomRightInlineVertical.Parent = Objects.BottomRight

    Objects.BottomRightOutlineHorizontal = Create("Frame")
    Objects.BottomRightOutlineHorizontal.Name = "OutlineHorizontal"
    Objects.BottomRightOutlineHorizontal.Position = UDim2.new(0, 0, 0, -1)
    Objects.BottomRightOutlineHorizontal.Size = UDim2.new(1, 1, 0, 3)
    Objects.BottomRightOutlineHorizontal.BorderSizePixel = 0
    Objects.BottomRightOutlineHorizontal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Objects.BottomRightOutlineHorizontal.Parent = Objects.BottomRight

    Objects.BottomRightOutlineVertical = Create("Frame")
    Objects.BottomRightOutlineVertical.Name = "OutlineVertical"
    Objects.BottomRightOutlineVertical.Position = UDim2.new(0, -1, 0, -1)
    Objects.BottomRightOutlineVertical.Size = UDim2.new(0, 3, 1, 2)
    Objects.BottomRightOutlineVertical.BorderSizePixel = 0
    Objects.BottomRightOutlineVertical.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Objects.BottomRightOutlineVertical.Parent = Objects.BottomRight

    -- Top Right
    Objects.TopRight = Create("Frame")
    Objects.TopRight.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Objects.TopRight.Rotation = 90
    Objects.TopRight.Name = "TopRight"
    Objects.TopRight.BackgroundTransparency = 1
    Objects.TopRight.Position = UDim2.new(1, -1, 0, 1)
    Objects.TopRight.AnchorPoint = Vector2.new(1, 0)
    Objects.TopRight.Size = UDim2.new(0, 10, 0, 10)
    Objects.TopRight.BorderSizePixel = 0
    Objects.TopRight.Parent = Objects.CornerBox

    Objects.TopRightInlineHorizontal = Create("Frame")
    Objects.TopRightInlineHorizontal.Name = "InlineHorizontal"
    Objects.TopRightInlineHorizontal.Size = UDim2.new(1, 0, 0, 1)
    Objects.TopRightInlineHorizontal.BorderSizePixel = 0
    Objects.TopRightInlineHorizontal.BackgroundColor3 = Options["esp/box/color"].Value
    Objects.TopRightInlineHorizontal.ZIndex = 2
    Objects.TopRightInlineHorizontal.Parent = Objects.TopRight

    Objects.TopRightInlineVertical = Create("Frame")
    Objects.TopRightInlineVertical.Name = "InlineVertical"
    Objects.TopRightInlineVertical.Size = UDim2.new(0, 1, 1, 0)
    Objects.TopRightInlineVertical.BorderSizePixel = 0
    Objects.TopRightInlineVertical.BackgroundColor3 = Options["esp/box/color"].Value
    Objects.TopRightInlineVertical.ZIndex = 5
    Objects.TopRightInlineVertical.Parent = Objects.TopRight

    Objects.TopRightOutlineHorizontal = Create("Frame")
    Objects.TopRightOutlineHorizontal.Name = "OutlineHorizontal"
    Objects.TopRightOutlineHorizontal.Position = UDim2.new(0, 0, 0, -1)
    Objects.TopRightOutlineHorizontal.Size = UDim2.new(1, 1, 0, 3)
    Objects.TopRightOutlineHorizontal.BorderSizePixel = 0
    Objects.TopRightOutlineHorizontal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Objects.TopRightOutlineHorizontal.Parent = Objects.TopRight

    Objects.TopRightOutlineVertical = Create("Frame")
    Objects.TopRightOutlineVertical.Name = "OutlineVertical"
    Objects.TopRightOutlineVertical.Position = UDim2.new(0, -1, 0, -1)
    Objects.TopRightOutlineVertical.Size = UDim2.new(0, 3, 1, 2)
    Objects.TopRightOutlineVertical.BorderSizePixel = 0
    Objects.TopRightOutlineVertical.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Objects.TopRightOutlineVertical.Parent = Objects.TopRight

    -- Top Left
    Objects.TopLeft = Create("Frame")
    Objects.TopLeft.Name = "TopLeft"
    Objects.TopLeft.BackgroundTransparency = 1
    Objects.TopLeft.Position = UDim2.new(0, 1, 0, 1)
    Objects.TopLeft.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Objects.TopLeft.Size = UDim2.new(0, 10, 0, 10)
    Objects.TopLeft.BorderSizePixel = 0
    Objects.TopLeft.Parent = Objects.CornerBox

    Objects.TopLeftInlineHorizontal = Create("Frame")
    Objects.TopLeftInlineHorizontal.Name = "InlineHorizontal"
    Objects.TopLeftInlineHorizontal.Size = UDim2.new(1, 0, 0, 1)
    Objects.TopLeftInlineHorizontal.BorderSizePixel = 0
    Objects.TopLeftInlineHorizontal.BackgroundColor3 = Options["esp/box/color"].Value
    Objects.TopLeftInlineHorizontal.ZIndex = 2
    Objects.TopLeftInlineHorizontal.Parent = Objects.TopLeft

    Objects.TopLeftInlineVertical = Create("Frame")
    Objects.TopLeftInlineVertical.Name = "InlineVertical"
    Objects.TopLeftInlineVertical.Size = UDim2.new(0, 1, 1, 0)
    Objects.TopLeftInlineVertical.BorderSizePixel = 0
    Objects.TopLeftInlineVertical.BackgroundColor3 = Options["esp/box/color"].Value
    Objects.TopLeftInlineVertical.ZIndex = 5
    Objects.TopLeftInlineVertical.Parent = Objects.TopLeft

    Objects.TopLeftOutlineHorizontal = Create("Frame")
    Objects.TopLeftOutlineHorizontal.Name = "OutlineHorizontal"
    Objects.TopLeftOutlineHorizontal.Position = UDim2.new(0, 0, 0, -1)
    Objects.TopLeftOutlineHorizontal.Size = UDim2.new(1, 1, 0, 3)
    Objects.TopLeftOutlineHorizontal.BorderSizePixel = 0
    Objects.TopLeftOutlineHorizontal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Objects.TopLeftOutlineHorizontal.Parent = Objects.TopLeft

    Objects.TopLeftOutlineVertical = Create("Frame")
    Objects.TopLeftOutlineVertical.Name = "OutlineVertical"
    Objects.TopLeftOutlineVertical.Position = UDim2.new(0, -1, 0, -1)
    Objects.TopLeftOutlineVertical.Size = UDim2.new(0, 3, 1, 2)
    Objects.TopLeftOutlineVertical.BorderSizePixel = 0
    Objects.TopLeftOutlineVertical.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Objects.TopLeftOutlineVertical.Parent = Objects.TopLeft

    -- Bottom Left
    Objects.BottomLeft = Create("Frame")
    Objects.BottomLeft.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Objects.BottomLeft.Rotation = -90
    Objects.BottomLeft.Name = "BottomLeft"
    Objects.BottomLeft.BackgroundTransparency = 1
    Objects.BottomLeft.Position = UDim2.new(0, 1, 1, -1)
    Objects.BottomLeft.AnchorPoint = Vector2.new(0, 1)
    Objects.BottomLeft.Size = UDim2.new(0, 10, 0, 10)
    Objects.BottomLeft.BorderSizePixel = 0
    Objects.BottomLeft.Parent = Objects.CornerBox

    Objects.BottomLeftInlineHorizontal = Create("Frame")
    Objects.BottomLeftInlineHorizontal.Name = "InlineHorizontal"
    Objects.BottomLeftInlineHorizontal.Size = UDim2.new(1, 0, 0, 1)
    Objects.BottomLeftInlineHorizontal.BorderSizePixel = 0
    Objects.BottomLeftInlineHorizontal.BackgroundColor3 = Options["esp/box/color"].Value
    Objects.BottomLeftInlineHorizontal.ZIndex = 2
    Objects.BottomLeftInlineHorizontal.Parent = Objects.BottomLeft

    Objects.BottomLeftInlineVertical = Create("Frame")
    Objects.BottomLeftInlineVertical.Name = "InlineVertical"
    Objects.BottomLeftInlineVertical.Size = UDim2.new(0, 1, 1, 0)
    Objects.BottomLeftInlineVertical.BorderSizePixel = 0
    Objects.BottomLeftInlineVertical.BackgroundColor3 = Options["esp/box/color"].Value
    Objects.BottomLeftInlineVertical.ZIndex = 5
    Objects.BottomLeftInlineVertical.Parent = Objects.BottomLeft

    Objects.BottomLeftOutlineHorizontal = Create("Frame")
    Objects.BottomLeftOutlineHorizontal.Name = "OutlineHorizontal"
    Objects.BottomLeftOutlineHorizontal.Position = UDim2.new(0, 0, 0, -1)
    Objects.BottomLeftOutlineHorizontal.Size = UDim2.new(1, 1, 0, 3)
    Objects.BottomLeftOutlineHorizontal.BorderSizePixel = 0
    Objects.BottomLeftOutlineHorizontal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Objects.BottomLeftOutlineHorizontal.Parent = Objects.BottomLeft

    Objects.BottomLeftOutlineVertical = Create("Frame")
    Objects.BottomLeftOutlineVertical.Name = "OutlineVertical"
    Objects.BottomLeftOutlineVertical.Position = UDim2.new(0, -1, 0, -1)
    Objects.BottomLeftOutlineVertical.Size = UDim2.new(0, 3, 1, 2)
    Objects.BottomLeftOutlineVertical.BorderSizePixel = 0
    Objects.BottomLeftOutlineVertical.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Objects.BottomLeftOutlineVertical.Parent = Objects.BottomLeft

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
    Objects.HealthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Objects.HealthBarBackground.BorderSizePixel = 0
    Objects.HealthBarBackground.ZIndex = 1

    Objects.HealthBarCover = Create("Frame")
    Objects.HealthBarCover.Parent = Objects.HealthBar
    Objects.HealthBarCover.Size = UDim2New(1, 0, 0, 0)
    Objects.HealthBarCover.BorderSizePixel = 0
    Objects.HealthBarCover.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
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
    Objects.HealthTextHolder.GroupTransparency = 0
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

    --# Sides Elements

    Objects.Bottom = Create("CanvasGroup")
    Objects.Bottom.Size = UDim2New(0, 500, 0, 500)
    Objects.Bottom.BackgroundTransparency = 1
    Objects.Bottom.GroupTransparency = 0
    Objects.Bottom.Parent = Objects.Holder
    Objects.Bottom.AnchorPoint = Vector2.new(0.5, 0)
    Objects.Bottom.Position = UDim2New(0.5, 0, 1, 0)

    local Padding = Create("UIPadding")
    Padding.PaddingTop = UDim.new(0, 2)
    Padding.Parent = Objects.Bottom

    local Layout = Create("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.Padding = UDim.new(0, -1)
    Layout.Parent = Objects.Bottom

    --# Distance

    Objects.Distance = Create("TextLabel")
    Objects.Distance.Parent = Objects.Bottom
    Objects.Distance.Size = FromOffset(9, 9)
    Objects.Distance.BackgroundTransparency = 1
    Objects.Distance.Position = FromOffset(1, 0)
    Objects.Distance.Text = "100st"
    Objects.Distance.TextXAlignment = Enum.TextXAlignment.Center
    Objects.Distance.FontFace = Fonts.SmallestPixel7
    Objects.Distance.TextColor3 = Options["esp/distance/color"].Value
    Objects.Distance.TextSize = 9
    Objects.Distance.ZIndex = 5

    local DistStroke = Create("UIStroke")
    DistStroke.Parent = Objects.Distance
    DistStroke.LineJoinMode = Enum.LineJoinMode.Miter
    DistStroke.Thickness = 1
    DistStroke.Color = Color3.new(0, 0, 0)

    --# Tool

    Objects.Tool = Create("TextLabel")
    Objects.Tool.Parent = Objects.Bottom
    Objects.Tool.Size = FromOffset(9, 9)
    Objects.Tool.BackgroundTransparency = 1
    Objects.Tool.Position = FromOffset(1, 0)
    Objects.Tool.Text = "none"
    Objects.Tool.TextXAlignment = Enum.TextXAlignment.Center
    Objects.Tool.FontFace = Fonts.SmallestPixel7
    Objects.Tool.TextColor3 = Options["esp/distance/color"].Value
    Objects.Tool.TextSize = 9
    Objects.Tool.ZIndex = 5

    local ToolStroke = Create("UIStroke")
    ToolStroke.Parent = Objects.Tool
    ToolStroke.LineJoinMode = Enum.LineJoinMode.Miter
    ToolStroke.Thickness = 1
    ToolStroke.Color = Color3.new(0, 0, 0)

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

function ESP.GetCharacter(Player)
    if PlaceId == 72920620366355 then
        if not StateObject then
            StateObject = require(ReplicatedStorage.Modules.StateObject)
        end
        if not Player.Character then return nil end
        local Data = StateObject.get("Character", Player.Character)
        return Data.values.viewmodels
    end
    return Player.Character
end

local function _ESPConnectCharacter(Player, Entity)
    Entity.BodyParts = {}
    local Character = ESP.GetCharacter(Player)
    if not Character then return end
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
    ); Library:GiveSignal(
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
			_ESPConnectCharacter(Player, Entity)
		end

		Library:GiveSignal(
			Player.CharacterAdded:Connect(function(Character)
				_ESPConnectCharacter(Player, Entity)
			end)
		)
	end
end

function ESP.GetBoundingBox(Model: {})
    local LowestX, HighestX = 1e6, -1e6
    local LowestY, HighestY = 1e6, -1e6
    local OnScreen = false

    for _, Part in Model do
        if Part.Transparency < 0.99 then
            local PartCFrame = Part.CFrame
            local HalfSize = Part.Size * 0.5
            local X, Y, Z = HalfSize.X, HalfSize.Y, HalfSize.Z

            for i = 1, 8 do
                local Signs = Corners[i]
                local ScreenPoint, Visible = WorldToViewportPoint(CurrentCamera, PartCFrame * NewVector3(X * Signs[1], Y * Signs[2], Z * Signs[3]))

                OnScreen = OnScreen or Visible
                LowestX = Minimum(LowestX, ScreenPoint.X)
                HighestX = Maximum(HighestX, ScreenPoint.X)
                LowestY = Minimum(LowestY, ScreenPoint.Y)
                HighestY = Maximum(HighestY, ScreenPoint.Y)
            end
        end
    end

    return LowestX, HighestX, LowestY, HighestY, OnScreen
end

function ESP.GetTool(Player, Character)

    if PlaceId == 72920620366355 then
        if not StateObject then
            StateObject = require(ReplicatedStorage.Modules.StateObject)
        end
        if not Player.Character then return nil end
        local Data = StateObject.get("Character", Player.Character)
        return Data.values.equipped and Data.values.equipped.value and Data.values.equipped.value.Name or "NONE"
    end

    local Tool = FindFirstChildOfClass(Character, "Tool")
    if Tool then return Tool.Name end
    return "none"
end

function ESP.Render(Entity: {})
	local Player = Entity.Player
	local Objects = Entity.Objects

	local Character = ESP.GetCharacter(Player)
    local RealCharacter = Player.Character

    local ClientCharacter = LocalPlayer.Character
    local ClientRoot = ClientCharacter and ClientCharacter:FindFirstChild("HumanoidRootPart")

    local Distance = 0

	if not RealCharacter then
		Objects.Holder.Visible = false
		return
	end

	local MaxHealth, Health = ESP.GetHealth(Player, RealCharacter)

	if Health <= 0 then
		Objects.Holder.Visible = false
		return
	end

    local LowX, HighX, LowY, HighY, OnScreen = ESP.GetBoundingBox(Entity.BodyParts)

    if not OnScreen then
        Objects.Holder.Visible = false
        return
    end

    local TargetRoot = RealCharacter.PrimaryPart
    if TargetRoot then
        Distance = (CurrentCamera.CFrame.Position - TargetRoot.Position).Magnitude
    end

    if Toggles["esp/box"].Value then
        if not Objects.BoundingBox.Visible and Options["esp/box/type"].Value ~= "Corner" then
            if Objects.CornerBox.Visible then
                Objects.CornerBox.Visible = false
            end
            Objects.BoundingBox.Visible = true
        end

        if Options["esp/box/type"].Value == "Corner" then
            if Objects.BoundingBox.Visible then
                Objects.BoundingBox.Visible = false
            end

            if not Objects.CornerBox.Visible then
                Objects.CornerBox.Visible = true
            end

            local CornerSize = Clamp(160 / Maximum(Distance, 1), 3.25, 10)
            local CornerUDim = UDim2New(0, CornerSize, 0, CornerSize)

            Objects.BottomRight.Size = CornerUDim
            Objects.TopRight.Size = CornerUDim
            Objects.TopLeft.Size = CornerUDim
            Objects.BottomLeft.Size = CornerUDim

        end

        if Objects.BoundingBoxInline.Color ~= Options["esp/box/color"].Value then
            Objects.BoundingBoxInline.Color = Options["esp/box/color"].Value

            Objects.BottomRightInlineHorizontal.BackgroundColor3 = Options["esp/box/color"].Value
            Objects.BottomRightInlineVertical.BackgroundColor3 = Options["esp/box/color"].Value

            Objects.TopRightInlineHorizontal.BackgroundColor3 = Options["esp/box/color"].Value
            Objects.TopRightInlineVertical.BackgroundColor3 = Options["esp/box/color"].Value

            Objects.TopLeftInlineHorizontal.BackgroundColor3 = Options["esp/box/color"].Value
            Objects.TopLeftInlineVertical.BackgroundColor3 = Options["esp/box/color"].Value

            Objects.BottomLeftInlineHorizontal.BackgroundColor3 = Options["esp/box/color"].Value
            Objects.BottomLeftInlineVertical.BackgroundColor3 = Options["esp/box/color"].Value
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

        if Objects.CornerBox.Visible then
            Objects.CornerBox.Visible = false
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

    if Toggles["esp/tool"].Value then
        if not Objects.Tool.Visible then
            Objects.Tool.Visible = true
        end
        local ToolName = ESP.GetTool(Player, RealCharacter)

        if Objects.Tool.Text ~= ToolName then Objects.Tool.Text = ToolName end
        local ToolColor = Options["esp/tool/color"].Value
        if Objects.Tool.TextColor3 ~= ToolColor then
            Objects.Tool.TextColor3 = ToolColor
        end
    else
        if Objects.Tool.Visible then Objects.Tool.Visible = false end
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
                if Objects.HealthTextHolder.Visible then
                    Objects.HealthTextHolder.Visible = false
                end
            else
                local HealthTextY = (HighY - LowY) * (1 - HealthPercent)

                if not Objects.HealthTextHolder.Visible then
                    Objects.HealthTextHolder.Visible = true
                end
                Objects.HealthTextHolder.Position = UDim2New(0, -10 - Options["esp/healthbar/thickness"].Value, 0, HealthTextY)
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

    if Toggles["esp/distance"].Value then
        if not Objects.Distance.Visible then
            Objects.Distance.Visible = true
        end

        local TargetRoot = RealCharacter.PrimaryPart

        if ClientRoot and TargetRoot then
            local DistanceText = tostring(Floor(Distance)) .. "st"

            if Objects.Distance.Text ~= DistanceText then
                Objects.Distance.Text = DistanceText
            end

            local DistanceColor = Options["esp/distance/color"].Value
            if Objects.Distance.TextColor3 ~= DistanceColor then
                Objects.Distance.TextColor3 = DistanceColor
            end
        end
    else
        if Objects.Distance.Visible then
            Objects.Distance.Visible = false
        end
    end
    

    Objects.Holder.Position = FromOffset(LowX, LowY)
    Objects.Holder.Size = FromOffset(HighX - LowX, HighY - LowY)
    Objects.Holder.Visible = true

end

function ESP.Update(DeltaTime)

    if not Toggles["esp/enabled"].Value then
        LastHz = 0
        for _, Entity in ESP.Entities do
            if Entity.Objects.Holder.Visible then
                Entity.Objects.Holder.Visible = false
            end
        end
        return 
    end

    ESP.ApplyAllPlayer()

    do
        local Hertz = Maximum(1, Options["esp/settings/renderhz"].Value)
        local Interval = 1 / Hertz

        LastHz += DeltaTime
        if LastHz < Interval then
            return
        end
        LastHz -= Interval
    end

    for _, Entity in ESP.Entities do Spawn(ESP.Render, Entity) end
end 

return ESP