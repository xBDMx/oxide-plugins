PLUGIN.Title = "Master Key"
PLUGIN.Version = V(0, 1, 3)
PLUGIN.Description = "Allows players with permission to unlock anything."
PLUGIN.Author = "Wulf / Luke Spragg"
PLUGIN.Url = "http://oxidemod.org/plugins/1151/"
PLUGIN.ResourceId = 1151

--[[ Do NOT edit the config here, instead edit MasterKey.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.BoxUnlocked = messages.BoxUnlocked or "<size=20>Box unlocked with master key!</size>"
    messages.DoorUnlocked = messages.DoorUnlocked or "<size=20>Door unlocked with master key!</size>"
    messages.CupboardUnlocked = messages.CupboardUnlocked or "<size=20>Cupboard unlocked with master key!</size>"
    messages.MasterKeyUsed = messages.MasterKeyUsed or "{player} ({steamid}) used master key at {position}"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.LogUsage = settings.LogUsage or "true"
    settings.ShowMessages = settings.ShowMessages or "true"

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

function PLUGIN:CanUseDoor(player, lock)
    local entity = lock.parentEntity:Get(true):LookupPrefabName()
    local steamId = rust.UserIDFromPlayer(player)

    if entity == "items/woodbox_deployed" then
        if HasPermission(steamId, "masterkey.all") or HasPermission(steamId, "masterkey.boxes") then
            if settings.ShowMessages == "true" then
                rust.SendChatMessage(player, messages.BoxUnlocked)
            end
            Log(self, player, messages.MasterKeyUsed, steamId)

            return true
        end
    end

    if entity == "build/door.hinged" then
        if HasPermission(steamId, "masterkey.all") or HasPermission(steamId, "masterkey.doors") then
            if settings.ShowMessages == "true" then
                rust.SendChatMessage(player, messages.DoorUnlocked)
            end
            Log(self, player, messages.MasterKeyUsed, steamId)

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
                if settings.ShowMessages == "true" then
                    rust.SendChatMessage(player, messages.CupboardUnlocked)
                end
                Log(self, player, messages.MasterKeyUsed, steamId)

                timer.Once(0.1, function()
                    player:SetPlayerFlag(global.BasePlayer.PlayerFlags.HasBuildingPrivilege, true)
                end, self.Plugin)
                return
            end
        end
    end
end
