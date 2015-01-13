PLUGIN.Title = "Auto Commands"
PLUGIN.Version = V(0, 2, 0)
PLUGIN.Description = "Automatically executes configured commands on server startup."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/774/"
PLUGIN.ResourceId = 774
PLUGIN.HasConfig = true

local debug = false

-- TODO:
---- Add timed config option for each command entry
---- Allow for partial matching with commands

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.ChatCommand, self.Object, "cmdAutoCommand")
    command.AddConsoleCommand(self.Config.Settings.ConsoleCommand, self.Object, "ccmdAutoCommand")
end

function PLUGIN:OnServerInitialized()
    for i = 1, #self.Config.Settings.Commands do
        global.ConsoleSystem.Run(self.Config.Settings.Commands[i], true)
        print("[" .. self.Title .. "] " .. self.Config.Settings.Commands[i])
    end
end

function PLUGIN:cmdAutoCommand(player, cmd, args)
    if player and not self:PermissionsCheck(player.net.connection) then
        player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.NoPermission .. "\"")
        return
    end
    local command = string.lower(args[1])
    local action = args[0]
    local list = self.Config.Settings.Commands
    if action == nil or action ~= "add" and action ~= "remove" and action ~= "list" then
        player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.UnknownAction .. "\"")
        return
    end
    if args.Length ~= 2 and action == "add" or action == "remove" then
        player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.ChatHelp .. "\"")
        return
    end
    if args.Length ~= 1 and action == "list" then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.ChatHelp .. "\""); return end
    if action == "add" then
        local listed
        for key, value in pairs(list) do if command == value then listed = true; break end end
        if not listed then
            table.insert(list, command)
            self:SaveConfig()
            player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.CommandAdded:gsub("{command}", command) .. "\"")
        else
            player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.AlreadyAdded:gsub("{command}", command) .. "\"")
        end
        return
    end
    if action == "remove" then
        local listed
        for key, value in pairs(list) do if command == value then listed = true; break end end
        if listed then
            table.remove(list, key)
            self:SaveConfig()
            player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.CommandRemoved:gsub("{command}", command) .. "\"")
        else
            player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. self.Config.Messages.NotListed:gsub("{command}", command) .. "\"")
        end
        return
    end
    if action == "list" then
        local commands
        for i = 1, #list do commands = commands .. ", " .. list[i] end
        player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. commands .. "\"")
        return
    end
end

function PLUGIN:ccmdAutoCommand(args)
    local player = nil
    if args.connection then player = args.connection.player end
    if player and not self:PermissionsCheck(player) then args:ReplyWith(self.Config.Messages.NoPermission); return end
    --if not args:HasArgs(2) then args:ReplyWith(self.Config.Messages.ConsoleHelp); return end
    local action = args:GetString(1)
    local message = "This command is not yet usable."
    if player then args:ReplyWith(message) else print(message) end
end

function PLUGIN:PermissionsCheck(connection)
    local authLevel
    if connection then authLevel = connection.authLevel else authLevel = 2 end
    local neededLevel = tonumber(self.Config.Settings.AuthLevel) or 2
    if debug then print(connection.username .. " has auth level: " .. tostring(authLevel)) end
    if authLevel and authLevel >= neededLevel then return true else return false end
end

function PLUGIN:SendHelpText(player)
    if self:PermissionsCheck(player.net.connection) then player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatNameHelp .. "\" \"" .. self.Config.Messages.ChatHelp[i] .. "\"") end
end

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.AuthLevel = tonumber(self.Config.Settings.AuthLevel) or 2
    self.Config.Settings.ChatCommand = self.Config.Settings.ChatCommand or "autocmd"
    self.Config.Settings.ChatName = self.Config.Settings.ChatName or "SERVER"
    self.Config.Settings.ChatNameHelp = self.Config.Settings.ChatNameHelp or "HELP"
    self.Config.Settings.ConsoleCommand = self.Config.Settings.ConsoleCommand or "auto.command"
    self.Config.Settings.Commands = self.Config.Settings.Commands or self.Config.Commands or { "server.globalchat true", "server.stability false" }
    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.AlreadyAdded = self.Config.Messages.AlreadyAdded or "{command} is already on the auto command list!"
    self.Config.Messages.ChatHelp = self.Config.Messages.Chathelp or "Use /{command} add|remove command to add or remove an auto command"
    self.Config.Messages.ConsoleHelp = self.Config.Messages.ConsoleHelp or "Use {command} add|remove command to add or remove an auto command"
    self.Config.Messages.CommandAdded = self.Config.Messages.CommandAdded or "{command} has been added to the auto command list!"
    self.Config.Messages.CommandRemoved = self.Config.Messages.CommandRemoved or "{command} has been removed from the auto command list!"
    self.Config.Messages.NoPermission = self.Config.Messages.NoPermission or "You do not have permission to use this command!"
    self.Config.Messages.NotListed = self.Config.Messages.NotListed or "{command} is not on the auto command list!"
    self.Config.Messages.UnknownAction = self.Config.Messages.UnknownAction or "Unknown command action! Use add or remove"
    self:SaveConfig()
end
