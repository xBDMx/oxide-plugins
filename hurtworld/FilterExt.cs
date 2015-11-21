using System.Linq;
using Oxide.Game.Hurtworld;

namespace Oxide.Plugins
{
    [Info("FilterExt", "Wulf/lukespragg", 0.1, ResourceId = 0)]
    [Description("Extension to Oxide's filter for removing unwanted console messages.")]

    class FilterExt : HurtworldPlugin
    {
        void Loaded()
        {
            // Get existing filter list
            var filter = HurtworldExtension.Filter.ToList();

            // Add messages to filter
            filter.Add("Finished writing containers for save, waiting on save thread");
            filter.Add("Writing to disk completed from background thread");

            // Update filter list
            HurtworldExtension.Filter = filter.ToArray();
        }
    }
}
