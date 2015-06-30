PLUGIN.Title = "Push Test"
PLUGIN.Version = V(0, 0, 1)
PLUGIN.Description = "Push API test plugin."
PLUGIN.Author = "Wulf / Luke Spragg"

function PLUGIN:Init()
    command.AddChatCommand("ptest", self.Plugin, "SendTest")
    command.AddConsoleCommand("global.ptest", self.Plugin, "SendTest")
end

function PLUGIN:SendTest()
    local pushApi = plugins.Find("PushAPI")
    if not pushApi then print("Push API is not loaded! http://oxidemod.org/plugins/705/") return end
    pushApi:CallHook("PushMessage", "This is a test push", "This is a test of the Push API!", "high", "gamelan")
end
