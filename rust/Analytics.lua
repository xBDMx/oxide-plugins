PLUGIN.Title = "Analytics"
PLUGIN.Version = V(0, 3, 0)
PLUGIN.Description = "Real-time collection and reporting of player locations to Google Analytics."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/679/"
PLUGIN.ResourceId = 679

local debug = false
local game = "rust"

-- TODO:
---- Add timed updates of player status

--[[ Do NOT edit the config here, instead edit Analytics.json in oxide/config ! ]]

function PLUGIN:LoadDefaultConfig()
    self.Config.TrackingId = self.Config.TrackingId or "UA-XXXXXXXX-Y"

    self:SaveConfig()
end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

local server = covalence.Server

local function GetSteamId(connection)
    if game == "rust" then return rust.UserIDFromConnection(connection) end
    if game == "legacy" then return rust.UserIDFromPlayer(connection) end
    if game == "rok" then return rok.IdFromConnection(connection) end
    --if game == "7dtd" then return sdtd.IdFromConnection(connection) end
    return false
end

local function GetIp(connection)
    if game == "rust" then return connection.ipaddress:match("([^:]*):") end
    return false
end

local function GetHostname()
    if game == "rust" then return server.Name end
    if game == "legacy" then return global.server.hostname end
    if game == "rok" then return global.DedicatedServerBypass.get_Settings().ServerName end
    --if game == "7dtd" then return global.GamePrefs.GetString(EnumGamePrefs.ServerName) end
    return false
end

function PLUGIN:Init() self:LoadDefaultConfig() end

function PLUGIN:OnPlayerConnected(packet)
    if not packet then return end
    if not packet.connection then return end

    self:CollectAnalytics(packet.connection, "start")
end

function PLUGIN:OnPlayerDisconnected(player)
    if not player then return end
    if not player.net then return end
    if not player.net.connection then return end

    self:CollectAnalytics(player.net.connection, "end")
end

function PLUGIN:CollectAnalytics(connection, session)
    local url = "https://ssl.google-analytics.com/collect?v=1"
    local data = "&tid=" .. self.Config.TrackingId
    .. "&sc=" .. session
    .. "&cid=" .. GetSteamId(connection)
    .. "&uip=" .. GetIp(connection)
    .. "&ua=" .. Oxide.Core.OxideMod.Version:ToString()
    .. "&dp=" .. GetHostname()
    .. "&t=pageview"

    webrequests.EnqueuePost(url, data, function(code, response)
        if debug then
            Print(self, "Request URL: " .. url)
            Print(self, "Request data: " .. data)
            Print(self, "Response: " .. response)
            Print(self, "HTTP code: " .. code)
        end
    end, self.Plugin)
end
