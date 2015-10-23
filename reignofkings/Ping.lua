PLUGIN.Title = "Ping"
PLUGIN.Version = V(0, 4, 0)
PLUGIN.Description = "Ping checking and optional high ping kicking."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/656/"
PLUGIN.ResourceId = 656

local debug = false

-- TODO:
---- Add command to change max ping, with permissions
---- Fix NRE when using "ping" with no args via console or RCON

--[[ Do NOT edit the config here, instead edit Ping.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.ChatHelp = messages.ChatHelp or "Use '/ping player' to check target player's ping"
    messages.InvalidTarget = messages.InvalidTarget or "Invalid target player! Please try again"
    messages.NoPermission = messages.NoPermission or "You do not have permission to use this command!"
    messages.PlayerCheck = messages.PlayerCheck or "{player} has a ping of {ping}ms"
    messages.PlayerExcluded = messages.PlayerExcluded or "{player} is excluded from ping checks!"
    messages.PlayerKicked = messages.PlayerKicked or "{player} was kicked for high ping ({ping}ms)"
    messages.Rejected = messages.Rejected or "Your ping is too high for this server!"
    messages.SelfCheck = messages.SelfCheck or "You have a ping of {ping}ms"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Command = settings.Command or "ping"
    settings.MaxPing = tonumber(settings.MaxPing) or 200 -- Milliseconds
    settings.PingKick = settings.PingKick or "true"
    settings.BroadcastKick = settings.BroadcastKick or "true"

    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(settings.Command, self.Plugin, "ChatCommand")
    permission.RegisterPermission("ping.bypass", self.Plugin)
    permission.RegisterPermission("ping.check", self.Plugin)
end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

local function ParseString(message, values)
    for key, value in pairs(values) do
        value = tostring(value):gsub("[%-?*+%[%]%(%)%%]", "%%%%%0")
        message = message:gsub("{" .. key .. "}", value)
    end
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
            rok.SendChatMessage(player, messages.InvalidTarget)
        end
        return
    end
    return targetPlayer
end

local function Ping(connection) return Network.Net.sv:GetAveragePing(connection) end

function PLUGIN:PingKick(player)
    local ping = Ping(player.net.connection)
    if settings.PingKick == "true" then
        if ping >= settings.MaxPing then
            local message = ParseString(messages.PlayerKicked, { player = player.displayName, ping = ping })
            print("[".. self.Title .. "] " .. message)
            Network.Net.sv:Kick(player.net.connection, messages.Rejected)
            if settings.BroadcastKick == "true" then
                rok.BroadcastChat(message)
            end
        end
    end
    return ping
end

function PLUGIN:OnPlayerConnected(player)
    if not player then return end
    
    print(CodeHatch.Engine.Networking.Connection.get_AveragePing(player))

    self:PingKick(player)
end

function PLUGIN:ChatCommand(player, cmd, args)
    if args.Length > 1 then
        rok.SendChatMessage(player, messages.ChatHelp)
        return
    end

    print(player.LastPing)
    print(player.AveragePing)

    if args.Length == 1 then
        local steamId = rok.IdFromPlayer(player)
        if player and not HasPermission(steamId, "ping.check") then
            rok.SendChatMessage(player, messages.NoPermission)
            return
        end

        local targetPlayer = FindPlayer(self, player, args[0])
        if targetPlayer then
            local steamId = rok.IdFromPlayer(targetPlayer)
            if HasPermission(steamId, "ping.bypass") then
                local message = ParseString(messages.PlayerExcluded, { player = targetPlayer.displayName })
                rok.SendChatMessage(player, message)
                return
            end
            local ping = self:PingKick(targetPlayer)
            local message = ParseString(messages.PlayerCheck, { player = targetPlayer.displayName, ping = ping })
            rok.SendChatMessage(player, message)
        end
    else
        local ping = Ping(player.net.connection)
        local message = ParseString(messages.SelfCheck, { player = player.displayName, ping = ping })
        rok.SendChatMessage(player, message)
    end
end

function PLUGIN:SendHelpText(player)
    if HasPermission(rok.IdFromPlayer(player), "ping.check") then
        rok.SendChatMessage(player, messages.ChatHelp)
    end
end
