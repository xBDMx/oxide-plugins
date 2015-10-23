PLUGIN.Title = "Country Block"
PLUGIN.Version = V(0, 1, 8)
PLUGIN.Description = "Allows or blocks players from specific countries via a whitelist or blacklist of country codes."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/698/"
PLUGIN.ResourceId = 698

local debug = false

-- TODO:
---- Fix chat help for chat command
---- Fix "Array index is out of range" when using invalid single arg or no arg
---- Add console command function
---- Add command action to list the countries on the blacklist/whitelist

--[[ Do NOT edit the config here, instead edit CountryBlock.json in oxide/config ! ]]

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.AdminExcluded = self.Config.Settings.AdminExcluded or "true"
    self.Config.Settings.AuthLevel = tonumber(self.Config.Settings.AuthLevel) or 2
    self.Config.Settings.Broadcast = self.Config.Settings.Broadcast or "true"
    self.Config.Settings.ChatCommand = self.Config.Settings.ChatCommand or "country"
    self.Config.Settings.ConsoleCommand = self.Config.Settings.ConsoleCommand or "country.block"
    self.Config.Settings.CountryList = self.Config.Settings.CountryList or { "UK", "US" }
    self.Config.Settings.ListType = self.Config.Settings.ListType or "whitelist"

    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.AlreadyAdded = self.Config.Messages.AlreadyAdded or "{country} is already on the country list!"
    self.Config.Messages.ChatHelp = self.Config.Messages.ChatHelp or {
        "Use /country add countrycode to add a country to the list",
        "Use /country remove countrycode to remove a country from the list",
        "Use /country list to list all the countries on the list"
    }
    self.Config.Messages.CountryAdded = self.Config.Messages.CountryAdded or "{country} has been added to the country list!"
    self.Config.Messages.CountryRemoved = self.Config.Messages.CountryRemoved or "{country} has been removed from the country list!"
    self.Config.Messages.NoPermission = self.Config.Messages.NoPermission or "You do not have permission to use this command!"
    self.Config.Messages.NotListed = self.Config.Messages.NotListed or "{country} is not on the country list!"
    self.Config.Messages.ListTypeChanged = self.Config.Messages.ListTypeChanged or "Country list type changed to {listtype}"
    self.Config.Messages.PlayerKicked = self.Config.Messages.PlayerKicked or "{player} was kicked as their country ({country}) is blocked!"
    self.Config.Messages.PlayerRejected = self.Config.Messages.PlayerRejected or self.Config.Messages.Rejected or "Sorry, this server doesn't allow players from your country!"
    self.Config.Messages.UnknownAction = self.Config.Messages.UnknownAction or "Unknown command action! Use add, remove, list, or type"
    self.Config.Messages.UnknownListType = self.Config.Messages.UnknownListType or "Unknown list type! Use blacklist or whitelist"

    self.Config.Settings.ChatName = nil -- Removed in 0.1.8
    self.Config.Settings.ChatNameHelp = nil -- Removed in 0.1.8
    self.Config.Messages.Rejected = nil -- Removed in 0.1.8

    self:SaveConfig()
end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

local function ParseString(message, values)
    for key, value in pairs(values) do
        value = tostring(value):gsub("[%-?*+%[%]%(%)%%]", "%%%%%0")
        message = message:gsub("{" .. key .. "}", value)
    end
    return message
end

local function HasPermission(self, connection)
    local authLevel = (connection and connection.authLevel) or 2
    if debug then print(connection.username .. " has auth level: " .. tostring(authLevel)) end
    local neededLevel = tonumber(self.Config.Settings.AuthLevel) or 2
    return authLevel >= neededLevel
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

local function IsLocalIp(ip)
    local ipRanges = { 10, 127, 172, 192 }
    for i = 1, #ipRanges do
        if ip:match(ipRanges[i] .. "%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)") then return true end
    end
    return false
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.ChatCommand, self.Plugin, "ChatCommand")
    --command.AddConsoleCommand(self.Config.Settings.ConsoleCommand, self.Plugin, "ConsoleCommand")
end

