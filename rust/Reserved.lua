PLUGIN.Title = "Reserved"
PLUGIN.Version = V(0, 2, 1)
PLUGIN.Description = "Reserves a number of slots so that reserved players can connect."
PLUGIN.Author = "Wulf / Luke Spragg"
PLUGIN.Url = "http://oxidemod.org/plugins/674/"
PLUGIN.ResourceId = 674

local debug = false

--[[ Do NOT edit the config here, instead edit Reserved.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.AlreadyAdded = messages.AlreadyAdded or "{player} ({steamid}) is already on the reserved list!"
    messages.ChatHelp = messages.ChatHelp or "Use '/reserved add|remove|slots player|steamid|#'"
    messages.InvalidTarget = messages.InvalidTarget or "Invalid player or Steam ID! Please try again"
    messages.NoPermission = messages.NoPermission or "You do not have permission to use this command!"
    messages.NotReserved = messages.NotReserved or "{player} ({steamid}) is not on the reserved list!"
    messages.PlayerAdded = messages.PlayerAdded or "{player} ({steamid}) has been added to the reserved list!"
    messages.PlayerRemoved = messages.PlayerRemoved or "{player} ({steamid}) has been removed from the reserved list!"
    messages.Rejected = messages.Rejected or "Sorry, the maximum number of players are connected!"
    messages.ReservedSlots = messages.ReservedSlots or "Reserved slots set to {number}!"
    messages.UnknownAction = messages.UnknownAction or "Unknown command action! Use add, remove, or slots"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Command = settings.Command or settings.ChatCommand or "reserved"
    settings.ReservedSlots = tonumber(settings.ReservedSlots) or 10

    settings.AuthLevel = nil -- Removed in 0.2.0
    settings.ChatCommand = nil -- Removed in 0.2.0
    settings.ChatName = nil -- Removed in 0.2.0
    settings.ChatNameHelp = nil -- Removed in 0.2.0
    settings.ReservedList = nil -- Removed in 0.2.0

    self:SaveConfig()
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

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(settings.Command, self.Plugin, "ChatCommand")
    command.AddConsoleCommand("global." .. settings.Command, self.Plugin, "ConsoleCommand")
    permission.RegisterPermission("reserved.manage", self.Plugin)
    permission.RegisterPermission("reserved.bypass", self.Plugin)
end

function PLUGIN:CanClientLogin(connection)
    local players = global.BasePlayer.activePlayerList.Count
    local steamId = rust.UserIDFromConnection(connection)
    local maxPlayers = ConVar.Server.maxplayers

    if players + tonumber(settings.ReservedSlots) >= maxPlayers then
        if not HasPermission(steamId, "reserved.bypass") then
            return messages.Rejected
        end
    end
end

function PLUGIN:Reserve(player, action, arg)
    if player and not HasPermission(rust.UserIDFromPlayer(player), "reserved.manage") then
        if player then
            rust.SendChatMessage(player, messages.NoPermission)
        else
            Print(self, messages.NoPermission)
        end
        return
    end

    if action == nil or action ~= "add" and action ~= "remove" and action ~= "slots" then
        if player then
            rust.SendChatMessage(player, messages.UnknownAction)
        else
            Print(self, messages.UnknownAction)
        end
        return
    end

    local list = settings.ReservedList

    if action == "add" then
        local target = FindPlayer(self, player, arg)
        if target then
            local steamId = rust.UserIDFromPlayer(target)

            if not HasPermission(steamId, "reserved.bypass") then
                rust.RunServerCommand("oxide.grant user " .. steamId .. " reserved.bypass")

                local message = ParseMessage(messages.PlayerAdded, { player = player.displayName, steamid = steamId })
                if player then
                    rust.SendChatMessage(player, message)
                else
                    Print(self, message)
                end
            else
                local message = ParseMessage(messages.AlreadyAdded, { player = player.displayName, steamid = steamId })
                if player then
                    rust.SendChatMessage(player, message)
                else
                    Print(self, message)
                end
            end
            return
        end
    end

    if action == "remove" then
        local target = FindPlayer(self, player, arg)
        if target then
            local steamId = rust.UserIDFromPlayer(target)

            if HasPermission(steamId, "reserved.bypass") then
                rust.RunServerCommand("oxide.revoke user " .. steamId .. " reserved.bypass")

                local message = ParseMessage(messages.PlayerRemoved, { player = player.displayName, steamid = steamId })
                if player then
                    rust.SendChatMessage(player, message)
                else
                    Print(self, message)
                end
            else
                local message = ParseMessage(messages.NotReserved, { player = player.displayName, steamid = steamId })
                if player then
                    rust.SendChatMessage(player, message)
                else
                    Print(self, message)
                end
            end
            return
        end
    end

    if action == "slots" then
        settings.ReservedSlots = tonumber(arg)

        local message = ParseMessage(messages.ReservedSlots, { number = arg })
        if player then
            rust.SendChatMessage(player, message)
        else
            Print(self, message)
        end

        self:SaveConfig()
    end
end

function PLUGIN:ChatCommand(player, cmd, args)
    if args.Length ~= 2 then
        rust.SendChatMessage(player, messages.ChatHelp)
        return
    end

    self:Reserve(player, args[0], args[1])
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

    self:Reserve(player, args:GetString(0), args:GetString(1))
end

function PLUGIN:SendHelpText(player)
    if HasPermission(GetSteamId(player), "reserve.slots") then
        SendChatMessage(player, messages.ChatHelp)
    end
end
