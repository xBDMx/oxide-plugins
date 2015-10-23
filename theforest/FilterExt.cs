using System.Linq;
using System.Reflection;

using Oxide.Game.TheForest;

namespace Oxide.Plugins
{
    [Info("Filter Extension", "Wulf/lukespragg", 0.1)]
    [Description("Extension to Oxide's filter for removing unwanted messages.")]

    class FilterExt : TheForestPlugin
    {
        void Loaded()
        {
            // Get existing filter list
            var filter = TheForestExtension.Filter.ToList();

            // Add messages to filter
            filter.Add("Placeholder");

            // Update filter list
            TheForestExtension.Filter = filter.ToArray();
        }
    }
}
