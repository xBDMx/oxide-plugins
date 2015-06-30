// For internal use only!

using System.Linq;
using System.Reflection;
using Oxide.Game.Rust;

namespace Oxide.Plugins
{
    [Info("Filter Extension", "Wulfspider", 0.1)]
    class FilterExt : RustPlugin
    {
        void Loaded()
        {
            var filter = typeof(RustExtension).GetField("Filter", BindingFlags.Static | BindingFlags.NonPublic);
            var filterItems = (string[])filter.GetValue(null);
            var filterList = filterItems.ToList();
            filterList.Add("took 00:");
            filterList.Add("Enforcing SpawnPopulation Limits");
            filterList.Add("but max allowed is");
            filterList.Add("- deleting");
            filterList.Add("Reporting Performance Data");
            filterList.Add("ERROR building certificate chain");
            filter.SetValue(null, filterList.ToArray());
        }
    }
}
