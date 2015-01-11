PLUGIN.Title = "Email Test"
PLUGIN.Version = V(0, 1, 2)
PLUGIN.Description = "Email API test plugin."
PLUGIN.Author = "Wulfspider"
PLUGIN.HasConfig = false

function PLUGIN:OnServerInitialized()
    local emailApi = plugins.Find("email")
    if not emailApi then print("Email API is not loaded! http://forum.rustoxide.com/plugins/712/"); return end
    emailApi:EmailMessage("This is a test email", "This is a test of the Email API for Oxide!")
end
