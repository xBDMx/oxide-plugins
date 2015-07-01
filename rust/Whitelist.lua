PLUGIN.Title = "Whitelist"
PLUGIN.Version = V(0, 3, 2)
PLUGIN.Description = "Restricts access to your server to whitelisted players only."
PLUGIN.Author = "Wulf / Luke Spragg"
PLUGIN.Url = "http://oxidemod.org/plugins/654/"
PLUGIN.ResourceId = 654

local debug = false

-- TODO: Move to permissions system?

--[[ Do NOT edit the config here, instead edit Whitelist.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.AlreadyAdded = messages.AlreadyAdded or "{target} is already whitelisted!"
    messages.ChatHelp = messages.ChatHelp or "Use '/whitelist add|remove player|steamid'"
    messages.ConsoleHelp = messages.ConsoleHelp or "Use 'whitelist add|remove player|steamid'"
    messages.InvalidAction = messages.InvalidAction or "Invalid command action! Use add or remove"
    messages.InvalidTarget = messages.InvalidTarget or "Invalid player or Steam ID! Please try again"
    messages.NoPermission = messages.NoPermission or "You do not have permission to use this command!"
    messages.NotWhitelisted = messages.NotWhitelisted or "{target} is not whitelisted!"
    messages.PlayerAdded = messages.PlayerAdded or "{target} has been added to the whitelist!"
    messages.PlayerRemoved = messages.PlayerRemoved or "{target} has been removed from the whitelist!"
    messages.Rejected = messages.Rejected or "Sorry, you are not whitelisted!"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Command = settings.Command or "whitelist"

    self:SaveConfig()
end

local whitelist

function PLUGIN:Init()
    self:LoadDefaultConfig()
    whitelist = datafile.GetDataTable("Whitelist") or {}
    command.AddChatCommand(settings.Command, self.Plugin, "ChatCommand")
    command.AddConsoleCommand("global." .. settings.Command, self.Plugin, "ConsoleCommand")
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
            Print(self, messages.InvalidTarget)
        else
            rust.SendChatMessage(player, messages.InvalidTarget)
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

    return messages.Rejected
end

function PLUGIN:Whitelist(action, player, target)
    if player and not HasPermission(rust.UserIDFromPlayer(player), "whitelist") then
        rust.SendChatMessage(player, messages.NoPermission)
        return
    end

    if action == nil or action ~= "add" and action ~= "remove" then
        if player then
            rust.SendChatMessage(player, messages.InvalidAction)
        else
            Print(self, messages.InvalidAction)
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

                local message = ParseMessage(messages.PlayerAdded, { target = target, player = target })
                if player then
                    rust.SendChatMessage(player, message)
                else
                    Print(self, message)
                end
            else
                local message = ParseMessage(messages.AlreadyAdded, { target = target, player = target })
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

                local message = ParseMessage(messages.PlayerRemoved, { target = target, player = target })
                if player then
                    rust.SendChatMessage(player, message)
                else
                    Print(self, message)
                end
            else
                local message = ParseMessage(messages.NotWhitelisted, { target = target, player = target })
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
        rust.SendChatMessage(player, messages.ChatHelp)
        return
    end

    self:Whitelist(args[0], player, args[1])
end

function PLUGIN:ConsoleCommand(args)
    local player
    if args.connection then player = args.connection.player end

    if not args:HasArgs(2) then
        if not player then
            Print(self, messages.ConsoleHelp)
        else
            args:ReplyWith(messages.ConsoleHelp)
        end
        return
    end

    self:Whitelist(args:GetString(0), player, args:GetString(1))
end

function PLUGIN:SendHelpText(player)
    if HasPermission(rust.UserIDFromPlayer(player), "whitelist") then
        rust.SendChatMessage(player, messages.ChatHelp)
    end
end
