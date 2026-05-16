local msg = loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/notify.lua"))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WebSocketManager = {}
WebSocketManager.__index = WebSocketManager

-- Вспомогательная функция для безопасного получения имени игрока/сервера
local function getClientIdentifier()
	local success, result = pcall(function()
		if RunService:IsClient() then
			local lp = Players.LocalPlayer
			return lp and lp.Name or "Unknown Client"
		else
			local activePlayers = Players:GetPlayers()
			if #activePlayers > 0 then
				return activePlayers[1].Name
			end
			return "Server"
		end
	end)
	return success and result or "Roblox_Instance"
end

function WebSocketManager.new(url: string, idleTimeout: number?)
	local self = setmetatable({}, WebSocketManager)
	
	local cleanUrl = url:gsub("^https?://", "ws://")
	self.url = cleanUrl
	self.isConnected = false
	self.socket = nil
	self.idleTimeout = idleTimeout or 30
	self.lastActivity = os.time()
	self.isIdleClosed = false
	self.sessionStartTime = os.time()
	self.queue = {}
	
	return self
end

function WebSocketManager:_connect()
	local success, res = pcall(function()
		return (syn and syn.websocket or WebSocket).connect(self.url)
	end)

	if success then
		self.socket = res
		self.isConnected = true
		self.isIdleClosed = false
		
		-- Сообщение о подключении
		self:Send({status = "connected"})

		self.socket.OnMessage:Connect(function(message)
			self.lastActivity = os.time()
			-- Тут можно добавить обработку входящих сообщений
		end)

		self.socket.OnClose:Connect(function()
			self.isConnected = false
			self.socket = nil
		end)
	else
		warn("[WS] Не удалось подключиться: " .. tostring(res))
	end
end

function WebSocketManager:Start()
	self:_connect()
	
	-- Мониторинг простоя
	task.spawn(function()
		while true do
			task.wait(1)
			if self.isConnected and (os.time() - self.lastActivity) > self.idleTimeout then
				self.isIdleClosed = true
				self:Stop("Idle timeout reached")
			end
		end
	end)
end

function WebSocketManager:Send(customData)
	if self.isIdleClosed then
		self.isIdleClosed = false
		self:_connect()
		task.wait(0.5) -- Ждем небольшую стабилизацию
	end

	local packet = {
		player_name = getClientIdentifier(),
		place_id = tostring(game.PlaceId),
		session_start_time = self.sessionStartTime
	}

	if customData ~= nil then
		if typeof(customData) == "table" then
			for key, value in pairs(customData) do
				packet[key] = value
			end
		else
			packet["message"] = tostring(customData)
		end
	end

	local payload = nil
	local success, jsonString = pcall(function()
		return HttpService:JSONEncode(packet)
	end)
	
	if success then
		payload = jsonString
	else
		warn("[WS] Ошибка сериализации JSON.")
		return
	end
	
	if self.isConnected and self.socket then
		pcall(function() self.socket:Send(payload) end)
		self.lastActivity = os.time()
	else
		table.insert(self.queue, payload)
	end
end

function WebSocketManager:Stop(reason)
	if self.isConnected and self.socket then
		-- Отправляем финальное уведомление перед закрытием
		self:Send({
			status = "disconnected",
			reason = reason or "Manual stop"
		})
		
		-- Небольшая задержка, чтобы сообщение успело уйти в буфер отправки сокета
		task.wait(0.1) 
		
		pcall(function()
			self.socket:Close()
		end)
		self.isConnected = false
		self.socket = nil
	end
end

return WebSocketManager