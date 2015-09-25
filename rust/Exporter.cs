using System;
using System.Linq;

namespace Oxide.Plugins
{
    [Info("Exporter", "Mughisi", 1.0)]
    [Description("Used to export various gamedata that can be used to display in the Oxide Rust Docs")]
    class Exporter : RustPlugin
    {
        [ConsoleCommand("export.items")]
        private void ExportItems()
        {
            var items = ItemManager.itemList;
            var itemList = items.OrderBy(x => x.shortname).ToList();
            var datetime = DateTime.Now.ToString("yyMMdd_HHmmss");

            ConVar.Server.Log($"Oxide/Logs/ItemListDocs_{datetime}.txt", "# Item List");
            ConVar.Server.Log($"Oxide/Logs/ItemListDocs_{datetime}.txt", "");
            ConVar.Server.Log($"Oxide/Logs/ItemListDocs_{datetime}.txt", "| Item Id       | Item Name                    | Item Shortname           |");
            ConVar.Server.Log($"Oxide/Logs/ItemListDocs_{datetime}.txt", "|---------------|------------------------------|--------------------------|");

            ConVar.Server.Log($"Oxide/Logs/ItemSkinsDocs_{datetime}.txt", "# Item Skins");

            foreach (var item in itemList)
            {
                var idSpace = string.Empty;
                var displayname = item.displayName.english.Replace("\t", "").Replace("\r", "").Replace("\n", "");
                var shortname = item.shortname.Replace("\t", " ").Replace("\r", "").Replace("\n", "");
                for (var i = 0; i < 14 - item.itemid.ToString().Length; i++)
                    idSpace += " ";
                var nameSpace = string.Empty;
                for (var i = 0; i < 29 - displayname.Length; i++)
                    nameSpace += " ";
                var shortnameSpace = string.Empty;
                for (var i = 0; i < 25 - shortname.Length; i++)
                    shortnameSpace += " ";
                
                ConVar.Server.Log($"Oxide/Logs/ItemListDocs_{datetime}.txt", $"| {item.itemid}{idSpace}| {displayname}{nameSpace}| {shortname}{shortnameSpace}|");

                if (item.skins.Count() == 0) continue;
                ConVar.Server.Log($"Oxide/Logs/ItemSkinsDocs_{datetime}.txt", "");
                ConVar.Server.Log($"Oxide/Logs/ItemSkinsDocs_{datetime}.txt", $"## {displayname}");
                ConVar.Server.Log($"Oxide/Logs/ItemSkinsDocs_{datetime}.txt", "| Skin Id      | Skin name                         |");
                ConVar.Server.Log($"Oxide/Logs/ItemSkinsDocs_{datetime}.txt", "|--------------|-----------------------------------|");
                foreach (var skin in item.skins.OrderBy(x => x.invItem.displayName.english))
                {
                    idSpace = string.Empty;
                    shortnameSpace = string.Empty;
                    for (var i = 0; i < 13 - skin.id.ToString().Length; i++)
                        idSpace += " ";
                    var skinname = skin.invItem.displayName.english;
                    for (var i = 0; i < 34 - skinname.Length; i++)
                        shortnameSpace += " ";
                    ConVar.Server.Log($"Oxide/Logs/ItemSkinsDocs_{ datetime}.txt", $"| {skin.id}{idSpace}| {skinname}{shortnameSpace}|");
                }
            }
        }
    }
}
