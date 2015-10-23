PLUGIN.Title = "Infected"
PLUGIN.Version = V(2, 0, 0)
PLUGIN.Description = ""
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/751/"
PLUGIN.ResourceId = 751

--[[ Do NOT edit the config here, instead edit Infected.json in oxide/config ! ]]

local messages, settings
function PLUGIN:LoadDefaultConfig()
    self.Config.Messages = self.Config.Messages or {}
    messages = self.Config.Messages
    messages.ChatHelp = messages.ChatHelp or "Use '/infected' to see your infection status"

    self.Config.Settings = self.Config.Settings or {}
    settings = self.Config.Settings
    settings.Command = settings.Command or "infected"
    settings.Spreadable = settings.Spreadable or "true"

        self.Config.RadInfection = true        -- cure with rad
        self.Config.InfectPercent = 20        -- the lower the number the more you get infected 10=90% (random chance) default 50:50
        self.Config.VirusSpeed = 30        -- virus decay poison and health timer lower is faster but can lag if too low
        self.Config.RadLevel = 400        -- means anything above that number in rads will kill virus(random chance) 1-500
        self.Config.InfLevels = {}        -- array
        self.Config.InfLevels.Timer = true    -- time that tells how many infected on server
        self.Config.InfLevels.Interval = 3600    -- time in seconds for above info default 1 hour
        self.Config.InfLevels.a = 2        -- amount of people for next level
        self.Config.InfLevels.b = 4        -- these are info only
        self.Config.InfLevels.c = 8        
        self.Config.InfLevels.d = 16

    self:SaveConfig()
end

function PLUGIN:Init()
    self:LoadDefaultConfig()
    command.AddChatCommand(settings.Command, self.Plugin, "Infected")
end

local GetRadLevel, SetRadLevel = typesystem.GetField(Rust.Metabolism, "radiationLevel", bf.private_instance)
local GetInstanceID, SetInstanceID = typesystem.GetField(UnityEngine.Object, "GetInstanceID", bf.public_instance)

function PLUGIN:OnServerInitialized()
    typesystem.LoadEnum(Rust.DamageTypeFlags, "DamageType") 
end

--[[
    self.HurtTimer = {}
    self.TheInfected = {}
    self.numInfected = 0
    local t = new(UnityEngine.GameObject._type) 
    if self.Config.InfLevels.Timer then
        timer.Repeat(self.Config.InfLevels.Interval, 0, function() self:InfectionMessage(nil) end)
]]

function PLUGIN:InfectionMessage(player)
    local message = "There are currently " .. tostring(self.numInfected) .. " virus contaminated survivors."
    local VirusInfo1 = "If you die or stand in radiation long enough it will cure the rust virus."
    local VirusInfo2 = "If you have the virus and attack player with a Rock, Axes or Arrow you give them the virus."
    local VirusInfo3 = "If you let yourself die or suicide there may be unexpected side effects. If you have virus."
    local InfectionLevel = ""
    if self.numInfected <= self.Config.InfLevels.a then
        InfectionLevel = "Medic claims current rust virus spread level is LOW"
    elseif self.numInfected >= self.Config.InfLevels.b then
        InfectionLevel = "Medic claims current rust virus spread level is MEDIUM"
    elseif self.numInfected >= self.Config.InfLevels.c then
        InfectionLevel = "Medic claims current rust virus spread level is HIGH"
    elseif self.numInfected >= self.Config.InfLevels.d then
        InfectionLevel = "Medic claims current rust virus spread level is VERY HIGH"
    end
    if not player then
        rust.BroadcastChat(message)
        rust.BroadcastChat(InfectionLevel)
    else
        rust.SendChatMessage(player, message)
        rust.SendChatMessage(player, VirusInfo1)
        rust.SendChatMessage(player, VirusInfo2)
        rust.SendChatMessage(player, VirusInfo3)
        rust.SendChatMessage(player, InfectionLevel)
    end
end

function PLUGIN:cmdInfection(player, cmd, args)
    self:InfectionMessage(player)
end

function PLUGIN:Infected(player, cmd, args)
    local status = self:IsInfected(player)
    local message = "Test results show you are " .. (function() if status then return 'contaminated with the rust virus!' else return 'negative, you have no rust virus.' end end)()
    rust.SendChatMessage(player, message)
end

function PLUGIN:OnSpawnPlayer(playerclient, usecamp, avatar)
    if avatar then
        if self:IsInfected(playerclient.player) then
            timer.Once(5, function() self:cmdHurt(playerclient.player) end)
            timer.Once(10, function() rust.Notice(playerclient.player, "Test results show you have the rust virus!") end)
        end
    end
