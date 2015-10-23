namespace Oxide.Plugins
{
    [Info("Prefabs", "Wulf/lukespragg", 0.1)]
    [Description("List all prefabs on command.")]

    class Prefabs : RustPlugin
    {
        [ChatCommand("prefabs")]
        void ChatDump(BasePlayer player)
        {
            if (player.net.connection.authLevel != 2)
            {
                SendReply(player, "You do not have permission to use this command!");
                return;
            }

            foreach (var str in GameManifest.Get().pooledStrings)
                Puts(str.str);
        }

        [ConsoleCommand("global.prefabs")]
        void ConsoleDump(ConsoleSystem.Arg arg)
        {
            if (arg.connection != null)
            {
                if (arg.connection.authLevel != 2)
                {
                    SendReply(arg, "You do not have permission to use this command!");
                    return;
                }
            }

            foreach (var str in GameManifest.Get().pooledStrings)
                Puts(str.str);
        }
    }
}
