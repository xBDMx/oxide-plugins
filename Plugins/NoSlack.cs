namespace Oxide.Plugins
{
    [Info("NoSlack", "Wulf/lukespragg", 0.1)]
    [Description("Disables Slack notifications.")]

    class NoSlack : CovalencePlugin
    {
        void OnServerInitialized() => PrintWarning("Slack notifications disabled!");

        bool OnPostToSlack() => false;
    }
}
