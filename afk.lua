PLUGIN.Title = "AFK Kick"
PLUGIN.Version = V(0, 1, 1)
PLUGIN.Description = "Kicks players that are AFK (away from keyboard) for set amount of seconds."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/765/"
PLUGIN.ResourceId = 765
PLUGIN.HasConfig = true

local debug = false

local afkTimer = {}
function PLUGIN:Init()
    self:LoadDefaultConfig()
end

function PLUGIN:CheckPosition(player)
    local steamId = rust.UserIDFromPlayer(player)
    local junk = player.transform.position; local start = player.transform.position -- Twice is the trick to get a valid start
    afkTimer[steamId] = timer.Repeat(self.Config.Settings.AfkLimit, 0, function()
        local current = player.transform.position
        if debug then
            print("[" .. self.Title .. "] Start position of " .. steamId .. ": " .. tostring(start))
            print("[" .. self.Title .. "] Current position of " .. steamId .. ": " .. tostring(current))
        end
        if start.x == current.x and start.y == current.y and start.z == current.z then
            local message = self.Config.Messages.YouKicked:gsub("{afklimit}", self.Config.Settings.AfkLimit)
            Network.Net.sv:Kick(player.net.connection, message)
            if self.Config.Settings.Broadcast ~= "false" then
                local message = self.Config.Messages.PlayerKicked:gsub("{player}", player.displayName)
                global.ConsoleSystem.Broadcast("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. message .. "\"")
            end
        end
        start = current
    end)
end

function PLUGIN:OnPlayerInit(player)
    if not player then return end; self:CheckPosition(player)
end

function PLUGIN:OnPlayerDisconnected(player)
    local steamId = rust.UserIDFromPlayer(player)
    if afkTimer[steamId] then afkTimer[steamId]:Destroy(); afkTimer[steamId] = nil end
end

function PLUGIN:Unload()
    if afkTimer then afkTimer = nil end
end

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.AfkLimit = tonumber(self.Config.Settings.AfkLimit) or 300 -- 5 minutes
    self.Config.Settings.Broadcast = self.Config.Settings.Broadcast or "true"
    self.Config.Settings.ChatName = self.Config.Settings.ChatName or "ADMIN"
    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.PlayerKicked = self.Config.Messages.PlayerKicked or "{player} was kicked for being AFK!"
    self.Config.Messages.YouKicked = self.Config.Messages.YouKicked or "You were kicked for being AFK for {afklimit} seconds!"
    self:SaveConfig()
end
