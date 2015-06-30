PLUGIN.Title = "Sleep"
PLUGIN.Version = V(0, 1, 1)
PLUGIN.Description = "Allows players with permission to get a well-rested sleep."
PLUGIN.Author = "Wulf / Luke Spragg"
PLUGIN.Url = "http://oxidemod.org/plugins/1156/"
PLUGIN.Resource = 1156

local debug = false

--[[ Do NOT edit the config here, instead edit Sleep.json in oxide/config ! ]]

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.Command = self.Config.Settings.Command or "sleep"
    self.Config.Settings.Cure = self.Config.Settings.Cure or "false"
    self.Config.Settings.CurePercent = tonumber(self.Config.Settings.CurePercent) or 5
    self.Config.Settings.Heal = self.Config.Settings.Heal or "true"
    self.Config.Settings.HealPercent = tonumber(self.Config.Settings.HealPercent) or 5
    self.Config.Settings.Realism = self.Config.Settings.Realism or "true"
    self.Config.Settings.RealismPercent = tonumber(self.Config.Settings.RealismPercent) or 5
    self.Config.Settings.Restore = self.Config.Settings.Restore or "true"
    self.Config.Settings.RestorePercent = tonumber(self.Config.Settings.RestorePercent) or 5
    self.Config.Settings.UpdateRate = tonumber(self.Config.Settings.UpdateRate) or 10

    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.CantSleep = self.Config.Messages.CantSleep or "You can't go to sleep right now!"
    self.Config.Messages.ChatHelp = self.Config.Messages.ChatHelp or "Use '/sleep' to go to sleep and rest"
    self.Config.Messages.Dirty = self.Config.Messages.Dirty or "You seem to be a bit dirty, go take a dip!"
    self.Config.Messages.Hungry = self.Config.Messages.Hungry or "You seem to be a bit hungry, eat something!"
    self.Config.Messages.Rested = self.Config.Messages.Rested or "You have awaken restored and rested!"
    self.Config.Messages.Thirsty = self.Config.Messages.Thirsty or "You seem to be a bit thirsty, drink something!"

    self:SaveConfig()
end

local function Print(self, message) print("[" .. self.Title .. "] " .. message) end

local function HasPermission(steamId, perm)
    if permission.UserHasPermission(steamId, perm) then return true end
    return false
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(self.Config.Settings.Command, self.Plugin, "ChatCommand")
    permission.RegisterPermission("sleep.allowed", self.Plugin)
end

local function Sleep(player)
    player:StartSleeping()
end

local function WakeUp(player)
    player:EndSleeping()
end

local function Cure(self, player, percent)
    -- Poison -- Default: 0, Min: 0, Max: 100
    local poison = player.metabolism.poison.value
    if poison > 0 then
        poison = poison - (poison / percent)
    end
    if debug then Print(self, player.displayName .. " poison: " .. poison) end

    -- Radiation level -- Default: 0, Min: 0, Max: 100
    local radLevel = player.metabolism.radiation_level.value
    if radLevel > 0 then
        radLevel = radLevel - (radLevel / percent)
    end
    if debug then Print(self, player.displayName .. " radiation level: " .. radLevel) end

    -- Radiation poison -- Default: 0, Min: 0, Max: 500
    local radPoison = player.metabolism.radiation_poison.value
    if radPoison > 0 then
        radPoison = radPoison - (radPoison / percent)
    end
    if debug then Print(self, player.displayName .. " radiation poison: " .. radPoison) end
end

local function Heal(self, player, percent)
    -- Bleeding -- Default: 0, Min: 0, Max: 1
    local bleeding = player.metabolism.bleeding.value
    if bleeding == 1 then bleeding = 0 end
    if debug then Print(self, player.displayName .. " bleeding: " .. bleeding) end

    -- Health -- Default: 50-60, Min: 0, Max: 100
    local health = player.health
    if health < 100 then
        health = health + (health / percent)
    end
    if debug then Print(self, player.displayName .. " health: " .. health) end

