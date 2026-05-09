local Library = {}
local TeleportService = game:GetService('TeleportService')
local ChatService = game:GetService("TextChatService")
local msg = loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/NotifyModule.lua"))()
local pls = game.Players
local lp = pls.LocalPlayer
Library.Link = "https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/additional.lua"
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/additional.lua"))()
Library.dist_to = function(pos)
    if not pos then return end
    if typeof(pos) == 'Vector3' then pos = pos
    elseif typeof(pos) == 'Instance' then
        if pos:IsA('Part') or pos:IsA('MeshPart') then pos = pos.Position
        elseif pos:IsA('Model') then pos = pos.PrimaryPart.Position
        elseif pos:IsA('Player') then pos = pos.Character.PrimaryPart.Position end
    end
    return math.floor(((game.Players.LocalPlayer.Character.HumanoidRootPart).Position - pos).magnitude) or 0
end
Library.is_moving = function(humanoid)
    if (humanoid.MoveDirection == Vector3.new(0,0,0) and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall) then return false end
    return true
end
Library.is_alive = function(ply)
	if not ply.Character then return false end
    if ply.Character:FindFirstChild("Humanoid") and ply.Character:FindFirstChild("Humanoid").Health > 0 then return true end
    return false
end
Library.int = function(value)
    if tonumber(value) then return tonumber(value) end
    return 0
end
Library.str = function(value)
    return tostring(value) or ""
end
Library.has_value = function(src, value)
    if type(src) == "string" then
        return string.find(src, value) and true or false
    elseif type(src) == "table" then
        for i,v in pairs(src) do if v == value then return true end end
    end
    return false
end
Library.get_ping = function() 
    return lp:GetNetworkPing()*2000
end
Library.get_friends = function(player)
    local friends = {}
    for i,v in pairs(pls:GetChildren()) do if player:IsFriendsWith(v.UserId) then table.insert(friends, v) end end
    return friends
end
Library.format_number = function(number)
    local str_num = tostring(number)
    if tonumber(str_num:sub(-1)) > 3 then
        return str_num..'th'
    elseif tonumber(str_num:sub(-1)) == 3 then
        return str_num..'rd'
    elseif tonumber(str_num:sub(-1)) == 2 then
        return str_num..'nd'
    elseif tonumber(str_num:sub(-1)) == 1 then
        return str_num..'st'
    end
end
Library.join_place = function(placeid, jobid)
    placeid = placeid or game.PlaceId
    jobid = jobid and tostring(jobid) or jobid
    if jobid then
        TeleportService:TeleportToPlaceInstance(placeid, jobid, game.Players.LocalPlayer)
    else
        TeleportService:Teleport(placeid, game.Players.LocalPlayer)
    end
end
Library.hl_player = function(ply, fillcolor, outlinecolor, filltransparency, outlinetransparency)
    if not ply.Character then return end
	fillcolor = fillcolor or Color3.fromRGB(0,0,0)
    outlinecolor = outlinecolor or Color3.fromRGB(255,255,255)
    filltransparency = filltransparency or 0
	outlinetransparency = outlinetransparency or 0
    local hl = not ply.Character:FindFirstChild("U_Highlight") and Instance.new("Highlight") or ply.Character:FindFirstChild("U_Highlight")
    hl.Name = "U_Highlight"
    hl.Parent = ply.Character
    hl.Adornee = ply.Character
    hl.FillColor = fillcolor
    hl.OutlineColor = outlinecolor
    hl.DepthMode = Enum.HighlightDepthMode.Occluded
    hl.FillTransparency = filltransparency
    hl.OutlineTransparency = outlinetransparency
    return hl
end
Library.unhl_player = function(ply)
	if not ply.Character or not ply.Character:FindFirstChild("U_Highlight") then return end
	ply.Character:FindFirstChild("U_Highlight"):Remove()
end
Library.get_teleport = function()
    setclipboard(string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game.Players.LocalPlayer)", tostring(game.PlaceId), game.JobId))
end
Library.equip_tool = function(name, instance)
	if not lp.Character then return end
	if name and lp.Backpack:FindFirstChild(name) or instance then
		lp.Character:WaitForChild("Humanoid"):EquipTool(name and lp.Backpack[name] or instance)
	elseif not name and not instance then
		lp.Character:WaitForChild("Humanoid"):UnequipTools()
	end
end
Library.inside_cube = function(point, cube)
	if not cube then return end
	point = point or lp.Character.PrimaryPart
	local relative = cframe:PointToObjectSpace(point)
	return math.abs(relative.X) <= cube.Size.X / 2
		and math.abs(relative.Y) <= cube.Size.Y / 2
		and math.abs(relative.Z) <= cube.Size.Z / 2
end
Library.chat = function(text)
	ChatService.TextChannels.RBXGeneral:SendAsync(text)
end
Library.chat_filter = function(...)
	local conditions = {...}
	for _, condition in conditions do
		ChatService.TextChannels.RBXGeneral.ShouldDeliverCallback = condition
	end
end
Library.ss = function()
    msg.Mini("Success", "Simple Spy: Loading", 2)
    loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua"))()
end
Library.dd = function()
    msg.Mini("Success", "Dark Dex: Loading", 2)
    loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
end
Library.aa = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Anti-AFK.lua"))()
end

local alias_list = {
	["dist_to"] = {"distTo","DistTo","distto"},
	["is_moving"] = {"isMoving","IsMoving","ismoving"},
	["is_alive"] = {"isAlive","IsAlive","isalive"},
	["has_value"] = {"hasValue","HasValue","hasvalue"},
	["get_ping"] = {"getPing","GetPing","getping"},
	["get_friends"] = {"getFriend","GetFriends","getfriends"},
	["format_number"] = {"formatNumber","FormatNumber","formatnumber"},
	["join_place"] = {"joinPlace","JoinPlace","joinplace"},
	["hl_player"] = {"hlPlayer","HLPlayer","hlplayer"},
	["unhl_player"] = {"unhlPlayer","UnHLPlayer","unhlplayer"},
	["get_teleport"] = {"getTeleport","GetTeleport","getteleport"},
	["equip_tool"] = {"equipTool","EquipTool","equiptool"},
	["inside_cube"] = {"insideCube","InsideCube","insidecube"},
	["chat"] = {"Chat","message","send_message", "Message", "SendMessage", "sendMessage"},
	["chat_filter"] = {"filter","ChatFilter","chatFilter", "chatfilter"},
}

for src, aliases in pairs(alias_list) do
	if Library[src] then
		for _, alias in pairs(aliases) do
			Library[alias] = Library[src]
		end
	end
end

return Library