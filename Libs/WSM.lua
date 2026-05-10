local HttpService = game:GetService("HttpService")

local WebSocketManager = {}
WebSocketManager.__index = WebSocketManager

-- Конструктор модуля
function WebSocketManager.new(url: string)
	local self = setmetatable({}, WebSocketManager)
	self.url = url
	self.socket = nil
	self.isConnected = false
	self.isConnecting = false
	self.queue = {} -- Очередь для отправки данных, если сокет временно отключен
	return self
end

-- Внутренний метод для безопасного подключения
function WebSocketManager:_connect()
	if self.isConnected or self.isConnecting then return end
	self.isConnecting = true
	
	warn("[WS] Попытка подключения к " .. self.url .. "...")
	
	local success, ws = pcall(function()
		-- Поддержка стандартного WebSocket окружения (Lune / Executor-специфичные API)
		if WebSocket and WebSocket.connect then
			return WebSocket.connect(self.url)
		elseif syn and syn.websocket and syn.websocket.connect then
			return syn.websocket.connect(self.url)
		else
			error("Окружение не поддерживает WebSocket API.")
		end
	end)
	
	self.isConnecting = false
	
	if success and ws then
		self.socket = ws
		self.isConnected = true
		print("[WS] Соединение успешно установлено!")
		
		-- Отправляем все накопившиеся в очереди данные
		self:_flushQueue()
		
		-- Слушаем закрытие соединения
		if ws.OnClose then
			ws.OnClose:Connect(function()
				self:_handleDisconnect()
			end)
		end
	else
		warn("[WS] Ошибка подключения. Повторная попытка через 5 секунд...")
		task.wait(5)
		self:_connect()
	end
end

-- Публичный метод для запуска сессии
function WebSocketManager:Start()
	task.spawn(function()
		self:_connect()
	end)
end

-- Обработка дисконнекта и авто-реконнект
function WebSocketManager:_handleDisconnect()
	self.isConnected = false
	self.socket = nil
	warn("[WS] Соединение разорвано!")
	task.wait(5)
	self:_connect()
end

-- Отправка сообщений из очереди после переподключения
function WebSocketManager:_flushQueue()
	if #self.queue == 0 then return end
	print("[WS] Отправка сохраненных пакетов из очереди: " .. #self.queue)
	for _, payload in ipairs(self.queue) do
		if self.isConnected and self.socket then
			self.socket:Send(payload)
		end
	end
	table.clear(self.queue)
end

-- Главный метод отправки данных
-- @param playerName - Имя игрока (обязательно)
-- @param placeId - ID плейса (обязательно)
-- @param extraData - Таблица с любыми дополнительными динамическими данными (опционально)
function WebSocketManager:SendData(playerName: string, placeId: number | string, extraData: table?)
	local packet = {
		player_name = playerName,
		place_id = tostring(placeId),
		time = os.date("%X") -- Системное время в формате HH:MM:SS
	}
	
	-- Подмешиваем дополнительные параметры, если они переданы
	if extraData and typeof(extraData) == "table" then
		for key, value in pairs(extraData) do
			packet[key] = value
		end
	end
	
	local success, jsonString = pcall(function()
		return HttpService:JSONEncode(packet)
	end)
	
	if not success then
		warn("[WS] Не удалось закодировать данные в JSON")
		return
	end
	
	if self.isConnected and self.socket then
		-- Если соединение активно — отправляем сразу
		self.socket:Send(jsonString)
	else
		-- Если сокет упал — сохраняем пакет в память, чтобы отправить при восстановлении сети
		warn("[WS] Нет сети. Пакет сохранен в очередь.")
		table.insert(self.queue, jsonString)
	end
end

return WebSocketManager