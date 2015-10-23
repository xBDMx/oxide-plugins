/*
TODO:
- Show blocked message via centered GUI overlay
- Move items back to inventory from Research Table?
- Add option to remove all deployed Research Tables?
- Add option to remove Research Tables in inventory?
- Add option to disable crafting of Research Table?
- Add permission support to bypass blocks?
- Add config for message localization
*/

namespace Oxide.Plugins
{
    [Info("NoResearch", "Wulf/lukespragg", 0.1, ResourceId = 0)]
    [Description("Blocks item researching completely.")]

    class NoResearch : RustPlugin
    {
        bool OnItemResearch(Item item, BasePlayer player)
        {
            PrintToChat(player, "Researching items is not allowed!");
            return false;
        }

        object OnItemCraft(ItemCraftTask item)
        {
            var player = item.owner.ToPlayer();
            if (!player) return null;
            PrintToChat(player, "Crafting research tables is not allowed!");
            return false;
        }
    }
}
