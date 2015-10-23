PLUGIN.Title = "FallDamage"
PLUGIN.Description = "Allows you to set the maximum fall height for deaths."
PLUGIN.Version = V(1, 0, 2)
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.ResourceId = 855

-- TODO:
---- Add permissions check to console command
---- Merge chat and console functions

function PLUGIN:LoadDefaultConfig()
    self.Config.MaxFallHeight = tonumber(self.Config.MaxFallHeight) or 12

    self:SaveConfig()
end

local function HasPermission(steamId, perm)
    if permission.UserHasPermission(steamId, perm) then return true end
    return false
end

function PLUGIN:Init()
    self:LoadDefaultConfig()

    command.AddChatCommand("maxfall", self.Plugin, "MaxFall")
    command.AddConsoleCommand("global.maxfall", self.Plugin, "MaxFallCon")

    permission.RegisterPermission("maxfall.set", self.Plugin)
end

function PLUGIN:OnEntityTakeDamage(player, hitinfo)
    if player:GetComponent("BasePlayer") then
        if not hitinfo.damageTypes:find("DamageTypeList") or hitinfo.damageTypes:Total() <= 0 then
            return
        end

        local damageType = hitinfo.damageTypes:GetMajorityDamageType()

        if damageType:find("Fall") then
            local damage = tonumber(hitinfo.damageTypes:Total())
            local newdamage, max, health = (damage * 0.35), self.Config.MaxFallHeight, tonumber(player:Health())
            local setdamage = (health/max) * newdamage

            hitinfo.damageTypes:Set(damageType, setdamage)
        end
    end
end

function PLUGIN:MaxFall(player, cmd, args)
    if args.Length ~= 1 then
        local feet = self.Config.MaxFallHeight * 3.3
        rust.SendChatMessage(player, "Max fall height is : " .. self.Config.MaxFallHeight .. "m (" .. feet .. "ft)")
        return
    end

    if not HasPermission(rust.UserIDFromPlayer(player), "setmaxfall") then
        rust.SendChatMessage(player, "You do not have permission to use this command!")
        return
    end

    self.Config.MaxFallHeight = tonumber(args[0])
    self:SaveConfig()

    local feet = tonumber(args[0]) * 3.3
    rust.SendChatMessage(player, "Max fall height is now: " .. tonumber(args[0]) .. "m (" .. feet .. "ft)")
end

function PLUGIN:MaxFallCon(arg)
    if not arg:HasArgs(1) then
        arg:ReplyWith("You must specify an amount! Use 'setmaxfall <amount>'")
        return
    end

    self.Config.MaxFallHeight = tonumber(arg.Args[0])
    self:SaveConfig()

    local feet = arg.Args[0] * 3.3
    arg:ReplyWith("Max fall height is now: " .. arg.Args[0] .. "m (" .. feet .. "ft)")
end
