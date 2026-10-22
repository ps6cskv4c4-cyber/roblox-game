--!strict
export type State = {
	Coins: number,
	Level: number,
	Inventory: { string },
	Collection: { [string]: boolean },
	BestHaul: number,
}
export type Item = { Name: string, Value: number, Weight: number, Rarity: string, Color: { number } }
export type Rules = {
	Items: { [string]: Item },
	Upgrades: { { Name: string, Capacity: number, Cost: number } },
	BaseSpeed: number,
	MinimumSpeed: number,
}

local Economy = {}

function Economy.new(): State
	return { Coins = 0, Level = 1, Inventory = {}, Collection = {}, BestHaul = 0 }
end

function Economy.summary(state: State, rules: Rules): (number, number, number)
	local weight, value = 0, 0
	for _, id in state.Inventory do
		local item = rules.Items[id]
		weight += item.Weight
		value += item.Value
	end
	return weight, value, #state.Inventory
end

function Economy.collect(state: State, id: string, rules: Rules): (boolean, string)
	local item = rules.Items[id]
	if not item then
		return false, "Unknown treasure."
	end
	local weight = Economy.summary(state, rules)
	if weight + item.Weight > rules.Upgrades[state.Level].Capacity then
		return false, "Bag full! Bank your haul at the workshop."
	end
	table.insert(state.Inventory, id)
	return true, item.Name
end

function Economy.bank(state: State, rules: Rules): (number, number, number)
	local _, value, count = Economy.summary(state, rules)
	local discoveries = 0
	for _, id in state.Inventory do
		if not state.Collection[id] then
			state.Collection[id] = true
			discoveries += 1
		end
	end
	state.Coins += value
	state.BestHaul = math.max(state.BestHaul, value)
	table.clear(state.Inventory)
	return value, count, discoveries
end

function Economy.loseHaul(state: State, rules: Rules): (number, number)
	local _, value, count = Economy.summary(state, rules)
	table.clear(state.Inventory)
	return value, count
end

function Economy.upgrade(state: State, rules: Rules): (boolean, string)
	local nextPack = rules.Upgrades[state.Level + 1]
	if not nextPack then
		return false, "Your pack is fully upgraded!"
	end
	if state.Coins < nextPack.Cost then
		return false, string.format("Need %d coins for %s.", nextPack.Cost, nextPack.Name)
	end
	state.Coins -= nextPack.Cost
	state.Level += 1
	return true, nextPack.Name
end

function Economy.speed(state: State, rules: Rules): number
	local weight = Economy.summary(state, rules)
	local fullness = math.clamp(weight / rules.Upgrades[state.Level].Capacity, 0, 1)
	return rules.BaseSpeed - (rules.BaseSpeed - rules.MinimumSpeed) * fullness
end

return Economy
