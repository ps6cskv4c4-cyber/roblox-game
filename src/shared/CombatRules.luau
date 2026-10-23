--!strict
-- Server policy shared with the offline tests; no engine or client input here.
export type Actor = { Kind: string, Alive: boolean, Safe: boolean, Arena: boolean, Protected: boolean }
local Rules = {}

function Rules.inside(x: number, y: number, z: number, sx: number, sy: number, sz: number): boolean
	return math.abs(x) <= sx / 2 and math.abs(y) <= sy / 2 and math.abs(z) <= sz / 2
end

function Rules.canDamage(attacker: Actor, target: Actor, phase: string): boolean
	if phase ~= "Scavenge" or not attacker.Alive or not target.Alive then
		return false
	end
	if attacker.Safe or target.Safe or attacker.Protected or target.Protected then
		return false
	end
	if attacker.Kind == "Player" and target.Kind == "Player" then
		return attacker.Arena and target.Arena
	end
	return (attacker.Kind == "Player" and target.Kind == "Enemy")
		or (attacker.Kind == "Enemy" and target.Kind == "Player")
end

function Rules.ready(now: number, last: number, cooldown: number): boolean
	return now == now and now < math.huge and now - last >= cooldown
end

function Rules.damage(base: number, level: number): number
	return math.floor(base * (1 + 0.25 * (math.clamp(level, 1, 3) - 1)))
end

function Rules.meleeReach(distance: number, facing: number, range: number): boolean
	return distance > 0.01 and distance <= range and facing >= -0.1
end

function Rules.finite(x: number, y: number, z: number): boolean
	return x == x and y == y and z == z and math.abs(x) < 1e7 and math.abs(y) < 1e7 and math.abs(z) < 1e7
end

return Rules
