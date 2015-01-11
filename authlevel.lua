PLUGIN.Title = "Auth Level"
PLUGIN.Version = V(0, 1, 4)
PLUGIN.Description = "Temporarily sets the auth level for players via command."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/702/"
PLUGIN.ResourceId = 702
PLUGIN.HasConfig = true

-- TODO:
---- Find method to set owner/moderator permanently

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.ChatCommand, self.Object, "cmdAuthLevel")
    command.AddConsoleCommand(self.Config.Settings.ConsoleCommand, self.Object, "ccmdAuthLevel")
end

function PLUGIN:cmdAuthLevel(player, cmd, args)
    if player and not self:PermissionsCheck(player) then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.NoPermission .. "\""); return end
    if args.Length ~= 2 then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatNameHelp .. "\" \"" .. self.Config.Messages.ChatHelp .. "\"") return end
    local authLevel = args[1]
    if authLevel ~= "0" and authLevel ~= "1" and authLevel ~= "2" then
        player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.InvalidAuthLevel .. "\"")
        return
    end
    local targetPlayer = global.BasePlayer.Find(args[0])
    if not targetPlayer then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.InvalidTarget .. "\"") return end
    targetPlayer.net.connection.authLevel = tonumber(authLevel)
    local message = self.Config.Messages.AuthLevelSet:gsub("{level}", authLevel); local message = message:gsub("{player}", targetPlayer.displayName)
    player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. message .. "\"")
end

function PLUGIN:ccmdAuthLevel(args)
    local player = nil
    if args.connection then player = args.connection.player end
    if player and not self:PermissionsCheck(player) then args:ReplyWith(self.Config.Messages.NoPermission); return end
    if not args:HasArgs(2) then args:ReplyWith(self.Config.Messages.ConsoleHelp); return end
    local targetPlayer = global.BasePlayer.Find(args:GetString(0))
    if targetPlayer == nil then args:ReplyWith(self.Config.Messages.InvalidTarget); return end
    local authLevel = args:GetString(1)
    targetPlayer.net.connection.authLevel = tonumber(authLevel)
    local message = self.Config.Messages.AuthLevelSet:gsub("{level}", authLevel); local message = message:gsub("{player}", targetPlayer.displayName)
    args:ReplyWith(message)
end

function PLUGIN:PermissionsCheck(player)
    local authLevel
    if player then authLevel = player.net.connection.authLevel else authLevel = 2 end
    local neededLevel = tonumber(self.Config.Settings.AuthLevel) or 2
    if debug then print(player.displayName .. " has auth level: " .. tostring(authLevel)) end
    if authLevel and authLevel >= neededLevel then return true else return false end
end

function PLUGIN:SendHelpText(player)
    if self:PermissionsCheck(player) then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatNameHelp .. "\" \"" .. self.Config.Messages.ChatHelp .. "\"") end
end

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.AuthLevel = tonumber(self.Config.Settings.AuthLevel) or 2
    self.Config.Settings.ChatCommand = self.Config.Settings.ChatCommand or "authlevel"
    self.Config.Settings.ChatName = self.Config.Settings.ChatName or "ADMIN"
    self.Config.Settings.ChatNameHelp = self.Config.Settings.ChatNameHelp or "HELP"
    self.Config.Settings.ConsoleCommand = self.Config.Settings.ConsoleCommand or "player.authlevel"
    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.AuthLevelSet = self.Config.Messages.AuthLevelSet or "Auth level set to {level} for {player}!"
    self.Config.Messages.ChatHelp = self.Config.Messages.ChatHelp or "Use /authlevel player # to set the auth level for player"
    self.Config.Messages.ConsoleHelp = self.Config.Messages.ConsoleHelp or "Use player.authlevel player # to set the auth level for player"
    self.Config.Messages.InvalidAuthLevel = self.Config.Messages.InvalidAuthLevel or "Invalid auth level! Valid levels are 0 (player), 1 (moderator), and 2 (owner/admin)"
    self.Config.Messages.InvalidTarget = self.Config.Messages.InvalidTarget or "Invalid player name! Please try again"
    self.Config.Messages.NoPermission = self.Config.Messages.NoPermission or "You do not have permission to use this command!"
    self:SaveConfig()
end
