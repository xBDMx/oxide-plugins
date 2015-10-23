using System;
using System.Collections;
using System.Collections.Generic;

using UnityEngine;

namespace Oxide.Plugins
{
    [Info("Sign Artist", "Bombardir", "0.2.3", ResourceId = 992)]

    class SignArtist : RustPlugin
    {
        static GameObject WebObject;
        static UnityWeb UWeb;
        static Dictionary<BasePlayer, float> CoolDowns = new Dictionary<BasePlayer, float>();

        #region Unity WWW

        class QueueItem
        {
            public string url;
            public Signage sign;
            public BasePlayer sender;
            public QueueItem(string ur, BasePlayer se, Signage si)
            {
                url = ur;
                sender = se;
                sign = si;
            }
        }

        class UnityWeb : MonoBehaviour
        {
            internal static bool ConsoleLog = true;
            internal static string ConsoleLogMsg = "Player[{steam} {name}] loaded {id} image from {url}!";
            internal static int MaxActiveLoads = 3;
            static List<QueueItem> QueueList = new List<QueueItem>();
            static byte ActiveLoads;

            public void Add(string url, BasePlayer player, Signage s)
            {
                QueueList.Add(new QueueItem(url, player, s));
                if (ActiveLoads < MaxActiveLoads)
                    Next();
            }

            void Next()
            {
                ActiveLoads++;
                QueueItem qi = QueueList[0];
                QueueList.RemoveAt(0);
                WWW www = new WWW(qi.url);
                StartCoroutine(WaitForRequest(www, qi));
            }

            IEnumerator WaitForRequest(WWW www, QueueItem info)
            {
                yield return www;
                BasePlayer player = info.sender;
                if (www.error == null)
                {
                    if (www.size <= MaxSize)
                    {
                        Signage sign = info.sign;
                        if (sign.textureID > 0U)
                            FileStorage.server.Remove(sign.textureID, FileStorage.Type.png, sign.net.ID);
                        sign.textureID = FileStorage.server.Store(www.bytes, FileStorage.Type.png, sign.net.ID, 0U);
                        sign.SendNetworkUpdate();
                        player.ChatMessage(Loaded);

                        if (ConsoleLog)
                            ServerConsole.PrintColoured(ConsoleColor.DarkYellow, "[Sign Artist]" + string.Format(ConsoleLogMsg, player.userID, player.displayName, sign.textureID, info.url));
                    }
                    else
                    {
                        player.ChatMessage(SizeError);
                        CoolDowns.Remove(player);
                    }
                }
                else
                {
                    player.ChatMessage( string.Format(Error, www.error) );
                    CoolDowns.Remove(player);
                }
                ActiveLoads--;
                if (QueueList.Count > 0)
                    Next();
            }
        }

        #endregion

        #region Chat Commands

        [ChatCommand("sil")]
        void sil(BasePlayer player, string command, string[] args)
        {
            if (args.Length == 0)
            {
                player.ChatMessage(Syntax);
                return;
            }

            float cd;
            if (CoolDowns.TryGetValue(player, out cd) && cd > Time.realtimeSinceStartup && !HasPerm(player, "sil_cd"))
            {
                player.ChatMessage( string.Format( CooldownMsg, ToReadableString(cd - Time.realtimeSinceStartup) ) );
                return;
            }

            RaycastHit hit;
            Signage sign = null;
            if (Physics.Raycast(player.eyes.HeadRay(), out hit, MaxDist))
                sign = hit.transform.GetComponentInParent<Signage>();

            if (sign == null)
            {
                player.ChatMessage(NoSignFound);
                return;
            }

            if (!(player.CanBuild() || HasPerm(player, "sil_owner")))
            {
                player.ChatMessage(NotYourSign);
                return;
            }

            if (HasPerm(player, "sil_url"))
            {
                UWeb.Add(args[0], player, sign);
                player.ChatMessage(AddedToQueue);
                if (UrlCooldown > 0)
                    CoolDowns[player] = Time.realtimeSinceStartup + UrlCooldown;
            }
            else
                player.ChatMessage(NoPerm);
        }

        #endregion

        #region Config | Init | Unload

