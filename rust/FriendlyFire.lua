PLUGIN.Title = "Friendly Fire"
PLUGIN.Version = V(1, 5, 3)
PLUGIN.Description = "Toggle friendly fire on/off for friends."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://oxidemod.org/plugins/687/"
PLUGIN.ResourceId = 687

local debug = false

--[[ Do NOT edit the config here, instead edit FriendlyFire.json in oxide/config ! ]]

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.Command = self.Config.Settings.Command or self.Config.Settings.ChatCommand or "ff"
    self.Config.Settings.FriendlyFire = self.Config.Settings.FriendlyFire or "true"

    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.CantHurtFriend = self.Config.Messages.CantHurtFriend or "You can't hurt your friend!"
    self.Config.Messages.ChatHelp = self.Config.Messages.ChatHelp or "Use '/ff' to toggle friendly fire on/off"
    self.Config.Messages.FriendlyFireOff = self.Config.Messages.FriendlyFireOff or "Friendly Fire is now off!"
    self.Config.Messages.FriendlyFireOn = self.Config.Messages.FriendlyFireOn or "Friendly Fire is now on!"
    self.Config.Messages.NoPermission = self.Config.Messages.NoPermission or "You do not have permission to use this command!"

    self.Config.Settings.ChatCommand = nil -- Removed in 1.5.1
    self.Config.Settings.ConsoleCommand = nil -- Removed in 1.5.1

    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.Command, self.Plugin, "ChatCommand")
    command.AddConsoleCommand("global." .. self.Config.Settings.Command, self.Plugin, "ConsoleCommand")
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
    if friendsApi and self.Config.Settings.FriendlyFire == "false" then
        if debug then Print(self, "HitEntity: " .. tostring(hitInfo.HitEntity)) end

        if hitInfo.HitEntity then
            if hitInfo.HitEntity:ToPlayer() then
                local targetPlayer = hitInfo.HitEntity
                local targetSteamId = rust.UserIDFromPlayer(targetPlayer)
                local attackerSteamId = rust.UserIDFromPlayer(attacker)
                local hasFriend = friendsApi:CallHook("HasFriend", attackerSteamId, targetSteamId)

                if debug then Print(self, "hasFriend: " .. tostring(hasFriend)) end

                if hasFriend then
                    rust.SendChatMessage(attacker, self.Config.Messages.CantHurtFriend)
                    hitInfo.damageTypes = new(Rust.DamageTypeList._type, nil)
                    hitInfo.HitMaterial = 0
                    return true
                end
            end
        end
    end
end

function PLUGIN:ChatCommand(player)
    local steamId = rust.UserIDFromPlayer(player)
    if not HasPermission(steamId, "ff.toggle") then
        rust.SendChatMessage(player, self.Config.Messages.NoPermission)
        return
    end

    if self.Config.Settings.FriendlyFire == "false" then
        self.Config.Settings.FriendlyFire = "true"
        rust.SendChatMessage(player, self.Config.Messages.FriendlyFireOn)
    else
        self.Config.Settings.FriendlyFire = "false"
        rust.SendChatMessage(player, self.Config.Messages.FriendlyFireOff)
    end

    self:SaveConfig()
end

function PLUGIN:ConsoleCommand(args)
    local player
    if args.connection then player = args.connection.player end

    if player and not HasPermission(rust.UserIDFromPlayer(player), "ff.toggle") then
        args:ReplyWith(self.Config.Messages.NoPermission)
        return
    end

    if self.Config.Settings.FriendlyFire == "false" then
        self.Config.Settings.FriendlyFire = "true"
        args:ReplyWith(self.Config.Messages.FriendlyFireOn)
    else
        self.Config.Settings.FriendlyFire = "false"
        args:ReplyWith(self.Config.Messages.FriendlyFireOff)
    end

    self:SaveConfig()
end

function PLUGIN:SendHelpText(player)
    if HasPermission(rust.UserIDFromPlayer(player), "ff.toggle") then
        rust.SendChatMessage(player, self.Config.Messages.ChatHelp)
    end
end
