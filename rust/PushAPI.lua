PLUGIN.Title = "Push API"
PLUGIN.Version = V(0, 2, 1)
PLUGIN.Description = "API for sending messages via mobile notification services."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/705/"
PLUGIN.ResourceId = 705

local debug = false

--[[ Do NOT edit the config here, instead edit PushAPI.json in oxide/config ! ]]

local messages, pushalot, pushover, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.InvalidService = messages.InvalidService or "Configured push service is not valid!"
    messages.TitleRequired = messages.TitleRequired or "Title not given! Please enter one and try again"
    messages.MessageRequired = messages.MessageRequired or "Message not given! Please enter one and try again"
    messages.SendFailed = messages.SendFailed or "Notification failed to send!"
    messages.SendSuccess = messages.SendSuccess or "Notification successfully sent!"
    messages.SetApiToken = messages.SetApiToken or "API token not set! Please set it and try again."
    messages.SetApiToken = messages.SetAuthToken or "Auth token not set! Please set it and try again."
    messages.SetUserKey = messages.SetUserKey or "User key not set! Please set it and try again."

    self.Config.Pushalot = self.Config.Pushalot or {}
    pushalot = self.Config.Pushalot
    pushalot.AuthToken = pushalot.AuthToken or ""

    self.Config.Pushover = self.Config.Pushover or {}
    pushover = self.Config.Pushover
    pushover.ApiToken = pushover.ApiToken or ""
    pushover.UserKey = pushover.UserKey or ""

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Service = settings.Service or "pushover"

    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

function PLUGIN:PushMessage(title, message, priority, sound)
    if title == "" then
        Print(self, messages.TitleRequired)
        return
    end

    if message == "" then
        Print(self, messages.MessageRequired)
        return
    end

    local url, data

    if string.lower(settings.Service) == "pushover" then
        if pushover.ApiToken == "" then
            Print(self, messages.SetApiToken)
            return
        end

        if pushover.UserKey == "" then
            Print(self, messages.SetUserKey)
            return
        end

        if not priority or priority == "high" then priority = "1"
        elseif priority == "low" then priority = "0"
        elseif priority == "quiet" then priority = "-1" end

        local sound = sound or "gamelan"

        url = "https://api.pushover.net/1/messages.json"
        data = "token=" .. pushover.ApiToken
        .. "&user=" .. pushover.UserKey
        .. "&title=" .. title
        .. "&message=" .. message
        .. "&priority=" .. priority
        .. "&sound=" .. sound
        .. "&html=1"

    elseif string.lower(settings.Service) == "pushalot" then
        if pushalot.AuthToken == "" then
            Print(self, messages.SetAuthToken)
            return
        end

        if not priority or priority == "high" then priority = "IsImportant=true"
        elseif priority == "low" then priority = "IsImportant=false"
        elseif priority == "quiet" then priority = "IsQuiet=true" end

        url = "https://pushalot.com/api/sendmessage"
        data = "AuthorizationToken=" .. pushalot.AuthToken
        .. "&Title=" .. title
        .. "&Body=" .. message
        .. "&" .. priority

    else
        Print(self, messages.InvalidService)
        return
    end

    webrequests.EnqueuePost(url, data, function(code, response)
        if debug then
            Print(self, "POST URL: " .. url)
            Print(self, "POST data: " .. data)
            Print(self, "HTTP code: " .. code)
        end

        if code ~= 200 then
            Print(self, messages.SendFailed)
        else
            Print(self, messages.SendSuccess)
        end
    end, self.Plugin)
end
