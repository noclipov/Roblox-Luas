--[[ ════════════════════════════════════════════════════════════
  Noclipov · msgs · v2.0
  Цветные системные сообщения в чат (TextChatService, фолбэк — Legacy Chat).
  API: Chat(text, color?, escape?) · Escape(text) · hex_colors · rgb_colors
════════════════════════════════════════════════════════════ ]]

-- [1] SERVICES
local TextChatService = game:GetService("TextChatService")
local StarterGui      = game:GetService("StarterGui")

-- [2] CONFIG
local Msgs = { Version = "2.0" }

Msgs.hex_colors = {
	red = "#BE0000", mint = "#00FFBE", green = "#00FF32", blue = "#0078FF",
	purple = "#825AFF", pink = "#C800FF", yellow = "#FFC800", orange = "#FF9600",
	black = "#000000", gray = "#3C3C3C", white = "#FFFFFF",
}
Msgs.rgb_colors = {
	red = Color3.fromRGB(190, 0, 0), mint = Color3.fromRGB(0, 255, 190),
	green = Color3.fromRGB(0, 255, 50), blue = Color3.fromRGB(0, 120, 255),
	purple = Color3.fromRGB(130, 90, 255), pink = Color3.fromRGB(200, 0, 255),
	yellow = Color3.fromRGB(255, 200, 0), orange = Color3.fromRGB(255, 150, 0),
	black = Color3.fromRGB(0, 0, 0), gray = Color3.fromRGB(60, 60, 60),
	white = Color3.fromRGB(255, 255, 255),
}

-- [3] HELPERS
function Msgs.Escape(text: any): string
	return (tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- [4] PUBLIC API
-- Неизвестный/пустой цвет → белый (раньше сообщение молча терялось).
function Msgs.Chat(text: any, color: string?, escape: boolean?): boolean
	local key = type(color) == "string" and color:lower() or "white"
	if not Msgs.hex_colors[key] then key = "white" end
	local body = escape and Msgs.Escape(text) or tostring(text)

	local channels = TextChatService:FindFirstChild("TextChannels")
	local system = channels and channels:FindFirstChild("RBXSystem")
	if system then
		return (pcall(system.DisplaySystemMessage, system,
			string.format("<font color='%s' face='Code' size='18'>%s</font>", Msgs.hex_colors[key], body)))
	end
	-- Legacy Chat
	return (pcall(StarterGui.SetCore, StarterGui, "ChatMakeSystemMessage", {
		Text = tostring(text), Color = Msgs.rgb_colors[key], Font = Enum.Font.Code, TextSize = 18,
	}))
end

return Msgs
