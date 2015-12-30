using System.Linq;

namespace Oxide.Plugins
{
    [Info("FilterExt", "Wulf/lukespragg", 0.1)]
    [Description("Extension to Oxide's filter for removing unwanted console messages.")]

    class FilterExt : CovalencePlugin
    {
        void Loaded()
        {
            #region Get existing filter list

            #if HURTWORLD
            var filter = Game.Hurtworld.HurtworldExtension.Filter.ToList();
#endif
#if REIGNOFKINGS
            var filter = Game.ReignOfKings.ReignOfKingsExtension.Filter.ToList();
#endif
#if RUST
            var filter = Game.Rust.RustExtension.Filter.ToList();
#endif
#if THEFOREST
            var filter = Game.TheForest.TheForestExtension.Filter.ToList();
#endif
#if UNTURNED
            var filter = Game.Unturned.UnturnedExtension.Filter.ToList();
#endif

            #endregion

            #region Add messages to filter

            // Rust
            filter.Add(", serialization");
            filter.Add("- deleting");
            filter.Add("[event] assets/");

            /*
            filter.Add("ERROR building certificate chain");
            filter.Add("Enforcing SpawnPopulation Limits");
            filter.Add("Finished writing containers for save, waiting on save thread");
            filter.Add("Reporting Performance Data");
            filter.Add("Saving complete");
            filter.Add("Starting game save to file");
            filter.Add("TimeWarning:");
            filter.Add("Writing to disk completed from background thread");
            filter.Add("but max allowed is");
            */

            // Hurtworld
            filter.Add("SteamServerConnectFailure: k_EResultServiceUnavailable");
            filter.Add("SteamServerConnectFailure: k_EResultNoConnection");
            filter.Add("SteamServerConnected");

            #endregion

            #region Update filter list

#if HURTWORLD
            Game.Hurtworld.HurtworldExtension.Filter = filter.ToArray();
            #endif
            #if REIGNOFKINGS
            Game.ReignOfKings.ReignOfKingsExtension.Filter = filter.ToArray();
            #endif
            #if RUST
            Game.Rust.RustExtension.Filter = filter.ToArray();
            #endif
            #if THEFOREST
            Game.TheForest.TheForestExtension.Filter = filter.ToArray();
            #endif
            #if UNTURNED
            Game.Unturned.UnturnedExtension.Filter = filter.ToArray();
            #endif

            #endregion
        }
    }
}
