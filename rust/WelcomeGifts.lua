PLUGIN.Title = "Welcome Gifts"
PLUGIN.Version = V(0, 1, 2)
PLUGIN.Description = "Gives new players one or more welcome gifts on first join."
PLUGIN.Author = "Wulf/lukespragg"
PLUGIN.Url = "http://oxidemod.org/plugins/703/"
PLUGIN.ResourceId = 703
PLUGIN.HasConfig = true

-- TODO:
---- Give player a choice if multiple gifts are available
---- Add command to reset welcome gift for player/steamid

function PLUGIN:Init()
    self:LoadDefaultConfig()
    self.DataTable = datafile.GetDataTable("welcomegifts")
    self.DataTable.Recipients = self.DataTable.Recipients or {}
end

function PLUGIN:OnPlayerInit(player)
    if not player then return end
    local inv = player.inventory
    local pref = inv.containerMain
    local gifts = self.Config.Settings.Gifts
    local recipients = self.DataTable.Recipients
    local steamId = rust.UserIDFromPlayer(player)
    for key, value in pairs(recipients) do if steamId == key then return end end
    local giftList = ""
    for key, value in pairs(gifts) do
        if not self.ItemTable then self:ItemDefinitions() end
        if self.ItemTable[string.lower(key)] then itemName = self.ItemTable[string.lower(key)] else itemName = key end
        local item = global.ItemManager.CreateByName(itemName, value)
        if not item then
            local message = self.Config.Messages.InvalidItem:gsub("{itemname}", itemName)
            print("[" .. self.Title .. "] " .. message)
            return
        end
        inv:GiveItem(item, pref)
        self.DataTable.Recipients[steamId] = {}
        recipients[steamId] = {}
        giftList = giftList .. ", " .. itemName
    end
    self.DataTable.Recipients[steamId].Gifts = giftList
    datafile.SaveDataTable("welcomegifts")
    local message = self.Config.Messages.GiftsGiven:gsub("{player}", player.displayName)
    print("[" .. self.Title .. "] " .. message)
    local message = self.Config.Messages.GiftsReceived:gsub("{player}", player.displayName)
    rust.SendChatMessage(player, "", message)
end

function PLUGIN:ItemDefinitions()
    self.ItemTable = {}
    local itemList = global.ItemManager.GetItemDefinitions()
    local itemEnum = itemList:GetEnumerator()
    while itemEnum:MoveNext() do
        local itemName = string.lower(itemEnum.Current.displayname, "%%", "t")
        self.ItemTable[itemName] = tostring(itemEnum.Current.shortname)
    end
end

function PLUGIN:LoadDefaultConfig()
    self.Config.Settings = self.Config.Settings or {}
    self.Config.Settings.Gifts = self.Config.Settings.Gifts or { ["bandage"] = 3, ["apple"] = 5, ["can_tuna"] = 3 }
    self.Config.Messages = self.Config.Messages or {}
    self.Config.Messages.GiftsGiven = self.Config.Messages.GiftsGiven or "Welcome gift(s) given to {player}"
    self.Config.Messages.GiftsReceived = self.Config.Messages.GiftsReceived or "Enjoy your welcome gift(s) {player}!"
    self.Config.Messages.InvalidItem = self.Config.Messages.InvalidItem or "{itemname} is not a valid item!"
    self.Config.Settings.ChatName = nil -- Removed in 0.1.2
    self.Config.Settings.Recipients = nil -- Removed in 0.1.2
    self:SaveConfig()
end
