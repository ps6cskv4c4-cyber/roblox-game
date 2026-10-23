"""Generate a self-contained, editable island using Roblox primitives only."""
from pathlib import Path
import math
import random
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
RNG = random.Random(9407)
MATERIAL = {"smooth": 272, "neon": 288, "wood": 512, "planks": 528,
            "slate": 800, "metal": 1088, "grass": 1280, "sand": 1296}
COLORS = {"ocean": (31, 132, 155), "sand": (226, 198, 139), "grass": (103, 156, 106),
          "wood": (101, 70, 55), "dark": (27, 50, 59), "mint": (98, 237, 199),
          "gold": (255, 199, 97), "rock": (98, 120, 126)}
NEXT_ID = 0


def prop(node, kind, name, value):
    entry = ET.SubElement(node.find("Properties"), kind, name=name)
    if kind in ("Vector3", "Color3"):
        keys = ("X", "Y", "Z") if kind == "Vector3" else ("R", "G", "B")
        for key, component in zip(keys, value):
            ET.SubElement(entry, key).text = str(component)
    elif kind == "Vector2":
        for key, component in zip(("X", "Y"), value):
            ET.SubElement(entry, key).text = str(component)
    elif kind == "UDim2":
        for key, component in zip(("XS", "XO", "YS", "YO"), value):
            ET.SubElement(entry, key).text = str(component)
    elif kind == "CoordinateFrame":
        x, y, z, yaw, roll = value
        cy, sy, cr, sr = math.cos(yaw), math.sin(yaw), math.cos(roll), math.sin(roll)
        matrix = (cy * cr, -cy * sr, sy, sr, cr, 0, -sy * cr, sy * sr, cy)
        for key, component in zip(("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"), (x, y, z, *matrix)):
            ET.SubElement(entry, key).text = str(round(component, 8))
    else:
        entry.text = str(value).lower() if isinstance(value, bool) else str(value)
    return entry


def instance(parent, cls, name):
    global NEXT_ID
    NEXT_ID += 1
    node = ET.SubElement(parent, "Item", {"class": cls, "referent": f"RBX{NEXT_ID}"})
    ET.SubElement(node, "Properties")
    prop(node, "string", "Name", name)
    return node


def color(node, name, rgb):
    prop(node, "Color3", name, tuple(c / 255 for c in rgb))


def part(parent, name, position, size, rgb, material="smooth", shape=1, yaw=0, roll=0,
         collide=True, transparency=0, cls="Part"):
    node = instance(parent, cls, name)
    prop(node, "bool", "Anchored", True)
    prop(node, "bool", "CanCollide", collide)
    prop(node, "bool", "CanTouch", False)
    prop(node, "bool", "CanQuery", collide)
    prop(node, "Vector3", "Size", size)
    prop(node, "CoordinateFrame", "CFrame", (*position, yaw, roll))
    color(node, "Color", rgb)
    prop(node, "token", "Material", MATERIAL[material])
    prop(node, "float", "Transparency", transparency)
    prop(node, "token", "TopSurface", 0)
    prop(node, "token", "BottomSurface", 0)
    if cls == "Part":
        prop(node, "token", "shape", shape)
    return node


def sign(parent, name, position, size, text, ink=None, background=None, yaw=0):
    board = part(parent, name, position, size, background or COLORS["dark"], "wood", yaw=yaw)
    gui = instance(board, "SurfaceGui", "Lettering")
    prop(gui, "token", "Face", 5)
    prop(gui, "Vector2", "CanvasSize", (1000, 240))
    prop(gui, "float", "LightInfluence", 0)
    label = instance(gui, "TextLabel", "Text")
    prop(label, "UDim2", "Size", (1, 0, 1, 0))
    prop(label, "float", "BackgroundTransparency", 1)
    prop(label, "string", "Text", text)
    color(label, "TextColor3", ink or COLORS["mint"])
    prop(label, "bool", "TextScaled", True)
    prop(label, "bool", "TextWrapped", True)
    prop(label, "token", "Font", 20)
    return board


