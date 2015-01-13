PLUGIN.Title = "Ping"
PLUGIN.Version = V(0, 2, 3)
PLUGIN.Description = "Player ping checking and with optional high ping rejection on join."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/656/"
PLUGIN.ResourceId = 656
PLUGIN.HasConfig = true

local debug = false

-- TODO:
---- Do average ping checking over time with timers?
---- Add command to change max ping, with permissions
---- Return ping to user if no argument is given with commands

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.ChatCommand, self.Object, "cmdPing")
    command.AddConsoleCommand(self.Config.Settings.ConsoleCommand, self.Object, "ccmdPing")
end

function PLUGIN:PingCheck(connection)
    local ping = connection.ping
    if self.Config.Settings.PingKick ~= "false" then
        if ping >= self.Config.Settings.MaxPing then
            if self.Config.Settings.ShowKick ~= "false" then
                local message = self.Config.Messages.PlayerKicked:gsub("{player}", connection.username); local message = message:gsub("{ping}", ping)
                global.ConsoleSystem.Broadcast("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. message .. "\"")
            end
            Network.Net.sv:Kick(connection, self.Config.Messages.Rejected)
        end
    end
    return ping
end

function PLUGIN:OnPlayerConnected(packet)
    if not packet then return end; if not packet.connection then return end
    local connection = packet.connection; local steamId = rust.UserIDFromConnection(connection); local ping = self:PingCheck(connection)
    local message = self.Config.Messages.PlayerConnected:gsub("{player}", connection.username); local message = message:gsub("{steamid}", steamId); local message = message:gsub("{ping}", ping)
    print("[" .. self.Title .. "] " .. message)
end

function PLUGIN:cmdPing(player, cmd, args)
    if player and not self:PermissionsCheck(player.net.connection) then
        player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.NoPermission .. "\"")
        return
    end
    if args.Length ~= 1 then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.ChatHelp .. "\"") return end
    local argument = args[0]
    local targetPlayer = global.BasePlayer.Find(argument)
    if not targetPlayer then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.InvalidTarget .. "\"") return end
    local ping = self:PingCheck(targetPlayer.net.connection)
    local message = self.Config.Messages.PingCheck:gsub("{player}", targetPlayer.displayName); local message = message:gsub("{ping}", ping)
    player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. message .. "\"")
end

function PLUGIN:ccmdPing(args)
    local player = nil; if args.connection then player = args.connection.player end
    if player and not self:PermissionsCheck(args.connection) then args:ReplyWith(self.Config.Messages.NoPermission); return end
    if not args:HasArgs(1) then args:ReplyWith(self.Config.Messages.ConsoleHelp); return end
    local targetPlayer = global.BasePlayer.Find(args:GetString(0))
    if targetPlayer == nil then args:ReplyWith(self.Config.Messages.InvalidTarget); return end
    local ping = self:PingCheck(targetPlayer.net.connection)
    local message = self.Config.Messages.PingCheck:gsub("{player}", targetPlayer.displayName); local message = message:gsub("{ping}", ping)
    args:ReplyWith(targetPlayer.displayName .. " has a ping of " .. ping .. "ms")
end

function PLUGIN:PermissionsCheck(connection)
    local authLevel; if connection then authLevel = connection.authLevel else authLevel = 2 end
    local neededLevel = tonumber(self.Config.Settings.AuthLevel) or 2
    if debug then print(connection.username .. " has auth level: " .. tostring(authLevel)) end
    if authLevel and authLevel >= neededLevel then return true else return false end
end

function PLUGIN:SendHelpText(player)
    player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatNameHelp .. "\" \"" .. self.Config.Messages.ChatHelp .. "\"")
end

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.AuthLevel = tonumber(self.Config.Settings.AuthLevel) or 2
    self.Config.Settings.ChatCommand = self.Config.Settings.ChatCommand or "ping"
    self.Config.Settings.ChatName = self.Config.Settings.ChatName or "PING"
    self.Config.Settings.ChatNameHelp = self.Config.Settings.ChatNameHelp or self.Config.Settings.HelpName or "HELP"
    self.Config.Settings.ConsoleCommand = self.Config.Settings.ConsoleCommand or "global.ping"
    self.Config.Settings.MaxPing = tonumber(self.Config.Settings.MaxPing) or 200 -- Milliseconds
    self.Config.Settings.PingKick = self.Config.Settings.PingKick or "true"
    self.Config.Settings.ShowKick = self.Config.Settings.ShowKick or "true"
    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.ChatHelp = self.Config.Messages.ChatHelp or self.Config.Messages.HelpText or "Use /ping player to check target player's ping"
    self.Config.Messages.ConsoleHelp = self.Config.Messages.ConsoleHelp or "Use player.ping player to check target player's ping"
    self.Config.Messages.InvalidTarget = self.Config.Messages.InvalidTarget or "Invalid target player! Please try again"
    self.Config.Messages.NoPermission = self.Config.Messages.NoPermission or "You do not have permission to use this command!"
    self.Config.Messages.PingCheck = self.Config.Messages.PingCheck or "{player} has a ping of {ping}ms"
    self.Config.Messages.PlayerConnected = self.Config.Messages.PlayerConnected  or "{player} ({steamid}) connected with {ping}ms ping"
    self.Config.Messages.PlayerKicked = self.Config.Messages.PlayerKicked or self.Config.Messages.Kicked or "{player} was kicked for high ping ({ping}ms)"
    self.Config.Messages.Rejected = self.Config.Messages.Rejected or "Sorry, your ping is too high for this server!"
    self.Config.Settings.HelpName = nil -- Removed in 0.2.2
    self.Config.Settings.HelpText = nil -- Removed in 0.2.2
    self.Config.Messages.Kicked = nil -- Removed in 0.2.2
    self:SaveConfig()
end
