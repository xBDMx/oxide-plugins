PLUGIN.Title = "Restrict Names"
PLUGIN.Version = V(0, 1, 0)
PLUGIN.Description = "Limit player names and characters allowed on the server."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/0/"
PLUGIN.ResourceId = 0

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    --"Connection Refused: You are not allowed to use this name"
    --connection.username .. " connection refused: Illegal name"
    --"Connection Refused: You have illegal characters in your name"
    --connection.username .. " connection refused: Illegal Character"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.RestrictName = tostring(settings.RestrictName) or "true"
    settings.RestrictCharacters = tostring(settings.RestrictCharacters) or "true"
    settings.RestrictedNames = settings.RestrictedNames or { "SERVER CONSOLE", "SERVER", "Oxide", "Facepunch", "Rust" }
    settings.AllowedCharacters = settings.AllowedCharacters or "abcdefghijklmnopqrstuvwxyz1234567890 [](){}!@#$%^&*_-=+.|"

    self:SaveConfig()
end

function PLUGIN:Init() self:LoadDefaultConfig() end

function PLUGIN:CanClientLogin(connection)
    if not connection then return end
    if not connection.username then return end

    local name = connection.username

    if settings.RestrictName == "true" then
        for i = 1, #settings.RestrictedNames do
            if name == settings.RestrictedNames[i] then
                print(name .. " connection refused: Illegal name")
                return "Connection Refused: You are not allowed to use this name"
            end
        end
    end

    if settings.RestrictCharacters == "true" then
        for i = 1, name:len() do
            if string.find(settings.AllowedCharacters, name:sub(i,i):lower(), nil, true) == nil then
                print(name .. " connection refused: Illegal Character")
                return "Connection Refused: You have illegal characters in your name"
            end
        end
    end
end
