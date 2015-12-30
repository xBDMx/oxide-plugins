/*
TODO:
- Add configuration for customizing chat sizes per group (owner, moderator, player)
*/

namespace Oxide.Plugins
{
    [Info("ChatSize", "Wulf/lukespragg", 0.1, ResourceId = 0)]
    [Description("Changes the chat size for certain players/groups.")]

    class ChatSize : RustPlugin
    {
        object OnPlayerChat(ConsoleSystem.Arg arg)
        {
            var message = arg.GetString(0, "text");
            var player = arg.connection.player as BasePlayer;
            var userId = (player?.UserIDString ?? "0");

            Puts($"{player.displayName}: {message}");
            //if (player.IsAdmin())
                ConsoleSystem.Broadcast("chat.add", userId, $"<size=20><color=#af5>{player.displayName}</color>: {message}</size>");

            return false;
        }
    }
}
