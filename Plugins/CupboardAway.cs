namespace Oxide.Plugins
{
    [Info("CupboardAway", "Wulf/lukespragg", "0.1.0", ResourceId = 0)]
    [Description("Makes cupboard protection available only if the owner is online.")]

    class CupboardAway : CovalencePlugin
    {
        bool OnCupboardAuthorize(BuildingPrivlidge cupboard) => CanAuthorize(cupboard);

        bool OnCupboardDeauthorize(BuildingPrivlidge cupboard) => CanAuthorize(cupboard);

        private void OnEntityEnter(TriggerBase trigger, BaseEntity entity)
        {
            if (!(entity is BasePlayer) || !(trigger is BuildPrivilegeTrigger)) return;
        }

        static bool CanAuthorize(BuildingPrivlidge cupboard)
        {
            foreach (var authorized in cupboard.authorizedPlayers) return BasePlayer.Find(authorized.userid.ToString());
            return false;
        }
    }
}
