PLUGIN.Title = "Email Test"
PLUGIN.Version = V(0, 0, 1)
PLUGIN.Description = "Email API test plugin."
PLUGIN.Author = "Wulf / Luke Spragg"

function PLUGIN:Init()
    command.AddChatCommand("etest", self.Plugin, "SendTest")
    command.AddConsoleCommand("global.etest", self.Plugin, "SendTest")
end

function PLUGIN:SendTest()
    local emailApi = plugins.Find("EmailAPI")
    if not emailApi then print("Email API is not loaded! http://oxidemod.org/plugins/712/") return end
    emailApi:CallHook("EmailMessage", "This is a test email", "This is a test of the Email API!")
end
