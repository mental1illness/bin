local HttpService = game.GetService(game,'HttpService')

local ImportFont = function(FontName, URL)
    local TTFFile = FontName .. ".ttf"
    local FontFile = FontName .. ".font"

    writefile(
        TTFFile,
        game:HttpGet(URL)
    )

    writefile(
        FontFile,
        HttpService:JSONEncode({
            name = FontName,
            faces = {
                {
                    name = "Regular",
                    weight = 400,
                    style = "normal",
                    assetId = getcustomasset(TTFFile),
                },
            },
        })
    )

    return Font.new(
        getcustomasset(FontFile),
        Enum.FontWeight.Regular
    )
end

return {
    Tahoma = ImportFont(
        "IMissYouAndYouMissMeToo",
        "https://mental1illness.vercel.app/fonts/windows-xp-tahoma.ttf"
    ),
}