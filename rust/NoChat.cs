namespace Oxide.Plugins
{
    [Info("NoChat", "Wulf/lukespragg", 0.1, ResourceId = 0)]
    [Description("Blocks player chat completely.")]

    class NoChat : RustPlugin
    {
        bool OnPlayerChat(ConsoleSystem.Arg arg) => false;
    }
}
