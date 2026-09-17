local IsDescendantOf, Raycast = workspace.IsDescendantOf, workspace.Raycast
local NewVector3, NewVector = Vector3.new, vector.create
local WorldToViewportPoint = workspace.CurrentCamera.WorldToViewportPoint
local NewRay = clonefunction(Ray.new)
local Typeof, Type = typeof, type
local Pack, Unpack = table.pack, table.unpack
local GetService = Game.GetService
local LookAt = CFrame.lookAt
local Lower = string.lower


--# Services

local Players = GetService(Game, "Players")

--# Vars

local Params = RaycastParams.new()
Params.FilterType = Enum.RaycastFilterType.Exclude

local ParamsWhitelist = RaycastParams.new()
ParamsWhitelist.FilterType = Enum.RaycastFilterType.Include

local Camera = workspace.CurrentCamera
local MagicBulletOffset = NewVector3(0, 0, -3)

local LocalPlayer = Players.LocalPlayer

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

    local URL = "https://cats-cure-depression.vercel.app/" .. Path
    local Result = loadstring(game:HttpGet(URL))()

    FuckYouCacheBitch[Path] = Result
    return Result
end

function IsBehindWalls(Hitbox)
    if not Hitbox then
        return true
    end

    local Origin = Camera.CFrame.Position
    local Direction = Hitbox.Position - Origin

    local IgnoreList = {
        LocalPlayer.Character
    }

    for _ = 1, 20 do
        Params.FilterDescendantsInstances = IgnoreList

        local Result = Raycast(
            workspace,
            Origin,
            Direction,
            Params
        )

        if not Result then
            return true
        end

        local Part = Result.Instance

        if Part == Hitbox then
            return false
        end

        if Part.Transparency >= 1 or not Part.CanCollide then
            table.insert(IgnoreList, Part)

            Origin = Result.Position + Direction.Unit * 0.01
            Direction = Hitbox.Position - Origin
        else
            return true
        end
    end

    return true
end

--# Modules

local Combat = LoadModule("moehack.net/modules/combat.luau", true)
local Hooks = {}

local SilentAimHook = {
    FindPartOnRay = function(Args)
        if Typeof(Args[1]) ~= "Ray" then
            return
        end

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"].Value)

        if not Target or not Hitbox then
            return
        end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and IsBehindWalls(Hitbox) then
            return
        end

        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        if MagicBullet then
            ParamsWhitelist.FilterDescendantsInstances = {Hitbox}
        end

        Args[1] = NewRay(Args[1].Origin, LookAt(Args[1].Origin, Hitbox.Position).LookVector * Args[1].Direction.Magnitude)
    end,

    FindPartOnRayWithIgnoreList = function(Args)
        if Typeof(Args[1]) ~= "Ray" then
            return
        end

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"].Value)

        if not Target or not Hitbox then
            return
        end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and IsBehindWalls(Hitbox) then
            return
        end

        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        if MagicBullet then
            ParamsWhitelist.FilterDescendantsInstances = {Hitbox}
        end

        Args[1] = NewRay(Args[1].Origin, LookAt(Args[1].Origin, Hitbox.Position).LookVector * Args[1].Direction.Magnitude)
    end,

    FindPartOnRayWithWhitelist = function(Args)
        if Typeof(Args[1]) ~= "Ray" then
            return
        end

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"].Value)

        if not Target or not Hitbox then
            return
        end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and IsBehindWalls(Hitbox) then
            return
        end

        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        if MagicBullet then
            ParamsWhitelist.FilterDescendantsInstances = {Hitbox}
        end

        Args[1] = NewRay(Args[1].Origin, LookAt(Args[1].Origin, Hitbox.Position).LookVector * Args[1].Direction.Magnitude)
    end,

    ScreenPointToRay = function(Args)
        if Args[3] and Type(Args[3]) ~= "number" then
            return
        end

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"].Value)

        if not Target or not Hitbox then
            return
        end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and IsBehindWalls(Hitbox) then
            return
        end

        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        if MagicBullet then
            return {
                NewRay(Camera.CFrame.Position, LookAt(Camera.CFrame.Position, Hitbox.Position).LookVector)
            }
        end

        local Direction = LookAt(Camera.CFrame.Position, Hitbox.Position).LookVector
        local Depth = Args[3]

        return {
            NewRay(Camera.CFrame.Position + (Depth and Direction * Depth or Vector3.zero), Direction)
        }
    end,

    ViewportPointToRay = function(Args)
        if Args[3] and Type(Args[3]) ~= "number" then
            return
        end

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"].Value)

        if not Target or not Hitbox then
            return
        end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and IsBehindWalls(Hitbox) then
            return
        end

        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        if MagicBullet then
            local Origin = Camera.CFrame.Position
            local Direction = LookAt(Origin, Hitbox.Position).LookVector

            return {
                NewRay(Origin + (Args[3] and Direction * Args[3] or Vector3.zero), Direction)
            }
        end

        local ViewPoint = WorldToViewportPoint(Camera, Hitbox.Position)
        Args[1] = ViewPoint.X
        Args[2] = ViewPoint.Y
    end,

    Raycast = function(Args)
        if Typeof(Args[1]) ~= "Vector3" or Typeof(Args[2]) ~= "Vector3" or Args[3] and Typeof(Args[3]) ~= "RaycastParams" then
            return
        end

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"].Value)

        if not Target or not Hitbox then
            return
        end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and IsBehindWalls(Hitbox) then
            return
        end

        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        if MagicBullet then
            ParamsWhitelist.FilterDescendantsInstances = {Hitbox}
            Args[3] = ParamsWhitelist
        end

        Args[2] = LookAt(Args[1], Hitbox.Position).LookVector * Args[2].Magnitude
    end,
}

