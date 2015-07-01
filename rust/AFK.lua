PLUGIN.Title = "AFK Kick"
PLUGIN.Version = V(0, 2, 0)
PLUGIN.Description = "Kicks players that are AFK (away from keyboard) for too long."
PLUGIN.Author = "Wulf / Luke Spragg"
PLUGIN.Url = "http://oxidemod.org/plugins/765/"
PLUGIN.ResourceId = 765

local debug = false

--[[ Do NOT edit the config here, instead edit AFK.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.PlayerKicked = messages.PlayerKicked or "{player} was kicked for being AFK!"
    messages.YouKicked = messages.YouKicked or "You were kicked for being AFK for {number} minute(s)!"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.TimeLimit = tonumber(settings.TimeLimit) or 5 -- Minutes
    settings.BroadcastKick = settings.BroadcastKick or "true"
    settings.AllowCrafting = settings.AllowCrafting or "true"

    settings.AfkTimeLimit = nil -- Removed in 0.2.0
    settings.BroadcastChat = nil -- Removed in 0.2.0

    self:SaveConfig()
end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

local function HasPermission(steamId, perm)
    if permission.UserHasPermission(steamId, perm) then return true end
    return false
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    permission.RegisterPermission("afkkick.bypass", self.Plugin)
end

local afkTimer = {}

function PLUGIN:CheckPosition(player)
    if settings.AllowCrafting == "true" and player.inventory.crafting.queue.Count >= 1 then
        if debug then Print(self, steamId .. " is currently crafting items") end
        return
    end

    local steamId = rust.UserIDFromPlayer(player)
    local junk = player.transform.position
    local start = player.transform.position.x .. ", "
               .. player.transform.position.y .. ", "
               .. player.transform.position.z

    afkTimer[steamId] = timer.Repeat(settings.TimeLimit * 60, 0, function()
        local current = player.transform.position.x .. ", "
                     .. player.transform.position.y .. ", "
                     .. player.transform.position.z

        if debug then
            Print(self, "Start position of " .. steamId .. ": " .. tostring(start))
            Print(self, "Current position of " .. steamId .. ": " .. tostring(current))
        end

        if start == current then            
            local message = messages.YouKicked:gsub("{number}", settings.TimeLimit)
            if player then Network.Net.sv:Kick(player.net.connection, message) end

            Print(self, messages.PlayerKicked:gsub("{player}", player.displayName))
            if settings.Broadcast == "true" then rust.BroadcastChat(message) end
        end

        start = current
    end, self.Plugin)
end

function PLUGIN:OnPlayerInit(player)
    if not player then return end
    if HasPermission(rust.UserIDFromPlayer(player), "afkkick.bypass") then return end

    self:CheckPosition(player)
end

function PLUGIN:OnPlayerDisconnected(player)
    if not player then return end

    local steamId = rust.UserIDFromPlayer(player)

    if afkTimer[steamId] then afkTimer[steamId]:Destroy() end
end
