PLUGIN.Title = "Auth Level"
PLUGIN.Version = V(0, 2, 4)
PLUGIN.Description = "Add/remove players as owner/moderator/player via command."
PLUGIN.Author = "Wulf / Luke Spragg"
PLUGIN.Url = "http://oxidemod.org/plugins/702/"
PLUGIN.ResourceId = 702

local debug = false

--[[ Do NOT edit the config here, instead edit AuthLevel.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.AuthLevelSet = messages.AuthLevelSet or "Auth level set to {level} for {player}!"
    messages.ChatHelp = messages.ChatHelp or "Use '/authlevel player authlevel' to set the auth level for player"
    messages.ConsoleHelp = messages.ConsoleHelp or "Use 'authlevel player authlevel' to set the auth level for player"
    messages.InvalidAuthLevel = messages.InvalidAuthLevel or "Invalid auth level! Valid levels are 0 (player), 1 (moderator), and 2 (owner)"
    messages.InvalidTarget = messages.InvalidTarget or "Invalid player name! Please try again"
    messages.NoPermission = messages.NoPermission or "You do not have permission to use this command!"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Command = settings.Command or "authlevel"

    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(settings.Command, self.Plugin, "ChatCommand")
    command.AddConsoleCommand("global." .. settings.Command, self.Plugin, "ConsoleCommand")
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
            Print(self, messages.InvalidTarget)
        else
            rust.SendChatMessage(player, messages.InvalidTarget)
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
    if player and not HasPermission(rust.UserIDFromPlayer(player), "authlevel.set") then
        rust.SendChatMessage(player, messages.NoPermission)
        return
    end

    if args.Length ~= 2 then
        rust.SendChatMessage(player, messages.ChatHelp)
        return
    end

    local targetPlayer = FindPlayer(self, player, args[0])
    if not targetPlayer then
        rust.SendChatMessage(player, messages.InvalidTarget)
        return
    end
    local authLevel = string.lower(args[1])
    if authLevel ~= "2" and authLevel ~= "1" and authLevel ~= "0" then
        rust.SendChatMessage(player, messages.InvalidAuthLevel)
        return
    end

    AuthLevel(targetPlayer, authLevel)

    local message = ParseMessage(messages.AuthLevelSet, { level = authLevel, player = targetPlayer.displayName })
    rust.SendChatMessage(player, message)
end

function PLUGIN:ConsoleCommand(args)
    local player
    if args.connection then player = args.connection.player end

    if player and not HasPermission(rust.UserIDFromPlayer(player), "authlevel.set") then
        args:ReplyWith(messages.NoPermission)
        return
    end

    if not args:HasArgs(2) then
        if not player then
            Print(self, messages.ConsoleHelp)
        else
            args:ReplyWith(messages.ConsoleHelp)
        end
        return
    end

    local targetPlayer = global.BasePlayer.Find(args:GetString(0))
    if not targetPlayer then args:ReplyWith(messages.InvalidTarget); return end
    local authLevel = args:GetString(1)
    if authLevel ~= "2" and authLevel ~= "1" and authLevel ~= "0" then
        if not player then
            Print(self, messages.InvalidAuthLevel)
        else
            args:ReplyWith(messages.InvalidAuthLevel)
        end
        return
    end

    AuthLevel(targetPlayer, authLevel)

    local message = ParseMessage(messages.AuthLevelSet, { level = authLevel, player = targetPlayer.displayName })
    if player then args:ReplyWith(message) else print(message) end
end

function PLUGIN:SendHelpText(player)
    if HasPermission(rust.UserIDFromPlayer(player), "authlevel.set") then
        rust.SendChatMessage(player, messages.ChatHelp)
    end
end
