PLUGIN.Title = "Email Test"
PLUGIN.Version = V(0, 1, 1)
PLUGIN.Description = "Email API test plugin."
PLUGIN.Author = "Wulfspider"
PLUGIN.HasConfig = false

function PLUGIN:OnServerInitialized()
    local emailApi = plugins.Find("email")
    emailApi:EmailMessage("This is a test email", "This is a test of the Email API for Oxide!")
end
