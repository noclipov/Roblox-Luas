local Library = {}
local TeleportService = game:GetService('TeleportService')
local ChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local msg = loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/Libs/notify.lua"))()
local pls = game.Players
local lp = pls.LocalPlayer
Library.Link = "https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/Libs/additional.lua"
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/Libs/additional.lua"))()
Library.dist_to = function(pos)
    if not pos or not lp.Character or not lp.Character.PrimaryPart then return end
    if typeof(pos) == 'Vector3' then pos = pos
    elseif typeof(pos) == 'Instance' then
        if pos:IsA('Part') or pos:IsA('MeshPart') then pos = pos.Position
        elseif pos:IsA('Model') then pos = pos.PrimaryPart.Position
        elseif pos:IsA('Player') then pos = pos.Character.PrimaryPart.Position end
    end
    return math.floor(((game.Players.LocalPlayer.Character.PrimaryPart).Position - pos).magnitude) or 0
end
Library.teleport = function(pos, spread)
	if not lp.Character or not lp.Character.PrimaryPart then return end
	spread = spread or 5
	local current_position = lp.Character.PrimaryPart.CFrame
	lp.Character.PrimaryPart.CFrame = CFrame.new(pos.X+math.random(-spread, spread), pos.Y, pos.Z+math.random(-spread, spread))
	return current_position
end
Library.keybinds_handler = nil
Library.setup_keybinds = function(keybinds)
	if Library.keybinds_handler then Library.keybinds_handler:Disconnect() end
	local keys = {}
	for key, callback in pairs(keybinds) do if not callback then continue end table.insert(keys, key) end
	Library.keybinds_handler = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		local key = input.KeyCode
		if keybinds[key] then keybinds[key]() end
	end)
	msg.New("Purple", "Information", ("Available keybinds are: %s"):format(table.concat(keys, ' | ')), 5)
end
Library.is_moving = function(humanoid)
    if not humanoid then return false end
	return humanoid.MoveDirection.Magnitude == 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.FreeFall 
end
Library.is_alive = function(ply)
	if not ply.Character then return false end
    if ply.Character:FindFirstChild("Humanoid") and ply.Character:FindFirstChild("Humanoid").Health > 0 then return true end
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
Library.join_place = function(placeid, jobid)
    placeid = placeid or game.PlaceId
    jobid = jobid and tostring(jobid) or jobid
    if jobid then
        TeleportService:TeleportToPlaceInstance(placeid, jobid, game.Players.LocalPlayer)
    else
        TeleportService:Teleport(placeid, game.Players.LocalPlayer)
    end
end
Library.hl_player = function(ply, fillcolor, outlinecolor, filltransparency, outlinetransparency, depthmode)
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
    hl.DepthMode = depthmode or Enum.HighlightDepthMode.Occluded
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
Library.remove_tool = function(name, instance)
	if not lp.Character then return end
	if name and lp.Backpack:FindFirstChild(name) or instance then
		(name and lp.Backpack[name] or instance):Destroy()
	end
end
Library.inside_cube = function(point, cube)
	if not cube then return end
	point = point or lp.Character.PrimaryPart
	local relative = cube:PointToObjectSpace(point)
	return math.abs(relative.X) <= cube.Size.X / 2
		and math.abs(relative.Y) <= cube.Size.Y / 2
		and math.abs(relative.Z) <= cube.Size.Z / 2
end
Library.chat = function(text)
	ChatService.TextChannels.RBXGeneral:SendAsync(text)
end
Library.chat_filter = function(callback, isfilter)
    if ChatService and ChatService.ChatVersion == Enum.ChatVersion.TextChatService then 
		if isfilter then
			ChatService.OnIncomingMessage = function(textMessage)
				local display, filter = callback(textMessage, textMessage.TextSource)
				if display == false then
					textMessage.Text = ""
				elseif filter then
					textMessage.Text = filter
				end
			end
		else 
			ChatService.TextChannels.RBXGeneral.ShouldDeliverCallback = callback
		end
    end
end
Library.toggle_coregui = function(coregui, state)
	game.StarterGui:SetCoreGuiEnabled(coregui, state)
end
Library.load_file = function(path, silent)
	silent = silent or false
	if isfolder("noclipov/") and isfile("noclipov/" .. path) then
		local success, result = pcall(readfile, "noclipov/" .. path)
		if success then
			local fn, err = loadstring(result)
			if fn then if not silent then msg.Mini("Mint", "Загружаем "..path, 1) end return fn() else msg.Mini("Coral", "Ошибка компиляции файла " .. path .. ": " .. tostring(err), 3) end
		else
			msg.Mini("Coral", "Не удалось прочитать файл " .. path, 3)
		end
	end
