using Oxide.Core.Plugins;

namespace Oxide.Plugins
{
    [Info("Email Test", "Wulf/lukespragg", 0.1)]
    [Description("Email API test plugin.")]

    class EmailTest : RustPlugin
    {
        [PluginReference]
        Plugin EmailAPI;

        [ConsoleCommand("global.etest")]
        void SendTest()
        {
            if (!EmailAPI)
            {
                Puts("Email API is not loaded! http://oxidemod.org/plugins/712/");
                return;
            }
            EmailAPI.Call("EmailMessage", "This is a test email", "This is a test of the Email API!");
        }
    }
}
