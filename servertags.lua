PLUGIN.Title = "Server Tags"
PLUGIN.Version = V(0, 1, 0)
PLUGIN.Description = "Adds specified tags to the existing server tags."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/764/"
PLUGIN.ResourceId = 764
PLUGIN.HasConfig = true

function PLUGIN:Init()
    self.Config.Tags = self.Config.Tags or { "custom", "pvp" }
    self:SaveConfig()
end

function PLUGIN:BuildServerTags(tags)
    for i = 1, #self.Config.Tags do tags:Add(self.Config.Tags[i]) end
end
