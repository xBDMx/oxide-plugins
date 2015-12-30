using System.Collections.Generic;
using System.Linq;

using UnityEngine;

namespace Oxide.Plugins
{
    [Info("Hooks", "Oxide Team", 0.1)]
    [Description("Tests all of the available Oxide hooks.")]

    class Hooks : CovalencePlugin
    {
        #region Hook Verification

        int hookCount;
        int hooksVerified;
        Dictionary<string, bool> hooksRemaining = new Dictionary<string, bool>();

        public void HookCalled(string hook)
        {
            if (!hooksRemaining.ContainsKey(hook)) return;
            hookCount--;
            hooksVerified++;
            PrintWarning($"{hook} is working");
            hooksRemaining.Remove(hook);
            PrintWarning(hookCount == 0 ? "All hooks verified!" : $"{hooksVerified} hooks verified, {hookCount} hooks remaining");
        }

        #endregion

        #region Plugin Hooks

        private void Init()
        {
            hookCount = hooks.Count;
            hooksRemaining = hooks.Keys.ToDictionary(k => k, k => true);
            PrintWarning("{0} hook to test!", hookCount);
            HookCalled("Init");
        }

        protected override void LoadDefaultConfig() => HookCalled("LoadDefaultConfig");

        private void Loaded() => HookCalled("Loaded");

        private void Unloaded() => HookCalled("Unloaded");

        private void OnFrame() => HookCalled("OnFrame");

        #endregion

        #region Server Hooks (generic)

        private void OnServerInitialized() => HookCalled("OnServerInitialized");

        private void OnServerSave() => HookCalled("OnServerSave");

        private void OnServerShutdown() => HookCalled("OnServerShutdown");

        #endregion

        private void OnExperienceGained()
        {
            PrintWarning("RECEIVED EXPERIENCE!");
        }

#if HURTWORLD

        private object OnPlayerChat(PlayerSession session)
        {
            HookCalled("OnPlayerChat");
            return null;
        }

        private void OnPlayerDeath(PlayerSession session, EntityEffectSourceData source)
        {
            HookCalled("OnPlayerDeath");
        }

        private void OnPlayerRespawn(PlayerSession session)
        {
            HookCalled("OnPlayerRespawn");
        }

        private bool CanExitVehicle(PlayerSession session, CharacterMotorSimple passenger, VehiclePassenger vehicle)
        {
            HookCalled("CanExitVehicle");
            return true;
        }

        private object CanUseVehicle(uLink.NetworkPlayer player, CharacterMotorSimple passenger, VehicleUsable vehicle)
        {
            HookCalled("CanUseVehicle");
            return null;
        }

        private void OnEnterVehicle(PlayerSession session, CharacterMotorSimple passenger, VehiclePassenger vehicle)
        {
            HookCalled("OnEnterVehicle");
        }

        private void OnExitVehicle(PlayerSession session, CharacterMotorSimple passenger, VehiclePassenger vehicle)
        {
            HookCalled("OnExitVehicle");
        }

        private void OnSetPassenger(PlayerSession session, CharacterMotorSimple passenger, VehiclePassenger vehicle)
        {
            HookCalled("OnSetPassenger");
        }

        /*private object OnVehicleInput(VehiclePassenger vehicle, ref InputControls controls)
        {
            HookCalled("OnVehicleInput");
            return null;
        }*/

#endif

#if RUST

        #region Server Hooks

        private void OnTick() => HookCalled("OnTick");

        private void OnTerrainInitialized() => HookCalled("OnTerrainInitialized");

        private void OnRunCommand(ConsoleSystem.Arg arg)
        {
            HookCalled("OnRunCommand");
            // TODO: Print command messages
        }

        #endregion

        #region Player Hooks

        private void OnUserApprove(Network.Connection connection)
        {
            HookCalled("OnUserApprove");
        }

        private void CanClientLogin(Network.Connection connection)
        {
            HookCalled("CanClientLogin");
        }

        private void OnPlayerConnected(Network.Message packet)
        {
            HookCalled("OnPlayerConnected");
            Puts($"{packet.connection.username} ({packet.connection.userid}) connected!");
        }

