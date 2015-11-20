using System;
using System.Linq;

namespace Oxide.Plugins
{
    [Info("Exporter", "Mughisi", 1.0, ResourceId = 0)]
    [Description("Exports game data for the Oxide API Docs.")]

    class Exporter : RustPlugin
    {
        [ConsoleCommand("export.items")]
        void ExportItems()
        {
            var items = ItemManager.itemList;
            var itemList = items.OrderBy(x => x.shortname).ToList();

            // Item List: http://docs.oxidemod.org/rust/#item-list
            Log("ItemListDocs", "# Item List");
            Log("ItemListDocs", "");
            Log("ItemListDocs", "| Item Id       | Item Name                    | Item Shortname           |");
            Log("ItemListDocs", "|---------------|------------------------------|--------------------------|");

            // Item Skins: http://docs.oxidemod.org/rust/#item-skins
            Log("ItemSkinsDocs", "# Item Skins");

            // Prefab List: http://docs.oxidemod.org/rust/#prefab-list
            Log("PrefabListDocs", "# Prefab List");

            foreach (var item in itemList)
            {
                #region Item List

                var idSpace = string.Empty;
                var displayname = item.displayName.english.Replace("\t", "").Replace("\r", "").Replace("\n", "");
                var shortname = item.shortname.Replace("\t", " ").Replace("\r", "").Replace("\n", "");
                for (var i = 0; i < 14 - item.itemid.ToString().Length; i++) idSpace += " ";
                var nameSpace = string.Empty;
                for (var i = 0; i < 29 - displayname.Length; i++) nameSpace += " ";
                var shortnameSpace = string.Empty;
                for (var i = 0; i < 25 - shortname.Length; i++)  shortnameSpace += " ";

                Log("ItemListDocs", $"| {item.itemid}{idSpace}| {displayname}{nameSpace}| {shortname}{shortnameSpace}|");

                #endregion

                #region Item Skins

                if (item.skins.Length == 0) continue;
                Log("ItemSkinsDocs", "");
                Log("ItemSkinsDocs", $"## {displayname}");
                Log("ItemSkinsDocs", "| Skin Id      | Skin name                         |");
                Log("ItemSkinsDocs", "|--------------|-----------------------------------|");

                foreach (var skin in item.skins.OrderBy(x => x.invItem.displayName.english))
                {
                    idSpace = string.Empty;
                    shortnameSpace = string.Empty;
                    for (var i = 0; i < 13 - skin.id.ToString().Length; i++) idSpace += " ";
                    var skinname = skin.invItem.displayName.english;
                    for (var i = 0; i < 34 - skinname.Length; i++) shortnameSpace += " ";

                    Log("ItemSkinsDocs", $"| {skin.id}{idSpace}| {skinname}{shortnameSpace}|");
                }

                #endregion
            }
        }

        [ConsoleCommand("export.prefabs")]
        void ExportPrefabs()
        {
            foreach (var prefab in GameManifest.Get().pooledStrings) Puts(prefab.str);
        }

        #region Helper Methods

        static void Log(string fileName, string content)
        {
            var dateTime = DateTime.Now.ToString("yyMMdd_HHmmss");
            ConVar.Server.Log($"oxide/logs/{fileName}_{dateTime}.txt", content);
        }

        #endregion
    }
}
