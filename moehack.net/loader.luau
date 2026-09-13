LoadModule = function(Path, Load)
    local url = "https://cats-cure-depression.vercel.app/" .. Path
    
    return Load == true and loadstring(game:HttpGet(url))() or game:HttpGet(url)
end

local ToRunOnActor = {
    [72920620366355] = true
}

--# Main


if ToRunOnActor[Game.PlaceId] then 
    local RunFunc = run_on_thread or run_on_actor
    local Actors  = getactorthreads or getactors

    RunFunc(Actors(), LoadModule("moehack.net/cheat.luau"))

    return 
end

LoadModule("moehack.net/cheat.luau", true)