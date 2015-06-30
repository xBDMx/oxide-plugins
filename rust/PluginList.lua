PLUGIN.Title = "Plugin List"
PLUGIN.Version = V(0, 1, 0)
PLUGIN.Description = "Shows installed plugins and plugin information."
PLUGIN.Author = "Wulf / Luke Spragg"
PLUGIN.Url = "http://oxidemod.org/plugins/1157/"
PLUGIN.ResourceId = 1157

--[[ Do NOT edit the config here, instead edit PluginList.json in oxide/config ! ]]

function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.InstalledPlugins = self.Config.Messages.InstalledPlugins or "<size=18><b><color=#FAB269>Installed plugin(s):</color></b></size>"
    self.Config.Messages.NoPluginFound = self.Config.Messages.NoPluginFound or "No plugin found with that name!"

    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand("plugin", self.Plugin, "ListPlugins")
    command.AddChatCommand("plugins", self.Plugin, "ListPlugins")
end

function PLUGIN:ListPlugins(player, cmd, args)
    local pluginList, pluginTable = plugins.GetAll(), {}
    local title, version, description, resourceId

    if args.Length ~= 1 then
        for i = 2, pluginList.Length - 1 do
            title = pluginList[i].Title
            version = pluginList[i].Version:ToString()
            description = pluginList[i].Description
            resourceId = pluginList[i].Object.ResourceId
            pluginTable[i - 1] = title
        end

        local message = table.concat(pluginTable, ", ")
        rust.SendChatMessage(player, self.Config.Messages.InstalledPlugins .. " " .. message)
    end

    if args.Length == 1 then
        local plugin = plugins.Find(args[0])

        if not plugin then rust.SendChatMessage(player, self.Config.Messages.NoPluginFound) return end

        local message = "<size=18><b><color=#FAB269>" .. plugin.Title .. " v" .. plugin.Version:ToString() .. "</color></b></size>"
        if plugin.Description then message = message .. "\n<size=15>" .. plugin.Description .. "</size>" end
        if plugin.Object.ResourceId and plugin.Object.ResourceId ~= "" and tonumber(plugin.Object.ResourceId) ~= 0 then
            message = message .. "\nhttp://oxidemod.org/plugins/" .. plugin.Object.ResourceId .. "/"
        end

        rust.SendChatMessage(player, message)
    end
end
