local Library = {}
local TeleportService = game:GetService('TeleportService')
local ChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local msg = loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/refs/heads/main/Libs/notify.lua"))()
local pls = game.Players
local lp = pls.LocalPlayer
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/refs/heads/main/Libs/additional.lua"))()
Library.Link = "https://raw.githubusercontent.com/noclipov/Roblox-Luas/refs/heads/main/Libs/additional.lua"
Library.dist_to = function(pos)
    if not pos or not lp.Character or not lp.Character.PrimaryPart then return end
    if typeof(pos) == 'Vector3' then pos = pos
    elseif typeof(pos) == 'Instance' then
        if pos:IsA('Part') or pos:IsA('MeshPart') then pos = pos.Position
        elseif pos:IsA('Model') and pos.PrimaryPart then pos = pos.PrimaryPart.Position
        elseif pos:IsA('Player') and pos.Character and pos.Character.PrimaryPart then pos = pos.Character.PrimaryPart.Position end
    end
    return math.floor(((game.Players.LocalPlayer.Character.PrimaryPart).Position - pos).magnitude) or 0
end
Library.teleport = function(pos, spread)
	if not lp.Character or not lp.Character.PrimaryPart then return end
	spread = spread or 0
	local current_position = lp.Character.PrimaryPart.CFrame
	local x = spread > 0 and (pos.X+math.random(-spread, spread)) or pos.X
	local y = pos.Y
	local z = spread > 0 and (pos.Z+math.random(-spread, spread)) or pos.Z
	lp.Character.PrimaryPart.CFrame = CFrame.new(x,y,z)
	return current_position
end
Library.setup_keybinds = function(keybinds)
	local laststate = false
	if getgenv().keybinds_handler then laststate =  true; getgenv().keybinds_handler:Disconnect() end
	local keys = {}
	for key, data in pairs(keybinds) do if not data['callback'] then continue end; table.insert(keys, key) end
	getgenv().keybinds_handler = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		local key = input.KeyCode
		if keybinds[key.Name] and ((keybinds[key.Name]['gpc'] and not gameProcessed) or not keybinds[key.Name]['gpc']) then keybinds[key.Name]['callback']() end
	end)
	msg.New("Purple", "Information", (laststate and "Updated keybinds are: %s" or "Available keybinds are: %s"):format(table.concat(keys, ' | ')), 5)
end
Library.screen_stretch = function()
	if getgenv().screen_stretch then getgenv().screen_stretch:Disconnect() end
	getgenv().screen_stretch = RunService.RenderStepped:Connect(function()
		workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0,0,0,1,0,0,0,0.8,0,0,0,1)
	end)
	msg.New("Purple", "Information", (laststate and "Updated keybinds are: %s" or "Available keybinds are: %s"):format(table.concat(keys, ' | ')), 5)
end
Library.is_moving = function(humanoid)
    if not humanoid then return false end
	return humanoid.MoveDirection.Magnitude == 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall 
end
Library.is_firstperson = function()
	return lp:DistanceFromCharacter(game.workspace.CurrentCamera.CFrame.Position) < 1; 
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
local function check_path_is_noclipov(path)
	if not string.find(path, "noclipov/") then
		path = "noclipov/"..path
	end
	if not string.find(path, ".lua") and not string.find(path, ".txt") and not string.find(path, ".json") then
		path = path..".txt"
	end
	return path
end
Library.check_noclipov = function(file)
	if file then
		return isfolder("noclipov/") and isfile("noclipov/" .. file)
	else
		return isfolder("noclipov/")
	end
end
Library.load_file = function(path, silent, instant)
	path = check_path_is_noclipov(path)
	silent = silent or false
	if Library.check_noclipov(path) then
		local success, result = pcall(readfile, "noclipov/" .. path)
		if success then
			local fn, err = loadstring(result)
			if fn then 
                if not silent then msg.Mini("Mint", "Загружаем "..path, 1) end
                if instant then return fn()
                else return fn end 
            else 
                msg.Mini("Coral", "Ошибка компиляции файла " .. path .. ": " .. tostring(err), 3) 
                return false
            end
		else
			msg.Mini("Coral", "Не удалось прочитать файл " .. path, 3)
            return false
		end
    else
        return false
	end
