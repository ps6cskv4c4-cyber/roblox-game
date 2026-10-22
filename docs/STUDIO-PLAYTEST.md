# Studio playtest checklist

Open the place and press **Play**, not Run. Open **View → Output** to catch red errors. This checklist is pending: the cloud environment cannot run Roblox Studio.

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
- Use the Device Emulator to inspect narrow screens, touch prompts and the default movement controls. Check collection and welcome cards in landscape and portrait.
- Test the actual supported devices before public release. Desktop keyboard testing alone does not validate mobile or gamepad controls.

Record the first red Output message, the action that caused it, and a screenshot for visual issues. Close Studio's test with Shift+F5. Progress intentionally resets between test sessions in this build.
