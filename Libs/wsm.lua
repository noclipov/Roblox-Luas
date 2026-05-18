while not game.IsLoaded do task.wait() end
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
	if not cleanUrl:match("^wss?://") then
		local isLocal = cleanUrl:match("^192%.168%.") or cleanUrl:match("^127%.0%.0%.1") or cleanUrl:match("^localhost")
		local protocol = isLocal and "ws://" or "wss://"
		cleanUrl = protocol .. cleanUrl
	end
	self.url = cleanUrl
	self.isConnected = false
	self.socket = nil
	self.idleTimeout = idleTimeout or 30
	self.lastActivity = os.time()
	self.isConnecting = false
	self.isManuallyClosed = false
	self.isIdleClosed = false

	self.queue = {}
	self._cleanupConnections = {}
	self:_setupLeaveListeners()

	self.sessionStartTime = os.time()
	
	return self
end

-- Настройка автоматического закрытия при выходе игрока
function WebSocketManager:_setupLeaveListeners()
	-- Если игрок отключается от сервера (включая телепортацию в другой плейс)
	local leaveConn = Players.PlayerRemoving:Connect(function(player)
		if player == Players.LocalPlayer then
			self:Stop()
		end
	end)
	table.insert(self._cleanupConnections, leaveConn)
end

-- Внутренний поток мониторинга активности (таймаут)
function WebSocketManager:_startIdleTracker()
	if self.idleTrackerActive then return end
	self.idleTrackerActive = true
	
	task.spawn(function()
		while self.isConnected and not self.isManuallyClosed do
			task.wait(1)
			local elapsed = os.time() - self.lastActivityTime
			if elapsed >= self.idleTimeout then
				msg.New("Coral", "WebSocketManager", "Соединение простаивает более " .. self.idleTimeout .. " сек. Переход в спящий режим...", 3)
				self.isIdleClosed = true
				self:_shutdownSocket()
				break
			end
		end
		self.idleTrackerActive = false
	end)
end

-- Внутренний метод физического закрытия сокета
function WebSocketManager:_shutdownSocket()
	self.isConnected = false
	if self.socket then
		pcall(function()
			self.socket:Close()
		end)
		self.socket = nil
	end
end

function WebSocketManager:_connect()
	if self.isConnected or self.isConnecting or self.isManuallyClosed then return end
	self.isConnecting = true
	local success, ws = pcall(function()
		return (syn and syn.websocket or WebSocket).connect(self.url)
	end)
	self.isConnecting = false

	if success then
		self.socket = ws
		self.isConnected = true
		self.isIdleClosed = false
		if not self.sessionStartTime then
			self.sessionStartTime = os.time()
		end
		self:Send({status = "connected"})
		-- self.socket.OnMessage:Connect(function(message)
		-- 	self.lastActivity = os.time()
		-- 	-- Тут можно добавить обработку входящих сообщений
		-- end)
		msg.Mini("Mint", "[WS] Соединение успешно установлено!", 1.5)
		self:_startIdleTracker()
		task.spawn(function() self:_flushQueue() end)

		if ws.OnClose then
			local connected = pcall(function()
				ws.OnClose:Connect(function()
					self:_handleDisconnect()
				end)
			end)
			if not connected then
				pcall(function()
					ws.OnClose = function()
						self:_handleDisconnect()
					end
				end)
			end
		end
	else
		if self.isManuallyClosed or self.isIdleClosed then return end
		local errorMsg = tostring(ws or "Unknown Error")
		warn("[WS] Ошибка соединения (" .. errorMsg .. "). Повторная попытка через 5 секунд...")
		task.wait(5)
		if not self.isManuallyClosed and not self.isIdleClosed then
			self:_connect()
		end
	end
end

-- Обработчик разрыва связи
function WebSocketManager:_handleDisconnect()
	self.isConnected = false
	self.socket = nil
	
	if self.isManuallyClosed or self.isIdleClosed then
		return
	end
	
	msg.New("Coral", "WebSocketManager", "Соединение потеряно! Автореконнект через 5 секунд...", 5)
	task.wait(5)
	if not self.isManuallyClosed and not self.isIdleClosed then
		self:_connect()
	end
end

function WebSocketManager:Start()
	self.isManuallyClosed = false
	self.isIdleClosed = false
	task.spawn(function()
		self:_connect()
	end)
end

function WebSocketManager:Send(customData)
	if self.isManuallyClosed then return end
	self.lastActivityTime = os.time()
	if self.isIdleClosed and not self.isConnected and not self.isConnecting then
		self.isIdleClosed = false
		task.spawn(function()
			self:_connect()
		end)
	end

	local packet = {
		player_name = getClientIdentifier(),
		place_id = tostring(game.PlaceId),
		session_start_time = self.sessionStartTime or os.time()
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
	
	-- 3. Безопасная отправка или удержание в очереди
	if self.isConnected and self.socket then
		local sendSuccess, sendErr = pcall(function()
			self.socket:Send(payload)
		end)
		if not sendSuccess then
			warn("[WS ERROR] Ошибка отправки. Пакет помещен в буфер: " .. tostring(sendErr))
			self.isConnected = false
			table.insert(self.queue, payload)
			task.spawn(function() self:_handleDisconnect() end)
		end
	else
		table.insert(self.queue, payload)
	end
end

function WebSocketManager:Stop()
	if self.isConnected and self.socket then
		self:Send({
			status = "disconnected",
		})
		task.wait(0.1) 
		
		for _, conn in ipairs(self._cleanupConnections) do
			if conn then
				pcall(function() conn:Disconnect() end)
			end
		end
		table.clear(self._cleanupConnections)
		table.clear(self.queue)
		self:_shutdownSocket()
		self.isManuallyClosed = true
		self.isConnecting = false
		self.isConnected = false
		self.isIdleClosed = false
		self.sessionStartTime = nil
	end
end

function WebSocketManager:_flushQueue()
	if #self.queue == 0 then return end
	-- print("[WS] Отправка сохраненных пакетов из буфера: " .. #self.queue)
	
	local tempQueue = {}
	for _, payload in ipairs(self.queue) do
		table.insert(tempQueue, payload)
	end
	table.clear(self.queue)
	
	for _, payload in ipairs(tempQueue) do
		if self.isConnected and self.socket then
			local sendSuccess = pcall(function()
				self.socket:Send(payload)
			end)
			if not sendSuccess then
				table.insert(self.queue, payload)
				self.isConnected = false
				break
			end
		else
			table.insert(self.queue, payload)
		end
	end
end
return WebSocketManager