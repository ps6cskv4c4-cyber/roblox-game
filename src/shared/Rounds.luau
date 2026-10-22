--!strict
local Rounds = {}

export type Rules = { ScavengeSeconds: number, StormSeconds: number, CalmSeconds: number }
export type Snapshot = { Round: number, Phase: string, EndsAt: number, Remaining: number }

function Rounds.at(now: number, origin: number, rules: Rules): Snapshot
	local cycle = rules.ScavengeSeconds + rules.StormSeconds + rules.CalmSeconds
	local elapsed = math.max(0, now - origin)
	local index = math.floor(elapsed / cycle)
	local within = elapsed - index * cycle
	local start = origin + index * cycle
	local phase, ending
	if within < rules.ScavengeSeconds then
		phase = "Scavenge"
		ending = start + rules.ScavengeSeconds
	elseif within < rules.ScavengeSeconds + rules.StormSeconds then
		phase = "Storm"
		ending = start + rules.ScavengeSeconds + rules.StormSeconds
	else
		phase = "Calm"
		ending = start + cycle
	end
	return { Round = index + 1, Phase = phase, EndsAt = ending, Remaining = math.max(0, ending - now) }
end

return Rounds
