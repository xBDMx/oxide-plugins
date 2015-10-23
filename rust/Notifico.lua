PLUGIN.Title = "Notifico"
PLUGIN.Version = V(0, 3, 0)
PLUGIN.Description = "Sends messages and alerts to configured IRC channels via Notifico - http://n.tkte.ch/"
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/704/"
PLUGIN.ResourceId = 704

local debug = false

-- TODO:
---- Additional user information such as IP, country, Steam ID, etc

--[[ Do NOT edit the config here, instead edit Notifico.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.Connected = messages.Connected or "{player} has connected to the server"
    messages.Disconnected = messages.Disconnected or "{player} has disconnected from the server"
    messages.PlayerChat = messages.PlayerChat or "{player}: {chat}"
    messages.RanChatCommand = messages.RanChatCommand or "{player} ran chat command: {command}"
    messages.RanConsoleCommand = messages.RanConsoleCommand or "{player} ran console command: {command}"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Exclusions = settings.Exclusions or {
        "chat.say", "craft.add", "craft.cancel", "global.kill", "global.respawn",
        "global.respawn_sleepingbag", "global.status", "global.wakeup", "inventory.endloot"
    }
    settings.HookUrl = settings.HookUrl or ""
    settings.ShowChat = settings.ShowChat or "true"
    settings.ShowCommands = settings.ShowCommands or "true"
    settings.ShowConnects = settings.ShowConnects or "true"
    settings.ShowDisconnects = settings.ShowDisconnects or "true"

    settings.AuthLevel = nil -- Removed in 0.3.0
    settings.ShowConsoleCommands = nil -- Removed in 0.3.0

    self:SaveConfig()
end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

local function ParseString(message, values)
    for key, value in pairs(values) do
        value = tostring(value):gsub("[%-?*+%[%]%(%)%%]", "%%%%%0")
        message = message:gsub("{" .. key .. "}", value)
    end
    return message
end

function PLUGIN:Init() self:LoadDefaultConfig() end

function PLUGIN:OnPlayerChat(arg)
    if not arg then return end
    if not arg.connection then return end
    if not arg.connection.player then return end

    local player, chat = arg.connection.player, arg:GetString(0, "text")

    if not chat or chat == "" or chat:sub(1, 1) == "/" then return end

    if settings.ShowChat == "true" then
        local message = ParseString(messages.PlayerChat, { player = player.displayName, chat = chat })
        self:SendPayload(message)
    end
end

function PLUGIN:OnPlayerConnected(packet)
    if not packet then return end
    if not packet.connection then return end

    local connection = packet.connection

    if settings.ShowConnects == "true" then
        local message = ParseString(messages.Connected, { player = connection.username })
        self:SendPayload(message)
    end
end

function PLUGIN:OnPlayerDisconnected(player)
    if not player then return end

    if settings.ShowDisconnects == "true" then
        local message = ParseString(messages.Disconnected, { player = player.displayName })
        self:SendPayload(message)
    end
end

function PLUGIN:OnRunCommand(arg)
    if not arg then return end
    if not arg.connection then return end
    if not arg.connection.player then return end
    if not arg.cmd then return end
    if not arg.cmd.namefull then return end

    local player = arg.connection.player
    local chat, console = arg:GetString(0, "text"), arg.cmd.namefull
    local excluded = false

    if settings.ShowCommands == "true" then
        for key, value in pairs(settings.Exclusions) do
            if value == console then excluded = true break end
        end

        if not excluded then
            local message = ParseString(messages.RanConsoleCommand, {
                player = player.displayName, command = console
            })

            self:SendPayload(message)

        elseif chat:sub(1, 1) == "/" then
            local message = ParseString(messages.RanChatCommand, {
                player = player.displayName, command = chat
            })

            self:SendPayload(message)
        end
    end
end

function PLUGIN:SendPayload(payload)
    if settings.HookUrl == "" then
        Print(self, "You need to set your Notifico hook URL!")
        return
    end

    local url = settings.HookUrl .. "?payload=" .. payload
    webrequests.EnqueueGet(url, function(code, response)
        if code ~= 200 then Print(self, "Failed to send message to Notifico!") return end
    end, self.Plugin)
end
