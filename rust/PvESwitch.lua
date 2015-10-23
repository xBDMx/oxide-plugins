PLUGIN.Title = "PvE Switch"
PLUGIN.Version = V(1, 2, 0)
PLUGIN.Description = "Allows you to switch between PvE and PvP modes."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/694/"
PLUGIN.ResourceId = 694

--[[ Do NOT edit the config here, instead edit PvESwitch.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.NoPermission = messages.NoPermission or "You do not have permission to use this command!"
    messages.PvP = messages.PvP or "PvP has been enabled"
    messages.PvE= messages.PvE or "PvE has been enabled"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Command = settings.Command or "pve"

    self:SaveConfig()
end

local function HasPermission(steamId, perm)
    if permission.UserHasPermission(steamId, perm) then return true end
    return false
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(settings.Command, self.Plugin, "ChatCommand")
    permission.RegisterPermission("pve.switch", self.Plugin)
end

function PLUGIN:ChatCommand(player)
    if player and not HasPermission(rust.UserIDFromPlayer(player), "pve.switch") then
        rust.SendChatMessage(player, messages.NoPermission)
        return
    end

    if ConVar.Server.pve then
        rust.RunServerCommand("server.pve false")
        rust.SendChatMessage(player, messages.PvP)
    else
        rust.RunServerCommand("server.pve true")
        rust.SendChatMessage(player, messages.PvE)
    end
end

function PLUGIN:OnRunCommand(arg)
    if not arg then return end
    if not arg.connection then return end
    if not arg.connection.player then return end
    if not arg.cmd then return end
    if not arg.cmd.namefull then return end

    local player = arg.connection.player

    if arg.cmd.namefull == "server.pve" then
        if player and not HasPermission(rust.UserIDFromPlayer(player), "pve.switch") then
            player:SendConsoleCommand("echo " .. messages.NoPermission)
            return false
        end
    end
end
