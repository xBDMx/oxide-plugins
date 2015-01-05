PLUGIN.Title = "Updater"
PLUGIN.Version = V(0, 2, 5)
PLUGIN.Description = "Automatic update checking and notifications for plugins."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/681/"
PLUGIN.ResourceId = 681
PLUGIN.HasConfig = true

local debug = false

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.ChatCommand, self.Object, "cmdUpdate")
    command.AddConsoleCommand(self.Config.Settings.ConsoleCommand, self.Object, "ccmdUpdate")
end

function PLUGIN:OnServerInitialized()
    self:UpdateCheck()
    if tonumber(self.Config.Settings.CheckInterval) > 0 then self.updateTimer = timer.Repeat(tonumber(self.Config.Settings.CheckInterval), 0, function() self:UpdateCheck() end) end
end

function PLUGIN:cmdUpdate(player, cmd)
    if player and not self:PermissionsCheck(player) then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.NoPermission .. "\""); return end
    self:UpdateCheck(player)
end

function PLUGIN:ccmdUpdate(arg)
    local player = nil
    if arg.connection then player = arg.connection.player end
    if player and not self:PermissionsCheck(player) then player:SendConsoleCommand("echo " .. self.Config.Messages.NoPermission); return end
    self:UpdateCheck(player)
end

function PLUGIN:UpdateCheck(player)
    print(self.Config.Messages.CheckStarted)
    if player then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.CheckStarted .. "\"") end
    local outdatedTable; local outdated = 0; local supported = 0
    local pluginList = plugins.GetAll()
    for i = 0, pluginList.Length - 1 do
        local title = pluginList[i].Object.Title
        local version = pluginList[i].Object.Version:ToString()
        local resourceId = tostring(pluginList[i].Object.ResourceId or pluginList[i].Object.ResourceID or pluginList[i].Object.RID)
        if resourceId ~= nil and resourceId ~= "" and tonumber(resourceId) ~= 0 and resourceId:match("%d") then
            supported = supported + 1
            local url = "https://dev.wulf.im/oxide/" .. resourceId
            webrequests.EnqueueGet(url, function(code, response)
                supported = supported - 1
                if code == 200 and response ~= "" then
                    if version < response then
                        self:LogWarning("[" .. self.Title .. "] " .. title .. " " .. self.Config.Messages.Outdated .. " " .. self.Config.Messages.Installed .. " " .. version .. ", " .. self.Config.Messages.Latest .. " " .. response)
                        self:LogWarning("[" .. self.Title .. "] -- " .. self.Config.Messages.Visit .. " http://forum.rustoxide.com/plugins/" .. resourceId .. "/")
                        if player then
                            player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. title .. " " .. self.Config.Messages.Outdated .. " " .. self.Config.Messages.Installed .. " " .. version .. ", " .. self.Config.Messages.Latest .. " " .. response)
                            player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \" -- " .. self.Config.Messages.Visit .. " http://forum.rustoxide.com/plugins/" .. resourceId .. "/")
                        end
                        outdated = outdated + 1
                    elseif self.Config.Settings.ShowUpToDate ~= "false" then
                        self:Log("[" .. self.Title .. "] " .. title .. " " .. self.Config.Messages.UpToDate .. " " .. version)
                        if player then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. title .. " " .. self.Config.Messages.UpToDate .. " " .. version .. "\"") end
                    end
                else
                    self:LogWarning("[" .. self.Title .. "] " .. title .. " " .. self.Config.Messages.CheckFailed)
                    if player then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.CheckFailed .. "\"") end
                end
                if supported == 0 then
                    print(self.Config.Messages.CheckFinished)
                    if player then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.CheckFinished .. "\"") end
                    if self.Config.Settings.PushNotifications ~= "false" and outdated > 0 then
                        pushApi = plugins.Find("push")
                        local message = self.Config.Messages.PushMessage:gsub("{outdated}", outdated)
                        local message = message:gsub("{hostname}", global.server.hostname)
                        pushApi:PushMessage(self.Config.Messages.PushSubject, message, self.Config.Settings.PushPriority, self.Config.Settings.PushSound)
                    end
                end
            end, self.Object)
        end
    end
    print("Supported plugin count: " .. tostring(supported))
