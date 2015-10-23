PLUGIN.Title = "HealFeedCure"
PLUGIN.Version = V(1, 3, 0)
PLUGIN.Description = "Allows you to heal, feed, and cure players."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/658/"
PLUGIN.ResourceId = 658

-- TODO:
---- Fix Line: 103 attempt to index field 'Args' (a nil value)
---- Fix Line: 42 attempt to concatenate local 'message' (a nil value)

--[[ Do NOT edit the config here, instead edit HealFeedCure.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    --messages.ChatHelp = messages.ChatHelp or "Use '/heal <player> [amount]' to heal a player"
    --messages.ConsoleHelp = messages.ConsoleHelp or "Use 'heal <player> [amount]' to heal a player"
    --messages.InvalidAmount = messages.InvalidAmount or "Please enter a valid number amount!"
    messages.InvalidTarget = messages.InvalidTarget or "Invalid player! Please try again"
    messages.NoPermission = messages.NoPermission or "You do not have permission to use this command!"
    --messages.YouHealed = messages.YouHealed or ""
    --messages.YouFed = messages.YouFed or ""
    --messages.YouCured = messages.YouCured or ""

    self:SaveConfig()
end

local names
function PLUGIN:Init()
    self:LoadDefaultConfig()

    command.AddChatCommand("heal", self.Plugin, "ChatCommand")
    command.AddChatCommand("feed", self.Plugin, "ChatCommand")
    command.AddChatCommand("cure", self.Plugin, "ChatCommand")
    command.AddConsoleCommand("global.heal", self.Plugin, "ConsoleCommand")
    command.AddConsoleCommand("global.feed", self.Plugin, "ConsoleCommand")
    command.AddConsoleCommand("global.cure", self.Plugin, "ConsoleCommand")

    permission.RegisterPermission("player.heal", self.Plugin)
    permission.RegisterPermission("player.feed", self.Plugin)
    permission.RegisterPermission("player.cure", self.Plugin)
end

local function Print(self, self, message) Print(self, "[" .. self.Title .. "] " .. message) end

local function HasPermission(steamId, perm)
    if permission.UserHasPermission(steamId, perm) then return true end
    return false
end

local function FindPlayer(self, player, target)
    local target = global.BasePlayer.Find(target)
    if not target then
        if player then
            rust.SendChatMessage(player, messages.InvalidTarget)
        else
            Print(self, self, messages.InvalidTarget)
        end
        return
    end
    return target
end

function PLUGIN:ChatCommand(player, cmd, args)
    if not HasPermission(self, player) then
        rust.SendChatMessage(player, messages.NoPermission)
        return
    end

    local target, amount = FindPlayer(self, player, args[0]), args[1]
    if args.Length == 1 then
        target = player
        amount = args[0]
    end

    if amount and cmd ~= "cure" then
        amount = string.match(amount, "^%d*")
        if amount == "" then
            rust.SendChatMessage(player, messages.InvalidAmount)
            return
        end
    end

    if cmd == "heal" then
        amount = tonumber(amount) or 100
        self:Heal(player, target, amount)
    elseif cmd == "feed" then
        amount = tonumber(amount) or 1000
        self:Feed(player, target, amount)
    elseif cmd == "cure" then
        self:Cure(player, target)
    end
end

function PLUGIN:ConsoleCommand(arg)
    local player
    if arg.connection then player = arg.connection.player end

    if player and not HasPermission(self, player) then
        arg:ReplyWith(messages.NoPermission)
        return true
    end

    local cmd = arg.cmd.name
    local target, amount = FindPlayer(self, player, arg.Args[0]), arg.Args[1]
    if player and arg:HasArgs(1) then
        target = player
        amount = arg.Args[0]
    end

    if not player and not target then
        if cmd == "cure" then
            Print(self, "Syntax: \"" .. cmd .. " <name>\"")
        else
            Print(self, "Syntax: \"" .. cmd .. " <name> <amount (optional)>\"")
        end
        return true
    end

    if amount and cmd ~= "cure" then
        amount = string.match(amount, "^%d*")
        if amount == "" then
            if player then
                arg:ReplyWith(messages.InvalidAmount)
            else
                Print(self, messages.InvalidAmount)
            end
            return true
        end
    end

    if cmd == "heal" then
        amount = tonumber(amount) or 100
        self:Heal(player, target, amount)
    elseif cmd == "feed" then
        amount = tonumber(amount) or 1000
        self:Feed(player, target, amount)
    elseif cmd == "cure" then
        self:Cure(player, target)
    end

    return true
end

function PLUGIN:Heal(player, target, amount)
    target.health = target.health + amount

    if player then
        if player ~= target then
            rust.SendChatMessage(player, "You healed " .. target.displayName .. " for " .. tostring(amount) .. " HP")
            rust.SendChatMessage(target, player.displayName .. " healed you for " .. tostring(amount) .. " HP")
        else
            rust.SendChatMessage(player, "You healed yourself for " .. tostring(amount) .. " HP")
        end
    else
        Print(self, "You healed " .. target.displayName .. " for " .. tostring(amount) .. " HP")
        rust.SendChatMessage(target, "An admin healed you for " .. tostring(amount) .. " HP")
    end
end

function PLUGIN:Cure(player, target)
    target.metabolism.poison.value = 0
    target.metabolism.radiation_level.value = 0
    target.metabolism.radiation_poison.value = 0
    target.metabolism.oxygen.value = 1
    target.metabolism.bleeding.value = 0
    target.metabolism.wetness.value = 0
    target.metabolism.dirtyness.value = 0

    if player then
        if player ~= target then
            rust.SendChatMessage(player, "You cured " .. target.displayName)
            rust.SendChatMessage(target, player.displayName .. " cured you")
        else
            rust.SendChatMessage(player, "You cured yourself")
        end
    else
        Print(self, "You cured " .. target.displayName)
        rust.SendChatMessage(target, "An admin cured you")
    end
end

function PLUGIN:Feed(player, target, amount)
    target.metabolism.calories.value = target.metabolism.calories.value + amount
    target.metabolism.hydration.value = target.metabolism.hydration.value + amount

    if player then
        if player ~= target then
            rust.SendChatMessage(player, "You fed " .. target.displayName .. " for " .. tostring(amount))
            rust.SendChatMessage(target, player.displayName .. " fed you for " .. tostring(amount))
        else
            rust.SendChatMessage(player, "You fed yourself for " .. tostring(amount))
        end
    else
        Print(self, "You fed " .. target.displayName .. " for " .. tostring(amount))
        rust.SendChatMessage(target, "An admin fed you for " .. tostring(amount))
    end
end
