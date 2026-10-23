--!strict
type Weapon = { Name: string, Damage: number, Cooldown: number, Range: number, Ranged: boolean }
type Enemy = {
	Name: string,
	Health: number,
	Damage: number,
	Cooldown: number,
	Speed: number,
	Aggro: number,
	Leash: number,
	Drop: string,
}
local Config: {
	Weapons: { [string]: Weapon },
	Enemies: { [string]: Enemy },
	BlasterCost: number,
	UpgradeCosts: { number },
	SpawnProtection: number,
	EnemyRespawn: number,
} =
	{
		Weapons = {
			Cutter = { Name = "Salvage Cutter", Damage = 26, Cooldown = 0.65, Range = 8, Ranged = false },
			Blaster = { Name = "Pulse Blaster", Damage = 18, Cooldown = 0.45, Range = 110, Ranged = true },
		},
		Enemies = {
			Scout = {
				Name = "Scrap Sentinel",
				Health = 78,
				Damage = 9,
				Cooldown = 1.7,
				Speed = 12,
				Aggro = 34,
				Leash = 40,
				Drop = "CircuitCore",
			},
			Brute = {
				Name = "Ruin Guardian",
				Health = 170,
				Damage = 16,
				Cooldown = 2.3,
				Speed = 10,
				Aggro = 32,
				Leash = 35,
				Drop = "AncientBattery",
			},
		},
		BlasterCost = 120,
		UpgradeCosts = { 160, 350 },
		SpawnProtection = 4,
		EnemyRespawn = 28,
	}
return Config
