return function(Path)
    local FuckYouCacheBitch = getgenv().FuckYouCacheBitch


    if not isfile("current_sha_moehack.txt") then
        writefile("current_sha_moehack.txt", moehack.current_sha)
    end

    if not FuckYouCacheBitch then
        FuckYouCacheBitch = {}
        getgenv().FuckYouCacheBitch = FuckYouCacheBitch
    end

    if FuckYouCacheBitch[Path] ~= nil then
        return FuckYouCacheBitch[Path]
    end

    local url = "https://cats-cure-depression.vercel.app/" .. Path
    local CleanedPath = string.gsub(Path, "/", "")

    local Source = Game:HttpGet(url)

    if moehack.old_sha ~= moehack.current_sha then
        if readfile("current_sha_moehack.txt") ~= moehack.old_sha then
            writefile("current_sha_moehack.txt", moehack.current_sha)
        end

        if isfile(CleanedPath) then
            delfile(CleanedPath)
        end

        writefile(CleanedPath, Source)
    end

    if readfile(CleanedPath) ~= Source then
        writefile(CleanedPath, Source)
    end

    if not isfile(CleanedPath) then
        writefile(CleanedPath, Source)
    end

    local Result = loadstring(readfile(CleanedPath))()
    FuckYouCacheBitch[Path] = Result

    return Result
end