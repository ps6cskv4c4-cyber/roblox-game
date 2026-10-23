# Storm Salvagers

A playable Roblox prototype: search an island for treasure, fight scrap sentinels, explore the docks, and optionally compete on Rival Island. Bank your haul at the safe workshop before the storm.

[Download the Studio place](downloads/Storm-Salvagers.rbxl) or [the playtest ZIP](downloads/Storm-Salvagers-Playtest.zip). On the GitHub file page, choose **Download raw file**. These contain the combat/island update; a successful build refreshes both `dist/` and these download copies. Save any manual edits to your previous Studio place in a separate copy before opening a new build.

## Play on Windows

Download and extract `Storm-Salvagers-Playtest.zip` from the build output. In Roblox Studio, open `Storm-Salvagers.rbxl` with **File → Open from File** (`Ctrl+O`), then press **Play** (`F5`). Use Play rather than Run so Studio creates your player and interface. No plugin installation, API access setting, or cloud-save configuration is needed.

- **Move:** WASD. **Jump:** Space. **Camera:** hold the right mouse button and move.
- **Collect:** approach a floating treasure and hold E. Native Roblox prompts also support touch and gamepad.
- **Bank:** return to the workshop's mint counter and hold E.
- **Upgrade:** hold E at the gold workbench; the next price is shown in the objective card or the station response.
- **Collection:** click the collection button at the top right. Finds count when banked.
- **Cutter:** equip hotbar slot 1, face an enemy and click to swing. Gamepad RT and the touch attack button also send attacks.
- **Blaster:** hold E at the blue armory counter to buy it for 120 banked coins, then equip it from the hotbar (normally slot 2). Aim and click/tap/RT to fire. The next two armory purchases reinforce both weapons for 160 and 350 coins.
- **PvE:** four sentinels guard salvage sites. Step out of their red attack warning, defeat them, and collect their dropped circuit or battery. Enemies respawn during the run.
- **PvP:** cross the red boundary on the island east of the bridge. Player damage requires both players inside that arena. Crossing out disables PvP, and players on the mainland are friendly. Knockouts don't transfer banked coins.
- **Healing:** the workshop heals automatically. Green-cross field medkits heal 40 HP with a personal 20-second cooldown.
- **Storm:** shelter inside the workshop before the countdown ends. Being caught outside loses your unbanked haul and returns you to safety.

Rounds have 150 seconds of scavenging, 15 seconds of storm, and 10 seconds of recovery. The first nearby pickup is guaranteed, and a storm heart can be found at the ruins each round. Carrying more weight reduces movement speed. Death and storm losses remove the current haul while retaining banked coins and purchased gear. All progress lasts for the current server session only; stopping a local Studio test resets it. Combat is disabled during storm and recovery phases.

## Included

An editable main island, western scrap docks and a bridge-connected PvP island with cover; a safe workshop and armory; 35 loot locations and 12 collectible types; starter melee and purchasable ranged weapons with damage upgrades; four pathfinding enemy guards across two types, health labels, attack warnings and loot drops; medkits, health/zone indicators, weapon effects and knockout counters; three bag upgrades; a rotating recent rare-find crew display; and a scrollable field guide. Map, equipment and UI use Roblox primitives and fonts without external asset IDs.

Damage, range, equipped-weapon ownership, purchase costs, cooldowns, finite aim coordinates, line of sight, safe zones, spawn protection and PvP eligibility are checked on the server. Enemy patrol/chase behavior stays near its guarded site. Those checks are prototype defenses, not a complete production anti-cheat system.

The prototype is intended for solo and small-group testing. Public release still needs Studio and device playtests, persistent data, additional security review, sound and art polish, and Roblox publishing eligibility checks. Configure an appropriate player limit in Creator Dashboard before a release. No purchase system or public publishing automation is included.

## Build from source

Pinned tool versions: Rojo **7.7.1**, Luau **0.743**, StyLua **2.6.0**, plus Python 3. In this cloud environment:

```bash
source /workspace/.cloud-setup/roblox/env.sh
cd /workspace/roblox-game
python3 scripts/build.py
```

The build runs economy/round and combat-policy tests, strict analysis of shared modules and tests, compilation of every game script, and a formatting check. It regenerates the map and builds binary and XML places, validates their structure and zone separation, and packages the playtest and source ZIPs under `dist/`. Only after those checks pass does it refresh the tracked place and ZIP in `downloads/`. The command exits on a failed check.

For a local source workflow, install those tool versions and put them on PATH, then run `python scripts/build.py`. The portable place-file workflow above requires only Studio. Generated map changes belong in `scripts/build_world.py`; the build overwrites `assets/World.rbxmx`.

```bash
luau tests/rules.luau
luau tests/combat.luau
rojo serve default.project.json --address 127.0.0.1 --port 34872
```

Rojo serving is optional and needs the matching Studio plugin and network connectivity to the same machine. This cloud server's localhost address is not reachable from your Windows PC. A live local sync setup has not been configured. For now, open the built place file. Save any manual Studio changes in a separate copy before opening a newer build, since source rebuilds do not include those edits automatically.

## Validation boundary

The first prototype was reported working in Studio by the user. This combat/island update still needs a new Studio playtest. Cloud checks execute the shared game rules and verify source compilation and place assembly; they do not run Roblox physics, NPC pathfinding, tool input, GUI layout or multiplayer replication. Use [the Studio playtest checklist](docs/STUDIO-PLAYTEST.md) for those checks.
