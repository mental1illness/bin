do  -- Common Stuff
    if setstackhidden then
        setstackhidden(getgenv().getfenv, true)
    end
end

if moehack.data.game_name == "Operation One" then -- not my shit bro
    local oldStrByte; oldStrByte = hookfunction(string.byte, newcclosure(function(a0, a1)
        if (checkcaller() or type(a0) ~= 'string' or not (a0:sub(1, 1) == '{' and a0:sub(-1) == '}')) then return oldStrByte(a0, a1) end;

        const luraph = getstack(3, 1);
        luraph[1] = luraph[2];
        luraph[5] = #luraph[2];
        setstack(3, 4, luraph[5]);

        return oldStrByte(luraph[1], a1);
    end));
end