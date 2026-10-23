--!strict
local Config = require("../src/shared/Config")
local Economy = require("../src/shared/Economy")
local Rounds = require("../src/shared/Rounds")
local passed = 0

local function test(name: string, body: () -> ())
	body()
	passed += 1
	print("PASS: " .. name)
end

test("pickup capacity rejects overflow without consuming an item", function()
	local state = Economy.new()
	assert(Economy.collect(state, "Idol", Config))
	assert(Economy.collect(state, "StormHeart", Config))
	assert(not Economy.collect(state, "SeaGlass", Config))
	local weight, value, count = Economy.summary(state, Config)
	assert(weight == 12 and value == 250 and count == 2)
	assert(Economy.speed(state, Config) == Config.MinimumSpeed)
end)

test("unknown item cannot enter inventory", function()
	local state = Economy.new()
	assert(not Economy.collect(state, "FakeItem", Config))
	assert(#state.Inventory == 0)
end)

test("banking pays exactly once and records only unique discoveries", function()
	local state = Economy.new()
	assert(Economy.collect(state, "Prism", Config))
	assert(Economy.collect(state, "Prism", Config))
	local coins, count, discoveries = Economy.bank(state, Config)
	assert(coins == 150 and count == 2 and discoveries == 1)
	assert(state.Coins == 150 and state.BestHaul == 150 and state.Collection.Prism)
	local duplicate = Economy.bank(state, Config)
	assert(duplicate == 0 and state.Coins == 150 and #state.Inventory == 0)
end)

test("storm loss preserves banked coins, upgrades, collection and best haul", function()
	local state = Economy.new()
	assert(Economy.collect(state, "StormHeart", Config))
	Economy.bank(state, Config)
	assert(Economy.upgrade(state, Config))
	assert(Economy.collect(state, "Idol", Config))
	local value, count = Economy.loseHaul(state, Config)
	assert(value == 100 and count == 1 and #state.Inventory == 0)
	assert(state.Coins == 70 and state.Level == 2 and state.Collection.StormHeart)
	assert(not state.Collection.Idol and state.BestHaul == 150)
	assert(Economy.speed(state, Config) == Config.BaseSpeed)
end)

test("upgrade rejects insufficient funds and caps at the last pack", function()
	local state = Economy.new()
	assert(not Economy.upgrade(state, Config))
	assert(state.Coins == 0 and state.Level == 1)
	state.Coins = 1000
	assert(Economy.upgrade(state, Config))
	assert(Economy.upgrade(state, Config))
	assert(Economy.upgrade(state, Config))
	assert(state.Level == 4 and state.Coins == 270)
	assert(not Economy.upgrade(state, Config))
	assert(state.Coins == 270)
end)

test("every treasure can be collected and contributes its configured value", function()
	local state = Economy.new()
	local expected = 0
	for id, item in Config.Items do
		assert(item.Weight <= Config.Upgrades[1].Capacity)
		assert(Economy.collect(state, id, Config))
		Economy.bank(state, Config)
		expected += item.Value
	end
	assert(state.Coins == expected)
	local unique = 0
	for _ in state.Collection do
		unique += 1
	end
	local expectedCount = 0
	for _ in Config.Items do
		expectedCount += 1
	end
	assert(unique == expectedCount)
end)

test("round boundaries move from collecting through storm and recovery", function()
	local origin = 1000
	assert(Rounds.at(origin, origin, Config).Phase == "Scavenge")
	local warning = Rounds.at(origin + 120, origin, Config)
	assert(warning.Phase == "Scavenge" and warning.Remaining == 30)
	local storm = Rounds.at(origin + 150, origin, Config)
	assert(storm.Phase == "Storm" and storm.Round == 1 and storm.Remaining == 15)
	assert(Rounds.at(origin + 165, origin, Config).Phase == "Calm")
	local nextRound = Rounds.at(origin + 175, origin, Config)
	assert(nextRound.Phase == "Scavenge" and nextRound.Round == 2 and nextRound.Remaining == 150)
	assert(Rounds.at(origin + 175 * 100, origin, Config).Round == 101)
end)

print(string.format("%d rule tests passed", passed))
