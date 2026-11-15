--[[
    Library — shared utilities for Roblox executor scripts.

    Structure (search for section numbers to jump):
      01. Services & Constants
      02. Internal State
      03. Private Helpers  (notify, http, fs, pos, script runner)
      04. Method Registration
      05. Shared Helpers
      06. Position & Movement
      07. Character State
      08. Players
      09. Highlight
      10. Tools
      11. Chat
      12. Input & Camera
      13. Filesystem
      14. Module Loader
      15. Numbers & Formatting
      16. Teleport, Join & Scripts
      17. CoreGui
      18. External Scripts
      19. Lifecycle
      20. Initialization
]]

-- ═══════════════════════════════════════════════════════════════════════
-- 01. SERVICES & CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════
local Library = {}

local TeleportService  = game:GetService("TeleportService")
local ChatService      = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local pls = game.Players
local lp  = pls.LocalPlayer

local URLS = {
    library      = "https://raw.githubusercontent.com/noclipov/Roblox-Luas/refs/heads/main/Libs/additional.lua",
    modules_base = {
        "https://raw.githubusercontent.com/noclipov/Roblox-Luas/refs/heads/main/Libs/",
        "https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/",
    },
    try_game     = "https://raw.githubusercontent.com/noclipov/Roblox-Scripts/main/",
    simple_spy   = "https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua",
    dex          = "https://raw.githubusercontent.com/Diffone7/r/refs/heads/main/tsb/dex",
    anti_afk     = "https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/anti_afk.lua",
    fps_control  = "https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/fps_control.lua",
}

local PATHS = {
    noclipov     = "noclipov/",
    modules_root = "Noclipov",
    modules      = "Noclipov/modules/",
}

Library.Link = URLS.library

-- ═══════════════════════════════════════════════════════════════════════
-- 02. INTERNAL STATE
-- ═══════════════════════════════════════════════════════════════════════
local msg   = nil   -- populated once notify.lua finishes loading
local ready = false -- set to true after init; gates verbose notifications

local HANDLERS = {
    keybinds = "keybinds_handler",
    stretch  = "screen_stretch",
}

-- ═══════════════════════════════════════════════════════════════════════
-- 03. PRIVATE HELPERS
-- ═══════════════════════════════════════════════════════════════════════

-- Safe notify wrappers — work even before notify.lua is loaded.
local function notify(color, text, duration)
    if msg and msg.Mini then
        pcall(msg.Mini, color, text, duration)
    else
        print(("[%s] %s"):format(tostring(color), tostring(text)))
    end
end

local function notify_info(text, duration)
    duration = duration or 5
    if msg and msg.New then
        pcall(msg.New, "Purple", "Information", text, duration)
    else
        print(("[Info] %s"):format(tostring(text)))
    end
end

local function http_get(url)
    local ok, res = pcall(game.HttpGet, game, url)
    if not ok or type(res) ~= "string" or #res == 0 then return nil end
    if res:find("404: Not Found", 1, true) or res:find("<!DOCTYPE", 1, true) then return nil end
    return res
end

local function ensure_folder(path)
    path = path:gsub("/+$", "")
    if isfolder(path) then return true end
    pcall(makefolder, path)
    return isfolder(path)
end

local function normalize_noclipov_path(path)
    path = path or "test.txt"
    if not path:find("^noclipov/") then
        path = PATHS.noclipov .. path
    end
    if not (path:find("%.lua$") or path:find("%.txt$") or path:find("%.json$")) then
        path = path .. ".txt"
    end
    return path
end

local function set_handler(name, handler)
    local prev = getgenv()[name]
    if prev and typeof(prev) == "RBXScriptConnection" then
        pcall(prev.Disconnect, prev)
    end
    getgenv()[name] = handler
end

local function clear_handler(name)
    local h = getgenv()[name]
    if h and typeof(h) == "RBXScriptConnection" then
        pcall(h.Disconnect, h)
    end
    getgenv()[name] = nil
end

-- Instance | Vector3 | Player → Vector3 (or nil)
local function resolve_pos(pos)
    if typeof(pos) == "Vector3" then return pos end
    if typeof(pos) ~= "Instance" then return nil end
    if pos:IsA("BasePart") then return pos.Position end
    if pos:IsA("Model") and pos.PrimaryPart then return pos.PrimaryPart.Position end
    if pos:IsA("Player") and pos.Character and pos.Character.PrimaryPart then
        return pos.Character.PrimaryPart.Position
    end
    return nil
