
local IsDescendantOf, Raycast = workspace.IsDescendantOf, workspace.Raycast
local Typeof, Type = typeof, type
local Pack, Unpack = table.pack, table.unpack
local LookAt = CFrame.lookAt
local Lower = string.lower

--# Vars

local Params = RaycastParams.new()
Params.FilterType = Enum.RaycastFilterType.Exclude

local ParamsWhitelist = RaycastParams.new()
ParamsWhitelist.FilterType = Enum.RaycastFilterType.Include

local Camera = workspace.CurrentCamera

--# Helper Funcs (USELESS)

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

--# Modules

local Combat = LoadModule("moehack.net/modules/combat.luau", true)

local Hooks = {}

local SilentAimHook = {
    FindPartOnRay = function(self, ...)
        local Args = Pack(...)
        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])
        if not Target or not Hitbox then return end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            return
        end

        if MagicBullet then
           
        end

        return Args
    end,

    FindPartOnRayWithIgnoreList = function(self, ...)
        local Args = Pack(...)
        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])
        if not Target or not Hitbox then return end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            return
        end

        if MagicBullet then
           
        end

        return Args
    end,

    FindPartOnRayWithWhitelist = function(self, ...)
        local Args = Pack(...)
        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])
        if not Target or not Hitbox then return end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            return
        end

        if MagicBullet then
            
        end

        return Args
    end,

    ScreenPointToRay = function(self, ...)
        local Args = Pack(...)
        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])
        if not Target or not Hitbox then return end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            return
        end

        if MagicBullet then
            
        end

        return Args
    end,

    ViewportPointToRay = function(self, ...)
        local Args = Pack(...)
        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])
        if not Target or not Hitbox then return end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            return
        end

        if MagicBullet then

        end

        return Args
    end,

    Raycast = function(self, ...)
        local Args = Pack(...)

        if Typeof(Args[1]) ~= 'Vector3' or Typeof(Args[2]) ~= 'Vector3' or Args[3] and Typeof(Args[3]) ~= 'RaycastParams' then
            return
        end

        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])
        if not Target or not Hitbox then return end

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            return
        end

        if MagicBullet then
            ParamsWhitelist.FilterDescendantsInstances = {targetPart}
            Args[3] = ParamsWhitelist
        end

        Args[2] = LookAt(Args[1], Hitbox.Position).LookVector * Args[2].Magnitude
        return Args
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
            local Args = Handler(self, ...)
            if Args then
                return Hooks.__Namecall(self, Unpack(Args, 1, Args.n)) -- we do nothin if there's nothin
            end
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

Hooks.__Namecall = hookmetamethod(game, "__namecall", __Namecall)

return Hooks