end

function PLUGIN:SendHelpText(player)
    if not HasPermission(rust.UserIDFromPlayer(player), "infection.immunity" then
        rust.SendChatMessage(player, messages.ChatHelp)
    end
end

function PLUGIN:InfectUser(player)
    if player then
        if self:IsInfected(player) == false then
            self.numInfected = self.numInfected + 1
            local uid = rust.GetUserID(player)
            self.TheInfected[uid].Infected = true
            rust.Notice(player, "You have contracted the rust virus!")
            self.HurtTimer[player] = timer.Repeat(self.Config.VirusSpeed, function() self:cmdHurt2(player) end)
        end
    end
end

function PLUGIN:RemoveVirusUser(player)
    if player then
        if self:IsInfected(player) == true then
            self.numInfected = self.numInfected - 1
            local uid = rust.GetUserID(player)
            self.TheInfected[uid].Infected = false
            rust.Notice(player, "Medic says you have been cured of the rust virus.")
                    self.HurtTimer[player]:Destroy()
        end
    end
end

function PLUGIN:RemoveVirusUserDead(player)
    if player then
        if self:IsInfected(player) == true then
            rust.Notice(player, "The rust virus dies with you.")
            self.numInfected = self.numInfected - 1
            local uid = rust.GetUserID(player)
            self.TheInfected[uid].Infected = false
                      self.HurtTimer[player]:Destroy()
        end
    end
end

function PLUGIN:IsInfected(player) 
    if player then
        local uid = rust.GetUserID(player) 
        local Infection = self.TheInfected[ uid ]
        if not Infection then
            Infection = {}
            Infection.Infected = false
            Infection.Inv = {}
            self.TheInfected[uid] = Infection
            self:Save()
        end
        return self.TheInfected[uid].Infected
    end
    return false
end

function PLUGIN:OnKilled(takedamage, damage)
    local victim = damage.victim.client
    if victim and damage.victim.controllable then
        if damage.victim.controllable:GetComponent("HumanController") then
            if self:IsInfected(victim.player) then        
                if victim.player then
                    self:RemoveVirusUserDead(victim.player)
                end
            end
        end
    end
end

function PLUGIN:OnHurt(takedamage, damage)  
    local victim = damage.victim.client
    if victim and damage.attacker.controllable and damage.victim.controllable then
        local Attacker = damage.attacker.client
        if damage.attacker.controllable:GetComponent("HumanController") and damage.victim.controllable:GetComponent("HumanController") then
            local dmgtype = tostring(damage.damageTypes)
            if dmgtype == tostring(DamageType.damage_melee) then
                if self:IsInfected(Attacker.player) then
                    if victim.player then
                        self:InfectUser(victim.player)
                    end
                end
            end
            end
        if self.Config.RadInfection and damage.attacker.controllable:GetComponent("Metabolism")  and damage.victim.controllable:GetComponent("HumanController") then
            local Avatar = victim.player:LoadAvatar()
            if Avatar.vitals.radiation >= self.Config.RadLevel then
                if self:IsInfected(victim.player) then
                    if victim.player then
                        self:RemoveVirusUser(victim.player)
                    end
                end
            end
        end
    else
        local Random = math.random(1, 100)
        if Random > self.Config.InfectPercent then
            if victim and damage.victim.controllable then
                if victim.player then
                    self:InfectUser(victim.player)
                end
            end
        end
    end
end

function PLUGIN:cmdHurt(player)
    local player = player.playerClient
    if not player then return end

    local controllable = player.controllable
    if not controllable then return end

    local metabolism = controllable:GetComponent("Metabolism")
    metabolism:AddPoison(2)

    local fallDamage = controllable:GetComponent("FallDamage")
    if fallDamage:GetLegInjury() < 3 then fallDamage:SetLegInjury(1) end
            
    local humanBodyTakeDamage = controllable:GetComponent("HumanBodyTakeDamage")
    if humanBodyTakeDamage:IsBleeding() == false then humanBodyTakeDamage:SetBleedingLevel(1) end

    self.HurtTimer[player] = timer.Repeat(self.Config.VirusSpeed, function() self:cmdHurt2(player) end)
end

function PLUGIN:cmdHurt2(player)
    local player = player.playerClient
    if not player then return end

    local controllable = player.controllable
    if not controllable then return end

    local char = rust.GetCharacter(player)
    if char.takeDamage.health > 1 then char.takeDamage.health = char.takeDamage.health - 1 end

    local metabolism = controllable:GetComponent("Metabolism")
    metabolism:AddPoison(2)
    if metabolism:GetCalorieLevel() > 100 then metabolism:AddCalories(-50) end
end