end

-- Compile & (optionally) execute source. Returns bool for instant=true,
-- or the compiled function for instant=false. Handles errors internally.
local function run_source(source, name, instant)
    local fn, err = loadstring(source)
    if not fn then
        notify("Coral", "Ошибка компиляции " .. name .. ": " .. tostring(err), 3)
        return false
    end
    if instant == false then
        if ready then notify("Mint", "Загружен скрипт " .. name, 1) end
        return fn
    end
    local ok, rerr = pcall(fn)
    if not ok then
        notify("Coral", "Ошибка исполнения " .. name .. ": " .. tostring(rerr), 3)
        return false
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════
-- 04. METHOD REGISTRATION
-- ═══════════════════════════════════════════════════════════════════════
-- Регистрирует метод и его алиасы. Алиасы не перезаписывают занятые имена.
local function register(name, fn, aliases)
    Library[name] = fn
    if not aliases then return end
    for _, alias in ipairs(aliases) do
        if Library[alias] == nil then
            Library[alias] = fn
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- 05. SHARED HELPERS
-- ═══════════════════════════════════════════════════════════════════════
local function get_character()
    local char = lp.Character
    if char and char.PrimaryPart then return char end
    return nil
end
register("get_character", get_character)

-- ═══════════════════════════════════════════════════════════════════════
-- 06. POSITION & MOVEMENT
-- ═══════════════════════════════════════════════════════════════════════
register("dist_to", function(pos)
    local char = get_character()
    if not char or not pos then return end
    pos = resolve_pos(pos)
    if not pos then return 0 end
    return math.floor((char.PrimaryPart.Position - pos).Magnitude)
end, {"distTo", "DistTo", "distto"})

register("teleport", function(pos, spread)
    local char = get_character()
    if not char then return end
    pos = resolve_pos(pos)
    if not pos then return end
    spread = spread or 0
    local prev = char.PrimaryPart.CFrame
    local x = spread > 0 and (pos.X + math.random(-spread, spread)) or pos.X
    local z = spread > 0 and (pos.Z + math.random(-spread, spread)) or pos.Z
    char.PrimaryPart.CFrame = CFrame.new(x, pos.Y, z)
    return prev
end, {"tp", "setpos"})

register("inside_cube", function(point, cube)
    if not cube then return false end
    point = point or (lp.Character and lp.Character.PrimaryPart)
    if not point then return false end
    local pos = resolve_pos(point)
    if not pos then return false end
    local rel = cube.CFrame:PointToObjectSpace(pos)
    return math.abs(rel.X) <= cube.Size.X / 2
        and math.abs(rel.Y) <= cube.Size.Y / 2
        and math.abs(rel.Z) <= cube.Size.Z / 2
end, {"insideCube", "InsideCube", "insidecube"})

-- ═══════════════════════════════════════════════════════════════════════
-- 07. CHARACTER STATE
-- ═══════════════════════════════════════════════════════════════════════
register("is_moving", function(humanoid)
    if not humanoid then return false end
    return humanoid.MoveDirection.Magnitude > 0
end, {"isMoving", "IsMoving", "ismoving"})

register("is_firstperson", function()
    return lp:DistanceFromCharacter(workspace.CurrentCamera.CFrame.Position) < 1
end, {"isFirstperson", "IsFirstperson", "firstperson", "fp", "FP"})

