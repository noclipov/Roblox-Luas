--[[ ════════════════════════════════════════════════════════════
  Noclipov · settings · v3.0
  JSON-хранилище настроек с кэшем.
  API: save(name, tbl) · get(name) · load(name, defaults) · update(name, patch, defaults?)
       isfile(name) · delfile(name) · clear_cache()
  Обратно совместимо с v2.0 (isfile/save/get/delfile/clear_cache).
════════════════════════════════════════════════════════════ ]]

-- [1] SERVICES
local HttpService = game:GetService("HttpService")

-- [2] MODULE
local settings = { Version = "3.0" }
local _cache: { [string]: any } = {}

-- [3] HELPERS
local function fsReady(): boolean
	return type(writefile) == "function" and type(readfile) == "function"
		and type(isfile) == "function" and type(delfile) == "function"
end

local function filename(name: any): string?
	if type(name) ~= "string" or name == "" then return nil end
	return name:sub(-5):lower() == ".json" and name or (name .. ".json")
end

-- Создаёт недостающие папки для "a/b/c.json"
local function ensureFolders(path: string)
	if type(makefolder) ~= "function" or type(isfolder) ~= "function" then return end
	local acc = ""
	for part in path:gmatch("([^/\\]+)[/\\]") do
		acc = acc == "" and part or (acc .. "/" .. part)
		if not isfolder(acc) then pcall(makefolder, acc) end
	end
end

-- Рекурсивно дополняет dst недостающими ключами из defaults (dst приоритетнее)
local function fill(dst: any, defaults: any): any
	if type(dst) ~= "table" then return defaults end
	for k, v in pairs(defaults) do
		if dst[k] == nil then
			dst[k] = type(v) == "table" and fill({}, v) or v
		elseif type(v) == "table" and type(dst[k]) == "table" then
			fill(dst[k], v)
		end
	end
	return dst
end

-- [4] PUBLIC API
function settings.isfile(name): boolean
	local f = filename(name)
	if not f or not fsReady() then return false end
	local ok, res = pcall(isfile, f)
	return ok and res == true
end

function settings.save(name, tbl): boolean
	local f = filename(name)
	if not f or type(tbl) ~= "table" or not fsReady() then return false end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, tbl)
	if not ok then return false end
	ensureFolders(f)
	if not pcall(writefile, f, encoded) then return false end
	_cache[f] = tbl
	return true
end

function settings.get(name): any?
	local f = filename(name)
	if not f or not fsReady() then return nil end
	if _cache[f] then return _cache[f] end
	if not settings.isfile(f) then return nil end
	local ok, data = pcall(readfile, f)
	if not ok or not data then return nil end
	local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, data)
	if okDecode and type(decoded) == "table" then
		_cache[f] = decoded
		return decoded
	end
	return nil
end

-- Прочитать файл и дополнить значениями по умолчанию (файл не перезаписывается)
function settings.load(name, defaults: { [string]: any }?): { [string]: any }
	local data = settings.get(name)
	if not defaults then return data or {} end
	return fill(data or {}, defaults)
end

-- Прочитать → наложить patch → сохранить. Возвращает итоговую таблицу
function settings.update(name, patch: { [string]: any }, defaults: { [string]: any }?)
	local data = settings.load(name, defaults)
	for k, v in pairs(patch) do data[k] = v end
	settings.save(name, data)
	return data
end

function settings.delfile(name): boolean
	local f = filename(name)
	if not f or not settings.isfile(f) then return false end
	if not pcall(delfile, f) then return false end
	_cache[f] = nil
	return true
end

function settings.clear_cache()
	table.clear(_cache)
end

return settings
