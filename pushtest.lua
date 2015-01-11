PLUGIN.Title = "Push Test"
PLUGIN.Version = V(0, 1, 2)
PLUGIN.Description = "Push API test plugin."
PLUGIN.Author = "Wulfspider"
PLUGIN.HasConfig = false

function PLUGIN:OnServerInitialized()
    local pushApi = plugins.Find("push")
    if not pushApi then print("Push API is not loaded! http://forum.rustoxide.com/plugins/705/"); return end
    pushApi:PushMessage(global.server.hostname, "This is a test of the Push API for Oxide!", "high", "gamelan")
end