        static float MaxDist = 2f;
        static float StorageCooldown = 180f;
        static float UrlCooldown = 180f;
        static uint MaxSize = 2048U;
        static string NoPerm = "You don't have permission to use this command!";
        static string Syntax = "Syntax: /sil <URL> | /sil s <number>";
        static string NoSignFound = "You need to look/get closer to a sign!";
        static string NotYourSign = "You can't change this sign! (protected by tool cupboard)";
        static string CooldownMsg = "You have recently used this command! You need to wait: {time}";
        static string AddedToQueue = "Your picture was added to load queue!";
        static string Loaded = "Image was loaded to Sign!";
        static string Error = "Image loading fail! Error: {error}";
        static string NotExists = "File with this name not exists in storage folder!";
        static string SizeError = "This file is too large. Max size: {size}KB";

        protected override void LoadDefaultConfig() { }

        void OnServerInitialized()
        {
            permission.RegisterPermission("sil_url", this);
            permission.RegisterPermission("sil_owner", this);
            permission.RegisterPermission("sil_cd", this);

            CheckCfg("Log url console", ref UnityWeb.ConsoleLog);
            CheckCfg("Log format", ref UnityWeb.ConsoleLogMsg);
            CheckCfg("Max active uploads", ref UnityWeb.MaxActiveLoads);
            CheckCfg("Max sign detection distance", ref MaxDist);
            CheckCfg("Max file size(KB)", ref MaxSize);
            CheckCfg("Command cooldown after storage", ref StorageCooldown);
            CheckCfg("Command cooldown after url", ref UrlCooldown);
            CheckCfg("Command cooldown msg", ref CooldownMsg);
            CheckCfg("NoPermission", ref NoPerm);
            CheckCfg("Syntax", ref Syntax);
            CheckCfg("No sign", ref NoSignFound);
            CheckCfg("Not your sign", ref NotYourSign);
            CheckCfg("Added to queue", ref AddedToQueue);
            CheckCfg("Loaded", ref Loaded);
            CheckCfg("Not Exists", ref NotExists);
            CheckCfg("Error", ref Error);
            SaveConfig();

            // Small performance improvements
            UnityWeb.ConsoleLogMsg = UnityWeb.ConsoleLogMsg
                                .Replace("{steam}", "{0}")
                                .Replace("{name}", "{1}")
                                .Replace("{id}", "{2}")
                                .Replace("{url}", "{3}");
            Error = Error.Replace("{error}", "{0}");

            CooldownMsg = CooldownMsg.Replace("{time}", "{0}");

            SizeError = SizeError.Replace("{size}", MaxSize.ToString());

            MaxSize *= 1024;

            WebObject = new GameObject("WebObject");
            UWeb = WebObject.AddComponent<UnityWeb>();
        }

        void Unload()
        {
            UnityEngine.Object.Destroy(WebObject);
        }

        #endregion

        #region Util methods

        void CheckCfg<T>(string Key, ref T var)
        {
            if (Config[Key] == null)
                Config[Key] = var;
            else
                try { var = (T)Convert.ChangeType(Config[Key], typeof(T)); }
                catch { Config[Key] = var; }
        }

        bool HasPerm(BasePlayer p, string pe) => permission.UserHasPermission(p.userID.ToString(), pe);

        static string ToReadableString(float seconds)
        {
            TimeSpan span = TimeSpan.FromSeconds(seconds).Duration();
            string formatted = string.Format("{0}{1}{2}{3}",
                span.Days > 0 ? $"{span.Days:0} day{(span.Days == 1 ? string.Empty : "s")}, " : string.Empty,
                span.Hours > 0 ? $"{span.Hours:0} hour{(span.Hours == 1 ? string.Empty : "s")}, " : string.Empty,
                span.Minutes > 0 ? $"{span.Minutes:0} minute{(span.Minutes == 1 ? string.Empty : "s")}, " : string.Empty,
                span.Seconds > 0 ? $"{span.Seconds:0} second{(span.Seconds == 1 ? string.Empty : "s")}" : string.Empty);

            if (formatted.EndsWith(", ")) formatted = formatted.Substring(0, formatted.Length - 2);

            if (string.IsNullOrEmpty(formatted)) formatted = "0 seconds";

            return formatted;
        }

        #endregion
    }
}
