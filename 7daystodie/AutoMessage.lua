PLUGIN.Title = "AutoMessage"
PLUGIN.Version = V(0, 1, 0)
PLUGIN.Description = ""
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/0/"
PLUGIN.ResourceId = 0

function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {
        "Hello world from Oxide!",
        "I like big butts and I cannot lie!"
    }
    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
end

function PLUGIN:OnServerInitialized()
    timer.Repeat(300, 0, function()
        local messages = self.Config.Messages
        for i = 1, #messages do
            sdtd.BroadcastChat(messages[i])
        end
    end, self.Plugin)
end
