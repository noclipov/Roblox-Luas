local Library = {}
Library.Link = "https://raw.githubusercontent.com/dimanoclip/Roblox-Luas/main/Libs/wh.lua"

Library.Send = function(title, desc, color, link)
    local lp = game.Players.LocalPlayer
    color = tonumber(color) or 0x825AFF
    local data = {
        username = "Noclipov System",
        avatar_url = "https://i.imgur.com/x4q1HDg.png",
        embeds = {{
            author = {
                name = "Noclipov Webhook Service",
                icon_url = "https://i.imgur.com/x4q1HDg.png",
                url = Library.Link
            },
            title = title or "🔔 Notification",
            description = desc or "No description provided.",
            color = color,
            
            -- Поля с информацией (теперь выглядят аккуратнее)
            fields = {
                {
                    name = "👤 User Information",
                    value = string.format("• **Name:** [%s](https://www.roblox.com/users/%s)\n• **ID:** `%s`", lp.Name, lp.UserId, lp.UserId),
                    inline = false
                },
                {
                    name = "🎮 Game Context",
                    value = string.format("• **Place:** [%s](https://www.roblox.com/games/%s)\n• **JobId:** `%s` ", game.PlaceId, game.PlaceId, game.JobId),
                    inline = false
                },
                {
                    name = "🔗 Source",
                    value = string.format("[GitHub Repository](%s)", Library.Link),
                    inline = true
                }
            },
            footer = {
                text = "Noclipov Runtime Environment • " .. os.date("%X"),
                icon_url = "https://i.imgur.com/x4q1HDg.png"
            },
            
            -- Добавляет время отправки внизу сообщения
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    local success, encoded = pcall(function() return game:GetService("HttpService"):JSONEncode(data) end)
    if not success then return warn("Failed to encode JSON") end

    local request = http_request or request or HttpPost or (syn and syn.request)
    if request then
        request({
            Url = link,
            Body = encoded,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"}
        })
    else
        warn("Executor does not support requests.")
    end
end

return Library