# Storm Salvagers

A first playable Roblox prototype: search a coastal island for treasure, return to the workshop to bank your haul, and decide whether one more find is worth risking the approaching storm.

[Download the Studio place](downloads/Storm-Salvagers.rbxl) or [the playtest ZIP](downloads/Storm-Salvagers-Playtest.zip). On the GitHub file page, choose **Download raw file**. These are the packaged first-prototype builds; rebuilding source writes newer outputs to `dist/`.

## Play on Windows

Download and extract `Storm-Salvagers-Playtest.zip` from the build output. In Roblox Studio, open `Storm-Salvagers.rbxl` with **File → Open from File** (`Ctrl+O`), then press **Play** (`F5`). Use Play rather than Run so Studio creates your player and interface. No plugin installation, API access setting, or cloud-save configuration is needed.

- **Move:** WASD. **Jump:** Space. **Camera:** hold the right mouse button and move.
- **Collect:** approach a floating treasure and hold E. Native Roblox prompts also support touch and gamepad.
- **Bank:** return to the workshop's mint counter and hold E.
- **Upgrade:** hold E at the gold workbench; the next price is shown in the objective card or the station response.
- **Collection:** click the collection button at the top right. Finds count when banked.
- **Storm:** shelter inside the workshop before the countdown ends. Being caught outside loses your unbanked haul and returns you to safety.

Rounds have 150 seconds of scavenging, 15 seconds of storm, and 10 seconds of recovery. The first nearby pickup is guaranteed, and a storm heart can be found at the ruins each round. Carrying more weight reduces movement speed. All banked coins, upgrades and discoveries last for the current server session only. Stopping a local Studio test resets them.

## Included

An editable island with a workshop, wreck, lighthouse and ruins; 28 loot locations; eight collectible types; three purchasable bag upgrades; a rare-find crew display; an objective card, storm clock, wallet, inventory meter and field guide; server-owned inventory/rewards and proximity validation; and pure Luau tests for economy and round rules. Map and UI use Roblox primitives and fonts without external asset IDs.

The prototype is intended for solo and small-group testing. Public release still needs Studio and device playtests, persistent data, additional security review, sound and art polish, and Roblox publishing eligibility checks. Configure an appropriate player limit in Creator Dashboard before a release. No purchase system or public publishing automation is included.

## Build from source

Pinned tool versions: Rojo **7.7.1**, Luau **0.743**, StyLua **2.6.0**, plus Python 3. In this cloud environment:

```bash
source /workspace/.cloud-setup/roblox/env.sh
cd /workspace/roblox-game
python3 scripts/build.py
```

The build runs the economy/round tests, strict analysis of shared modules and tests, compilation of every game script, and a formatting check. It regenerates the map and builds both binary and XML places, validates their structure, and packages the playtest and source ZIPs under `dist/`. The command exits on a failed check.

For a local source workflow, install those tool versions and put them on PATH, then run `python scripts/build.py`. The portable place-file workflow above requires only Studio. Generated map changes belong in `scripts/build_world.py`; the build overwrites `assets/World.rbxmx`.

```bash
luau tests/rules.luau
rojo serve default.project.json --address 127.0.0.1 --port 34872
```

Rojo serving is optional and needs the matching Studio plugin and network connectivity to the same machine. This cloud server's localhost address is not reachable from your Windows PC. A live local sync setup has not been configured. For now, open the built place file. Save any manual Studio changes in a separate copy before opening a newer build, since source rebuilds do not include those edits automatically.

## Validation boundary

Cloud checks execute the shared game rules and verify source compilation and place assembly. They do not run the Roblox engine, its physics, native prompts, GUI layout or multiplayer replication. Use [the Studio playtest checklist](docs/STUDIO-PLAYTEST.md) for those checks. These engine checks remain pending until someone runs the place in Studio.
