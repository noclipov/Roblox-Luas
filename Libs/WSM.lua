local HttpService = game:GetService("HttpService")

local WebSocketManager = {}
WebSocketManager.__index = WebSocketManager

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
	
	-- Настройки таймаута активности
	self.idleTimeout = idleTimeout or 30 -- Через сколько секунд закрывать сокет при простое
	self.lastActivityTime = os.time()
	self.isIdleClosed = false -- Флаг, что сокет "спит" из-за простоя
	
	self.queue = {}
	
	return self
end

-- Внутренний поток мониторинга активности (таймаут)
function WebSocketManager:_startIdleTracker()
	if self.idleTrackerActive then return end
	self.idleTrackerActive = true
	
	task.spawn(function()
		while self.isConnected and not self.isManuallyClosed do
			task.wait(1)
			
			-- Проверяем, сколько времени прошло с последней отправки
			local elapsed = os.time() - self.lastActivityTime
			if elapsed >= self.idleTimeout then
				warn("[WS] Соединение простаивает более " .. self.idleTimeout .. " сек. Переход в спящий режим...")
				self.isIdleClosed = true
				self:_shutdownSocket() -- Мягко закрываем физический сокет
				break
			end
		end
		self.idleTrackerActive = false
	end)
end

-- Внутренний метод физического закрытия сокета без отмены сессии
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
		self.lastActivityTime = os.time() -- Сбрасываем таймер при коннекте
		print("[WS] Соединение успешно установлено!")
		
		-- Запускаем трекер простоя
		self:_startIdleTracker()
		
		-- Фоновая отправка буфера
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
		-- Если закрыли руками или он ушел в сон, реконнект по ошибке не нужен
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
	
	-- Если закрыли руками или сокет уснул сам — автореконнект не вызываем
	if self.isManuallyClosed or self.isIdleClosed then
		return
	end
	
	warn("[WS] Соединение потеряно! Автореконнект через 5 секунд...")
	task.wait(5)
	if not self.isManuallyClosed and not self.isIdleClosed then
		self:_connect()
	end
end

-- Полная принудительная остановка (очищает очередь)
function WebSocketManager:Close()
	self.isManuallyClosed = true
	self.isConnecting = false
	self.isConnected = false
	self.isIdleClosed = false
	
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

-- Универсальный метод отправки данных (с автоматическим пробуждением)
function WebSocketManager:Send(data: any)
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

	local payload = nil

	if typeof(data) == "table" then
		local success, jsonString = pcall(function()
			return HttpService:JSONEncode(data)
		end)
		if success then
			payload = jsonString
		else
			warn("[WS] Ошибка сериализации таблицы в JSON.")
			return
		end
	else
		payload = tostring(data)
	end
	
	-- Отправляем или сохраняем в очередь
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
		-- Если сокет спит или подключается, пакет аккуратно подождет в очереди и отправится сразу после коннекта
		table.insert(self.queue, payload)
	end
end

return WebSocketManager