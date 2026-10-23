# Studio playtest checklist

Open the new place and press **Play**, not Run. Open **View → Output** to catch red errors. The user reported the first prototype working; the checks below remain pending for the combat/island update because the cloud environment cannot run Roblox Studio.

## First session

- The island is visible in edit mode; no baseplate setup or scripts need to be pasted.
- Play spawns a character inside the workshop with the Storm Salvagers HUD and a welcome card.
- Dismiss the card, leave via the stairs and collect the nearby sea glass with E.
- Haul value and weight increase; the treasure disappears for all players.
- Collect enough treasure to fill the bag. Overflow is rejected without removing the pickup.
- Verify a loaded bag moves more slowly than an empty one.
- Return to the mint bank counter. Banking clears the bag and adds the correct coins exactly once.
- Open the field guide. Only banked finds are discovered.
- Use the gold workbench. An affordable upgrade deducts the displayed cost and increases capacity; an unaffordable one changes nothing.
- Bank a rare or legendary find. A matching trophy appears on a workshop plinth.
- Scroll the field guide and check all 12 slots. New dock and arena loot should use the same inventory/banking rules.

## Weapons, enemies and healing

- Equip slot 1. A cutter should appear in the character's hand; clicking while facing a nearby sentinel produces a swing and damage number.
- Attack too far away, facing away, or through cover: no damage should land.
- Approach each guard. It should chase, route around obstacles, stop chasing far from its camp, and return home. Confirm the wreck/ruins steps are traversable in actual physics.
- Step out of a red attack warning before the strike. Damage should be avoidable; staying close should reduce health.
- Defeat a scout and the ruin guardian. Exactly one loot item drops per enemy, it can be collected and banked, and the enemy returns after its respawn delay if the run is still active.
- Try the armory with insufficient funds; then buy a blaster for 120. Equip it, aim and fire. Verify distance and cover block inappropriate hits.
- Reinforce weapons for 160 then 350. The next purchase should be rejected without a charge. Check both weapons after a respawn.
- Visit a field medkit while injured. It heals up to 40 HP without exceeding max health, then rejects immediate reuse by that player for 20 seconds. A second player's cooldown is separate.
- Visit the workshop while injured. Health regenerates, enemies stop following, and equipped weapons cannot damage anyone from inside.
- Reset or lose a fight with treasure in the bag. The bag empties, while previously banked coins, gear and finds remain for the current session.

## Storm and recovery

- At 0:30, the warning appears and the home marker is visible when outside.
- Stay outside carrying treasure when the storm begins. You return to the workshop, lose that haul, and retain banked coins, discoveries and upgrades.
- Repeat while sheltered inside the workshop. Unbanked treasure remains available to bank.
- Lighting changes during the storm, then recovers. A new run repopulates the island.
- Walk into the ocean. You return to the workshop without losing previously banked progress.
- Reset your character while carrying treasure. The haul clears and the HUD still works after respawning.

## Multiplayer and devices

- Use Studio's local server/client testing controls with two players, then a small group.
- Attempt to pick up the same treasure simultaneously: exactly one player receives it.
- Confirm one player's inventory, upgrades and wallet do not modify another's.
- Both clients see banked rare-find trophies and the same round phase.
- Leave/join during a storm; the new player starts safely.
- With two clients on the mainland, cutter and blaster attacks must not hurt the other player.
- Send one player into Rival Island while keeping the other outside its boundary. Test shots in BOTH directions: neither may cause player damage.
- Put both players inside the marked arena. Cutter and blaster hits should damage opponents when in range and unobstructed; cover should stop shots.
- Leave the red boundary during combat and verify protection returns. Confirm the HUD switches between safe, PvE and PvP states.
- Confirm deaths credit at most one knockout and never award the opponent banked coins. Repeat rapid attacks and weapon switches to check cooldowns.
- Start a storm during a fight. Combat stops and enemies disappear; surviving players outside are returned to the workshop by the storm.
- Verify the four-second spawn protection cannot be used to attack others while immune.
- Use the Device Emulator to inspect narrow screens, touch prompts and the default movement controls. Check collection and welcome cards in landscape and portrait.
- Test the actual supported devices before public release. Desktop keyboard testing alone does not validate mobile or gamepad controls.
- Check touch ATTACK and gamepad RT with both weapons. Center aiming should be used on these devices, while mouse aiming follows the cursor. Confirm standard jump/movement and collection prompts remain usable.

Record the first red Output message, the action that caused it, and a screenshot for visual issues. Close Studio's test with Shift+F5. Progress intentionally resets between test sessions in this build.
