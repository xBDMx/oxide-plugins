using Oxide.Core.Plugins;

namespace Oxide.Plugins
{
    [Info("Push Test", "Wulf / Luke Spragg", 0.1)]
    [Description("Push API test plugin.")]
    class PushTest : RustPlugin
    {
        [PluginReference]
        Plugin PushAPI;

        [ChatCommand("ptest")]
        [ConsoleCommand("global.ptest")]
        void SendTest()
        {
            if (!PushAPI)
            {
                Puts("Push API is not loaded! http://oxidemod.org/plugins/705/");
                return;
            }
            PushAPI.Call("PushMessage", "This is a test push", "This is a test of the Push API!");
        }
    }
}
