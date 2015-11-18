namespace Oxide.Plugins
{
    [Info("NoSupplySignal", "Wulf/lukespragg", 0.1, ResourceId = 0)]
    [Description("Prevents airdrops triggering from supply signals.")]

    class NoSupplySignal : RustPlugin
    {
        void OnWeaponThrown(BasePlayer player, BaseEntity entity)
        {
            if (entity.name.Contains("signal")) entity.KillMessage();
        }
    }
}
