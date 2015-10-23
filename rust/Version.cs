namespace Oxide.Plugins
{
    [Info("Version", "Wulf/lukespragg", 2.0, ResourceId = 763)]
    [Description("Shows current Oxide version and Rust protocol on command.")]

    class Version : RustPlugin
    {
        [ChatCommand("version")]
        void ShowVersion(BasePlayer player)
        {
            const int rustProtocol = Rust.Protocol.network;
            var oxideVersion = Core.OxideMod.Version.ToString();

            PrintToChat(player, "<size=15><b>Server is running ",
            "<color=orange>Oxide Mod v" + oxideVersion + "</color> and ",
            "<color=red>Rust v" + rustProtocol + "</color></b></size>");
        }
    }
}
