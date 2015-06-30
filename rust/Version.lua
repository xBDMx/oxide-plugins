PLUGIN.Title = "Version"
PLUGIN.Version = V(0, 1, 0)
PLUGIN.Description = "Shows current Oxide and Rust versions on command."
PLUGIN.Author = "Wulf / Luke Spragg"

function PLUGIN:Init()
    command.AddChatCommand("version", self.Plugin, "ShowVersion")
end

local function SendChatMessage(player, message)
    if game == "rust" then player.ConnectedPlayer:SendChatMessage(message) return end
    if game == "legacy" then rust.SendChatMessage(player, message) return end
    if game == "rok" then rok.SendChatMessage(player, message) return end
    --if game == "7dtd" then sdtd.SendChatMessage(player, message) return end
end

Command{ "version" }
function PLUGIN:ShowVersion(player, cmd, args)
    local rustProtocol = Rust.Protocol.network
    local oxideVersion = Oxide.Core.OxideMod.Version:ToString()

    SendChatMessage(player, "<size=15><b>Server is running "
    .. "<color=orange>Oxide Mod v" .. oxideVersion .. "</color> and "
    .. "<color=red>Rust v" .. rustProtocol .. "</color></b></size>")
end
