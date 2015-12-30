namespace Oxide.Plugins
{
    [Info("CupboardProtection", "Wulf/lukespragg", 0.1, ResourceId = 1390)]
    [Description("Makes cupboards invulnerable, unable to be destroyed.")]

    class CupboardProtection : RustPlugin
    {
        object OnEntityTakeDamage(BaseCombatEntity entity) => entity.name.Contains("cupboard") ? (object) false : null;
    }
}
