local Library = {}
Library.hex_colors = {
    red = '#BE0000',
    mint = '#00FFBE',
    green = '#00FF32',
    blue = '#0078FF',
    purple = '#825AFF',
    pink = '#C800FF',
    yellow = '#FFC800',
    orange = '#FF9600',
    black = '#000000',
    gray = '#3C3C3C',
    white = '#ffffff'
}
Library.rgb_colors = {
    red = Color3.fromRGB(190,0,0),
    mint = Color3.fromRGB(0,255,190),
    green = Color3.fromRGB(0,255,50),
    blue = Color3.fromRGB(0,120,255),
    purple = Color3.fromRGB(130,90,255),
    pink = Color3.fromRGB(200, 0,255),
    yellow = Color3.fromRGB(255, 200,0),
    orange = Color3.fromRGB(255,150,0),
    black = Color3.fromRGB(0,0,0),
    gray = Color3.fromRGB(60,60,60),
    white = Color3.fromRGB(255,255,255)
}
local TextChatService = game:GetService("TextChatService")
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/noclipov/Roblox-Luas/main/Libs/msgs.lua"))()
Library.Chat = function(text:string, color:string)
    color = color:lower()
    if color and type(color) == "string" and Library.hex_colors[color:lower()] then
        TextChatService.TextChannels.RBXSystem:DisplaySystemMessage(
            string.format("<font color='%s' face='Code' size='18'>%s</font>", Library.hex_colors[color], text)
        )
    end
end
return Library
