// For development use only!

using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;
using Newtonsoft.Json.Linq;
using Oxide.Core;
using Oxide.Core.Libraries;

namespace Oxide.Plugins
{
    [Info("Developer", "Wulf/lukespragg", 0.1, ResourceId = 0)]
    [Description("Adds Steam group members to the Rust developers list.")]

    class Developer : RustPlugin
    {
        #region Configuration

        const string Group = "oxidemod";
        const string ApiKey = "3C6AC44419D5B1B63E2DBBDFE085417F"; // http://steamcommunity.com/dev/apikey

        #endregion

        #region Developers List

        readonly WebRequests request = Interface.Oxide.GetLibrary<WebRequests>("WebRequests");
        readonly FieldInfo developers = typeof(DeveloperList).GetField("developerIDs", BindingFlags.Static | BindingFlags.NonPublic);
        ulong[] developerIds;
        List<ulong> list;

        void OnServerInitialized()
        {
            timer.Once(3f, () =>
            {
                // Get developer list
                developerIds = (ulong[])developers.GetValue(null);
                list = developerIds.ToList();
                Puts($"{list.Count} developers listed");

                // Add group members
                timer.Once(3f, AddDevelopers);
            });
        }

        static readonly Regex Regex = new Regex(@"<steamID64>(?<steamid>.+)</steamID64>");

        void AddDevelopers()
        {
            var url = $"http://steamcommunity.com/groups/{Group}/memberslistxml/?xml=1";

            // Get Steam group members
            request.EnqueueGet(url, (code, response) =>
            {
                if (code != 200 || response == null)
                {
                    Puts("Checking for Steam group members failed! (" + code + ")");
                    Puts("Retrying in 5 seconds...");
                    timer.Once(5f, AddDevelopers);
                    return;
                }

                if (Regex.Matches(response).Count == 0) timer.Once(10f, AddDevelopers);

                foreach (Match match in Regex.Matches(response))
                {
                    // Convert Steam ID to ulong format
                    var steamid = ulong.Parse(match.Groups["steamid"].ToString());

                    // Check if list contains Steam ID
                    if (developerIds.Contains(steamid)) continue;
                    // Add Steam ID to list
                    Puts($"Added {steamid} to developers list");
                    list.Add(steamid);
                    developers.SetValue(null, list.ToArray());
                    Puts($"{list.Count.ToString()} developers listed");
                }
            }, this);
        }

        #endregion

        #region Console Command

        [ConsoleCommand("developers")]
        void ListDevelopers()
        {
            if (list == null || list.Count == 0)
            {
                Puts("No developers listed!");
                return;
            }

            foreach (var developer in list)
            {
                var url = $"http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key={ApiKey}&steamids={developer}";

                // Get Steam username from ID
                request.EnqueueGet(url, (code, response) =>
                {
                    if (code != 200 || response == null)
                    {
                        Puts("Checking for Steam username failed! (" + code + ")");
                        return;
                    }

                    // Extract the username
                    var json = JObject.Parse(response);
                    var username = (string)json["response"]["players"][0]["personaname"];

                    // Show the developer info
                    Puts($"{developer.ToString()} ({username})");
                }, this);
            }

            Puts($"{list.Count} developers listed");
        }

        #endregion
    }
}
