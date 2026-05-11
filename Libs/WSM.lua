local HttpService = game:GetService("HttpService")

local WebSocketManager = {}
WebSocketManager.__index = WebSocketManager

function WebSocketManager.new(host: string)
	local self = setmetatable({}, WebSocketManager)
	
	local cleanHost = host:gsub("^https?://", ""):gsub("^wss?://", "")
	local isSecure = not cleanHost:match("^192%.168%.") and not cleanHost:match("^127%.0%.0%.1") and not cleanHost:match("^localhost")
	local protocol = isSecure and "wss://" or "ws://"
	
	self.url = protocol .. cleanHost
	if not self.url:match("/luau$") then
		self.url = self.url:gsub("/+$", "") .. "/luau"
	end
	
	self.socket = nil
	self.isConnected = false
	self.isConnecting = false
	self.isManuallyClosed = false
	self.queue = {}
	
	return self
end

function WebSocketManager:_connect()
	if self.isConnected or self.isConnecting or self.isManuallyClosed then return end
	self.isConnecting = true
	
	warn("[WS] Попытка подключения к " .. self.url .. "...")
	
	local success, ws = pcall(function()
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
		
		self:_flushQueue()
		
		-- Безопасная подписка на закрытие соединения
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
		if self.isManuallyClosed then return end
		
		warn("[WS] Ошибка подключения. Повторная попытка через 5 секунд...")
		task.wait(5)
		-- Проверяем флаг еще раз перед реконнектом
		if not self.isManuallyClosed then
			self:_connect()
		end
	end
end

function WebSocketManager:Start()
	self.isManuallyClosed = false
	task.spawn(function()
		self:_connect()
	end)
end

function WebSocketManager:_handleDisconnect()
	self.isConnected = false
	self.socket = nil
	
	if self.isManuallyClosed then
		print("[WS] Соединение закрыто пользователем.")
		return
	end
	
	warn("[WS] Соединение разорвано!")
	task.wait(5)
	if not self.isManuallyClosed then
		self:_connect()
	end
end

function WebSocketManager:Close()
	self.isManuallyClosed = true
	self.isConnecting = false
	self.isConnected = false
	
	table.clear(self.queue)
	
	if self.socket then
		pcall(function()
			self.socket:Close()
		end)
		self.socket = nil
	end
	
	print("[WS] Сессия успешно завершена.")
end

function WebSocketManager:_flushQueue()
	if #self.queue == 0 then return end
	print("[WS] Отправка сохраненных пакетов из очереди: " .. #self.queue)
	
	-- Копируем очередь, чтобы избежать конфликтов при итерации
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
				-- Если при отправке очереди сокет снова упал, возвращаем пакет назад
				table.insert(self.queue, payload)
			end
		else
			table.insert(self.queue, payload)
		end
	end
end

function WebSocketManager:SendData(playerName: string, placeId: number | string, extraData: table?)
	if self.isManuallyClosed then
		warn("[WS] Попытка отправить данные через закрытый сокет. Используй :Start() для возобновления работы.")
		return
	end

	local packet = {
		player_name = playerName,
		place_id = tostring(placeId),
		time = os.date("%X")
	}
	
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
		local sendSuccess, sendErr = pcall(function()
			self.socket:Send(jsonString)
		end)
		
		if not sendSuccess then
			warn("[WS ERROR] Ошибка отправки, сохраняем в очередь: " .. tostring(sendErr))
			self.isConnected = false
			table.insert(self.queue, jsonString)
		end
	else
		table.insert(self.queue, jsonString)
	end
end

return WebSocketManager