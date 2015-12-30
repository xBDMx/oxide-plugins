/*
TODO:
- Make LogToFile more dynamic/generic?
- Fix invalid log directory due to variable
*/

using System;

using Oxide.Core;

namespace Oxide.Plugins
{
    [Info("Logger", "Wulf/lukespragg", "0.1.0", ResourceId = 0)]
    [Description("")]

    class Logger : RustPlugin
    {        #region Connection Logging
        void OnPlayerInit(BasePlayer player)
        {
            LogToFile(player, "{player} ({steamid} connected at {position}");
        }

        #endregion

        #region Helper Methods

        static void LogToFile(BasePlayer player, string message)
        {
            var dateTime = DateTime.Now.ToString("M-d-yyyy");
            var position = $"{player.transform.position.x}, {player.transform.position.y}, {player.transform.position.z}";
            message = message.Replace("{player}", player.displayName).Replace("{steamid}", player.UserIDString).Replace("{position}", position);
            ConVar.Server.Log(Interface.Oxide.LogDirectory + $"connections_{dateTime}.txt", message);
        }

        #endregion
    }
}
