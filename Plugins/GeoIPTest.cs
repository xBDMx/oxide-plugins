using Oxide.Core.Plugins;

namespace Oxide.Plugins
{
    [Info("GeoIPTest", "Wulf/lukespragg", 0.1)]
    [Description("GeoIP test plugin.")]

    class GeoIPTest : RustPlugin
    {
        [PluginReference] Plugin GeoIP;

        void Loaded()
        {
            if (!GeoIP)
            {
                Puts("GeoIP is not loaded! http://oxidemod.org/plugins/1364/");
                return;
            }
            var country = GeoIP.Call("GetCountry", "8.8.8.8");
            Puts("Country name for IP 8.8.8.8 is " + country);
        }
    }
}