local __Namecall = newcclosure(function(self, ...)
    if not Hooks.__Namecall then
        return
    end

    if Toggles["combat/bulletredirection"].Value and not checkcaller() then
        local Method = getnamecallmethod()
        local Handler = SilentAimHook[Method]

        if Handler and Lower(Method) == Lower(Options["combat/bulletredirection/method"].Value) then
            local Args = Pack(...)
            local Data = Handler(Args)

            if Data then
                return Hooks.__Namecall(self, Unpack(Data, 1, Data.n or #Data))
            end

            return Hooks.__Namecall(self, Unpack(Args, 1, Args.n))
        end
    end

    return Hooks.__Namecall(self, ...)
end)

if setstackhidden then
    setstackhidden(__Namecall, true)

    if hookmetamethod then
        setstackhidden(hookmetamethod, true)
    end

    if hookfunction then
        setstackhidden(hookfunction, true)
    end
end

if not moehack.data.use_custom_silent_aim then
    Hooks.__Namecall = hookmetamethod(game, "__namecall", __Namecall)
end

if moehack.data.use_custom_silent_aim and moehack.data.game_name == "Operation One" then
    type UMod = {
        [string]: (...any) -> any
    }

    local Gun = require(game.ReplicatedStorage.Modules.Items.Item.Gun)
    local Debug = debug
    local Original = Debug.getupvalue(Gun.send_shoot, 1)

    local function ValidatePosition(Origin: Vector3, Target: Vector3, RaycastParameters: RaycastParams?)
        if not Toggles["combat/bulletredirection"].Value then
            return Original.validate_position(Origin, Target, RaycastParameters)
        end

        if not Debug.traceback():find("send_shoot") then
            return Original.validate_position(Origin, Target, RaycastParameters)
        end

        local TargetPlayer, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"].Value)

        if not TargetPlayer or not Hitbox then
            return Original.validate_position(Origin, Target, RaycastParameters)
        end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and IsBehindWalls(Hitbox) then
            return Original.validate_position(Origin, Target, RaycastParameters)
        end

        local CFrameValue = Debug.getstack(2, 3)

        if typeof(CFrameValue) == "CFrame" then
            Debug.setstack(2, 5, CFrame.lookAt(CFrameValue.Position, Hitbox.Position))
        end

        return Original.validate_position(Origin, Target, RaycastParameters)
    end

    Debug.setupvalue(Gun.send_shoot, 1, setmetatable({}, {
        __index = function(_, Key: string)
            if Key == "validate_position" then
                return ValidatePosition
            end

            return Original[Key]
        end,
    }))
end

return Hooks