        private void OnPlayerDisconnected(BasePlayer player, string reason)
        {
            HookCalled("OnPlayerDisconnected");
            Puts($"{player.displayName} ({player.userID}) disconnected!");
        }

        private void OnPlayerInit(BasePlayer player)
        {
            HookCalled("OnPlayerInit");
            // TODO: Force admin to spawn/wakeup
        }

        private void OnFindSpawnPoint()
        {
            HookCalled("OnFindSpawnPoint");
            // TODO: Print spawn point
        }

        private void OnPlayerRespawned(BasePlayer player)
        {
            HookCalled("OnPlayerRespawned");
            // TODO: Print respawn location
            // TODO: Print start metabolism values
            // TODO: Give admin items for testing
        }

        private void OnPlayerChat(ConsoleSystem.Arg arg)
        {
            HookCalled("OnPlayerChat");
        }

        private void OnPlayerLoot(PlayerLoot inventory, BaseEntity entity)
        //private void OnPlayerLoot(PlayerLoot inventory, BasePlayer target)
        //private void OnPlayerLoot(PlayerLoot inventory, Item item)
        {
            HookCalled("OnPlayerLoot");
        }

        private void OnPlayerInput(BasePlayer player, InputState input)
        {
            HookCalled("OnPlayerInput");
        }

        private void OnRunPlayerMetabolism(PlayerMetabolism metabolism)
        {
            HookCalled("OnRunPlayerMetabolism");
            // TODO: Print new metabolism values
        }

        #endregion

        #region Entity Hooks

        private void OnAirdrop(CargoPlane plane, Vector3 location)
        {
            HookCalled("OnAirdrop");
        }

        private void OnEntityTakeDamage(BaseCombatEntity entity, HitInfo info)
        {
            HookCalled("OnEntityTakeDamage");
        }

        private void OnEntityBuilt(Planner planner, GameObject go)
        {
            HookCalled("OnEntityBuilt");
        }

        private void OnEntityDeath(BaseCombatEntity entity, HitInfo hitInfo)
        {
            HookCalled("OnEntityDeath");
            // TODO: Print player died
            // TODO: Automatically respawn admin after X time
        }

        private void OnEntityEnter(TriggerBase trigger, BaseEntity entity)
        {
            HookCalled("OnEntityEnter");
        }

        private void OnEntityLeave(TriggerBase trigger, BaseEntity entity)
        {
            HookCalled("OnEntityLeave");
        }

        private void OnEntitySpawned(BaseNetworkable entity)
        {
            HookCalled("OnEntitySpawned");
        }

        #endregion

        #region Item Hooks

        private void OnItemCraft(ItemCraftTask item)
        {
            HookCalled("OnItemCraft");
            // TODO: Print item crafting
        }

        private void OnItemDeployed(Deployer deployer, BaseEntity entity)
        {
            HookCalled("OnItemDeployed");
            // TODO: Print item deployed
        }

        private void OnCollectiblePickup(Item item, BasePlayer player)
        {
            HookCalled("OnCollectiblePickup");
            // TODO: Print item picked up
        }

        private void OnItemAddedToContainer(ItemContainer container, Item item)
        {
            HookCalled("OnItemAddedToContainer");
            // TODO: Print item added
        }

        private void OnItemRemovedFromContainer(ItemContainer container, Item item)
        {
            HookCalled("OnItemRemovedToContainer");
            // TODO: Print item removed
        }

        private void OnConsumableUse(Item item)
        {
            HookCalled("OnConsumableUse");
            // TODO: Print consumable item used
        }

        private void OnConsumeFuel(BaseOven oven, Item fuel, ItemModBurnable burnable)
        {
            HookCalled("OnConsumeFuel");
            // TODO: Print fuel consumed
        }

        private void OnDispenserGather(ResourceDispenser dispenser, BaseEntity entity, Item item)
        {
            HookCalled("OnDispenserGather");
            // TODO: Print item to be gathered
        }

        private void OnCropGather(PlantEntity plant, Item item, BasePlayer player)
        {
            HookCalled("OnCropGather");
            // TODO: Print item to be gathered
        }

