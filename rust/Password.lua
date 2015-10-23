PLUGIN.Title = "Server Password"
PLUGIN.Version = V(0, 2, 0)
PLUGIN.Description = "Require a password for players to join your server."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/0/"
PLUGIN.ResourceId = 0

local debug = true

-- TODO:
---- Add check for success before processing password command
---- Add console command to set or disable password
---- Add "# attempts remaining" to player messages
---- Convert remaining hard-coded strings to configurable message strings
---- Add option to remember players who have entered the password successfully before, only prompting new players

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.Attempts = tonumber(self.Config.Settings.Attempts) or 3
    self.Config.Settings.BlockMovement = self.Config.Settings.BlockMovement or "true"
    self.Config.Settings.Command = self.Config.Settings.Command or "password"
    self.Config.Settings.GracePeriod = tonumber(self.Config.Settings.GracePeriod) or 30 -- Seconds
    self.Config.Settings.HideChat = self.Config.Settings.HideChat or "true"
    self.Config.Settings.Password = self.Config.Settings.Password or math.random(8)
    self.Config.Settings.Punishment = self.Config.Settings.Punishment or "kick"

    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.InvalidPassword = self.Config.Messages.InvalidPassword or "You entered an incorrect password. Please try again!"
    self.Config.Messages.PasswordPrompt = self.Config.Messages.PasswordPrompt or "Please enter the server password using /password:"
    self.Config.Messages.PlayerBanned = self.Config.Messages.PlayerBanned or "{player} was banned"
    self.Config.Messages.PlayerKicked = self.Config.Messages.PlayerKicked or "{player} was kicked"
    self.Config.Messages.TooManyAttempts = self.Config.Messages.TooManyAttempts or "Too many password attempts. Goodbye!"
    self.Config.Messages.ValidPassword = self.Config.Messages.ValidPassword or "Password accepted! Welcome to {server}!"

    self:SaveConfig()
end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

local function HasPermission(steamId, perm)
    if permission.UserHasPermission(steamId, perm) then return true end
    return false
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.Command, self.Plugin, "ChatCommand")
    command.AddConsoleCommand("global." .. self.Config.Settings.Command, self.Plugin, "ConsoleCommand")
    permission.RegisterPermission("password.bypass", self.Plugin)
end

local attempts, success = 0, false
local movementTimer, passwordTimer, spawnTimer = {}, {}, {}

function PLUGIN:BlockMovement(player, steamId)
    if self.Config.Settings.BlockMovement == "true" then
        movementTimer[steamId] = timer.Repeat(1, 0, function()
            player.transform.position = player.transform.position
            player.transform.rotation = player.transform.rotation
            --player:Respawn(false)
        end, self.Plugin)
    end
end

function PLUGIN:PasswordCheck(player)
    if not success then
        if attempts >= tonumber(self.Config.Settings.Attempts) - 1 then
            if debug then Print(self, "Max password attempts reached by " .. player.displayName) end

            print(player.displayName .. " was " .. self.Config.Settings.Punishment .. "ed for max password attempts allowed")
            rust.BroadcastChat(self.Config.Settings.ChatName, player.displayName .. " was " .. self.Config.Settings.Punishment .. "ed for max password attempts allowed")

            self:PunishPlayer(player)

        elseif password == self.Config.Settings.Password then
            rust.SendChatMessage(player, self.Config.Messages.ValidPassword .. " " .. player.displayName .. "!")

            -- TODO: Close death screen and show valid password message

            self:DestroyTimers()
 
            return true

        else
            rust.SendChatMessage(player, self.Config.Messages.InvalidPassword)
            rust.SendChatMessage(player, self.Config.Messages.PasswordPrompt)

            attempts = attempts + 1

            if debug then
                rust.SendChatMessage(player, "Password attempts from " .. player.displayName .. ": " .. self.Attempts)
            end
        end
    end
end

function PLUGIN:OnPlayerInit(player)
    if self.Config.Settings.Password == "" then
        -- TODO: Send set password message
        return
    end

    local steamId = rust.UserIDFromPlayer(player)

    self:BlockMovement(player, steamId)

    rust.SendChatMessage(player, self.Config.Messages.PasswordPrompt)
    if debug then Print(self, "Max password attempts allowed: " .. self.Config.Settings.Attempts) end

    passwordTimer[steamId] = timer.Once(tonumber(self.Config.Settings.GracePeriod), function()
        if not success then
            Print(self, player.displayName .. " was " .. self.Config.Settings.Punishment .. "ed for not entering the server password")
            rust.BroadcastChat(player.displayName .. " was " .. self.Config.Settings.Punishment .. "ed for not entering the server password")

            self:Punish(player)
        end
    end, self.Plugin)
end

function PLUGIN:OnPlayerChat(args)
    if debug then
        Print(self, "Password success (" .. player.displayName .. "): " .. success)
        --Print(self, "Seconds connected (" .. player.displayName .. "): " .. tostring(netuser:SecondsConnected()))
        Print(self, "Password grace period: " .. self.Config.Settings.GracePeriod)
    end

    if success then
        player:EndSleeping()
        return
    elseif netuser:SecondsConnected() <= tonumber(self.Config.Settings.GracePeriod) then
        return false
    end
    self:PasswordCheck(player)
end

function PLUGIN:OnPlayerDisconnected(player)
    local steamId = rust.UserIDFromPlayer(player)

    self:DestroyTimers(steamId)
end

function PLUGIN:ChatCommand(player, cmd, args)
    local password = args[0]

    self:PasswordCheck(player)
end

function PLUGIN:Punish(player)
    if not player then return end

    if self.Config.Settings.Punishment == "kick" then
        -- TODO: Configure message
        Network.Net.sv:Kick(player.net.connection, message)
    elseif self.Config.Settings.Punishment == "ban" then
        -- TODO: Configure message
        rust.RunServerCommand("ban", player.displayName, reason)
    end
end

function PLUGIN:DestroyTimers(steamId)
    if movementTimer[steamId] then movementTimer[steamId]:Destroy() end
    if passwordTimer[steamId] then passwordTimer[steamId]:Destroy() end
    if spawnTimer[steamId] then spawnTimer[steamId]:Destroy() end
end