end
Library.round = function(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end
Library.to_letters = function(num, DecimalPlaces)
	DecimalPlaces = DecimalPlaces or 0
	if num >= 1e78 then num = num / 1e78
		return Library.Round(num, DecimalPlaces).."QiVi"
	elseif num >= 1e75 then num = num / 1e75
		return Library.Round(num, DecimalPlaces).."QaVi"
	elseif num >= 1e72 then num = num / 1e72
		return Library.Round(num, DecimalPlaces).."TVi"
	elseif num >= 1e69 then num = num / 1e69
		return Library.Round(num, DecimalPlaces).."DVi"
	elseif num >= 1e66 then num = num / 1e66
		return Library.Round(num, DecimalPlaces).."UVi"
	elseif num >= 1e63 then num = num / 1e63
		return Library.Round(num, DecimalPlaces).."Vi"
	elseif num >= 1e60 then num = num / 1e60
		return Library.Round(num, DecimalPlaces).."NoV"
	elseif num >= 1e57 then num = num / 1e57
		return Library.Round(num, DecimalPlaces).."OcDc"
	elseif num >= 1e54 then num = num / 1e54
		return Library.Round(num, DecimalPlaces).."SpDc"
	elseif num >= 1e51 then num = num / 1e51
		return Library.Round(num, DecimalPlaces).."SxDc"
	elseif num >= 1e48 then num = num / 1e48
		return Library.Round(num, DecimalPlaces).."QiDc"
	elseif num >= 1e45 then num = num / 1e45
		return Library.Round(num, DecimalPlaces).."QaDc"
	elseif num >= 1e42 then num = num / 1e42
		return Library.Round(num, DecimalPlaces).."TDc"
	elseif num >= 1e39 then num = num / 1e39
		return Library.Round(num, DecimalPlaces).."DDc"
	elseif num >= 1e36 then num = num / 1e36
		return Library.Round(num, DecimalPlaces).."UDc"
	elseif num >= 1e33 then num = num / 1e33
		return Library.Round(num, DecimalPlaces).."Dc"
	elseif num >= 1e30 then num = num / 1e30
		return Library.Round(num, DecimalPlaces).."No"
	elseif num >= 1e27 then num = num / 1e27
		return Library.Round(num, DecimalPlaces).."Oc"
	elseif num >= 1e24 then num = num / 1e24
		return Library.Round(num, DecimalPlaces).."Sp"
	elseif num >= 1e21 then num = num / 1e21
		return Library.Round(num, DecimalPlaces).."Sx"
	elseif num >= 1e18 then num = num / 1e18
		return Library.Round(num, DecimalPlaces).."Qi"
	elseif num >= 1e15 then num = num / 1e15
		return Library.Round(num, DecimalPlaces).."Qa"
	elseif num >= 1e12 then num = num / 1e12
		return Library.Round(num, DecimalPlaces).."T"
	elseif num >= 1e09 then num = num / 1e09
		return Library.Round(num, DecimalPlaces).."B"
	elseif num >= 1e06 then num = num / 1e06
		return Library.Round(num, DecimalPlaces).."M"
	elseif num >= 1e03 then num = num / 1e03
		return Library.Round(num, DecimalPlaces).."K"
	else return num
	end
end

Library.simple_spy = function()
    msg.Mini("Purple", "Simple Spy: Loading", 2)
    loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua"))()
end
Library.dex_explorer = function()
    msg.Mini("Purple", "Dex Explorer: Loading", 5)
    loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
end
Library.anti_afk = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/anti_afk.lua"))()
end
Library.fps_control = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/fps_control.lua"))()
end

local alias_list = {
	["dist_to"] = {"distTo","DistTo","distto"},
	["teleport"] = {"teleport","tp","setpos"},
	["setup_keybinds"] = {"setupKeyBinds","KeyBinds","keybinds", "keys", "binds", "setupKeys", "setupBinds"},
	["is_moving"] = {"isMoving","IsMoving","ismoving"},
	["is_alive"] = {"isAlive","IsAlive","isalive"},
	["has_value"] = {"hasValue","HasValue","hasvalue"},
	["get_ping"] = {"getPing","GetPing","getping"},
	["get_friends"] = {"getFriend","GetFriends","getfriends"},
	["join_place"] = {"joinPlace","JoinPlace","joinplace"},
	["hl_player"] = {"hlPlayer","HLPlayer","hlplayer", "hl", "HL"},
	["unhl_player"] = {"unhlPlayer","UnHLPlayer","unhlplayer", "unhl", "unHL"},
	["get_teleport"] = {"getTeleport","GetTeleport","getteleport"},
	["equip_tool"] = {"equipTool","EquipTool","equiptool"},
	["remove_tool"] = {"removeTool","RemoveTool","removetool"},
	["inside_cube"] = {"insideCube","InsideCube","insidecube"},
	["chat"] = {"Chat", "send_message", "SendMessage", "sendMessage", "message", "Message"},
	["chat_filter"] = {"filter","ChatFilter","chatFilter", "chatfilter"},
	["toggle_coregui"] = {"toggleCG","toggleCoreGui","CoreGui", "coregui"},
	["load_file"] = {"loadFile","LoadFile","loadfile", "load"},
	["round"] = {"Round"},
	["to_letters"] = {"toLetters","ToLetters","toletters", "Letters", "letters", "format"},

	["simple_spy"] = {"simpleSpy","SimpleSpy","simplespy", "ss"},
	["dex_explorer"] = {"dexExplorer","DexExplorer","dexexplorer", "de"},
	["anti_afk"] = {"antiAFK","AntiAFK","antiafk", "afk"},
	["fps_control"] = {"fpsControl","FPSControl","fpscontrol", "fps"},
}

for src, aliases in pairs(alias_list) do
	if Library[src] then
		for _, alias in pairs(aliases) do
			Library[alias] = Library[src]
		end
	end
end

return Library