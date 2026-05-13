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
			-- Если скрипт на сервере, берем первого игрока или пишем "Server"
			local activePlayers = Players:GetPlayers()
			if #activePlayers > 0 then
				return activePlayers[1].Name
			end
			return "Server"
		end
	end)
	return success and result or "Roblox_Instance"
end

-- Конструктор модуля
-- @param url - Полный адрес вебсокета
-- @param idleTimeout - Время простоя в секундах до автозакрытия (по умолчанию 30)
function WebSocketManager.new(url: string, idleTimeout: number?)
	local self = setmetatable({}, WebSocketManager)
	
	-- Валидация протокола
	local cleanUrl = url:gsub("^https?://", "ws://")
	if not cleanUrl:match("^wss?://") then
		local isLocal = cleanUrl:match("^192%.168%.") or cleanUrl:match("^127%.0%.0%.1") or cleanUrl:match("^localhost")
		local protocol = isLocal and "ws://" or "wss://"
		cleanUrl = protocol .. cleanUrl
	end
	
	self.url = cleanUrl
	self.socket = nil
	self.isConnected = false
	self.isConnecting = false
	self.isManuallyClosed = false
	
	-- Метка первого успешного подключения для расчета uptime на сервере
	self.sessionStartTime = nil
	
	-- Настройки таймаута активности
	self.idleTimeout = idleTimeout or 30
	self.lastActivityTime = os.time()
	self.isIdleClosed = false -- Флаг "спящего" режима
	
	self.queue = {}
	self._cleanupConnections = {} -- Хранилище для системных подключений
	
	-- Инициализация системных слушателей для автозакрытия
	self:_setupLeaveListeners()
	
	return self
end

-- Настройка автоматического закрытия при выходе игрока
function WebSocketManager:_setupLeaveListeners()
	-- Если игрок отключается от сервера (включая телепортацию в другой плейс)
	local leaveConn = Players.PlayerRemoving:Connect(function(player)
		local isTarget = false
		if RunService:IsClient() then
			isTarget = (player == Players.LocalPlayer)
		end

		if isTarget then
			warn("[WS] Локальный игрок покидает игру (или телепортируется). Закрытие соединения...")
			self:Close()
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
				msg.New("Coral", "WebSocketManager", "Соединение простаивает более " .. self.idleTimeout .. " сек. Переход в спящий режим...", 5)
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

-- Внутренний метод аппаратного подключения
function WebSocketManager:_connect()
	if self.isConnected or self.isConnecting or self.isManuallyClosed then return end
	self.isConnecting = true
	
	warn("[WS] Подключение к: " .. self.url)
	
	local success, ws = pcall(function()
		if WebSocket and WebSocket.connect then
			return WebSocket.connect(self.url)
		elseif syn and syn.websocket and syn.websocket.connect then
			return syn.websocket.connect(self.url)
		else
			error("[WS] Среда выполнения не поддерживает WebSocket API.")
		end
	end)
	
	self.isConnecting = false
	
	if success and ws then
		self.socket = ws
		self.isConnected = true
		self.isIdleClosed = false
		self.lastActivityTime = os.time()
		
		-- Запоминаем время ПЕРВОГО успешного подключения в формате Unixtimestamp
		if not self.sessionStartTime then
			self.sessionStartTime = os.time()
		end
		
		msg.Mini("Mint", "[WS] Соединение успешно установлено!", 3)
		
		self:_startIdleTracker()
		
		task.spawn(function()
			self:_flushQueue()
		end)
		
		-- Безопасная подписка на закрытие
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

-- Старт сессии
function WebSocketManager:Start()
	self.isManuallyClosed = false
	self.isIdleClosed = false
	task.spawn(function()
		self:_connect()
	end)
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

-- Полная принудительная остановка
function WebSocketManager:Close()
	self.isManuallyClosed = true
	self.isConnecting = false
	self.isConnected = false
	self.isIdleClosed = false
	
	-- Сбрасываем метку аптайма, чтобы при новом :Start() сессия считалась чистой
	self.sessionStartTime = nil
	
	-- Отключаем все внутренние события слежения за выходом
	for _, conn in ipairs(self._cleanupConnections) do
		if conn then
			pcall(function() conn:Disconnect() end)
		end
	end
	table.clear(self._cleanupConnections)
	
	table.clear(self.queue)
	self:_shutdownSocket()
	
	print("[WS] Менеджер полностью остановлен.")
end

-- Очистка очереди (отправка отложенных пакетов)
function WebSocketManager:_flushQueue()
	if #self.queue == 0 then return end
	print("[WS] Отправка сохраненных пакетов из буфера: " .. #self.queue)
	
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

-- Универсальный метод отправки данных (с авто-генерацией базовых полей и авто-пробуждением)
-- @param customData - Таблица с дополнительными параметрами, строка или число
function WebSocketManager:Send(customData: any?)
	if self.isManuallyClosed then
		warn("[WS] Попытка отправки через закрытый менеджер. Вызовите :Start() для возобновления.")
		return
	end

	-- Обновляем время последней активности (сброс таймера простоя)
	self.lastActivityTime = os.time()

	-- Если сокет "спит" из-за долгого простоя, будим его
	if self.isIdleClosed and not self.isConnected and not self.isConnecting then
		print("[WS] Обнаружена активность! Пробуждение вебсокета...")
		self.isIdleClosed = false
		task.spawn(function()
			self:_connect()
		end)
	end

	-- 1. Генерируем базовый пакет со стандартными системными данными
	local packet = {
		player_name = getClientIdentifier(),
		place_id = tostring(game.PlaceId),
		session_start_time = self.sessionStartTime or os.time() -- Метка unixtimestamp начала сессии
	}

	-- 2. Интегрируем пользовательские данные
	if customData ~= nil then
		if typeof(customData) == "table" then
			-- Подмешиваем кастомные поля в базовый пакет
			for key, value in pairs(customData) do
				packet[key] = value
			end
		else
			-- Если передана строка или число, записываем её в специальное поле "message"
			packet["message"] = tostring(customData)
		end
	end

	-- Кодируем весь пакет в JSON-строку
	local payload = nil
	local success, jsonString = pcall(function()
		return HttpService:JSONEncode(packet)
	end)
	
	if success then
		payload = jsonString
	else
		warn("[WS] Ошибка сериализации данных в JSON.")
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

return WebSocketManager