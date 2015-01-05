PLUGIN.Title = "Push Test"
PLUGIN.Version = V(0, 1, 0)
PLUGIN.Description = "Push API test plugin."
PLUGIN.Author = "Wulfspider"
PLUGIN.HasConfig = false

function PLUGIN:Init()
    local pushApi = plugins.Find("push")
    pushApi:PushMessage(global.server.hostname, "This is a test of the Push API for Oxide!", "high", "gamelan")
end
