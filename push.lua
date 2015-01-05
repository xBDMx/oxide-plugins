PLUGIN.Title = "Push API"
PLUGIN.Version = V(0, 1, 3)
PLUGIN.Description = "API for sending messages via Pushover and Pushalot mobile notification services."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/705/"
PLUGIN.ResourceId = 705
PLUGIN.HasConfig = true

local debug = true

function PLUGIN:Init()
    self:LoadDefaultConfig()
end

function PLUGIN:PushMessage(title, message, priority, sound)
    if message == "" then print("[" .. self.Title .. "] " .. self.Config.Messages.MessageRequired) return end
    if string.lower(self.Config.Settings.Service) == "pushover" then
        if self.Config.Pushover.ApiToken == "" then print("[" .. self.Title .. "] " .. self.Config.Messages.SetApiToken) return end
        if self.Config.Pushover.UserKey == "" then print("[" .. self.Title .. "] " .. self.Config.Messages.SetUserKey) return end
        self.title = title or global.server.hostname
        if priority == "high" then self.priority = "1" elseif priority == "low" then self.priority = "0" elseif priority == "quiet" then self.priority = "-1" end
        self.sound = sound or "gamelan"
        self.url = "https://api.pushover.net/1/messages.json"
        self.data = "token=" .. self.Config.Pushover.ApiToken
        .. "&user=" .. self.Config.Pushover.UserKey
        .. "&title=" .. self.title
        .. "&message=" .. message
        .. "&priority=" .. self.priority
        .. "&sound=" .. self.sound
    elseif string.lower(self.Config.Settings.Service) == "pushalot" then
        if self.Config.Pushalot.AuthToken == "" then print("[" .. self.Title .. "] " .. self.Config.Messages.SetApiToken) return end
        self.title = title or global.server.hostname
        if priority == "high" then self.priority = "IsImportant=true" elseif priority == "low" then self.priority = "IsImportant=false" elseif priority == "quiet" then self.priority = "IsQuiet=true" end
        self.url = "https://pushalot.com/api/sendmessage"
        self.data = "AuthorizationToken=" .. self.Config.Pushalot.AuthToken
        .. "&Title=" .. self.title
        .. "&Body=" .. message
        .. "&" .. self.priority
    end
    webrequests.EnqueuePost(self.url, self.data, function(code, response)
        if debug then self:DebugMessages(self.url, self.data, code) end
        if code ~= 200 then
            print("[" .. self.Title .. "] " .. self.Config.Messages.SendFailed)
        else
            print("[" .. self.Title .. "] " .. self.Config.Messages.SendSuccess)
        end
    end, self.Object)
end

function PLUGIN:DebugMessages(url, data, code)
    if debug then
        print("[" .. self.Title .. "] POST URL: " .. tostring(url))
        print("[" .. self.Title .. "] POST data: " .. tostring(data))
        print("[" .. self.Title .. "] HTTP code: " .. code)
    end
end

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.Service = self.Config.Settings.Service or "pushover"
    self.Config.Pushalot = self.Config.Pushalot or {}
    self.Config.Pushalot.AuthToken = self.Config.Pushalot.AuthToken or ""
    self.Config.Pushover = self.Config.Pushover or {}
    self.Config.Pushover.ApiToken = self.Config.Pushover.ApiToken or self.Config.Settings.ApiToken or ""
    self.Config.Pushover.UserKey = self.Config.Pushover.UserKey or self.Config.Settings.UserKey or ""
    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.MessageRequired = self.Config.Messages.MessageRequired or "Message not given! Please enter one and try again"
    self.Config.Messages.SendFailed = self.Config.Messages.SendFailed or "Notification failed to send!"
    self.Config.Messages.SendSuccess = self.Config.Messages.SendSuccess or "Notification successfully sent!"
    self.Config.Messages.SetApiToken = self.Config.Messages.SetApiToken or self.Config.Messages.SetApiKey or "API token not set! Please set it and try again."
    self.Config.Messages.SetUserKey = self.Config.Messages.SetUserKey or "User key not set! Please set it and try again."
    self.Config.Settings.ApiToken = nil -- Removed in 0.1.1
    self.Config.Settings.UserKey = nil -- Removed in 0.1.1
    self.Config.Messages.SetApiKey = nil -- Removed in 0.1.1
    self:SaveConfig()
end
