
local IsDescendantOf, Raycast = workspace.IsDescendantOf, workspace.Raycast
local Pack, Unpack = table.pack, table.unpack
local LookAt = CFrame.lookAt
local Lower = string.lower

--# Vars

local Params = RaycastParams.new()
Params.FilterType = Enum.RaycastFilterType.Exclude

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

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            Target, Hitbox = nil, nil
        end

        if MagicBullet then
           
        end

        return Hooks.__Namecall(self, Unpack(Args, 1, Args.n))
    end,

    FindPartOnRayWithIgnoreList = function(self, ...)
        local Args = Pack(...)
        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            Target, Hitbox = nil, nil
        end

        if MagicBullet then
           
        end

        return Hooks.__Namecall(self, Unpack(Args, 1, Args.n))
    end,

    FindPartOnRayWithWhitelist = function(self, ...)
        local Args = Pack(...)
        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            Target, Hitbox = nil, nil
        end

        if MagicBullet then
            
        end

        return Hooks.__Namecall(self, Unpack(Args, 1, Args.n))
    end,

    ScreenPointToRay = function(self, ...)
        local Args = Pack(...)
        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            Target, Hitbox = nil, nil
        end

        if MagicBullet then
            
        end

        return Hooks.__Namecall(self, Unpack(Args, 1, Args.n))
    end,

    ViewportPointToRay = function(self, ...)
        local Args = Pack(...)
        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            Target, Hitbox = nil, nil
        end

        if MagicBullet then

        end

        return Hooks.__Namecall(self, Unpack(Args, 1, Args.n))
    end,

    Raycast = function(self, ...)
        local Args = Pack(...)
        local MagicBullet = Toggles["combat/bulletredirection/magicbullet"].Value

        local Target, Hitbox = Combat.GetTarget(Options["combat/bulletredirection/fov"].Value, Toggles["combat/bulletredirection/usenearhitbox"])

        if Toggles["combat/bulletredirection/ignorebehindwalls"].Value and not Combat.IsBehindWalls(Target, Hitbox) then
            Target, Hitbox = nil, nil
        end

        if MagicBullet then

        end

        return Hooks.__Namecall(self, Unpack(Args, 1, Args.n))
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
            return Handler(self, ...)
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