PLUGIN.Title = "AFK Kick"
PLUGIN.Version = V(0, 2, 0)
PLUGIN.Description = "Kicks players that are AFK (away from keyboard) for too long."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/1031/"
PLUGIN.ResourceId = 1031

local debug = false

--[[ Do NOT edit the config here, instead edit AFK.json in oxide/config ! ]]

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.TimeLimit = tonumber(self.Config.Settings.TimeLimit) or 5 -- Minutes
    self.Config.Settings.BroadcastChat = self.Config.Settings.BroadcastChat or "true"

    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.PlayerKicked = self.Config.Messages.PlayerKicked or "{player} was kicked for being AFK!"
    self.Config.Messages.YouKicked = self.Config.Messages.YouKicked or "You were kicked for being AFK for {number} minutes!"

    self.Config.Settings.AfkTimeLimit = nil -- Removed in 0.2.0

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

function PLUGIN:CheckPosition(event)
    local player = event.Player
    local steamId = rok.IdFromPlayer(player)
    local start = event.Position
    local timeLimit = self.Config.Settings.TimeLimit * 60

    afkTimer[steamId] = timer.Repeat(timeLimit, 0, function()
        local current = player.CurrentCharacter.Entity.Position
        
        if debug then
            Print(self, "Start position of " .. steamId .. ": " .. tostring(start))
            Print(self, "Current position of " .. steamId .. ": " .. tostring(current))
        end
        
        if start.x == current.x and start.y == current.y and start.z == current.z then
            local message = self.Config.Messages.YouKicked:gsub("{number}", timeLimit)
            CodeHatch.Engine.Networking.Server.Kick.methodarray[2]:Invoke(nil, util.TableToArray({ player, message }))
            
            local message = self.Config.Messages.PlayerKicked:gsub("{player}", player.Name)
            Print(self, message)
            if self.Config.Settings.Broadcast == "true" then rok.BroadcastChat(message) end
        end
        
        start = current
    end, self.Plugin)
end

function PLUGIN:OnPlayerSpawn(event)
    local player = event.Player
    if not player then return end
    if HasPermission(rok.IdFromPlayer(player), "afkkick.bypass") then return end
    
    self:CheckPosition(event)
end

function PLUGIN:OnPlayerDisconnected(player)
    if not player then return end
    local steamId = rok.IdFromPlayer(player)
    
    if afkTimer[steamId] then afkTimer[steamId]:Destroy() end
end
