--!strict
-- Plain data so the rules can also run in the standalone Luau test runner.
type CatalogItem = { Name: string, Value: number, Weight: number, Rarity: string, Color: { number } }
type ConfigData = {
	ScavengeSeconds: number,
	StormSeconds: number,
	CalmSeconds: number,
	WarningSeconds: number,
	BaseSpeed: number,
	MinimumSpeed: number,
	PickupDistance: number,
	RespawnSeconds: number,
	Upgrades: { { Name: string, Capacity: number, Cost: number } },
	Items: { [string]: CatalogItem },
	ShorePool: { string },
	WildPool: { string },
}
local Config: ConfigData = {
	ScavengeSeconds = 150,
	StormSeconds = 15,
	CalmSeconds = 10,
	WarningSeconds = 30,
	BaseSpeed = 22,
	MinimumSpeed = 12,
	PickupDistance = 13,
	RespawnSeconds = 22,
	Upgrades = {
		{ Name = "Canvas bag", Capacity = 12, Cost = 0 },
		{ Name = "Field pack", Capacity = 18, Cost = 80 },
		{ Name = "Salvage rig", Capacity = 25, Cost = 200 },
		{ Name = "Storm hauler", Capacity = 34, Cost = 450 },
	},
	Items = {
		Driftwood = { Name = "Driftwood bundle", Value = 8, Weight = 2, Rarity = "Common", Color = { 174, 121, 76 } },
		SeaGlass = { Name = "Sea glass", Value = 12, Weight = 1, Rarity = "Common", Color = { 100, 216, 182 } },
		OldGear = { Name = "Old brass gear", Value = 18, Weight = 3, Rarity = "Common", Color = { 210, 162, 83 } },
		Compass = { Name = "Lost compass", Value = 32, Weight = 3, Rarity = "Uncommon", Color = { 101, 186, 251 } },
		Pearl = { Name = "Moon pearl", Value = 40, Weight = 2, Rarity = "Uncommon", Color = { 194, 206, 255 } },
		Prism = { Name = "Tide prism", Value = 75, Weight = 4, Rarity = "Rare", Color = { 177, 119, 255 } },
		Idol = { Name = "Sunken idol", Value = 100, Weight = 6, Rarity = "Rare", Color = { 255, 199, 92 } },
		StormHeart = { Name = "Storm heart", Value = 150, Weight = 6, Rarity = "Legendary", Color = { 255, 113, 135 } },
	},
	ShorePool = { "Driftwood", "SeaGlass", "OldGear", "SeaGlass", "Compass", "Pearl" },
	WildPool = { "OldGear", "Compass", "Pearl", "Prism", "Prism", "Idol", "StormHeart" },
}

return Config
