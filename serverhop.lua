-- loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/serverhop.lua"))()
local Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. game.PlaceId .. '/servers/Public?sortOrder=Asc&limit=100'))
local lowest,serverid = math.huge, ""
for i,v in pairs(Site.data) do
	if lowest > v.playing then lowest = v.playing; serverid = tostring(v.id) end
end
game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, serverid, game.Players.LocalPlayer)