end
Library.write_file = function(path, content, rewrite)
	path = check_path_is_noclipov(path and path or "test.txt")
	content = content or "test text for no reason"
	rewrite = rewrite or false
	if Library.check_noclipov(path) then
		if rewrite then
			writefile(path, content)
		else
			appendfile(path, content)
		end
	else
		writefile(path, content)
	end
end
Library.load_module = function(module_name, instant)
	instant = instant or true
	module_name = module_name or "additional.lua"
	local success, result = pcall(Library.load_file, module_name, false, instant)
    if not result then
		local fn, err = loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/refs/heads/main/Libs/"..module_name))
		if err then fn, err = loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/"..module_name)) end
		if fn then
			if instant then
				return fn()
			else
				return fn
			end
		end
	else
		return result
	end
    return false
end
Library.round = function(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end
Library.to_letters = function(num, DecimalPlaces)
	DecimalPlaces = DecimalPlaces or 0
	if num >= 1e42 then num = num / 1e42
		return Library.round(num, DecimalPlaces).."TDc"
	elseif num >= 1e39 then num = num / 1e39
		return Library.round(num, DecimalPlaces).."DDc"
	elseif num >= 1e36 then num = num / 1e36
		return Library.round(num, DecimalPlaces).."UDc"
	elseif num >= 1e33 then num = num / 1e33
		return Library.round(num, DecimalPlaces).."Dc"
	elseif num >= 1e30 then num = num / 1e30
		return Library.round(num, DecimalPlaces).."No"
	elseif num >= 1e27 then num = num / 1e27
		return Library.round(num, DecimalPlaces).."Oc"
	elseif num >= 1e24 then num = num / 1e24
		return Library.round(num, DecimalPlaces).."Sp"
	elseif num >= 1e21 then num = num / 1e21
		return Library.round(num, DecimalPlaces).."Sx"
	elseif num >= 1e18 then num = num / 1e18
		return Library.round(num, DecimalPlaces).."Qi"
	elseif num >= 1e15 then num = num / 1e15
		return Library.round(num, DecimalPlaces).."Qa"
	elseif num >= 1e12 then num = num / 1e12
		return Library.round(num, DecimalPlaces).."T"
	elseif num >= 1e09 then num = num / 1e09
		return Library.round(num, DecimalPlaces).."B"
	elseif num >= 1e06 then num = num / 1e06
		return Library.round(num, DecimalPlaces).."M"
	elseif num >= 1e03 then num = num / 1e03
		return Library.round(num, DecimalPlaces).."K"
	else return num
	end
end
Library.format = function(string, ...)
	return string:format(...)
end

Library.simple_spy = function()
    msg.Mini("Purple", "Simple Spy: Loading", 2)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua"))()
end
Library.dex_explorer = function()
    msg.Mini("Purple", "Dex Explorer: Loading", 5)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Diffone7/r/refs/heads/main/tsb/dex"))()
end
Library.anti_afk = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/anti_afk.lua"))()
end
Library.fps_control = function(fps_limit)
	fps_limit = fps_limit or 5
	getgenv().idle_fps = fps_limit
    loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/fps_control.lua"))()
end

local alias_list = {
	["dist_to"] = {"distTo","DistTo","distto"},
	["teleport"] = {"teleport","tp","setpos"},
	["setup_keybinds"] = {"setupKeyBinds","KeyBinds","keybinds", "keys", "binds", "setupKeys", "setupBinds"},
	["is_moving"] = {"isMoving","IsMoving","ismoving"},
	["is_firstperson"] = {"isFirstperson","IsFirstperson","firstperson", "fp", "FP"},
	["is_alive"] = {"isAlive","IsAlive","isalive"},
	["has_value"] = {"hasValue","HasValue","hasvalue"},
	["get_ping"] = {"getPing","GetPing","getping"},
	["get_friends"] = {"getFriend","GetFriends","getfriends"},
	["join_place"] = {"joinPlace","JoinPlace","joinplace", "join", "jp"},
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
	["load_module"] = {"loadModule","LoadModule","loadmodule", "module"},
	["round"] = {"round"},
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