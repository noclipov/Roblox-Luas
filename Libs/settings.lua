-- [[ Noclipov Settings Library v2.0 ]] --
local HttpService = game:GetService("HttpService")
local settings = {}
local _cache = {}

local function check_fs()
    return type(writefile) == "function" and type(readfile) == "function" 
       and type(isfile) == "function" and type(delfile) == "function"
end

local function ensure_ext(name)
    if type(name) ~= "string" then return nil end
    if string.sub(name, -5):lower() ~= ".json" then
        return name .. ".json"
    end
    return name
end

function settings.isfile(name)
    if not check_fs() then return false end
    local fname = ensure_ext(name)
    if not fname then return false end
    local ok, res = pcall(isfile, fname)
    return ok and res or false
end

function settings.save(name, tbl)
    if not check_fs() then return false end
    local fname = ensure_ext(name)
    if not fname or type(tbl) ~= "table" then return false end
    
    local ok, encoded = pcall(function() return HttpService:JSONEncode(tbl) end)
    if not ok or not encoded then return false end
    
    local writeOk = pcall(writefile, fname, encoded)
    if writeOk then _cache[fname] = tbl end
    return writeOk
end

function settings.get(name)
    if not check_fs() then return nil end
    local fname = ensure_ext(name)
    if not fname then return nil end
    
    if _cache[fname] then return _cache[fname] end
    if not settings.isfile(fname) then return nil end
    
    local ok, data = pcall(readfile, fname)
    if not ok or not data then return nil end
    
    local decodeOk, decoded = pcall(function() return HttpService:JSONDecode(data) end)
    if decodeOk and decoded then
        _cache[fname] = decoded
    end
    return decodeOk and decoded or nil
end

function settings.delfile(name)
    if not check_fs() then return false end
    local fname = ensure_ext(name)
    if not fname or not settings.isfile(fname) then return false end
    
    local ok = pcall(delfile, fname)
    if ok then _cache[fname] = nil end
    return ok
end

function settings.clear_cache()
    _cache = {}
end

return settings