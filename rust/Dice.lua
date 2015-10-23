PLUGIN.Title = "Dice"
PLUGIN.Version = V(0, 3, 0)
PLUGIN.Description = "Feeling lucky? Roll dice to get a random number."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/655/"
PLUGIN.ResourceId = 655

-- TODO:
---- Add support for giving random items
---- Add permissions support?
---- Add ParseString function

--[[ Do NOT edit the config here, instead edit Dice.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.ChatHelp = messages.ChatHelp or "Use '/dice #' to roll dice (# being optional number of dice)"
    messages.Rolled = messages.Rolled or "{player} rolled {number}"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Command = settings.Command or settings.ChatCommand or "dice"

    settings.ChatCommand = nil -- Removed in 0.3.0
    settings.ChatName = nil -- Removed in 0.3.0
    settings.ChatNameHelp = nil -- Removed in 0.3.0

    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(settings.Command, self.Plugin, "RollDice")
end

function PLUGIN:RollDice(player, cmd, arg)
    local dice = tonumber(arg[0]) or 1
    local count, total = 0, 0

    if dice > 1000 then dice = 1 end

    while count < dice do
        local roll = math.random(6);
        total = total + roll; count = count + 1
    end

    local number = tostring(total)
    local message = messages.Rolled:gsub("{player}", player.displayName):gsub("{number}", number)
    rust.BroadcastChat(message)
end

function PLUGIN:SendHelpText(player)
    rust.SendChatMessage(player, messages.ChatHelp)
end