local blacklisted, whitelisted = false, false
function PLUGIN:CanClientLogin(connection)
    if not debug then if self.Config.Settings.AdminExcluded ~= "false" and HasPermission(self, connection) then return end end
    local playerIp = connection.ipaddress:match("([^:]*):")
    if debug then playerIp = "84.200.69.125"; Print(self, "IP for " .. connection.username .. ": " .. playerIp) end
    if IsLocalIp(playerIp) then return end
    local country = GetCountryFromIp(self, playerIp)
    if not country then
        Print(self, "Checking country for " .. connection.username .. " failed!")
        self:DeportPlayer(connection, country)
        return
    end
    local listType = self.Config.Settings.ListType
    if string.lower(listType) == "blacklist" and self:ListCheck(country) then
        self:DeportPlayer(connection, country)
    end
    if string.lower(listType) == "whitelist" and not self:ListCheck(country) then
        self:DeportPlayer(connection, country)
    end
end

function PLUGIN:ListCheck(arg)
    local list = self.Config.Settings.CountryList
    for _, entry in pairs(list) do if arg == entry then return true end end
end

function PLUGIN:DeportPlayer(connection, country)
    local message = ParseString(self.Config.Messages.PlayerRejected, { player = connection.username, country = homeland })
    Network.Net.sv:Kick(connection, message)
    local message = ParseString(self.Config.Messages.PlayerKicked, { player = connection.username, country = homeland })
    if self.Config.Settings.BroadcastKick == "true" then rust.BroadcastChat(message) end
    Print(self, message)
end

function PLUGIN:ChatCommand(player, cmd, args)
    if player and not HasPermission(self, player.net.connection) then
        rust.SendChatMessage(player, self.Config.Messages.NoPermission)
        return
    end
    local argument = string.upper(args[1])
    --[[if string.len(country) > 2 or string.len(country) < 2 then -- args.Length ~= 2, bring this back but support 1 for list action?
        rust.SendChatMessage(player, self.Config.Messages.ChatHelp) -- Can't do this with an array :/
        return
    end]]
    local action = args[0]
    local list = self.Config.Settings.CountryList
    if action == nil or action ~= "add" and action ~= "remove" and action ~= "type" then
        rust.SendChatMessage(player, self.Config.Messages.UnknownAction)
        return
    end
    if action == "add" then
        local listed
        for key, value in pairs(list) do if argument == value then listed = true; break end end
        if not listed then
            table.insert(list, argument)
            self:SaveConfig()
            local message = ParseString(self.Config.Messages.CountryAdded, { country = argument })
            rust.SendChatMessage(player, message)
        else
            local message = ParseString(self.Config.Messages.AlreadyAdded, { country = argument })
            rust.SendChatMessage(player, message)
        end
        return
    end
    if action == "remove" then
        local listed
        for key, value in pairs(list) do if argument == value then listed = true; break end end
        if listed then
            table.remove(list, key)
            self:SaveConfig()
            local message = ParseString(self.Config.Messages.CountryRemoved, { country = argument })
            rust.SendChatMessage(player, message)
        else
            local message = ParseString(self.Config.Messages.NotListed, { country = argument })
            rust.SendChatMessage(player, message)
        end
        return
    end
    if action == "type" then
        if string.lower(argument) == "blacklist" or string.lower(argument) == "whitelist" then
            self.Config.Settings.ListType = string.lower(argument)
            self:SaveConfig()
            local message = ParseString(self.Config.Messages.ListTypeChanged, { listtype = argument })
            rust.SendChatMessage(player, message)
            return
        else
            rust.SendChatMessage(player, self.Config.Messages.UnknownListType)
        end
        return
    end
    --[[if action == "list" then
        local countries = ""
        --for i = 1, #list do print(list[i]); countries = countries .. ", " .. list[i] end
        rust.SendChatMessage(player, countries)
    end]]
end

function PLUGIN:SendHelpText(player)
    if HasPermission(self, player.net.connection) then
        for i = 1, #self.Config.Messages.ChatHelp do
            rust.SendChatMessage(player, self.Config.Messages.ChatHelp[i])
        end
    end
end