end

function PLUGIN:Log(message)
    local arr = util.TableToArray({ message })
    UnityEngine.Debug.Log.methodarray[0]:Invoke(nil,arr)
end

function PLUGIN:LogWarning(message)
    local arr = util.TableToArray({ message })
    UnityEngine.Debug.LogWarning.methodarray[0]:Invoke(nil,arr)
end

function PLUGIN:Unload()
    if self.updateTimer then self.updateTimer = nil end
end

function PLUGIN:PermissionsCheck(player)
    local authLevel
    if player then authLevel = player.net.connection.authLevel else authLevel = 2 end
    local neededLevel = tonumber(self.Config.Settings.AuthLevel) or 2
    if debug then print(player.displayName .. " has auth level: " .. tostring(authLevel)) end
    if authLevel and authLevel >= neededLevel then return true else return false
    end
end

function PLUGIN:SendHelpText(player)
    if self:PermissionsCheck(player) then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatNameHelp .. "\" \"" .. self.Config.Messages.ChatHelp .. "\"") end
end

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.AuthLevel = tonumber(self.Config.Settings.AuthLevel) or 2
    self.Config.Settings.ChatCommand = self.Config.Settings.ChatCommand or "update"
    self.Config.Settings.ChatName = self.Config.Settings.ChatName or "UPDATER"
    self.Config.Settings.ChatNameHelp = self.Config.Settings.ChatNameHelp or self.Config.Settings.HelpChatName or "HELP"
    self.Config.Settings.CheckInterval = tonumber(self.Config.Settings.CheckInterval) or tonumber(self.Config.Settings.CheckEvery) or 3600
    self.Config.Settings.ConsoleCommand = self.Config.Settings.ConsoleCommand or "server.update"
    self.Config.Settings.PushNotifications = self.Config.Settings.PushNotifications or "false"
    self.Config.Settings.PushPriority = self.Config.Settings.PushPriority or "high"
    self.Config.Settings.PushSound = self.Config.Settings.PushSound or "gamelan"
    self.Config.Settings.ShowUpToDate = self.Config.Settings.ShowUpToDate or "false"
    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.ChatHelp = self.Config.Messages.ChatHelp or self.Config.Messages.HelpText or "Use /update to check for plugin updates"
    self.Config.Messages.CheckFailed = self.Config.Messages.CheckFailed or "plugin update check failed!"
    self.Config.Messages.CheckFinished = self.Config.Messages.CheckFinished or "##############  Update check finished!"
    self.Config.Messages.CheckStarted = self.Config.Messages.CheckStarted or "##############  Update check started!"
    self.Config.Messages.Installed = self.Config.Messages.Installed or "Installed:"
    self.Config.Messages.Latest = self.Config.Messages.Latest or "Latest:"
    self.Config.Messages.NoPermission = self.Config.Messages.NoPermission or "You do not have permission to use this command!"
    self.Config.Messages.Outdated = self.Config.Messages.Outdated or "is outdated!"
    self.Config.Messages.PushMessage = self.Config.Messages.PushMessage or "{outdated} plugin updates available on your server {hostname}"
    self.Config.Messages.PushSubject = self.Config.Messages.PushSubject or "Plugin updates available!"
    self.Config.Messages.UpToDate = self.Config.Messages.UpToDate or "is up-to-date, currently using version:"
    self.Config.Messages.Visit = self.Config.Messages.Visit or "Visit"
    self.Config.Messages.HelpText = nil -- Removed in 0.2.2
    self.Config.Settings.CheckEvery = nil -- Removed in 0.2.5
    self.Config.Settings.HelpChatName = nil -- Removed in 0.2.5
    self:SaveConfig()
end
