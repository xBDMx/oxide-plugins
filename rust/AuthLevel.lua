PLUGIN.Title = "Auth Level"
PLUGIN.Version = V(0, 2, 3)
PLUGIN.Description = "Add/remove players as owner/moderator/player via command."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://oxidemod.org/plugins/702/"
PLUGIN.ResourceId = 702

local debug = false

--[[ Do NOT edit the config here, instead edit AuthLevel.json in oxide/config ! ]]

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.Command = self.Config.Settings.Command or self.Config.Settings.ChatCommand or "authlevel"

    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.AuthLevelSet = self.Config.Messages.AuthLevelSet or "Auth level set to {level} for {player}!"
    self.Config.Messages.ChatHelp = self.Config.Messages.ChatHelp or "Use '/authlevel player authlevel' to set the auth level for player"
    self.Config.Messages.ConsoleHelp = self.Config.Messages.ConsoleHelp or "Use 'authlevel player authlevel' to set the auth level for player"
    self.Config.Messages.InvalidAuthLevel = self.Config.Messages.InvalidAuthLevel or "Invalid auth level! Valid levels are 0 (player), 1 (moderator), and 2 (owner)"
    self.Config.Messages.InvalidTarget = self.Config.Messages.InvalidTarget or "Invalid player name! Please try again"
    self.Config.Messages.NoPermission = self.Config.Messages.NoPermission or "You do not have permission to use this command!"

    self.Config.Settings.ChatName = nil -- Removed in 0.2.0
    self.Config.Settings.ChatNameHelp = nil -- Removed in 0.2.0
    self.Config.Settings.AuthLevel = nil -- Removed in 0.2.3
    self.Config.Settings.ChatCommand = nil -- Removed in 0.2.3
    self.Config.Settings.ConsoleCommand = nil -- Removed in 0.2.3

    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.Command, self.Plugin, "ChatCommand")
    command.AddConsoleCommand("global." .. self.Config.Settings.Command, self.Plugin, "ConsoleCommand")
    permission.RegisterPermission("authlevel.set", self.Plugin)
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

local function AuthLevel(targetPlayer, authLevel)
    local steamId = rust.UserIDFromPlayer(targetPlayer)
    if authLevel == "2" then
        rust.RunServerCommand("ownerid", steamId, targetPlayer.displayName)
        targetPlayer.net.connection.authLevel = 2
    end
    if authLevel == "1" then
        rust.RunServerCommand("moderatorid", steamId, targetPlayer.displayName)
        targetPlayer.net.connection.authLevel = 1
    end
    if authLevel == "0" then
        rust.RunServerCommand("removeowner", steamId)
        rust.RunServerCommand("removemoderator", steamId)
        targetPlayer.net.connection.authLevel = 0
    end
    rust.RunServerCommand("server.writecfg")
end

function PLUGIN:ChatCommand(player, cmd, args)
    local steamId = rust.UserIDFromPlayer(player)
    if player and not HasPermission(steamId, "authlevel.set") then
        rust.SendChatMessage(player, self.Config.Messages.NoPermission)
        return
    end

    if args.Length ~= 2 then
        rust.SendChatMessage(player, self.Config.Messages.ChatHelp)
        return
    end

    local targetPlayer = FindPlayer(self, player, args[0])
    if not targetPlayer then
        rust.SendChatMessage(player, self.Config.Messages.InvalidTarget)
        return
    end
    local authLevel = string.lower(args[1])
    if authLevel ~= "2" and authLevel ~= "1" and authLevel ~= "0" then
        rust.SendChatMessage(player, self.Config.Messages.InvalidAuthLevel)
        return
    end

    AuthLevel(targetPlayer, authLevel)

    local message = ParseMessage(self.Config.Messages.AuthLevelSet, { level = authLevel, player = targetPlayer.displayName })
    rust.SendChatMessage(player, message)
end

function PLUGIN:ConsoleCommand(args)
    local player, steamId
    if args.connection then
        player = args.connection.player
        steamId = rust.UserIDFromPlayer(player)
    end

    if player and not HasPermission(steamId, "authlevel.set") then
        args:ReplyWith(self.Config.Messages.NoPermission)
        return
    end

    if not args:HasArgs(2) then
        if not player then
            Print(self, self.Config.Messages.ConsoleHelp)
        else
            args:ReplyWith(self.Config.Messages.ConsoleHelp)
        end
        return
    end

    local targetPlayer = global.BasePlayer.Find(args:GetString(0))
    if not targetPlayer then args:ReplyWith(self.Config.Messages.InvalidTarget); return end
    local authLevel = args:GetString(1)
    if authLevel ~= "2" and authLevel ~= "1" and authLevel ~= "0" then
        if not player then
            Print(self, self.Config.Messages.InvalidAuthLevel)
        else
            args:ReplyWith(self.Config.Messages.InvalidAuthLevel)
        end
        return
    end

    AuthLevel(targetPlayer, authLevel)

    local message = ParseMessage(self.Config.Messages.AuthLevelSet, { level = authLevel, player = targetPlayer.displayName })
    if player then args:ReplyWith(message) else print(message) end
end

function PLUGIN:SendHelpText(player)
    if HasPermission(rust.UserIDFromPlayer(player), "authlevel.set") then
        rust.SendChatMessage(player, self.Config.Messages.ChatHelp)
    end
end
