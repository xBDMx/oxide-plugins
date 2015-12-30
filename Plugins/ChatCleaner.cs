using System;
using System.Collections.Generic;
using System.Linq;

using Oxide.Core.Plugins;

namespace Oxide.Plugins
{
    [Info("Chat Cleaner", "Wulf/lukespragg", 0.4, ResourceId = 1183)]
    [Description("Clears or resets player's chat when joining the server and on command.")]

    class ChatCleaner : RustPlugin
    {
        #region Configuration Defaults

        // Do NOT edit the config here, instead edit ChatCleaner.json in server/<identity>/oxide/config

        private bool configChanged;

        // Plugin settings
        private const string DefaultChatCommand = "clear";
        private const bool DefaultClearOnJoin = true;
        private const bool DefaultRestoreChat = false;
        private const bool DefaultShowCleared = true;
        private const bool DefaultShowWelcome = true;

        public string ChatCommand { get; private set; }
        public bool ClearOnJoin { get; private set; }
        public bool RestoreChat { get; private set; }
        public bool ShowCleared { get; private set; }
        public bool ShowWelcome { get; private set; }

        // Plugin messages
        private const string DefaultCleared = "<color=orange><size=18><b><i>Chat Cleared!</i></b></size></color>";
        private const string DefaultWelcome = "<color=orange><size=20><b>Welcome to {0}!</b></size></color>";

        public string Cleared { get; private set; }
        public string Welcome { get; private set; }

        #endregion

        #region Configuration Setup

        protected override void LoadDefaultConfig() => PrintWarning("New configuration file created.");

        void Loaded() => LoadConfigValues();

        void LoadConfigValues()
        {
            // Plugin settings
            ChatCommand = GetConfigValue("Settings", "ChatCommand", DefaultChatCommand);
            ClearOnJoin = GetConfigValue("Settings", "ClearOnJoin", DefaultClearOnJoin);
            RestoreChat = GetConfigValue("Settings", "RestoreChat", DefaultRestoreChat);
            ShowCleared = GetConfigValue("Settings", "ShowCleared", DefaultShowCleared);
            ShowWelcome = GetConfigValue("Settings", "ShowWelcome", DefaultShowWelcome);

            // Plugin messages
            Cleared = GetConfigValue("Messages", "Cleared", DefaultCleared);
            Welcome = GetConfigValue("Messages", "Welcome", DefaultWelcome);

            if (!configChanged) return;
            Puts("Configuration file updated.");
            SaveConfig();
        }

        #endregion

        [ChatCommand("clear")]
        void ChatClear(BasePlayer player, string command)
        {
            /*
            local i = 1; while i <= 14 do rust.SendChatMessage(player, messages.Cleared); i = i + 1 end
            */
            var magic = string.Concat(Enumerable.Repeat("\n", 802));
            PrintToChat(player, magic);

            if (ShowCleared) PrintToChat(player, Cleared);
            if (command != null && RestoreChat) ChatRestore(player);
        }

        [PluginReference]
        Plugin ChatHandler;

        void ChatRestore(BasePlayer player)
        {
            if (!ChatHandler)
            {
                Puts("History cannot be restored, please install http://oxidemod.org/plugins/707/");
                return;
            }
            ChatHandler.Call("cmdHistory", player);
        }

        void OnPlayerInit(BasePlayer player)
        {
            if (ClearOnJoin) ChatClear(player, null);
            if (ShowWelcome) PrintToChat(player, Welcome, ConVar.Server.hostname);
        }

        //void SendHelpText(BasePlayer player) => PrintToChat(player, ChatHelp);

        #region Helper Methods

        T GetConfigValue<T>(string category, string setting, T defaultValue)
        {
            var data = Config[category] as Dictionary<string, object>;
            object value;
            if (data == null)
            {
                data = new Dictionary<string, object>();
                Config[category] = data;
                configChanged = true;
            }
            if (data.TryGetValue(setting, out value)) return (T)Convert.ChangeType(value, typeof(T));
            value = defaultValue;
            data[setting] = value;
            configChanged = true;
            return (T)Convert.ChangeType(value, typeof(T));
        }

        void SetConfigValue<T>(string category, string setting, T newValue)
        {
            var data = Config[category] as Dictionary<string, object>;
            object value;
            if (data != null && data.TryGetValue(setting, out value))
            {
                value = newValue;
                data[setting] = value;
                configChanged = true;
            }
            SaveConfig();
        }

        #endregion
    }
}
