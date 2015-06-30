PLUGIN.Title = "Whitelist"
PLUGIN.Version = V(0, 3, 1)
PLUGIN.Description = "Restricts access to your server to whitelisted players only."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://oxidemod.org/plugins/654/"
PLUGIN.ResourceId = 654

local debug = false

--[[ Do NOT edit the config here, instead edit Whitelist.json in oxide/config ! ]]

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.Command = self.Config.Settings.Command or self.Config.Settings.ChatCommand or "whitelist"

    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.AlreadyAdded = self.Config.Messages.AlreadyAdded or "{target} is already whitelisted!"
    self.Config.Messages.ChatHelp = self.Config.Messages.ChatHelp or "Use '/whitelist add|remove player|steamid'"
    self.Config.Messages.ConsoleHelp = self.Config.Messages.ConsoleHelp or "Use 'whitelist add|remove player|steamid'"
    self.Config.Messages.InvalidAction = self.Config.Messages.InvalidAction or self.Config.Messages.UnknownAction or "Invalid command action! Use add or remove"
    self.Config.Messages.InvalidTarget = self.Config.Messages.InvalidTarget or "Invalid player or Steam ID! Please try again"
    self.Config.Messages.NoPermission = self.Config.Messages.NoPermission or "You do not have permission to use this command!"
    self.Config.Messages.NotWhitelisted = self.Config.Messages.NotWhitelisted or "{target} is not whitelisted!"
    self.Config.Messages.PlayerAdded = self.Config.Messages.PlayerAdded or "{target} has been added to the whitelist!"
    self.Config.Messages.PlayerRemoved = self.Config.Messages.PlayerRemoved or "{target} has been removed from the whitelist!"
    self.Config.Messages.Rejected = self.Config.Messages.Rejected or "Sorry, you are not whitelisted!"

    self.Config.Settings.AuthLevel = nil -- Removed in 0.3.0
    self.Config.Settings.ChatName = nil -- Removed in 0.3.0
    self.Config.Settings.ChatNameHelp = nil -- Removed in 0.3.0
    self.Config.Settings.ConsoleCommand = nil -- Removed in 0.3.0
    self.Config.Settings.Whitelist = nil -- Removed in 0.3.0

    self.Config.Messages.UnknownAction = nil -- Removed in 0.3.0

    self:SaveConfig()
end

local whitelist

function PLUGIN:Init()
    self:LoadDefaultConfig()
    whitelist = datafile.GetDataTable("Whitelist") or {}
    command.AddChatCommand(self.Config.Settings.Command, self.Plugin, "ChatCommand")
    command.AddConsoleCommand("global." .. self.Config.Settings.Command, self.Plugin, "ConsoleCommand")
    permission.RegisterPermission("whitelist", self.Plugin)
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

function PLUGIN:CanClientLogin(connection)
    local steamId = rust.UserIDFromConnection(connection)

    if debug then print(connection.username .. " (" .. steamId .. ") connected") end

    for key, value in pairs(whitelist) do
        if steamId == key then
            whitelist[steamId] = connection.username
            datafile.SaveDataTable("Whitelist")
            return
        end
    end

    return self.Config.Messages.Rejected
end

function PLUGIN:Whitelist(action, player, target)
    if player and not HasPermission(rust.UserIDFromPlayer(player), "whitelist") then
        rust.SendChatMessage(player, self.Config.Messages.NoPermission)
        return
    end

    if action == nil or action ~= "add" and action ~= "remove" then
        if player then
            rust.SendChatMessage(player, self.Config.Messages.InvalidAction)
        else
            Print(self, self.Config.Messages.InvalidAction)
        end
        return
    end

    local targetPlayer, targetSteamId
    if string.len(target) == 17 and target:match("%d+") then
        targetName = ""
        targetSteamId = target
    else
        targetPlayer = FindPlayer(self, player, target)
        if targetPlayer then
            targetName = targetPlayer.displayName
            targetSteamId = rust.UserIDFromPlayer(targetPlayer)
        end
    end

    if targetSteamId then
        if action == "add" then
            local whitelisted = false
            for key, value in pairs(whitelist) do
                if targetSteamId == key then
                    whitelisted = true
                    break
                end
            end

            if not whitelisted then
                whitelist[targetSteamId] = targetName
                datafile.SaveDataTable("Whitelist")

                local message = ParseMessage(self.Config.Messages.PlayerAdded, { target = target, player = target })
                if player then
                    rust.SendChatMessage(player, message)
                else
                    Print(self, message)
                end
            else
                local message = ParseMessage(self.Config.Messages.AlreadyAdded, { target = target, player = target })
                if player then
                    rust.SendChatMessage(player, message)
                else
                    Print(self, message)
                end
            end
            return
        end

        if action == "remove" then
            local whitelisted = false
            for key, value in pairs(whitelist) do
                if targetSteamId == key then
                    whitelisted = true
                    break
                end
            end

            if whitelisted then
                whitelist[targetSteamId] = nil
                datafile.SaveDataTable("Whitelist")

                local message = ParseMessage(self.Config.Messages.PlayerRemoved, { target = target, player = target })
                if player then
                    rust.SendChatMessage(player, message)
                else
                    Print(self, message)
                end
            else
                local message = ParseMessage(self.Config.Messages.NotWhitelisted, { target = target, player = target })
                if player then
                    rust.SendChatMessage(player, message)
                else
                    Print(self, message)
                end
            end
            return
        end
    end
end

function PLUGIN:ChatCommand(player, cmd, args)
    if args.Length ~= 2 then
        rust.SendChatMessage(player, self.Config.Messages.ChatHelp)
        return
    end

    self:Whitelist(args[0], player, args[1])
end

function PLUGIN:ConsoleCommand(args)
    local player
    if args.connection then
        player = args.connection.player
    end

    if not args:HasArgs(2) then
        if not player then
            Print(self, self.Config.Messages.ConsoleHelp)
        else
            args:ReplyWith(self.Config.Messages.ConsoleHelp)
        end
        return
    end

    self:Whitelist(args:GetString(0), player, args:GetString(1))
end

function PLUGIN:SendHelpText(player)
    if HasPermission(rust.UserIDFromPlayer(player), "whitelist") then
        rust.SendChatMessage(player, self.Config.Messages.ChatHelp)
    end
end
