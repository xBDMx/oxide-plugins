PLUGIN.Title = "Analytics"
PLUGIN.Version = V(0, 2, 0)
PLUGIN.Description = "Real-time collection and reporting of player locations on connect to Google Analytics."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/679/"
PLUGIN.ResourceId = 679
PLUGIN.HasConfig = true

local debug = false

function PLUGIN:Init()
    self:LoadDefaultConfig()
end

function PLUGIN:OnPlayerConnected(packet)
    if not packet then return end
    if not packet.connection then return end
    self:CollectAnalytics(packet.connection, "start")
end

function PLUGIN:OnPlayerDisconnected(player)
    if not player then return end
    if not player.net.connection then return end
    self:CollectAnalytics(player.net.connection, "end")
end

function PLUGIN:CollectAnalytics(connection, session)
    local url = "https://ssl.google-analytics.com/collect?v=1"
    local data = "&tid=" .. self.Config.TrackingID
    .. "&sc=" .. session
    .. "&cid=" .. rust.UserIDFromConnection(connection)
    .. "&uip=" .. connection.ipaddress:match("([^:]*):")
    .. "&ua=" .. tostring(Oxide.Core.OxideMod.Version)
    .. "&dp=" .. global.server.hostname
    .. "&t=pageview"
    webrequests.EnqueueGet(url .. data, function(code, response)
        if debug then
            print("[" .. self.Title .. "] Request URL: " .. url)
            print("[" .. self.Title .. "] Request data: " .. data)
            print("[" .. self.Title .. "] Response: " .. response)
            print("[" .. self.Title .. "] HTTP code: " .. code)
        end
    end, self.Object)
end

function PLUGIN:LoadDefaultConfig()
    self.Config.TrackingID = self.Config.TrackingID or "UA-XXXXXXXX-Y"
    self:SaveConfig()
end