register("is_alive", function(ply)
    ply = ply or lp
    if not ply.Character then return false end
    local humanoid = ply.Character:FindFirstChild("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0
end, {"isAlive", "IsAlive", "isalive"})

-- ═══════════════════════════════════════════════════════════════════════
-- 08. PLAYERS
-- ═══════════════════════════════════════════════════════════════════════
register("get_ping", function()
    -- GetNetworkPing returns seconds; ×1000 → ms
    return math.floor(lp:GetNetworkPing() * 1000)
end, {"getPing", "GetPing", "getping"})

register("get_friends", function(player)
    player = player or lp
    local friends = {}
    if not player then return friends end
    for _, v in ipairs(pls:GetPlayers()) do
        if v ~= player then
            local ok, is_friend = pcall(function() return player:IsFriendsWith(v.UserId) end)
            if ok and is_friend then
                table.insert(friends, v)
            end
        end
    end
    return friends
end, {"getFriend", "GetFriends", "getfriends"})

-- ═══════════════════════════════════════════════════════════════════════
-- 09. HIGHLIGHT
-- ═══════════════════════════════════════════════════════════════════════
register("hl_player", function(ply, fill, outline, fill_t, outline_t, depth)
    if not ply.Character then return end
    local hl = ply.Character:FindFirstChild("U_Highlight") or Instance.new("Highlight")
    hl.Name               = "U_Highlight"
    hl.Parent             = ply.Character
    hl.Adornee            = ply.Character
    hl.FillColor          = fill    or Color3.fromRGB(0, 0, 0)
    hl.OutlineColor       = outline or Color3.fromRGB(255, 255, 255)
    hl.DepthMode          = depth   or Enum.HighlightDepthMode.Occluded
    hl.FillTransparency   = fill_t  or 0
    hl.OutlineTransparency = outline_t or 0
    return hl
end, {"hlPlayer", "HLPlayer", "hlplayer", "hl", "HL"})

register("unhl_player", function(ply)
    if not ply.Character then return end
    local hl = ply.Character:FindFirstChild("U_Highlight")
    if hl then hl:Destroy() end
end, {"unhlPlayer", "UnHLPlayer", "unhlplayer", "unhl", "unHL"})

-- ═══════════════════════════════════════════════════════════════════════
-- 10. TOOLS
-- ═══════════════════════════════════════════════════════════════════════
register("equip_tool", function(name, instance)
    local char = lp.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local tool = instance or (name and lp.Backpack:FindFirstChild(name))
    if tool then
        humanoid:EquipTool(tool)
    elseif not name and not instance then
        humanoid:UnequipTools()
    end
end, {"equipTool", "EquipTool", "equiptool"})

register("remove_tool", function(name, instance)
    local tool = instance or (name and lp.Backpack:FindFirstChild(name))
    if tool then tool:Destroy() end
end, {"removeTool", "RemoveTool", "removetool"})

-- ═══════════════════════════════════════════════════════════════════════
-- 11. CHAT
-- ═══════════════════════════════════════════════════════════════════════
local function get_chat_channel()
    local channels = ChatService:FindFirstChild("TextChannels")
    return channels and channels:FindFirstChild("RBXGeneral")
end

register("chat", function(text)
    local channel = get_chat_channel()
    if channel then channel:SendAsync(text) end
end, {"Chat", "send_message", "SendMessage", "sendMessage", "message", "Message"})

register("chat_filter", function(callback, isfilter)
    if not (ChatService and ChatService.ChatVersion == Enum.ChatVersion.TextChatService) then return end
    if isfilter then
        ChatService.OnIncomingMessage = function(textMessage)
            local display, filtered = callback(textMessage, textMessage.TextSource)
            if display == false then
                textMessage.Text = ""
            elseif filtered then
                textMessage.Text = filtered
            end
        end
    else
        local channel = get_chat_channel()
        if channel then channel.ShouldDeliverCallback = callback end
    end
end, {"filter", "ChatFilter", "chatFilter", "chatfilter"})

-- ═══════════════════════════════════════════════════════════════════════
-- 12. INPUT & CAMERA
-- ═══════════════════════════════════════════════════════════════════════
register("setup_keybinds", function(keybinds)
    local laststate = getgenv()[HANDLERS.keybinds] ~= nil
    local keys = {}
    for key, data in pairs(keybinds) do
        if type(data) == "table" and data.callback then
            table.insert(keys, key)
        end
    end

    set_handler(HANDLERS.keybinds, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local data = keybinds[input.KeyCode.Name]
        if not data or not data.callback then return end
        if data.gpc and gameProcessed then return end
        pcall(data.callback)
    end))

    notify_info((laststate and "Updated keybinds are: %s" or "Available keybinds are: %s")
        :format(table.concat(keys, " | ")))
end, {"setupKeyBinds", "KeyBinds", "keybinds", "keys", "binds", "setupKeys", "setupBinds"})

register("screen_stretch", function(value)
    clear_handler(HANDLERS.stretch)
    if not value then return end
    value = math.clamp(value, 0, 1)
    set_handler(HANDLERS.stretch, RunService.RenderStepped:Connect(function()
        workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame
            * CFrame.new(0, 0, 0, 1, 0, 0, 0, value, 0, 0, 0, 1)
    end))
end, {"stretch", "screenstretch", "ScreenStretch", "Screenstretch", "screenStretch"})

-- ═══════════════════════════════════════════════════════════════════════
-- 13. FILESYSTEM
-- ═══════════════════════════════════════════════════════════════════════
register("check_noclipov", function(file)
    if not file then return isfolder((PATHS.noclipov:gsub("/+$", ""))) end
    return isfile(normalize_noclipov_path(file))
end)

