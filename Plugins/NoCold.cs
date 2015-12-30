namespace Oxide.Plugins
{
    [Info("NoCold", "Wulf/lukespragg", 0.1, ResourceId = 0)]
    [Description("Stops players from getting cold.")]

    class NoCold : RustPlugin
    {
        void OnRunPlayerMetabolism(PlayerMetabolism metabolism)
        {
            metabolism.temperature.min = 0f; // TODO: Check for actual normal value
        }
    }
}
