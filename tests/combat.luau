--!strict
local Rules = require("../src/shared/CombatRules")
local Weapons = require("../src/shared/CombatConfig")
local Economy = require("../src/shared/Economy")
local Catalog = require("../src/shared/Config")
local passed = 0
local function test(name: string, body: () -> ())
	body()
	passed += 1
	print("PASS: " .. name)
end
local function player(arena: boolean): Rules.Actor
	return { Kind = "Player", Alive = true, Safe = false, Arena = arena, Protected = false }
end
local function enemy(): Rules.Actor
	return { Kind = "Enemy", Alive = true, Safe = false, Arena = false, Protected = false }
end

test("PvP requires BOTH players inside the arena", function()
	assert(Rules.canDamage(player(true), player(true), "Scavenge"))
	assert(not Rules.canDamage(player(false), player(true), "Scavenge"))
	assert(not Rules.canDamage(player(true), player(false), "Scavenge"))
	assert(not Rules.canDamage(player(false), player(false), "Scavenge"))
end)
test("workshop, spawn immunity, death and storm override combat", function()
	for _, field in { "Safe", "Protected" } do
		local protected = player(true)
		if field == "Safe" then
			protected.Safe = true
		else
			protected.Protected = true
		end
		assert(not Rules.canDamage(protected, player(true), "Scavenge"))
		assert(not Rules.canDamage(player(true), protected, "Scavenge"))
		assert(not Rules.canDamage(enemy(), protected, "Scavenge"))
	end
	local dead = player(true)
	dead.Alive = false
	assert(not Rules.canDamage(dead, enemy(), "Scavenge"))
	assert(not Rules.canDamage(enemy(), dead, "Scavenge"))
	for _, phase in { "Storm", "Calm", "" } do
		assert(not Rules.canDamage(player(true), player(true), phase))
		assert(not Rules.canDamage(enemy(), player(false), phase))
	end
end)
test("PvE works on the mainland; enemies cannot farm one another", function()
	assert(Rules.canDamage(player(false), enemy(), "Scavenge"))
	assert(Rules.canDamage(enemy(), player(false), "Scavenge"))
	assert(not Rules.canDamage(enemy(), enemy(), "Scavenge"))
end)
test("zone boundaries include the edge and reject above and below", function()
	assert(Rules.inside(40, 16, 42, 80, 32, 84))
	assert(not Rules.inside(40.01, 0, 0, 80, 32, 84))
	assert(not Rules.inside(0, 16.01, 0, 80, 32, 84))
	assert(not Rules.inside(0, -16.01, 0, 80, 32, 84))
end)
test("weapon cooldowns and invalid aim data are rejected", function()
	assert(not Rules.ready(1.4, 1, Weapons.Weapons.Blaster.Cooldown))
	assert(Rules.ready(1.5, 1, Weapons.Weapons.Blaster.Cooldown))
	assert(not Rules.ready(0 / 0, 1, 0.4))
	assert(not Rules.ready(math.huge, 1, 0.4))
	assert(Rules.finite(-100, 4, 200))
	assert(not Rules.finite(0 / 0, 0, 0))
	assert(not Rules.finite(0, math.huge, 0))
	assert(not Rules.finite(0, 0, 1e20))
end)
test("armory cannot overspend, charge twice for a gun or exceed tier three", function()
	local state = Economy.new()
	assert(not Economy.armory(state, Weapons.BlasterCost, Weapons.UpgradeCosts))
	assert(not state.HasBlaster and state.Coins == 0)
	state.Coins = 1000
	assert(Economy.armory(state, Weapons.BlasterCost, Weapons.UpgradeCosts))
	assert(state.HasBlaster and state.Coins == 880 and state.WeaponLevel == 1)
	assert(Economy.armory(state, Weapons.BlasterCost, Weapons.UpgradeCosts))
	assert(state.Coins == 720 and state.WeaponLevel == 2)
	assert(Economy.armory(state, Weapons.BlasterCost, Weapons.UpgradeCosts))
	assert(state.Coins == 370 and state.WeaponLevel == 3)
	assert(not Economy.armory(state, Weapons.BlasterCost, Weapons.UpgradeCosts))
	assert(state.Coins == 370)
	assert(Rules.damage(26, 1) == 26 and Rules.damage(26, 3) == 39)
	assert(Rules.damage(26, 999) == 39)
	assert(Economy.collect(state, "CircuitCore", Catalog))
	Economy.loseHaul(state, Catalog)
	assert(state.HasBlaster and state.WeaponLevel == 3 and state.Coins == 370)
end)
test("melee rejects distant, rear and overlapping targets", function()
	assert(Rules.meleeReach(8, 1, 8))
	assert(not Rules.meleeReach(8.01, 1, 8))
	assert(not Rules.meleeReach(3, -1, 8))
	assert(not Rules.meleeReach(0, 1, 8))
	assert(not Rules.meleeReach(0 / 0, 1, 8))
end)
test("every enemy drops usable loot with positive combat settings", function()
	for _, spec in Weapons.Enemies do
		assert(spec.Health > 0 and spec.Damage > 0 and spec.Cooldown > 0)
		assert(spec.Speed > 0 and spec.Leash >= spec.Aggro)
		local state = Economy.new()
		assert(Economy.collect(state, spec.Drop, Catalog))
		local coins = Economy.bank(state, Catalog)
		assert(coins > 0 and state.Collection[spec.Drop])
	end
end)
print(string.format("%d combat tests passed", passed))
