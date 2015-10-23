namespace Oxide.Plugins
{
    [Info("No Slack", "Wulf/lukespragg", 0.1)]
    [Description("Disables Slack notifications.")]

    public class NoSlack : HurtworldPlugin
    {
        void OnServerInitialized()
        {
            GameManager.Instance.EnableSlackNotifications = false;
            Puts("Slack notifications disabled!");
        }

        object OnPostToSlack() => null;
    }
}
