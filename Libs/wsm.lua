while not game.IsLoaded do task.wait() end
local msg = loadstring(game:HttpGet("https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/notify.lua"))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

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
	-- Проверяем, существует ли уже запущенный менеджер в глобальной среде эксплойта
	local sharedEnv = getgenv and getgenv() or _G
	if sharedEnv.__ActiveWebSocketManager then
		pcall(function()
			-- Жестко закрываем старый сокет предыдущего запуска скрипта
			sharedEnv.__ActiveWebSocketManager:Stop()
		end)
		sharedEnv.__ActiveWebSocketManager = nil
		task.wait(0.2) -- Короткая пауза, чтобы порт гарантированно освободился
	end

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
	
	-- Сохраняем текущий инстанс, чтобы следующий запуск его «выбил»
	sharedEnv.__ActiveWebSocketManager = self
	
	return self
end

function WebSocketManager:_setupLeaveListeners()
	local leaveConn = Players.PlayerRemoving:Connect(function(player)
		if player == Players.LocalPlayer then
			self:Stop()
		end
	end)
	table.insert(self._cleanupConnections, leaveConn)

	local errorConn = GuiService.ErrorMessageChanged:Connect(function(errorMessage, errorType)
		if errorMessage and errorMessage ~= "" then
			pcall(function()
				if self.isConnected and self.socket and typeof(self.socket) == "table" then
					self:Send({
						status = "disconnected",
						reason = "game_error_or_kick",
						details = errorMessage
					})
					task.wait(0.05)
				end
			end)
			self:Stop()
		end
	end)
	table.insert(self._cleanupConnections, errorConn)
end

function WebSocketManager:_startIdleTracker()
	if self.idleTrackerActive then return end
	self.idleTrackerActive = true
	
	task.spawn(function()
		while self.isConnected and not self.isManuallyClosed do
			task.wait(1)
			local elapsed = os.time() - (self.lastActivity or os.time())
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

function WebSocketManager:_shutdownSocket()
	self.isConnected = false
	if self.socket then
		pcall(function()
			if typeof(self.socket) == "table" and self.socket.Close then
				self.socket:Close()
			elseif typeof(self.socket) == "function" then
				-- Если сокет внезапно остался функцией (на всякий случай)
				self.socket("close")
			end
		end)
		self.socket = nil
	end
end

function WebSocketManager:_connect()
	if self.isManuallyClosed then return end
	if self.isConnecting then return end

	if self.isConnected or self.socket then
		self:_shutdownSocket()
	end

	self.isConnecting = true
	
	local success, ws = pcall(function()
		-- Находим саму таблицу библиотеки сокетов
		local wsLibrary = (syn and syn.websocket) or WebSocket
		if not wsLibrary then
			error("WebSocket API полностью отсутствует в вашем эксплойте.")
		end
		
		-- Ищем правильный метод подключения (connect, Connect, new)
		local connectMethod = wsLibrary.connect or wsLibrary.Connect or wsLibrary.new
		if not connectMethod or typeof(connectMethod) ~= "function" then
			error("Библиотека WebSocket найдена, но метод подключения (.connect/.Connect/.new) отсутствует.")
		end
		
		-- Вызываем метод напрямую от таблицы, если это конструктор типа .new
		return connectMethod(self.url)
	end)
	
	self.isConnecting = false

	if success and ws then
		-- ФИКС: Если пришел не объект (таблица/userdata), а функция/прочее,
		-- пробуем адаптировать под стандартный объект.
		if typeof(ws) == "function" then
			warn("[WS] Получена функция вместо объекта. Попытка нормализации...")
			local rawWs = ws
			ws = {
				Send = function(_, msg) rawWs("send", msg) end,
				Close = function(_) rawWs("close") end,
				OnClose = {
					Connect = function(_, callback)
						task.spawn(function()
							while task.wait(1) do
								-- Логика проверки (заглушка)
							end
						end)
					end
				}
			}
		end

		self.socket = ws
		self.isConnected = true
		self.isIdleClosed = false
		if not self.sessionStartTime then
			self.sessionStartTime = os.time()
		end
		self.lastActivity = os.time()

		-- Базовый пакет успешного подключения
		self:Send({
			status = "connected"
		})

		msg.Mini("Mint", "[WS] Соединение успешно установлено!", 1.5)
		self:_startIdleTracker()
		task.spawn(function() self:_flushQueue() end)

		-- Безопасная проверка OnClose
		if typeof(ws) == "table" or typeof(ws) == "userdata" then
			local onCloseEvent = ws.OnClose or ws.onClose
			if onCloseEvent then
				local connected = pcall(function()
					if typeof(onCloseEvent) == "table" and onCloseEvent.Connect then
						onCloseEvent:Connect(function()
							self:_handleDisconnect()
						end)
						return true
					end
					return false
				end)
				
				if not connected then
					pcall(function()
						ws.OnClose = function()
							if self.socket == ws then
								self:_handleDisconnect()
							end
						end
					end)
				end
			end
		end
	else
		self.isConnected = false
		if self.isManuallyClosed or self.isIdleClosed then return end
		
		local errorMsg = tostring(ws or "Unknown Error")
		warn("[WS] Ошибка соединения (" .. errorMsg .. "). Повторная попытка через 5 секунд...")
		
		task.wait(5)
		if not self.isManuallyClosed and not self.isIdleClosed then
			self:_connect()
		end
	end
end

function WebSocketManager:_handleDisconnect()
	self.isConnected = false
	self.socket = nil
	
	if self.isManuallyClosed or self.isIdleClosed then return end
	
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
	self.lastActivity = os.time()
	
	if self.isIdleClosed and not self.isConnected and not self.isConnecting then
		self.isIdleClosed = false
		task.spawn(function() self:_connect() end)
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
	
	if self.isConnected and self.socket and typeof(self.socket) == "table" and self.socket.Send then
		local sendSuccess, sendErr = pcall(function()
			self.socket:Send(payload)
		end)
		if not sendSuccess then
			warn("[WS ERROR] Ошибка отправки. Буферизация: " .. tostring(sendErr))
			self.isConnected = false
			table.insert(self.queue, payload)
			task.spawn(function() self:_handleDisconnect() end)
		end
	else
		table.insert(self.queue, payload)
	end
end

function WebSocketManager:Stop()
	pcall(function()
		if self.isConnected and self.socket and typeof(self.socket) == "table" then
			self:Send({ status = "disconnected" })
			task.wait(0.05)
		end
	end)
	
	self:_shutdownSocket()
	
	for _, conn in ipairs(self._cleanupConnections) do
		if conn then pcall(function() conn:Disconnect() end) end
	end
	table.clear(self._cleanupConnections)
	table.clear(self.queue)
	
	self.isManuallyClosed = true
	self.isConnecting = false
	self.isConnected = false
	self.isIdleClosed = false
	self.sessionStartTime = nil
	
	local sharedEnv = getgenv and getgenv() or _G
	if sharedEnv.__ActiveWebSocketManager == self then
		sharedEnv.__ActiveWebSocketManager = nil
	end
end

function WebSocketManager:_flushQueue()
	if #self.queue == 0 then return end
	
	local tempQueue = {}
	for _, payload in ipairs(self.queue) do table.insert(tempQueue, payload) end
	table.clear(self.queue)
	
	for _, payload in ipairs(tempQueue) do
		if self.isConnected and self.socket and typeof(self.socket) == "table" and self.socket.Send then
			local sendSuccess = pcall(function() self.socket:Send(payload) end)
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