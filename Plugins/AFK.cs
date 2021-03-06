﻿using System;
using System.Collections.Generic;
using Oxide.Core.Libraries.Covalence;

namespace Oxide.Plugins
{
    [Info("AFK", "Wulf/lukespragg", "2.0.0")]
    [Description("Kicks players that are AFK (away from keyboard) for too long.")]

    class AFK : CovalencePlugin
    {
        // Do NOT edit this file, instead edit AFK.json in oxide/config and AFK.en.json in oxide/lang,
        // or create a language file for another language using the 'en' file as a default.

        #region Configuration

        int AfkLimitInSeconds => GetConfig("AfkLimitInSeconds", 600);
        bool KickAfkPlayers => GetConfig("KickAfkPlayers", true);

        protected override void LoadDefaultConfig()
        {
            Config["AfkLimitInSeconds"] = AfkLimitInSeconds;
            Config["KickAfkPlayers"] = KickAfkPlayers;
            SaveConfig();
        }

        #endregion

        #region Localization

        void LoadDefaultMessages()
        {
            var messages = new Dictionary<string, string>
            {
                {"KickedForAfk", "You were kicked for being AFK for {0} minutes"},
                {"NoLongerAfk", "You are no longer AFK"},
                {"YouWentAfk", "You went AFK"}
            };
            lang.RegisterMessages(messages, this);
        }

        #endregion

        #region Initialization

        void Loaded()
        {
            #if !HURTWORLD && !REIGNOFKINGS && !RUST
            throw new NotSupportedException("This plugin does not support this game");
            #endif

            LoadDefaultConfig();
            LoadDefaultMessages();
            permission.RegisterPermission("afk.bypass", this);
        }

        void OnServerInitialized()
        {
            foreach (var player in players.Online) AfkCheck(player.BasePlayer.UniqueID);
        }

        #endregion

        #region AFK Checking

        readonly Hash<string, GenericPosition> lastPosition = new Hash<string, GenericPosition>();
        readonly Dictionary<string, Timer> afkTimer = new Dictionary<string, Timer>();

        void AfkCheck(string steamId)
        {
            if (HasPermission(steamId, "afk.bypass")) return;
            afkTimer.Add(steamId, timer.Repeat(AfkLimitInSeconds, 0, () =>
            {
                var player = players.GetOnlinePlayer(steamId);
                if (!IsPlayerAfk(player)) return;

                // TODO: Send message/warning to player

                if (!KickAfkPlayers) return;
                var limit = TimeSpan.FromSeconds(AfkLimitInSeconds).ToString(); // TODO: Convert to minutes
                player.Kick(string.Format(GetMessage("KickedForAfk", steamId), limit));
            }));
        }

        void ResetPlayer(string steamId)
        {
            if (afkTimer.ContainsKey(steamId))
            {
                afkTimer[steamId].Destroy();
                afkTimer.Remove(steamId);
            }
            if (lastPosition.ContainsKey(steamId)) lastPosition.Remove(steamId);
        }

        bool IsPlayerAfk(ILivePlayer player)
        {
            Puts(player.BasePlayer.UniqueID);
            Puts(player.Character.GetPosition().ToString()); // This is somehow erroring
            var position = player.Character.GetPosition();

            if (!lastPosition[player.BasePlayer.UniqueID].Equals(position)) return false;
            lastPosition[player.BasePlayer.UniqueID] = position;

            return true;
        }

        void Unload()
        {
            foreach (var player in players.Online) ResetPlayer(player.BasePlayer.UniqueID);
        }

        #endregion

        #region Game Hooks

        #if HURTWORLD
        float OnEntityTakeDamage()
        {
            PrintWarning("OnEntityTakeDamage");
            return 0f;
        }

        void OnPlayerInit(PlayerSession session) => AfkCheck(session.SteamId.ToString());
        void OnPlayerDisconnected(PlayerSession session) => ResetPlayer(session.SteamId.ToString());
        bool IsPlayerAfk(PlayerSession session) => IsPlayerAfk(players.GetOnlinePlayer(session.SteamId.ToString()));
        #endif

        #if REIGNOFKINGS
        //OnPlayerSpawn(PlayerFirstSpawnEvent e)
        void OnPlayerConnected(CodeHatch.Engine.Networking.Player player) => AfkCheck(players.GetOnlinePlayer(player.Id.ToString()));
        void OnPlayerDisconnected(CodeHatch.Engine.Networking.Player player) => ResetPlayer(players.GetOnlinePlayer(player.Id.ToString()));
        bool IsPlayerAfk(CodeHatch.Engine.Networking.Player player) => IsPlayerAfk(players.GetOnlinePlayer(player.Id.ToString()));
        #endif

        #if RUST
        void OnPlayerInit(BasePlayer player) => AfkCheck(players.GetOnlinePlayer(player.UserIDString()));
        void OnPlayerDisconnected(BasePlayer player) => ResetPlayer(players.GetOnlinePlayer(player.UserIDString));
        bool IsPlayerAfk(BasePlayer player) => IsPlayerAfk(players.GetOnlinePlayer(player.UserIDString));
        #endif

        #endregion

        #region Helper Methods

        T GetConfig<T>(string name, T defaultValue)
        {
            if (Config[name] == null) return defaultValue;
            return (T)Convert.ChangeType(Config[name], typeof(T));
        }

        string GetMessage(string key, string steamId = null) => lang.GetMessage(key, this, steamId);

        bool HasPermission(string steamId, string perm) => permission.UserHasPermission(steamId, perm);

        #endregion
    }
}
