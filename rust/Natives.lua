PLUGIN.Title = "Natives"
PLUGIN.Version = V(0, 1, 9)
PLUGIN.Description = "Allows only players from the server's country to join."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/678/"
PLUGIN.ResourceId = 678

local debug = false

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.BroadcastKick = self.Config.Settings.BroadcastKick or self.Config.Settings.Broadcast or "true"

    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.PlayerKicked = self.Config.Messages.PlayerKicked or self.Config.Messages.Kicked or "{player} kicked for not being from {country}!"
    self.Config.Messages.PlayerRejected = self.Config.Messages.PlayerRejected or self.Config.Messages.Rejected or "Sorry, this server only allows players from {country}!"

    self.Config.Settings.ChatName = nil -- Removed in 0.1.9
    self.Config.Messages.Kicked = nil -- Removed in 0.1.9
    self.Config.Messages.Rejected = nil -- Removed in 0.1.9

    self:SaveConfig()
end

function PLUGIN:Init() self:LoadDefaultConfig() end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

local function ParseString(message, values)
    for key, value in pairs(values) do
        value = tostring(value):gsub("[%-?*+%[%]%(%)%%]", "%%%%%0")
        message = message:gsub("{" .. key .. "}", value)
    end
    return message
end

local function FormatIpAddress(ip)
    return ("%s.%s.%s.%s"):format(bit32.rshift(ip, 24), bit32.band(bit32.rshift(ip, 16), 0xff), bit32.band(bit32.rshift(ip, 8), 0xff), bit32.band(ip, 0xff))
end

local function GetCountryFromIp(self, ip)
    local urls = { "http://api.hostip.info/country.php?ip=" .. ip, "http://ipinfo.io/" .. ip .. "/country" }
    local url = urls[math.random(1, #urls)]
    if debug then Print(self, url) end
    webrequests.EnqueueGet(url, function(code, response)
        country = response:gsub("\n", "")
        if debug then Print(self, "Response: " .. country .. ", Code: " .. code) end
        if country == "undefined" or country == "xx" or code ~= 200 then
            Print(self, "Getting country for " .. ip .. " failed!")
            return
        end
    end, self.Plugin)
    return country
end

local serverIp; local homeland = "undefined"
function PLUGIN:OnServerInitialized()
    self.ipTimer = timer.Once(5, function()
        serverIp = FormatIpAddress(Steamworks.SteamGameServer.GetPublicIP())
        if debug then Print(self, "Server's IP: " .. serverIp) end
        if serverIp == "" or serverIp == "0.0.0.0" then Print(self, "Getting IP for server failed!") end
        homeland = GetCountryFromIp(self, serverIp)
    end, self.Plugin)
end

local function IsLocalIp(ip)
    local ipRanges = { 10, 127, 172, 192 }
    for i = 1, #ipRanges do
        if ip:match(ipRanges[i] .. "%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)") then return true end
    end
    return false
end

function PLUGIN:CanClientLogin(connection)
    local playerIp = connection.ipaddress:match("([^:]*):")
    if debug then playerIp = "84.200.69.125"; Print(self, "IP for " .. connection.username .. ": " .. playerIp) end
    if IsLocalIp(playerIp) then return end
    local country = GetCountryFromIp(self, playerIp)
    if not country then
        Print("Checking country for " .. connection.username .. " failed!")
        self:DeportPlayer(connection, country)
        return
    end
    if country ~= homeland then self:DeportPlayer(connection, country) end
end

function PLUGIN:DeportPlayer(connection, country)
    local message = ParseString(self.Config.Messages.PlayerRejected, { player = connection.username, country = homeland })
    Network.Net.sv:Kick(connection, message)
    local message = ParseString(self.Config.Messages.PlayerKicked, { player = connection.username, country = homeland })
    if self.Config.Settings.BroadcastKick == "true" then rust.BroadcastChat(message) end
    Print(self, message)
end
