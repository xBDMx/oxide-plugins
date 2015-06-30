PLUGIN.Title = "Master Key"
PLUGIN.Version = V(0, 1, 2)
PLUGIN.Description = "Allows players with permission to unlock anything."
PLUGIN.Author = "Wulf / Luke Spragg"
PLUGIN.Url = "http://oxidemod.org/plugins/1151/"
PLUGIN.ResourceId = 1151

--[[ Do NOT edit the config here, instead edit MasterKey.json in oxide/config ! ]]

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.LogUsage = self.Config.Settings.LogUsage or "true"
    self.Config.Settings.ShowMessages = self.Config.Settings.ShowMessages or "true"

    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.BoxUnlocked = self.Config.Messages.BoxUnlocked or "<size=20>Box unlocked with master key!</size>"
    self.Config.Messages.DoorUnlocked = self.Config.Messages.DoorUnlocked or "<size=20>Door unlocked with master key!</size>"
    self.Config.Messages.CupboardUnlocked = self.Config.Messages.CupboardUnlocked or "<size=20>Cupboard unlocked with master key!</size>"
    self.Config.Messages.MasterKeyUsed = self.Config.Messages.MasterKeyUsed or "{player} ({steamid}) used master key at {position}"

    self:SaveConfig()
end

local function ParseMessage(message, values)
    for key, value in pairs(values) do message = message:gsub("{" .. key .. "}", value) end
    return message
end

local function HasPermission(steamId, perm)
    if permission.UserHasPermission(steamId, perm) then return true end
    return false
end

local function Log(self, player, message, steamId)
    local position = player.transform.position.x .. ", "
                  .. player.transform.position.y .. ", "
                  .. player.transform.position.z

    local message = ParseMessage(message, { player = player.displayName, steamid = steamId, position = position })
    ConVar.Server.Log("oxide/logs/masterkeys_" .. time.GetCurrentTime():ToLocalTime():ToString("d-M-yyyy") .. ".txt", message)
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    permission.RegisterPermission("masterkey.all", self.Plugin)
    permission.RegisterPermission("masterkey.boxes", self.Plugin)
    permission.RegisterPermission("masterkey.doors", self.Plugin)
    permission.RegisterPermission("masterkey.cupboards", self.Plugin)
end

function PLUGIN:CanOpenDoor(player, lock)
    local entity = lock.parentEntity:Get(true):LookupPrefabName()
    local steamId = rust.UserIDFromPlayer(player)

    if entity == "items/woodbox_deployed" then
        if HasPermission(steamId, "masterkey.all") or HasPermission(steamId, "masterkey.boxes") then
            if self.Config.Settings.ShowMessages == "true" then
                rust.SendChatMessage(player, self.Config.Messages.BoxUnlocked)
            end
            Log(self, player, self.Config.Messages.MasterKeyUsed, steamId)

            return true
        end
    end

    if entity == "build/door.hinged" then
        if HasPermission(steamId, "masterkey.all") or HasPermission(steamId, "masterkey.doors") then
            if self.Config.Settings.ShowMessages == "true" then
                rust.SendChatMessage(player, self.Config.Messages.DoorUnlocked)
            end
            Log(self, player, self.Config.Messages.MasterKeyUsed, steamId)

            return true
        end
    end
end

function PLUGIN:OnEntityEnter(trigger, entity)
    if entity:ToPlayer() then
        local player = entity:ToPlayer()
        local steamId = rust.UserIDFromPlayer(player)

        if trigger:GetType() == global.BuildPrivilegeTrigger._type then
            if HasPermission(steamId, "masterkey.all") or HasPermission(steamId, "masterkey.cupboards") then
                if self.Config.Settings.ShowMessages == "true" then
                    rust.SendChatMessage(player, self.Config.Messages.CupboardUnlocked)
                end
                Log(self, player, self.Config.Messages.MasterKeyUsed, steamId)

                timer.Once(0.1, function()
                    player:SetPlayerFlag(global.BasePlayer.PlayerFlags.HasBuildingPrivilege, true)
                end, self.Plugin)
                return
            end
        end
    end
end
