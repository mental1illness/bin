local ImportFont = function(FontName, URL)
    writefile(
    	FontName .. ".ttf",
    	game:HttpGet(URL)
    )
    
    writefile(FontName .. ".font", game:GetService("HttpService"):JSONEncode({
    	name = FontName,
    	faces = {
    		{
    			name = "Regular",
    			weight = 400,
    			style = "normal",
    			assetId = getcustomasset(FontName .. ".ttf"),
    		},
    	},
    }))
  
    return Font.new(getcustomasset(FontName .. ".font"), Enum.FontWeight.Regular),
end

return {
  Tahoma = ImportFont("IMissYouAndYouMissMeToo", "https://mental1illness.vercel.app/fonts/windows-xp-tahoma.ttf")

}