def light(parent, rgb, brightness=1, radius=20):
    lamp = instance(parent, "PointLight", "Glow")
    color(lamp, "Color", rgb)
    prop(lamp, "float", "Brightness", brightness)
    prop(lamp, "float", "Range", radius)


def build():
    global NEXT_ID
    NEXT_ID = 0
    RNG.seed(9407)
    doc = ET.Element("roblox", version="4")
    world = instance(doc, "Model", "World")
    terrain = instance(world, "Folder", "Landscape")
    part(terrain, "Ocean", (0, -4.5, 0), (1600, 1, 1600), COLORS["ocean"], collide=False)
    part(terrain, "SandShelf", (0, -4, -12), (8, 224, 224), COLORS["sand"], "sand", 2, roll=math.pi / 2)
    part(terrain, "GrassPlateau", (0, -.4, -15), (2.4, 202, 202), COLORS["grass"], "grass", 2, roll=math.pi / 2)
    # Flat, walkable routes with distinct destination colors.
    part(terrain, "MainTrail", (0, .86, -10), (15, .14, 104), (199, 180, 128), "sand")
    part(terrain, "WreckTrail", (-28, .87, -38), (12, .15, 74), (199, 180, 128), "sand", yaw=.85)
    part(terrain, "LighthouseTrail", (35, .88, -17), (12, .15, 84), (199, 180, 128), "sand", yaw=-1.12)

    workshop = instance(world, "Model", "Workshop")
    part(workshop, "Foundation", (0, 1.7, 66), (88, 5, 62), COLORS["wood"], "planks")
    part(workshop, "Floor", (0, 4.35, 66), (88, .3, 62), (151, 113, 79), "planks")
    for x in (-42, 42):
        for z in (37, 94):
            part(workshop, "Support", (x, 14, z), (2, 20, 2), COLORS["wood"], "wood")
        part(workshop, "SideRail", (x, 6, 67), (1, 3, 54), COLORS["wood"], "planks")
    part(workshop, "BackWall", (0, 11, 95), (88, 14, 1.5), COLORS["wood"], "planks")
    part(workshop, "Roof", (0, 25, 66), (94, 2, 67), COLORS["dark"], "metal")
    for x in (-44, 44):
        part(workshop, "RoofTrim", (x, 24, 66), (1, 1, 66), COLORS["mint"], "neon")
    for step in range(5):
        part(workshop, "EntryStep", (0, .8 + step * .8 / 2, 27 + step * 2), (29, .8 + step * .8, 2.1), COLORS["wood"], "planks")
    sign(workshop, "WorkshopSign", (0, 21, 35), (57, 6, 1), "STORM SALVAGERS")
    sign(workshop, "SafeSign", (0, 15, 35), (34, 3.2, .6), "WORKSHOP / SAFE IN THE STORM", (255, 231, 173))
    spawn = part(workshop, "Spawn", (0, 4.75, 69), (9, .5, 9), COLORS["mint"], "neon", cls="SpawnLocation")
    prop(spawn, "bool", "Neutral", True)
    prop(spawn, "int", "Duration", 0)
    prop(spawn, "bool", "AllowTeamChangeOnTouch", False)

    interactions = instance(world, "Folder", "Interactables")
    bank = part(interactions, "Bank", (-25, 6.5, 57), (12, 4, 7), COLORS["dark"], "metal")
    part(workshop, "BankGlow", (-25, 8.6, 57), (12.5, .2, 7.5), COLORS["mint"], "neon")
    sign(workshop, "BankSign", (-25, 13, 61), (21, 4, .5), "BANK YOUR HAUL", COLORS["mint"])
    light(bank, COLORS["mint"], 1.1, 24)
    upgrade = part(interactions, "Upgrade", (25, 6.5, 57), (12, 4, 7), (126, 87, 59), "planks")
    part(workshop, "UpgradeGlow", (25, 8.6, 57), (12.5, .2, 7.5), COLORS["gold"], "neon")
    sign(workshop, "UpgradeSign", (25, 13, 61), (21, 4, .5), "UPGRADE YOUR PACK", COLORS["gold"])
    light(upgrade, COLORS["gold"], .8, 24)
    weapons = part(interactions, "Weapons", (0, 6.5, 54), (12, 4, 6), COLORS["dark"], "metal")
    part(workshop, "ArmoryGlow", (0, 8.6, 54), (12.5, .2, 6.5), (117, 190, 255), "neon")
    sign(workshop, "ArmorySign", (0, 12, 59), (20, 3.5, .4), "ARMORY / BLASTER 120", (117, 190, 255))
    light(weapons, (117, 190, 255), .8, 20)
    sign(workshop, "CollectionSign", (0, 14, 93.7), (30, 4, .4), "THE CREW'S RARE FINDS", COLORS["gold"])
    displays = instance(world, "Folder", "DisplaySlots")
    for i, x in enumerate((-12, 0, 12)):
        part(workshop, "DisplayPlinth", (x, 6, 87), (7, 3, 7), COLORS["dark"], "metal")
        part(displays, f"Slot{i+1}", (x, 9, 87), (1, 1, 1), COLORS["mint"], collide=False, transparency=1)
    part(world, "SafeZone", (0, 14, 66), (88, 32, 62), COLORS["mint"], collide=False, transparency=1)

    landmarks = instance(world, "Folder", "Landmarks")
    wreck = instance(landmarks, "Model", "TheWreck")
    part(wreck, "Hull", (-60, 3.5, -50), (25, 5, 41), (112, 72, 50), "planks", yaw=-.35)
    part(wreck, "Deck", (-60, 6.1, -50), (22, .4, 38), (161, 118, 74), "planks", yaw=-.35)
    part(wreck, "Mast", (-60, 19, -50), (1.5, 29, 1.5), COLORS["wood"], "wood")
    part(wreck, "TornSail", (-58, 23, -50), (13, 13, .3), (225, 212, 178), "smooth", yaw=-.35)
    for i in range(6):
        part(wreck, "BoardingStep", (-60, 1.1 + i * .8 / 2, -23-i*1.8), (10, 1.2+i*.8, 2), COLORS["wood"], "planks")
    sign(wreck, "WreckSign", (-50, 5, -18), (17, 4, 1), "THE WRECK", COLORS["gold"], yaw=math.pi)

    tower = instance(landmarks, "Model", "Lighthouse")
    part(tower, "Tower", (72, 15, -27), (26, 12, 12), (229, 220, 194), "smooth", 2, roll=math.pi/2)
    part(tower, "Stripe", (72, 18, -27), (5, 12.3, 12.3), (199, 99, 77), "smooth", 2, roll=math.pi/2)
    part(tower, "Cap", (72, 30, -27), (2, 18, 18), COLORS["dark"], "metal", 2, roll=math.pi/2)
    lantern = part(tower, "Beacon", (72, 33, -27), (5, 5, 5), COLORS["gold"], "neon", 0)
    light(lantern, COLORS["gold"], 2, 45)
    part(tower, "LanternRoof", (72, 36.5, -27), (1.5, 11, 11), COLORS["dark"], "metal", 2, roll=math.pi/2)
    sign(tower, "LighthouseSign", (57, 4.7, -11), (19, 4, 1), "BEACON POINT", COLORS["gold"], yaw=math.pi)

    ruins = instance(landmarks, "Model", "TideRuins")
    for x in (-18, 18):
        part(ruins, "Column", (x, 9, -79), (5, 17, 5), COLORS["rock"], "slate")
    part(ruins, "Lintel", (0, 17, -79), (42, 4, 6), COLORS["rock"], "slate")
    part(ruins, "Altar", (0, 2.6, -84), (14, 4, 10), COLORS["rock"], "slate")
    sign(ruins, "RuinsSign", (-30, 5, -59), (20, 4, 1), "TIDE RUINS", (199, 170, 255), yaw=math.pi)

    foliage = instance(world, "Folder", "Foliage")
    tree_positions = [(-82,7),(-66,19),(-40,12),(-27,-17),(28,9),(46,23),(88,-2),
                      (-84,-32),(-40,-77),(39,-72),(60,-59),(-16,-46),(20,-39),(78,18)]
    for x,z in tree_positions:
        height=RNG.uniform(13,19)
        part(foliage,"Trunk",(x,height/2+.8,z),(2.3,height,2.3),(114,85,62),"wood")
        for layer in range(3):
            size=16-layer*3
            part(foliage,"Canopy",(x,height-3+layer*3,z),(size,5,size),(52+layer*9,113+layer*12,88+layer*5),"grass",yaw=layer*.5)
    for _ in range(32):
        angle=RNG.uniform(0,math.tau)
        radius=RNG.uniform(94,107)
        x,z=math.cos(angle)*radius,-12+math.sin(angle)*radius
        if (z>30 and abs(x)<47) or (x>86 and -6<z<22) or (x<-86 and 5<z<35):
            continue
        part(foliage,"CoastalRock",(x,0,z),(RNG.uniform(5,11),RNG.uniform(4,9),RNG.uniform(5,10)),COLORS["rock"],"slate",yaw=angle)

    # Markers define spawn locations without any external map dependencies.
    markers=instance(world,"Folder","TreasureSpawns")
    points=[(-16,23),(14,20),(-30,7),(29,3),(-8,-4),(13,-17),(-45,-7),(45,-5),
            (-32,-32),(28,-36),(-64,-14),(62,-4),(5,-41),(-16,-38),(-47,18),(43,20)]
    for i,(x,z) in enumerate(points):
        part(markers,f"Shore{i+1:02}",(x,2.8,z),(1,1,1),COLORS["mint"],collide=False,transparency=1)
    far=[(-62,-50,8),(-54,-57,8),(-66,-42,8),(-76,-68,2.8),(0,-84,6),(12,-75,2.8),
         (-17,-86,2.8),(27,-76,2.8),(58,-39,2.8),(83,-39,2.8),(62,-59,2.8),(0,-66,2.8)]
    for i,(x,z,y) in enumerate(far):
        part(markers,f"Wild{i+1:02}",(x,y,z),(1,1,1),COLORS["gold"],collide=False,transparency=1)

    # A second island gives PvP a visible, avoidable entrance and fixed bounds.
    arena = instance(landmarks, "Model", "RivalIsland")
    part(arena, "ArenaSand", (165, -3, 8), (7, 111, 111), COLORS["sand"], "sand", 2, roll=math.pi/2)
    part(arena, "ArenaFloor", (165, 1.1, 8), (80, .5, 84), (75, 94, 105), "slate")
    part(arena, "ArenaBridge", (110, 1.1, 8), (32, .5, 12), (153, 113, 77), "planks")
    for z in (1, 15):
        part(arena, "BridgeRail", (110, 3, z), (32, 2, .7), COLORS["wood"], "wood")
    for x in (125, 205):
        part(arena, "ArenaBoundary", (x, 1.55, 8), (.6, .35, 84), (255, 100, 126), "neon", collide=False)
    for z in (-34, 50):
        part(arena, "ArenaBoundary", (165, 1.55, z), (80, .35, .6), (255, 100, 126), "neon", collide=False)
    for z in (-7, 23):
        part(arena, "GatePost", (124, 7, z), (2, 13, 2), COLORS["dark"], "metal")
    sign(arena, "PvPGate", (124, 15, 8), (34, 6, 1), "PVP ARENA\nCROSS THE RED LINE TO FIGHT", (255, 137, 154), yaw=math.pi/2)
    sign(arena, "ArenaExit", (128, 10, 8), (23, 4, .5), "EXIT TO PEACEFUL ISLAND", COLORS["mint"], yaw=-math.pi/2)
    part(world, "PvPZone", (165, 14, 8), (80, 32, 84), (255, 90, 120), collide=False, transparency=1)
    for x,z in ((144,-13),(180,-12),(146,29),(188,29),(165,9)):
        part(arena, "ArenaCover", (x, 4.2, z), (8, 6, 7), COLORS["dark"], "metal")
        part(arena, "CoverTrim", (x, 7.3, z), (8.2, .2, 7.2), (255, 122, 145), "neon", collide=False)
    for i,(x,z) in enumerate(((140,8),(191,8),(165,-20),(165,36))):
        part(markers,f"Arena{i+1:02}",(x,3.2,z),(1,1,1),(255,100,126),collide=False,transparency=1)

    docks = instance(landmarks, "Model", "ScrapDocks")
    part(docks, "DockDeck", (-110, 1.1, 20), (50, 2, 34), (145, 105, 72), "planks")
    part(docks, "DockTrail", (-70, .91, 20), (49, .2, 10), COLORS["sand"], "sand")
    for x in (-130,-112,-94):
        for z in (5,35):
            part(docks, "DockPost", (x, -.3, z), (2, 10, 2), COLORS["wood"], "wood")
    for x,z in ((-126,11),(-128,27),(-105,8)):
        part(docks, "CargoCrate", (x, 4.6, z), (6, 5, 6), (137, 96, 64), "planks")
        part(docks, "CrateBand", (x, 4.6, z), (6.15, .7, 6.15), COLORS["dark"], "metal")
    sign(docks, "DockSign", (-79, 5.5, 29), (22, 4, .5), "SCRAP DOCKS", COLORS["gold"], yaw=math.pi)
    for i,(x,z) in enumerate(((-116,26),(-111,16),(-98,29))):
        part(markers,f"Dock{i+1:02}",(x,4,z),(1,1,1),COLORS["gold"],collide=False,transparency=1)

    enemy_markers = instance(world, "Folder", "EnemySpawns")
    for name,x,z in (("Scout01",-42,-34),("Scout02",46,-36),("Scout03",-77,4),("Brute01",-7,-68)):
        part(enemy_markers,name,(x,4.8,z),(1,1,1),(255,170,95),collide=False,transparency=1)
        part(landmarks,"SentinelCamp",(x,.94,z),(.12,20,20),(226,167,106),"sand",2,roll=math.pi/2,collide=False,transparency=.6)
    for i,(x,z) in enumerate(((-40,9),(48,-49))):
        box = part(interactions,f"Medkit{i+1}",(x,2.6,z),(5,3.5,4),(225,230,212),"metal")
        part(landmarks,"MedicalCrossVertical",(x,4.41,z),(.7,.12,2.6),COLORS["mint"],"neon",collide=False)
        part(landmarks,"MedicalCrossHorizontal",(x,4.42,z),(2.6,.12,.7),COLORS["mint"],"neon",collide=False)
        light(box,COLORS["mint"],.5,13)
    for x,z in ((-30,-53),(35,-60),(52,-20),(-51,5),(24,-88)):
        part(landmarks,"SalvageCrate",(x,2.8,z),(4,4,4),(123,104,76),"planks",yaw=.2)
        part(landmarks,"ScrapPlate",(x+3,1.2,z-2),(4,.6,3),COLORS["rock"],"metal",yaw=.6)
    sign(landmarks,"ExploreSign",(0,12,17),(27,5,.7),"WEST: DOCKS / NORTH: SENTINELS\nEAST: OPTIONAL PVP",COLORS["gold"],yaw=math.pi)
    for z in (17,7,-3):
        part(world,"TrailLight",(-9,1.1,z),(1.3,.3,2.5),COLORS["mint"],"neon",collide=False)
        part(world,"TrailLight",(9,1.1,z),(1.3,.3,2.5),COLORS["mint"],"neon",collide=False)
    (ROOT/"assets").mkdir(exist_ok=True)
    ET.indent(doc)
    ET.ElementTree(doc).write(ROOT/"assets/World.rbxmx",encoding="utf-8",xml_declaration=True)
    print(f"Generated world with {NEXT_ID} instances")


if __name__ == "__main__":
    build()
