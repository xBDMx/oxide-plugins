PLUGIN.Title = "Dice"
PLUGIN.Version = V(0, 2, 2)
PLUGIN.Description = "Feeling lucky? Roll one or multiple dice to get a random number."
PLUGIN.Author = "Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/plugins/655/"
PLUGIN.ResourceId = 655
PLUGIN.HasConfig = true

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.ChatCommand, self.Object, "cmdRollDice")
end

function PLUGIN:cmdRollDice(player, cmd, arg)
    local dice, count, total = 0, 0, 0
    if arg.Length >= 1 then dice = tonumber(arg[0]) else dice = 1 end
    while count < dice do local roll = math.random(6); total = total + roll; count = count + 1 end
    local number = tostring(total)
    local message = self.Config.Messages.Rolled:gsub("{player}", player.displayName); local message = message:gsub("{number}", number)
    global.ConsoleSystem.Broadcast("chat.add \"" .. self.Config.Settings.ChatName .. "\" \"" .. message .. "\"")
end

function PLUGIN:SendHelpText(player)
    player:SendConsoleCommand("chat.add \"" .. self.Config.Settings.ChatNameHelp .. "\" \"" .. self.Config.Messages.ChatHelp .. "\"")
end

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.ChatCommand = self.Config.Settings.ChatCommand or "dice"
    self.Config.Settings.ChatName = self.Config.Settings.ChatName or "DICE"
    self.Config.Settings.ChatNameHelp = self.Config.Settings.ChatNameHelp or self.Config.Settings.HelpChatName or "HELP"
    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.ChatHelp = self.Config.Messages.ChatHelp or self.Config.Messages.HelpText or "Use /dice # to roll dice (# being optional number of dice to roll)"
    self.Config.Messages.Rolled = self.Config.Messages.Rolled or "{player} rolled {number}"
    self.Config.Settings.HelpChatName = nil -- Removed in 0.2.3
    self.Config.Messages.HelpText = nil -- Removed in 0.2.3
    self:SaveConfig()
end
