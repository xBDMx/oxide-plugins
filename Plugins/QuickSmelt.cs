﻿/*
TODO:
- Fix 'Creating item with less than 1 amount! (Charcoal)'
- Fix 'Failed to call hook 'OnConsumeFuel' on plugin 'QuickSmelt v1.1.0' (NullReferenceException: Object reference not set to an instance of an object)'
  at Oxide.Plugins.QuickSmelt.OnConsumeFuel (.BaseOven oven, .Item fuel, .ItemModBurnable burnable) [0x00000] in <filename unknown>:0
  at Oxide.Plugins.QuickSmelt.DirectCallHook (System.String name, System.Object&ret, System.Object[] args) [0x00000] in <filename unknown>:0
  at Oxide.Plugins.CSharpPlugin.InvokeMethod (System.Reflection.MethodInfo method, System.Object[] args) [0x00000] in <filename unknown>:0
- Check why it isn't increasing the speed
*/

using System;
using Random = UnityEngine.Random;

namespace Oxide.Plugins
{
    [Info("QuickSmelt", "Wulf/lukespragg", "1.1.1", ResourceId = 1067)]
    [Description("Increases the speed of the furnace smelting.")]

    class QuickSmelt : RustPlugin
    {
        // Do NOT edit this file, instead edit QuickSmelt.json in server/<identity>/oxide/config

        #region Configuration

        float ChancePerConsumption => GetConfig("ChancePerConsumption", 0.5f);
        float CharcoalChanceModifier => GetConfig("CharcoalChanceModifier", 1.5f);
        float CharcoalProductionModifier => GetConfig("CharcoalProductionModifier", 1f);
        bool DontOvercookMeat => GetConfig("DontOvercookMeat", true);
        float ProductionModifier => GetConfig("ProductionModifier", 1f);

        protected override void LoadDefaultConfig()
        {
            // Default is *roughly* x2 production rate
            Config["ChancePerConsumption"] = ChancePerConsumption;
            Config["CharcoalChanceModifier"] = CharcoalChanceModifier;
            Config["CharcoalProductionModifier"] = CharcoalProductionModifier;
            Config["DontOvercookMeat"] = DontOvercookMeat;
            Config["ProductionModifier"] = ProductionModifier;
            SaveConfig();
        }

        #endregion

        void OnConsumeFuel(BaseOven oven, Item fuel, ItemModBurnable burnable)
        {
            if (oven == null) return;

            var byproductChance = burnable.byproductChance * CharcoalChanceModifier;

            if (oven.allowByproductCreation && burnable.byproductItem != null && Random.Range(0.0f, 1f) <= byproductChance)
            {
                var obj = ItemManager.Create(burnable.byproductItem, (int)Math.Round(burnable.byproductAmount * CharcoalProductionModifier));
                if (!obj.MoveToContainer(oven.inventory)) obj.Drop(oven.inventory.dropPosition, oven.inventory.dropVelocity);
            }

            for (var i = 0; i < oven.inventorySlots; i++)
            {
                try
                {
                    var slotItem = oven.inventory.GetSlot(i);
                    if (slotItem == null || !slotItem.IsValid()) continue;

                    var cookable = slotItem.info.GetComponent<ItemModCookable>();
                    if (cookable == null) continue;

                    if (cookable.becomeOnCooked.category == ItemCategory.Food &&
                        slotItem.info.shortname.Trim().EndsWith(".cooked") && DontOvercookMeat) continue;

                    // The chance of consumption is going to result in a 1 or 0
                    var consumptionAmount = (int)Math.Ceiling(ProductionModifier * (Random.Range(0f, 1f) <= ChancePerConsumption ? 1 : 0));

                    // Check how many are actually in the furnace, before we try removing too many
                    var inFurnaceAmount = slotItem.amount;
                    if (inFurnaceAmount < consumptionAmount) consumptionAmount = inFurnaceAmount;

                    // Set consumption to however many we can pull from this actual stack
                    consumptionAmount = TakeFromInventorySlot(oven.inventory, slotItem.info.itemid, consumptionAmount, i);

                    // If we took nothing, then... we can't create any
                    if (consumptionAmount <= 0) continue;

                    // Create the item(s) that are now smelted
                    var smeltedItem = ItemManager.Create(cookable.becomeOnCooked, cookable.amountOfBecome * consumptionAmount);
                    if (!smeltedItem.MoveToContainer(oven.inventory)) smeltedItem.Drop(oven.inventory.dropPosition, oven.inventory.dropVelocity);
                }
                catch (InvalidOperationException) {}
            }
        }

        static int TakeFromInventorySlot(ItemContainer container, int itemId, int amount, int slot)
        {
            var item = container.GetSlot(slot);
            if (item.info.itemid != itemId || item.IsBlueprint()) return 0;

            if (item.amount > amount)
            {
                item.MarkDirty();
                item.amount -= amount;
                return amount;
            }

            amount = item.amount;
            item.RemoveFromContainer();
            return amount;
        }

        #region Helper Methods

        T GetConfig<T>(string name, T defaultValue)
        {
            if (Config[name] == null) return defaultValue;
            return (T)Convert.ChangeType(Config[name], typeof(T));
        }

        #endregion
    }
}
