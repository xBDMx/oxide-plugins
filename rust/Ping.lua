PLUGIN.Title = "Ping"
PLUGIN.Version = V(0, 3, 4)
PLUGIN.Description = "Ping checking and optional high ping kicking."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://oxidemod.org/plugins/656/"
PLUGIN.ResourceId = 656

local debug = false

-- TODO:
---- Add command to change max ping, with permissions

--[[ Do NOT edit the config here, instead edit Ping.json in oxide/config ! ]]

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.Command = self.Config.Settings.Command or self.Config.Settings.ChatCommand or "ping"
    self.Config.Settings.MaxPing = tonumber(self.Config.Settings.MaxPing) or 200 -- Milliseconds
    self.Config.Settings.PingKick = self.Config.Settings.PingKick or "true"
    self.Config.Settings.BroadcastKick = self.Config.Settings.BroadcastKick or "true"

    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.ChatHelp = self.Config.Messages.ChatHelp or "Use '/ping player' to check target player's ping"
    self.Config.Messages.ConsoleHelp = self.Config.Messages.ConsoleHelp or "Use 'ping player' to check target player's ping"
    self.Config.Messages.InvalidTarget = self.Config.Messages.InvalidTarget or "Invalid target player! Please try again"
    self.Config.Messages.NoPermission = self.Config.Messages.NoPermission or "You do not have permission to use this command!"
    self.Config.Messages.PlayerCheck = self.Config.Messages.PlayerCheck or "{player} has a ping of {ping}ms"
    self.Config.Messages.PlayerExcluded = self.Config.Messages.PlayerExcluded or "{player} is excluded from ping checks!"
    self.Config.Messages.PlayerKicked = self.Config.Messages.PlayerKicked or "{player} was kicked for high ping ({ping}ms)"
    self.Config.Messages.Rejected = self.Config.Messages.Rejected or "Your ping is too high for this server!"
    self.Config.Messages.SelfCheck = self.Config.Messages.SelfCheck or "You have a ping of {ping}ms"

    self.Config.Settings.ChatCommand = nil -- Removed in 0.3.3
    self.Config.Settings.ConsoleCommand = nil -- Removed in 0.3.3

    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.Command, self.Plugin, "ChatCommand")
    command.AddConsoleCommand("global." .. self.Config.Settings.Command, self.Plugin, "ConsoleCommand")
    permission.RegisterPermission("ping.bypass", self.Plugin)
    permission.RegisterPermission("ping.check", self.Plugin)
end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

local function ParseMessage(message, values)
    for key, value in pairs(values) do message = message:gsub("{" .. key .. "}", value) end
    return message
end

local function HasPermission(steamId, perm)
    if permission.UserHasPermission(steamId, perm) then return true end
    return false
end

local function FindPlayer(self, player, target)
    local targetPlayer = global.BasePlayer.Find(target)
    if not targetPlayer then
        if not player then
            Print(self, self.Config.Messages.InvalidTarget)
        else
            rust.SendChatMessage(player, self.Config.Messages.InvalidTarget)
        end
        return
    end
    return targetPlayer
end

local function Ping(connection) return Network.Net.sv:GetAveragePing(connection) end

function PLUGIN:PingKick(player)
    local ping = Ping(player.net.connection)
    if self.Config.Settings.PingKick == "true" then
        if ping >= self.Config.Settings.MaxPing then
            local message = ParseMessage(self.Config.Messages.PlayerKicked, { player = player.displayName, ping = ping })
            print("[".. self.Title .. "] " .. message)
            Network.Net.sv:Kick(player.net.connection, self.Config.Messages.Rejected)
            if self.Config.Settings.BroadcastKick == "true" then
                rust.BroadcastChat(message)
            end
        end
    end
    return ping
end

function PLUGIN:OnPlayerInit(player)
    if not player then return end
    if not player.net then return end
    if not player.net.connection then return end
    self:PingKick(player)
end

function PLUGIN:ChatCommand(player, cmd, args)
    if args.Length > 1 then
        rust.SendChatMessage(player, self.Config.Messages.ChatHelp)
        return
    end

    if args.Length == 1 then
        local steamId = rust.UserIDFromPlayer(player)
        if player and not HasPermission(steamId, "ping.check") then
            rust.SendChatMessage(player, self.Config.Messages.NoPermission)
            return
        end

        local targetPlayer = FindPlayer(self, player, args[0])
        if targetPlayer then
            local steamId = rust.UserIDFromPlayer(targetPlayer)
            if HasPermission(steamId, "ping.bypass") then
                local message = ParseMessage(self.Config.Messages.PlayerExcluded, { player = targetPlayer.displayName })
                rust.SendChatMessage(player, message)
                return
            end
            local ping = self:PingKick(targetPlayer)
            local message = ParseMessage(self.Config.Messages.PlayerCheck, { player = targetPlayer.displayName, ping = ping })
            rust.SendChatMessage(player, message)
        end
    else
        local ping = Ping(player.net.connection)
        local message = ParseMessage(self.Config.Messages.SelfCheck, { player = player.displayName, ping = ping })
        rust.SendChatMessage(player, message)
    end
end

function PLUGIN:ConsoleCommand(args)
    local player, steamId
    if args.connection then
        player = args.connection.player
        steamId = rust.UserIDFromPlayer(player)
    end

    if player and not HasPermission(steamId, "ping.check") then
        args:ReplyWith(self.Config.Messages.NoPermission)
        return
    end

    if args.Args.Length > 1 then
        args:ReplyWith(self.Config.Messages.ConsoleHelp)
        return
    end

    if args:HasArgs(1) then
        local targetPlayer = FindPlayer(self, player, args:GetString(0))
        if targetPlayer then
            local steamId = rust.UserIDFromPlayer(targetPlayer)
            if HasPermission(steamId, "ping.bypass") then
                local message = ParseMessage(self.Config.Messages.PlayerExcluded, { player = targetPlayer.displayName })
                args:ReplyWith(message)
                return
            end
            local ping = self:PingKick(targetPlayer)
            local message = ParseMessage(self.Config.Messages.PlayerCheck, { player = targetPlayer.displayName, ping = ping })
            args:ReplyWith(message)
        end
    else
        local ping = Ping(player.net.connection)
        local message = ParseMessage(self.Config.Messages.SelfCheck, { player = player.displayName, ping = ping })
        args:ReplyWith(message)
    end
end

function PLUGIN:SendHelpText(player)
    if HasPermission(rust.UserIDFromPlayer(player), "ping.check") then
        rust.SendChatMessage(player, self.Config.Messages.ChatHelp)
    end
end
