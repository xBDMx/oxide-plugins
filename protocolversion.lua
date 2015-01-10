PLUGIN.Title = "Protocol Version"
PLUGIN.Version = V(0, 1, 0)
PLUGIN.Description = "Shows the current protocol version of the server."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/763/"
PLUGIN.ResourceId = 763

function PLUGIN:ModifyTags(tags)
    UnityEngine.Debug.LogWarning.methodarray[0]:Invoke(nil, util.TableToArray({ "Current server protocol version: v" .. tags:match("v([%d]+)") }))
end
