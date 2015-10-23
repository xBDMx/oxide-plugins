PLUGIN.Title = "Metabolism Control"
PLUGIN.Version = V(1, 2, 0)
PLUGIN.Description = "Allows control of player stats and rates."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/680/"
PLUGIN.ResourceId = 680

-- ----------------------------
-- Rust default rates
-- ----------------------------
-- healthgain = 0.03
-- caloriesloss = 0 - 0.05
-- hydrationloss = 0 - 0.025
-- ----------------------------

--[[ Do NOT edit the config here, instead edit MetabolismControl.json in oxide/config ! ]]

local settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Health = settings.Health or {}
    settings.Health.MaxValue = tonumber(settings.Health.MaxValue) or 100
    settings.Health.SpawnValue = settings.Health.SpawnValue or "default"
    settings.Health.GainRate = settings.Health.GainRate or "default"

    settings.Calories = settings.Calories or {}
    settings.Calories.MaxValue = tonumber(settings.Calories.MaxValue) or 1000
    settings.Calories.SpawnValue = settings.Calories.SpawnValue or "default"
    settings.Calories.LossRate = settings.Calories.LossRate or "default"

    settings.Hydration = settings.Hydration or {}
    settings.Hydration.MaxValue = tonumber(settings.Hydration.MaxValue) or 1000
    settings.Hydration.SpawnValue = settings.Hydration.SpawnValue or "default"
    settings.Hydration.LossRate = settings.Hydration.LossRate or "default"

    self:SaveConfig()
end

function PLUGIN:Init() self:LoadDefaultConfig() end

function PLUGIN:OnPlayerInit(player) self:SetMetabolismValues(player) end

function PLUGIN:OnPlayerRespawned(player) self:SetMetabolismValues(player) end

function PLUGIN:OnRunPlayerMetabolism(metabolism, player)
    local caloriesLossRate = settings.Calories.LossRate
    local hydrationLossRate = settings.Hydration.LossRate
    local healthGainRate = settings.Health.GainRate
    local heartRate = metabolism.heartrate.value

    if caloriesLossRate ~= "default" then
        if calorieLossRate == 0 or calorieLossRate == "0" then
            metabolism.calories.value = metabolism.calories.value
        else
            metabolism.calories.value = metabolism.calories.value - (tonumber(caloriesLossRate) + (heartRate / 10))
        end
    end

    if hydrationLossRate ~= "default" then
        if hydrationLossRate == 0 or hydrationLossRate == "0" then
            metabolism.hydration.value = metabolism.hydration.value
        else
            metabolism.hydration.value = metabolism.hydration.value - (tonumber(hydrationLossRate) + (heartRate / 10))
        end
    end

    if healthGainRate ~= "default" then
        if healthGainRate == 0 or healthGainRate == "0" then
            player.health = player.health
        else
            player.health = player.health + tonumber(healthGainRate) - 0.03
        end
    end
end

function PLUGIN:SetMetabolismValues(player)
    local maxHealth = tonumber(settings.Health.MaxValue)
    local maxCalories = tonumber(settings.Calories.MaxValue)
    local maxHydration = tonumber(settings.Hydration.MaxValue)

    player.health = maxHealth
    player.metabolism.calories.max = maxCalories
    player.metabolism.hydration.max = maxHydration

    if settings.Health.SpawnValue ~= "default" then
        player.health = tonumber(settings.Health.SpawnValue)
    else
        player.health = maxHealth
    end

    if settings.Calories.SpawnValue ~= "default" then
        player.metabolism.calories.value = tonumber(settings.Calories.SpawnValue)
    end

    if settings.Hydration.SpawnValue ~= "default" then
        player.metabolism.hydration.value = tonumber(settings.Hydration.SpawnValue)
    end
end