register("load_file", function(path, silent, instant)
    path = normalize_noclipov_path(path)
    if not isfile(path) then return false end
    local ok, content = pcall(readfile, path)
    if not ok then
        notify("Coral", "Не удалось прочитать файл " .. path, 3)
        return false
    end
    if not silent and ready then notify("Mint", "Загружаем " .. path, 1) end
    return run_source(content, path, instant ~= false)
end, {"loadFile", "LoadFile", "loadfile", "load"})

register("write_file", function(path, content, rewrite)
    path    = normalize_noclipov_path(path or "test.txt")
    content = content or "test text for no reason"
    if rewrite or not isfile(path) then
        writefile(path, content)
    else
        appendfile(path, content)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 14. MODULE LOADER
-- ═══════════════════════════════════════════════════════════════════════
local function ensure_module_dirs(module_name)
    ensure_folder(PATHS.modules_root)
    ensure_folder(PATHS.modules)
    local sub = module_name:match("^(.*)/[^/]+$")
    if sub then ensure_folder(PATHS.modules .. sub) end
end

local function read_cached(path)
    if not isfile(path) then return nil end
    local ok, content = pcall(readfile, path)
    if ok and type(content) == "string" and #content > 0 then return content end
    return nil
end

local function download_module(module_name)
    for _, base in ipairs(URLS.modules_base) do
        local source = http_get(base .. module_name)
        if source then return source end
    end
    return nil
end

register("load_module", function(module_name, instant, force_update)
    module_name  = module_name  or "additional.lua"
    instant      = instant      or false
    force_update = force_update or false

    ensure_module_dirs(module_name)
    local local_path = PATHS.modules .. module_name

    local source, from_cache = nil, false
    if not force_update then
        source     = read_cached(local_path)
        from_cache = source ~= nil
    end

    if not source then
        source = download_module(module_name)
        if not source then
            notify("Coral", "Не удалось скачать модуль " .. module_name, 3)
            return false
        end
        if not pcall(writefile, local_path, source) then
            notify("Coral", "Не удалось сохранить кэш модуля " .. module_name, 3)
        end
    end

    if instant then
        local fn, err = loadstring(source)
        if not fn then
            notify("Coral", "Ошибка компиляции модуля " .. module_name .. ": " .. tostring(err), 3)
            return false
        end
        local ok, result = pcall(fn)
        if ok then return result end
        notify("Coral", "Ошибка исполнения " .. module_name .. ": " .. tostring(result), 3)
        return fn
    end

    if ready then
        notify("Mint", "Загружен модуль " .. module_name ..
            (from_cache and " (cache)" or " (GitHub)"), 1)
    end

    local fn, err = loadstring(source)
    if not fn then
        notify("Coral", "Ошибка компиляции модуля " .. module_name .. ": " .. tostring(err), 3)
        return false
    end
    return fn
end, {"loadModule", "LoadModule", "loadmodule", "module"})
Library.module("additional.lua", false, true)

-- ═══════════════════════════════════════════════════════════════════════
-- 15. NUMBERS & FORMATTING
-- ═══════════════════════════════════════════════════════════════════════
local function round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end
register("round", round)

register("to_letters", function(num, decimals)
    decimals = decimals or 0
    if     num >= 1e42 then return round(num / 1e42, decimals) .. "TDc"
    elseif num >= 1e39 then return round(num / 1e39, decimals) .. "DDc"
    elseif num >= 1e36 then return round(num / 1e36, decimals) .. "UDc"
    elseif num >= 1e33 then return round(num / 1e33, decimals) .. "Dc"
    elseif num >= 1e30 then return round(num / 1e30, decimals) .. "No"
    elseif num >= 1e27 then return round(num / 1e27, decimals) .. "Oc"
    elseif num >= 1e24 then return round(num / 1e24, decimals) .. "Sp"
    elseif num >= 1e21 then return round(num / 1e21, decimals) .. "Sx"
    elseif num >= 1e18 then return round(num / 1e18, decimals) .. "Qi"
    elseif num >= 1e15 then return round(num / 1e15, decimals) .. "Qa"
    elseif num >= 1e12 then return round(num / 1e12, decimals) .. "T"
    elseif num >= 1e09 then return round(num / 1e09, decimals) .. "B"
    elseif num >= 1e06 then return round(num / 1e06, decimals) .. "M"
    elseif num >= 1e03 then return round(num / 1e03, decimals) .. "K"
    else return num
    end
end, {"toLetters", "ToLetters", "toletters", "Letters", "letters"})

register("format", function(str, ...)
    return str:format(...)
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 16. TELEPORT, JOIN & SCRIPTS
-- ═══════════════════════════════════════════════════════════════════════
register("join_place", function(placeid, jobid)
    placeid = placeid or game.PlaceId
    jobid   = jobid and tostring(jobid) or jobid
    local ok, err
    if jobid then
        ok, err = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, placeid, jobid, lp)
    else
        ok, err = pcall(TeleportService.Teleport, TeleportService, placeid, lp)
    end
    if not ok then notify("Coral", "Teleport failed: " .. tostring(err), 3) end
end, {"joinPlace", "JoinPlace", "joinplace", "join", "jp"})

register("get_teleport", function()
    setclipboard(("game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game.Players.LocalPlayer)")
        :format(tostring(game.PlaceId), game.JobId))
end, {"getTeleport", "GetTeleport", "getteleport"})

-- Как try_game, но принимает имя скрипта. instant == false → вернуть функцию.
register("try_game", function(instant)
    local source = http_get(URLS.try_game .. game.PlaceId .. ".lua")
    if not source then
        notify("Coral", "Скрипт для этой игры не найден", 3)
        return false
	else
		notify("Mint", "Скрипт найден", 3)
    end
    return run_source(source, "game(" .. tostring(game.PlaceId) .. ")", instant ~= false)
end)

-- load_script("farm") → скачает .../main/farm.lua и запустит.
-- load_script("farm", false) → вернёт скомпилированную функцию.
register("load_script", function(name, instant)
    if not name or name == "" then
        notify("Coral", "load_script: не указано имя", 3)
        return false
    end
    name = tostring(name)
    if not (name:find("%.lua$") or name:find("%.txt$")) then
        name = name .. ".lua"
    end
    local source = http_get(URLS.try_game .. name)
    if not source then
        notify("Coral", "Скрипт не найден: " .. name, 3)
        return false
    end
    -- по умолчанию — как try_game: сразу исполняем
    return run_source(source, name, instant == nil and true or instant)
end, {"loadScript", "LoadScript", "loadscript", "run_script", "runScript", "runscript", "script"})

-- ═══════════════════════════════════════════════════════════════════════
-- 17. COREGUI
-- ═══════════════════════════════════════════════════════════════════════
register("toggle_coregui", function(coregui, state)
    pcall(game.StarterGui.SetCoreGuiEnabled, game.StarterGui, coregui, state)
end, {"toggleCG", "toggleCoreGui", "CoreGui", "coregui"})

-- ═══════════════════════════════════════════════════════════════════════
-- 18. EXTERNAL SCRIPTS
-- ═══════════════════════════════════════════════════════════════════════
local function run_remote(url, label)
    local source = http_get(url)
    if not source then
        notify("Coral", (label or url) .. ": не удалось скачать", 3)
        return false
    end
    return run_source(source, label or url, true)
end

register("simple_spy", function()
    notify("Purple", "Simple Spy: Loading", 2)
    return run_remote(URLS.simple_spy, "SimpleSpy")
end, {"simpleSpy", "SimpleSpy", "simplespy", "ss"})

register("dex_explorer", function()
    notify("Purple", "Dex Explorer: Loading", 5)
    return run_remote(URLS.dex, "Dex")
end, {"dexExplorer", "DexExplorer", "dexexplorer", "de"})

register("anti_afk", function()
    return run_remote(URLS.anti_afk, "AntiAFK")
end, {"antiAFK", "AntiAFK", "antiafk", "afk"})

register("fps_control", function(fps_limit)
    getgenv().idle_fps = fps_limit or 5
    return run_remote(URLS.fps_control, "FPSControl")
end, {"fpsControl", "FPSControl", "fpscontrol", "fps"})

-- ═══════════════════════════════════════════════════════════════════════
-- 19. LIFECYCLE
-- ═══════════════════════════════════════════════════════════════════════
register("unload_all", function()
    clear_handler(HANDLERS.keybinds)
    clear_handler(HANDLERS.stretch)
end)

-- ═══════════════════════════════════════════════════════════════════════
-- 20. INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════
do
    local ok, mod = pcall(Library.load_module, "notify.lua", true)
    if ok and type(mod) == "table" then
        msg = mod
    end
    ready = true
end

return Library