end

local function Realism(self, player, percent)
    -- Calories -- Default: 75-100, Min: 0, Max: 1000
    local calories = player.metabolism.calories.value
    if calories < 1000 then
        calories = calories - (calories / percent)
    end
    if debug then Print(self, player.displayName .. " calories: " .. calories) end

    -- Dirtyness -- Default: 0, Min: 0, Max: 100
    local dirtyness = player.metabolism.dirtyness.value
    if dirtyness < 100 then
        dirtyness = dirtyness + (dirtyness / percent)
    end
    if debug then Print(self, player.displayName .. " dirtyness: " .. dirtyness) end

    -- Hydration -- Default: 75-100, Min: 0, Max: 1000
    local hydration = player.metabolism.hydration.value
    if hydration >= 1 then
        hydration = hydration - (hydration / percent)
    end
    if debug then Print(self, player.displayName .. " hydration: " .. hydration) end
end

local function Restore(self, player, percent)
    -- Comfort -- Default: 0.5, Min: 0, Max: 1
    local comfort = player.metabolism.comfort.value
    if comfort < 0.5 then
        comfort = comfort + (comfort / percent)
    end
    if debug then Print(self, player.displayName .. " comfort: " .. comfort) end

    -- Heartrate -- Default 0.5, Min: 0, Max: 1
    local heartrate = player.metabolism.heartrate.value
    if heartrate > 0.5 then
        heartrate = heartrate - (heartrate / percent)
    end
    if debug then Print(self, player.displayName .. " heartrate: " .. heartrate) end

    -- Temperature -- Default: 20, Min: -100, Max: 100
    local temperature = player.metabolism.temperature.value
    if temperature ~= 20 then
        if temperature < 20 then
            temperature = temperature + (temperature / percent)
        elseif temperature > 20 then
            temperature = temperature - (temperature / percent)
        end
    end
    if debug then Print(self, player.displayName .. " temperature: " .. temperature) end
end

local sleepTimer = {}

function PLUGIN:ChatCommand(player, cmd, args)
    local steamId = rust.UserIDFromPlayer(player)

    if not HasPermission(steamId, "sleep.allowed") then
        rust.SendChatMessage(player, self.Config.Messages.CantSleep)
        return
    end

    Sleep(player)

    sleepTimer[steamId] = timer.Repeat(self.Config.Settings.UpdateRate, 0, function()
        if player:IsSleeping() then
            if self.Config.Settings.Cure == "true" then
                Cure(self, player, self.Config.Settings.CurePercent)
            end
            if self.Config.Settings.Heal == "true" then
                Heal(self, player, self.Config.Settings.HealPercent)
            end

            if self.Config.Settings.Realism == "true" then
                Realism(self, player, self.Config.Settings.RealismPercent)
            end

            if self.Config.Settings.Restore == "true" then
                Restore(self, player, self.Config.Settings.RestorePercent)
            end

            player.metabolism:SendChangesToClient()
        end
    end, self.Plugin)
end

function PLUGIN:OnPlayerSleepEnded(player)
    local steamId = rust.UserIDFromPlayer(player)

    if sleepTimer[steamId] then
        sleepTimer[steamId]:Destroy()

        rust.SendChatMessage(player, self.Config.Messages.Rested)
    end

    if player.metabolism.calories.value < 40 then
        rust.SendChatMessage(player, self.Config.Messages.Hungry)
    end

    if player.metabolism.dirtyness.value > 0 then
        rust.SendChatMessage(player, self.Config.Messages.Dirty)
    end

    if player.metabolism.hydration.value < 40 then
        rust.SendChatMessage(player, self.Config.Messages.Thirsty)
    end
end

function PLUGIN:SendHelpText(player)
    if HasPermission(rust.UserIDFromPlayer(player), "sleep.allowed") then
        rust.SendChatMessage(player, self.Config.Messages.ChatHelp)
    end
end
