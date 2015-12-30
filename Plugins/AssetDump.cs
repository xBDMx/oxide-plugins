using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEngine;
using Oxide.Core;
using Oxide.Game.Rust.Cui;

namespace Oxide.Plugins
{
    [Info("AssetDump", "Nogrod", "1.0.0")]
    class AssetDump : RustPlugin
    {
        private Dictionary<ulong, string> GUIInfo = new Dictionary<ulong, string>();

        [ConsoleCommand("asset.show")]
        void ccmdAssetShow(ConsoleSystem.Arg arg)
        {
            if (!arg.HasArgs()) return;
            var player = arg.Player();
            if (player == null) return;
            var shoppage = arg.GetInt(0);
            ShowAsset(player, shoppage);
        }

        [ChatCommand("asset")]
        private void cmdAsset(BasePlayer player, string command, string[] args)
        {
            ShowAsset(player);
        }

        private void ShowAsset(BasePlayer player, int page = 0)
        {
            string guiInfo;
            if (GUIInfo.TryGetValue(player.userID, out guiInfo))
                CuiHelper.DestroyUi(player, guiInfo);
            var filesField = typeof(FileSystem_AssetBundles).GetField("files", BindingFlags.Instance | BindingFlags.NonPublic);
            var files = (Dictionary<string, AssetBundle>)filesField.GetValue(FileSystem.iface);
            var images = files.Where(f => f.Key.EndsWith(".png")).Select(f => f.Key).ToArray();
            var max = 10;
            var maxHeight = 6;
            var maxSize = 1f / max;
            var maxSizeHeight = 0.9f / maxHeight;
            if (page < 0) page = 0;
            if (page > images.Length / max / maxHeight) page = images.Length / max / maxHeight;
            var offset = page * max * maxHeight;
            var elements = new CuiElementContainer();
            var main = GUIInfo[player.userID] = elements.Add(new CuiPanel
            {
                Image =
                    {
                        Color = "0.1 0.1 0.1 0.8"
                    },
                RectTransform =
                    {
                        AnchorMin = "0 0",
                        AnchorMax = "1 1"
                    },
                CursorEnabled = true
            });
            elements.Add(new CuiButton
            {
                Button =
                {
                    Command = $"asset.show {page - 1}",
                    Color = "0.8 0.8 0.8 0.2"
                },
                RectTransform =
                {
                    AnchorMin = "0.25 0.92",
                    AnchorMax = "0.35 0.98"
                },
                Text =
                {
                    Text = "Prev",
                    FontSize = 20,
                    Align = TextAnchor.MiddleCenter
                }
            }, main);
            elements.Add(new CuiButton
            {
                Button =
                {
                    Close = main,
                    Color = "0.8 0.8 0.8 0.2"
                },
                RectTransform =
                {
                    AnchorMin = "0.45 0.92",
                    AnchorMax = "0.55 0.98"
                },
                Text =
                {
                    Text = "Close",
                    FontSize = 20,
                    Align = TextAnchor.MiddleCenter
                }
            }, main);
            elements.Add(new CuiButton
            {
                Button =
                {
                    Command = $"asset.show {page + 1}",
                    Color = "0.8 0.8 0.8 0.2"
                },
                RectTransform =
                {
                    AnchorMin = "0.65 0.92",
                    AnchorMax = "0.75 0.98"
                },
                Text =
                {
                    Text = "Next",
                    FontSize = 20,
                    Align = TextAnchor.MiddleCenter
                }
            }, main);
            for (int index = 0; index < maxHeight; index++)
            {
                for (int index2 = 0; index2 < max; index2++)
                {
                    var image = offset + (index*max) + index2;
                    if (image >= images.Length) break;
                    elements.Add(new CuiElement
                    {
                        Parent = main,
                        Components =
                        {
                            new CuiRawImageComponent
                            {
                                Sprite = images[image]
                            },
                            new CuiRectTransformComponent
                            {
                                AnchorMin = $"{index2*maxSize} {0.9 - ((index+1)*maxSizeHeight)}",
                                AnchorMax = $"{(index2 + 1)*maxSize} {0.9 - (index*maxSizeHeight)}"
                            }
                        }
                    });
                    elements.Add(new CuiLabel
                    {
                        RectTransform =
                        {
                            AnchorMin = $"{index2*maxSize} {0.9 - ((index + 1)*maxSizeHeight)}",
                            AnchorMax = $"{(index2 + 1)*maxSize} {0.9 - (index*maxSizeHeight)}"
                        },
                        Text = { Text = Utility.GetFileNameWithoutExtension(images[image]) }
                    }, main);
                    PrintToConsole(player, images[image]);
                }
            }
            CuiHelper.AddUi(player, elements);
        }

        [ConsoleCommand("asset.export")]
        private void ccmdExport(ConsoleSystem.Arg arg)
        {
            var sb = new StringBuilder();
            var bundlesField = typeof(FileSystem_AssetBundles).GetField("bundles", BindingFlags.Instance | BindingFlags.NonPublic);
            var assetPathField = typeof(FileSystem_AssetBundles).GetField("assetPath", BindingFlags.Instance | BindingFlags.NonPublic);
            var bundles = (Dictionary<string, AssetBundle>)bundlesField.GetValue(FileSystem.iface);
            sb.AppendLine("Bundles: " + bundles.Count + " Path: " + assetPathField.GetValue(FileSystem.iface));
            foreach (var bundle in bundles)
            {
                sb.AppendLine("Bundle: " + bundle.Key);
                var assets = bundle.Value.GetAllAssetNames();
                foreach (var asset in assets)
                {
                    if (!asset.EndsWith(".png")) continue;
                    try
                    {
                        var path = Utility.GetDirectoryName(asset);
                        var assetObject = bundle.Value.LoadAsset<Texture2D>(asset);
                        var png = assetObject?.EncodeToPNG();
                        if (png == null) continue;
                        sb.AppendLine("\tAsset: " + asset + " Path: " + path + " Size: " + png.Length);
                        if (!Directory.Exists(path)) Directory.CreateDirectory(path);
                        File.WriteAllBytes(asset, png);
                    }
                    catch (Exception e)
                    {
                        sb.AppendLine(e.Message);
                    }
                }
            }
            Puts(sb.ToString());
        }
    }
}
