--[[ ════════════════════════════════════════════════════════════
  Noclipov · webhook · v2.0
  Отправка embed-уведомлений в Discord webhook.
  API: Send(title, desc, color, link) → ok, err · SendAsync(...) · Config
  Config: Username, AvatarUrl, SourceLink, IncludeUser, IncludeGame, Cooldown
════════════════════════════════════════════════════════════ ]]

-- [1] SERVICES
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")

-- [2] CONFIG
local Webhook = { Version = "2.0" }
Webhook.Link = "https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/Libs/webhook.lua"
Webhook.Config = {
	Username    = "Noclipov System",
	AvatarUrl   = "https://i.imgur.com/x4q1HDg.png",
	Author      = "Noclipov Webhook Service",
	DefaultColor = 0x825AFF,
	IncludeUser = true,  -- ник/ID локального игрока в embed
	IncludeGame = true,  -- PlaceId / JobId
	Cooldown    = 0.5,   -- минимум секунд между отправками (защита от rate limit)
}

-- [3] HELPERS
local _last = 0

local function getRequest()
	return (syn and syn.request) or http_request or request or (fluxus and fluxus.request)
end

local function buildFields()
	local C, fields = Webhook.Config, {}
	local lp = Players.LocalPlayer
	if C.IncludeUser and lp then
		fields[#fields + 1] = {
			name = "👤 User Information",
			value = string.format("• **Name:** [%s](https://www.roblox.com/users/%d)\n• **ID:** `%d`", lp.Name, lp.UserId, lp.UserId),
			inline = false,
		}
	end
	if C.IncludeGame then
		fields[#fields + 1] = {
			name = "🎮 Game Context",
			value = string.format("• **Place:** [%d](https://www.roblox.com/games/%d)\n• **JobId:** `%s`", game.PlaceId, game.PlaceId, game.JobId),
			inline = false,
		}
	end
	fields[#fields + 1] = { name = "🔗 Source", value = string.format("[GitHub Repository](%s)", Webhook.Link), inline = true }
	return fields
end

-- [4] PUBLIC API
function Webhook.Send(title: string?, desc: string?, color: number?, link: string): (boolean, string?)
	if type(link) ~= "string" or not link:match("^https://") then
		return false, "invalid webhook url"
	end
	local req = getRequest()
	if not req then return false, "executor does not support requests" end

	local C = Webhook.Config
	local wait = C.Cooldown - (os.clock() - _last)
	if wait > 0 then task.wait(wait) end
	_last = os.clock()

	local icon = C.AvatarUrl
	local ok, body = pcall(HttpService.JSONEncode, HttpService, {
		username   = C.Username,
		avatar_url = icon,
		embeds = {{
			author      = { name = C.Author, icon_url = icon, url = Webhook.Link },
			title       = title or "🔔 Notification",
			description = desc or "No description provided.",
			color       = tonumber(color) or C.DefaultColor,
			fields      = buildFields(),
			footer      = { text = "Noclipov Runtime Environment • " .. os.date("%X"), icon_url = icon },
		}},
	})
	if not ok then return false, "json encode failed" end

	local okReq, res = pcall(req, {
		Url = link, Method = "POST", Body = body,
		Headers = { ["Content-Type"] = "application/json" },
	})
	if not okReq then return false, tostring(res) end
	local code = type(res) == "table" and (res.StatusCode or res.status_code) or nil
	if code and (code < 200 or code >= 300) then return false, "http " .. tostring(code) end
	return true
end

-- Не блокирует вызывающий поток
function Webhook.SendAsync(...)
	local args = table.pack(...)
	return task.spawn(function() Webhook.Send(table.unpack(args, 1, args.n)) end)
end

return Webhook
