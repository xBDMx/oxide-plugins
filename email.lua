PLUGIN.Title = "Email API"
PLUGIN.Version = V(0, 1, 1)
PLUGIN.Description = "API for sending email messages via supported transactional email services."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/712/"
PLUGIN.ResourceId = 712
PLUGIN.HasConfig = true

local debug = false

function PLUGIN:Init()
    self:LoadDefaultConfig()
end

function PLUGIN:EmailMessage(subject, message)
    if subject == "" then print("[" .. self.Title .. "] " .. self.Config.Messages.SubjectRequired) return end
    if message == "" then print("[" .. self.Title .. "] " .. self.Config.Messages.MessageRequired) return end
    if string.lower(self.Config.Settings.Provider) == "elastic" or string.lower(self.Config.Settings.Provider) == "elasticemail" then
        if self.Config.Settings.ApiKeyPrivate == "" then print("[" .. self.Title .. "] " .. self.Config.Messages.SetApiKey) return end
        self.url = "https://api.elasticemail.com/mailer/send"
        self.data = "api_key=" .. self.Config.Settings.ApiKeyPrivate
        .. "&username=" .. self.Config.Settings.Username
        .. "&from=" .. self.Config.Settings.EmailFrom
        .. "&from_name=" .. self.Config.Settings.NameFrom
        .. "&to=" .. self.Config.Settings.EmailTo
        .. "&toname=" .. self.Config.Settings.NameTo
        .. "&subject=" .. subject
        .. "&body_text=" .. message
    elseif string.lower(self.Config.Settings.Provider) == "mandrill" then
        if self.Config.Settings.ApiKeyPrivate == "" then print("[" .. self.Title .. "] " .. self.Config.Messages.SetApiKey) return end
        self.url = "https://mandrillapp.com/api/1.0/messages/send.json"
        self.data = '{\"key\": \"' .. self.Config.Settings.ApiKeyPrivate .. '\",'
        .. '\"message\": {'
            .. '\"from_email\": \"' .. self.Config.Settings.EmailFrom .. '\",'
            .. '\"from_name\": \"' .. self.Config.Settings.NameFrom .. '\",'
            .. '\"to\": [{'
                .. '\"email\": \"' .. self.Config.Settings.EmailTo .. '\",'
                .. '\"name\": \"' .. self.Config.Settings.NameTo .. '\"}],'
        .. '\"subject\": \"' .. subject .. '\",'
        .. '\"text\": \"' .. message .. '\"}}'
    elseif string.lower(self.Config.Settings.Provider) == "sendgrid" then
        if self.Config.Settings.ApiKeyPrivate == "" then print("[" .. self.Title .. "] " .. self.Config.Messages.SetApiKey) return end
        self.url = "https://api.sendgrid.com/api/mail.send.json"
        self.data = "api_key=" .. self.Config.Settings.ApiKeyPrivate
        .. "&api_user=" .. self.Config.Settings.Username
        .. "&from=" .. self.Config.Settings.EmailFrom
        .. "&fromname=" .. self.Config.Settings.NameFrom
        .. "&to=" .. self.Config.Settings.EmailTo
        .. "&toname=" .. self.Config.Settings.NameTo
        .. "&subject=" .. subject
        .. "&text=" .. message
    else
        print("[" .. self.Title .. "] " .. self.Config.Messages.InvalidProvider)
        return
    end
    webrequests.EnqueuePost(self.url, self.data, function(code, response)
        if debug then self:DebugMessages(self.url, self.data, code) end
        if code ~= 200 and code ~= 250 then
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
    self.Config.Settings.ApiKeyPrivate = self.Config.Settings.ApiKeyPrivate or ""
    self.Config.Settings.ApiKeyPublic = self.Config.Settings.ApiKeyPublic or ""
    self.Config.Settings.EmailFrom = self.Config.Settings.EmailFrom or "me@me.tld"
    self.Config.Settings.EmailTo = self.Config.Settings.EmailTo or "you@you.tld"
    self.Config.Settings.NameFrom = self.Config.Settings.NameFrom or "Bob Barker"
    self.Config.Settings.NameTo = self.Config.Settings.NameTo or "Drew Carey"
    self.Config.Settings.Provider = self.Config.Settings.Provider or "mandrill"
    self.Config.Settings.Username = self.Config.Settings.Username or ""
    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.InvalidProvider = self.Config.Messages.InvalidProvider or "Configured email provider is not valid!"
    self.Config.Messages.MessageRequired = self.Config.Messages.MessageRequired or "Message not given! Please enter one and try again"
    self.Config.Messages.SendFailed = self.Config.Messages.SendFailed or "Email failed to send!"
    self.Config.Messages.SendSuccess = self.Config.Messages.SendSuccess or "Email successfully sent!"
    self.Config.Messages.SetApiKey = self.Config.Messages.SetApiKey or "API key not set! Please set it and try again."
    self.Config.Messages.SubjectRequired = self.Config.Messages.SubjectRequired or "Subject not given! Please enter one and try again"
    self:SaveConfig()
end