        private void OnSurveyGather(SurveyCharge survey, Item item)
        {
            HookCalled("OnSurveyGather");
        }

        private void OnQuarryGather(MiningQuarry quarry, Item item)
        {
            HookCalled("OnQuarryGather");
        }

        private void OnQuarryEnabled() => HookCalled("OnQuarryEnabled");

        private void OnTrapArm(BearTrap trap)
        {
            HookCalled("OnTrapArm");
        }

        private void OnTrapSnapped(BaseTrapTrigger trap, GameObject go)
        {
            HookCalled("OnTrapSnapped");
        }

        private void OnTrapTrigger(BaseTrap trap, GameObject go)
        {
            HookCalled("OnTrapTrigger");
        }

        #endregion

        #region Structure Hooks

        private void CanUseDoor(BasePlayer player, BaseLock door)
        //private void CanUseDoor(BasePlayer player, CodeLock door)
        //private void CanUseDoor(BasePlayer player, KeyLock door)
        {
            HookCalled("CanUseDoor");
        }

        private void OnStructureDemolish(BuildingBlock block, BasePlayer player)
        {
            HookCalled("OnStructureDemolish");
        }

        private void OnStructureRepair(BuildingBlock block, BasePlayer player)
        {
            HookCalled("OnStructureRepair");
        }

        private void OnStructureRotate(BuildingBlock block, BasePlayer player)
        {
            HookCalled("OnStructureRotate");
        }

        private void OnStructureUpgrade(BuildingBlock block, BasePlayer player, BuildingGrade.Enum grade)
        {
            HookCalled("OnStructureUpgrade");
        }

        private void OnHammerHit(BasePlayer player, HitInfo info)
        {
            HookCalled("OnHammerHit");
        }

        private void OnWeaponFired(BaseProjectile projectile, BasePlayer player, ItemModProjectile mod, ProtoBuf.ProjectileShoot projectiles)
        {
            HookCalled("OnWeaponFired");
        }

        private void OnMeleeThrown(BasePlayer player, Item item)
        {
            HookCalled("OnMeleeThrown");
        }

        private void OnItemThrown(BasePlayer player, BaseEntity entity)
        {
            HookCalled("OnItemThrown");
        }

        private void OnSignLocked(Signage sign, BasePlayer player)
        {
            HookCalled("OnSignLocked");
        }

        private void OnSignUpdated(Signage sign, BasePlayer player)
        {
            HookCalled("OnSignUpdated");
        }

        private void OnDoorClosed(Door door, BasePlayer player)
        {
            HookCalled("OnDoorClosed");
        }

        private void OnDoorOpened(Door door, BasePlayer player)
        {
            HookCalled("OnDoorOpened");
        }

        private void OnCupboardAuthorize(BuildingPrivlidge priviledge, BasePlayer player)
        {
            HookCalled("OnCupboardAuthorize");
        }

        private void OnCupboardDeauthorize(BuildingPrivlidge priviledge, BasePlayer player)
        {
            HookCalled("OnCupboardDeauthorize");
        }

        private void OnRocketLaunched(BasePlayer player, BaseEntity entity)
        {
            HookCalled("OnRocketLaunched");
        }

        private void OnTrapArm(BearTrap trap, BasePlayer player)
        {
            HookCalled("OnTrapArm");
        }

        private void OnTrapDisarm(Landmine trap, BasePlayer player)
        {
            HookCalled("OnTrapDisarm");
        }

        private void OnTrapSnapped(BearTrap trap, GameObject go)
        {
            HookCalled("OnTrapSnapped");
        }

        private void OnTrapTrigger(BearTrap trap, GameObject go)
        {
            HookCalled("OnTrapTrigger");
        }

        private void OnPlayerAttack(BasePlayer attacker, HitInfo info)
        {
            HookCalled("OnPlayerAttack");
        }

        #endregion

#endif

#if UNTURNED
        private void OnRunCommand(Steamworks.CSteamID steamId, string command, string arg)
        {
            HookCalled("OnRunCommand");
        }
#endif
    }
}
