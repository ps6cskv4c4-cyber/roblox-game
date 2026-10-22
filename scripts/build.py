"""Validate source, generate the map, and package places for Roblox Studio."""
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET
import zipfile

from build_world import build as build_world

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"


def tool(name):
    found = shutil.which(name)
    cloud = Path("/workspace/.cloud-setup/roblox/bin") / name
    if found:
        return found
    if cloud.exists():
        return str(cloud)
    raise SystemExit(f"Missing {name}. Install the documented tool version and add it to PATH.")


def run(name, *args):
    subprocess.run([tool(name), *map(str, args)], cwd=ROOT, check=True)


def validate_place(path):
    tree = ET.parse(path)
    items = list(tree.iter("Item"))
    scripts = [i for i in items if i.attrib["class"] in ("Script", "LocalScript", "ModuleScript")]
    assert len(scripts) == 5, f"Expected 5 scripts/modules, found {len(scripts)}"
    sources = [n.text or "" for i in scripts for n in i.iter() if n.attrib.get("name") == "Source"]
    assert any("Economy.loseHaul" in source and "PlayerAdded" in source for source in sources)
    assert any("LET'S GO SALVAGING" in source and "OnClientEvent" in source for source in sources)
    assert len([i for i in items if i.attrib["class"] == "SpawnLocation"]) == 1
    names = [n.text for n in tree.iter("string") if n.attrib.get("name") == "Name"]
    for required in ("World", "Workshop", "SafeZone", "Bank", "Upgrade", "TheWreck", "Lighthouse", "TideRuins"):
        assert required in names, f"Missing {required}"
    assert sum(name.startswith(("Shore", "Wild")) for name in names if name) == 28
    assert not any(i.attrib["class"] in ("MeshPart", "Sound") for i in items)
    print(f"PASS: place contains {len(items)} instances, 5 source scripts/modules, spawn and 28 loot markers")


def main():
    DIST.mkdir(exist_ok=True)
    source_files = sorted((ROOT / "src").rglob("*.luau"))
    run("luau", "tests/rules.luau")
    run("luau-analyze", "src/shared/Config.luau", "src/shared/Economy.luau", "src/shared/Rounds.luau", "tests/rules.luau")
    run("luau-compile", "--null", *source_files)
    run("stylua", "--syntax", "Luau", "--check", "src", "tests")
    build_world()
    for extension in ("rbxl", "rbxlx"):
        run("rojo", "build", "default.project.json", "--output", DIST / f"Storm-Salvagers.{extension}")
    assert (DIST / "Storm-Salvagers.rbxl").read_bytes().startswith(b"<roblox!")
    validate_place(DIST / "Storm-Salvagers.rbxlx")
    instructions = """STORM SALVAGERS - FIRST PLAYABLE PROTOTYPE

1. Extract this ZIP to a folder on your Windows computer.
2. In Roblox Studio, use File > Open from File (or Ctrl+O).
3. Select Storm-Salvagers.rbxl.
4. Press Play (F5), not Run. Play spawns your character and HUD.
5. Click LET'S GO SALVAGING, leave the workshop, and follow the trail.
6. Hold E near treasure. Return to the mint bank counter and hold E.
7. Use banked coins at the gold upgrade workbench.
8. At 0:00, stay in the workshop or lose your unbanked haul.

Movement: WASD. Jump: Space. Camera: hold right mouse and move.
Collection: click COLLECTION in the top-right card.
Stop the test with Shift+F5.

Progress is session-only and resets when you stop or leave.
This prototype has no paid purchases, external assets, or cloud saves.

Validated in cloud: game rules, shared type checks, all-source compilation,
formatting, generated place structure, and Rojo builds.
Interactive Roblox-engine behavior still needs your Studio playtest.

For an error: open View > Output, copy the first red message, and send it
back to the chat with what you were doing. A screenshot helps with layout.

Keep this local until playtesting is complete. Publishing publicly is a
separate step; opening this file does not publish anything.
"""
    (DIST / "START-HERE.txt").write_text(instructions, encoding="utf-8")
    with zipfile.ZipFile(DIST / "Storm-Salvagers-Playtest.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        archive.write(DIST / "Storm-Salvagers.rbxl", "Storm-Salvagers.rbxl")
        archive.writestr("START-HERE.txt", instructions)
    files = [ROOT / name for name in ("README.md", "default.project.json", ".gitignore", "assets/World.rbxmx", "docs/STUDIO-PLAYTEST.md")]
    for folder, pattern in (("src", "*.luau"), ("tests", "*.luau"), ("scripts", "*.py")):
        files.extend((ROOT / folder).rglob(pattern))
    with zipfile.ZipFile(DIST / "Storm-Salvagers-Source.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(files):
            archive.write(path, path.relative_to(ROOT))
    print("Built Studio places, Playtest.zip and Source.zip in", DIST)


if __name__ == "__main__":
    main()
