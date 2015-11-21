namespace Oxide.Plugins
{
    [Info("NoSlack", "Wulf/lukespragg", 0.1)]
    [Description("Disables Slack notifications.")]

    public class NoSlack : HurtworldPlugin
    {
        void OnServerInitialized()
        {
            GameManager.Instance.EnableSlackNotifications = false;
            PrintWarning("Slack notifications disabled!");
        }

        bool OnPostToSlack() => false;
    }
}
