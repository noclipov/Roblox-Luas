local HttpService = game:GetService("HttpService")
local Library = {}
Library.Link = "https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/Libs/settings.lua"
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/Libs/settings.lua"))()
local function encode(table: table) return HttpService:JSONEncode(table) end
local function decode(table: table) return HttpService:JSONDecode(table) end
local function check() if writefile and readfile and isfile and delfile then return true end return false end
Library.isfile = function(name: string)
    if check() then
        return isfile(name)
    else return end
end
Library.save = function(name: string, table: table)
    table = table or {}
    if check() then
        if string.sub(name, -5) ~= ".json" then name = name..".json" end
        writefile(name, encode(table))
    else return end
end
Library.get = function(name: string)
    if check() then
        if isfile(name) then
            if string.sub(name, -5) ~= ".json" then name = name..".json" end
            return decode(readfile(name))
        end
    else return end
end
Library.delfile = function(name: string)
    if check() and Library.isfile(name) then
        delfile(name)
    else return end
end
return Library