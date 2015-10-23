PLUGIN.Title = "Friendly Fire"
PLUGIN.Version = V(1, 5, 4)
PLUGIN.Description = "Toggle friendly fire on/off for friends."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/687/"
PLUGIN.ResourceId = 687

local debug = false

--[[ Do NOT edit the config here, instead edit FriendlyFire.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.CantHurtFriend = messages.CantHurtFriend or "You can't hurt your friend!"
    messages.ChatHelp = messages.ChatHelp or "Use '/ff' to toggle friendly fire on/off"
    messages.FriendlyFireOff = messages.FriendlyFireOff or "Friendly Fire is now off!"
    messages.FriendlyFireOn = messages.FriendlyFireOn or "Friendly Fire is now on!"
    messages.NoPermission = messages.NoPermission or "You do not have permission to use this command!"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Command = settings.Command or "ff"
    settings.FriendlyFire = settings.FriendlyFire or "false"

    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()

    command.AddChatCommand(settings.Command, self.Plugin, "ChatCommand")
    command.AddConsoleCommand("global." .. settings.Command, self.Plugin, "ConsoleCommand")

    permission.RegisterPermission("ff.toggle", self.Plugin)
end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

local function HasPermission(steamId, perm)
    if permission.UserHasPermission(steamId, perm) then return true end
    return false
end

local friendsApi

function PLUGIN:OnServerInitialized()
    friendsApi = plugins.Find("0friendsAPI") or false
    if not friendsApi then
        Print(self, "Friends API not found! http://oxidemod.org/plugins/686/")
        return
    end
end

function PLUGIN:OnPlayerAttack(attacker, hitInfo)
    if friendsApi and settings.FriendlyFire == "false" then
        if not hitInfo.HitEntity then return end
        if not hitInfo.HitEntity:ToPlayer() then return end

        if debug then Print(self, "HitEntity: " .. tostring(hitInfo.HitEntity)) end

        local targetPlayer = hitInfo.HitEntity
        local targetSteamId = rust.UserIDFromPlayer(targetPlayer)
        local attackerSteamId = rust.UserIDFromPlayer(attacker)

        if targetSteamId and attackerSteamId then
            local hasFriend = friendsApi:CallHook("HasFriend", attackerSteamId, targetSteamId)

            if debug then Print(self, "hasFriend: " .. tostring(hasFriend)) end

            if hasFriend then
                rust.SendChatMessage(attacker, messages.CantHurtFriend)
                hitInfo.damageTypes = new(Rust.DamageTypeList._type, nil)
                hitInfo.HitMaterial = 0
                return true
            end
        end
    end
end

function PLUGIN:ChatCommand(player)
    local steamId = rust.UserIDFromPlayer(player)
    if not HasPermission(steamId, "ff.toggle") then
        rust.SendChatMessage(player, messages.NoPermission)
        return
    end

    if settings.FriendlyFire == "false" then
        settings.FriendlyFire = "true"
        rust.SendChatMessage(player, messages.FriendlyFireOn)
    else
        settings.FriendlyFire = "false"
        rust.SendChatMessage(player, messages.FriendlyFireOff)
    end

    self:SaveConfig()
end

function PLUGIN:ConsoleCommand(args)
    local player
    if args.connection then player = args.connection.player end

    if player and not HasPermission(rust.UserIDFromPlayer(player), "ff.toggle") then
        args:ReplyWith(messages.NoPermission)
        return
    end

    if settings.FriendlyFire == "false" then
        settings.FriendlyFire = "true"
        args:ReplyWith(messages.FriendlyFireOn)
    else
        settings.FriendlyFire = "false"
        args:ReplyWith(messages.FriendlyFireOff)
    end

    self:SaveConfig()
end

function PLUGIN:SendHelpText(player)
    if HasPermission(rust.UserIDFromPlayer(player), "ff.toggle") then
        rust.SendChatMessage(player, messages.ChatHelp)
    end
end
