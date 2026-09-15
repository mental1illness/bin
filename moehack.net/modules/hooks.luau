local Hooks = {}

local function __Namecall(...)

end

if setstackhidden then
    setstackhidden(NameCall, true)
    if hookmetamethod then
        setstackhidden(hookmetamethod, true)
    end
end

Hooks.NameCall = hookmetamethod(Game, "__namecall", __Namecall)

return Hooks