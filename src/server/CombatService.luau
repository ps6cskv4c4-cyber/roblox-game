--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("CombatConfig"))
local Rules = require(Shared:WaitForChild("CombatRules"))
local Combat = {}

function Combat.start(context)
	local world, runtime = context.World, context.Runtime
	local enemies = Instance.new("Folder")
	enemies.Name = "Enemies"
	enemies.Parent = world
	local attack = Instance.new("RemoteEvent")
	attack.Name = "Attack"
	attack.Parent = runtime
	local effects = Instance.new("RemoteEvent")
	effects.Name = "CombatFX"
	effects.Parent = runtime
	local records, cooldowns, medkitCooldowns = {}, {}, {}
	local generation = 0

	local function phase()
		return runtime:GetAttribute("Phase") or "Calm"
	end
	local function inBox(box, position)
		local p = box.CFrame:PointToObjectSpace(position)
		return Rules.inside(p.X, p.Y, p.Z, box.Size.X, box.Size.Y, box.Size.Z)
	end
	local function actor(model)
		if not model or not model.Parent then
			return nil
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then
			return nil
		end
		local owner = Players:GetPlayerFromCharacter(model)
		if not owner and not records[model] then
			return nil
		end
		local position = root.Position
		if not Rules.finite(position.X, position.Y, position.Z) then
			return nil
		end
		return {
			Kind = owner and "Player" or "Enemy",
			Alive = humanoid.Health > 0,
			Safe = inBox(world.SafeZone, position),
			Arena = inBox(world.PvPZone, position),
			Protected = model:FindFirstChildOfClass("ForceField") ~= nil
				or (owner ~= nil and workspace:GetServerTimeNow() < (owner:GetAttribute("ProtectedUntil") or 0)),
			Root = root,
			Humanoid = humanoid,
			Owner = owner,
			Model = model,
		}
	end
	local function clearShot(fromModel, destination, target)
		local source = fromModel.HumanoidRootPart.Position + Vector3.new(0, 1, 0)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { fromModel }
		local result = workspace:Raycast(source, destination - source, params)
		return not result or result.Instance:IsDescendantOf(target)
	end
	local function hurt(fromModel, targetModel, damage)
		local from, target = actor(fromModel), actor(targetModel)
		if not from or not target or fromModel == targetModel or not Rules.canDamage(from, target, phase()) then
			return false
		end
		local record = records[targetModel]
		if record and from.Owner then
			record.LastHit = from.Owner
		end
		local oldHealth = target.Humanoid.Health
		target.Humanoid:TakeDamage(damage)
		local actual = oldHealth - target.Humanoid.Health
		if actual <= 0 then
			return false
		end
		effects:FireAllClients("Hit", target.Root.Position, math.ceil(actual))
		if target.Humanoid.Health <= 0 and from.Owner and target.Owner then
			from.Owner:SetAttribute("PvPKOs", (from.Owner:GetAttribute("PvPKOs") or 0) + 1)
			context.Notice:FireClient(from.Owner, "Arena knockout! Banked coins stay with their owner.", "success")
		end
		return true
	end

	local function piece(parent, name, size, color, cf, collide)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Color, p.CFrame = name, size, color, cf
		p.Material = Enum.Material.Metal
		p.CanCollide, p.CanTouch = collide == true, false
		p.Massless = name ~= "HumanoidRootPart"
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end
	local function weld(a, b)
		local link = Instance.new("WeldConstraint")
		link.Part0, link.Part1 = a, b
		link.Parent = b
	end
	local function giveWeapons(player)
		local state = context.States[player]
		local backpack = player:FindFirstChildOfClass("Backpack")
		if not state or not backpack then
			return
		end
		for _, id in { "Cutter", "Blaster" } do
			local weapon = Config.Weapons[id]
			if id == "Blaster" and not state.HasBlaster then
				continue
			end
			local found = false
			for _, container in { backpack, player.Character } do
				if not container then
					continue
				end
				for _, tool in container:GetChildren() do
					if tool:IsA("Tool") and tool:GetAttribute("WeaponId") == id then
						found = true
						tool.ToolTip = string.format("%s / Tier %d", weapon.Name, state.WeaponLevel)
					end
				end
			end
			if found then
				continue
			end
			local tool = Instance.new("Tool")
			tool.Name, tool.ToolTip = weapon.Name, "Equip and click / tap to attack"
			tool.CanBeDropped = false
			tool:SetAttribute("WeaponId", id)
			local handle =
				piece(tool, "Handle", Vector3.new(0.45, 1.5, 0.5), Color3.fromRGB(62, 81, 92), CFrame.identity, false)
			handle.CanQuery = false
			local detail
			if id == "Cutter" then
				detail = piece(
					tool,
					"Blade",
					Vector3.new(0.8, 2.2, 0.23),
					Color3.fromRGB(128, 255, 215),
					CFrame.new(0, 1.6, 0),
					false
				)
				tool.Grip = CFrame.new(0, -0.6, 0)
			else
				detail = piece(
					tool,
					"Barrel",
					Vector3.new(0.8, 0.8, 2.8),
					Color3.fromRGB(111, 195, 255),
					CFrame.new(0, 0.65, -0.8),
					false
				)
				tool.Grip = CFrame.new(0, -0.3, 0)
			end
			detail.Material, detail.CanQuery = Enum.Material.Neon, false
			weld(handle, detail)
			tool.Parent = backpack
		end
	end

	attack.OnServerEvent:Connect(function(player, aim)
		local model = player.Character
		local from = actor(model)
		local state = context.States[player]
		if not from or not state or not from.Alive or from.Safe or from.Protected or phase() ~= "Scavenge" then
			return
		end
		local tool = model:FindFirstChildOfClass("Tool")
		local id = tool and tool:GetAttribute("WeaponId")
		local weapon = id and Config.Weapons[id]
		if not weapon or (id == "Blaster" and not state.HasBlaster) then
			return
		end
		local now = workspace:GetServerTimeNow()
		if not Rules.ready(now, cooldowns[player] or -math.huge, weapon.Cooldown) then
			return
		end
		if weapon.Ranged and (typeof(aim) ~= "Vector3" or not Rules.finite(aim.X, aim.Y, aim.Z)) then
			return
		end
		cooldowns[player] = now
		local damage = Rules.damage(weapon.Damage, state.WeaponLevel)
		local source = from.Root.Position + Vector3.new(0, 1, 0)
		if weapon.Ranged then
			local direction = aim - source
			if direction.Magnitude < 0.1 then
				return
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { model }
			local result = workspace:Raycast(source, direction.Unit * weapon.Range, params)
			local finish = result and result.Position or source + direction.Unit * weapon.Range
			effects:FireAllClients("Shot", source, finish)
			if result then
				local target = result.Instance:FindFirstAncestorOfClass("Model")
				if target then
					hurt(model, target, damage)
				end
			end
		else
			local closest, best = nil, weapon.Range
			local candidates = {}
			for enemy in records do
				table.insert(candidates, enemy)
			end
			for _, other in Players:GetPlayers() do
				if other ~= player and other.Character then
					table.insert(candidates, other.Character)
				end
			end
			for _, candidate in candidates do
				local target = actor(candidate)
				if not target or not Rules.canDamage(from, target, phase()) then
					continue
				end
				local offset = target.Root.Position - from.Root.Position
				local distance = offset.Magnitude
				if
					distance > best
					or not Rules.meleeReach(distance, from.Root.CFrame.LookVector:Dot(offset.Unit), weapon.Range)
				then
					continue
				end
				if not clearShot(model, target.Root.Position, candidate) then
					continue
				end
				closest, best = candidate, distance
			end
			effects:FireAllClients("Swing", source, source + from.Root.CFrame.LookVector * 5)
			local grip = CFrame.new(0, -0.6, 0)
			tool.Grip = grip * CFrame.Angles(math.rad(-65), 0, 0)
			TweenService:Create(tool, TweenInfo.new(0.25), { Grip = grip }):Play()
			if closest then
				hurt(model, closest, damage)
			end
		end
	end)

	local spawnEnemy
	spawnEnemy = function(marker, token)
		if token ~= generation or phase() ~= "Scavenge" then
			return
		end
		local kind = string.sub(marker.Name, 1, 5) == "Brute" and "Brute" or "Scout"
		local spec = Config.Enemies[kind]
		local model = Instance.new("Model")
		model.Name = spec.Name
		local cf = CFrame.new(marker.Position)
		local bodyColor = kind == "Brute" and Color3.fromRGB(146, 98, 68) or Color3.fromRGB(71, 102, 114)
		local root = piece(model, "HumanoidRootPart", Vector3.new(2, 2, 1), bodyColor, cf, false)
		root.Transparency = 1
		local torso = piece(model, "Torso", Vector3.new(2.5, 2.4, 1.5), bodyColor, cf, true)
		local joint = Instance.new("Motor6D")
		joint.Name, joint.Part0, joint.Part1, joint.Parent = "RootJoint", root, torso, root
		local definitions = {
			{ "Head", Vector3.new(0, 2, 0), Vector3.new(2.2, 1.5, 1.5) },
			{ "Left Arm", Vector3.new(-1.8, 0, 0), Vector3.new(1, 2.3, 1) },
			{ "Right Arm", Vector3.new(1.8, 0, 0), Vector3.new(1, 2.3, 1) },
			{ "Left Leg", Vector3.new(-0.65, -2, 0), Vector3.new(1, 2, 1) },
			{ "Right Leg", Vector3.new(0.65, -2, 0), Vector3.new(1, 2, 1) },
		}
		for _, definition in definitions do
			local p = piece(model, definition[1], definition[3], bodyColor, cf + definition[2], false)
			weld(torso, p)
		end
		local eye = piece(
			model,
			"Optic",
			Vector3.new(1.7, 0.3, 0.12),
			Color3.fromRGB(255, 172, 91),
			cf * CFrame.new(0, 2, -0.82),
			false
		)
		eye.Material = Enum.Material.Neon
		weld(torso, eye)
		local humanoid = Instance.new("Humanoid")
		humanoid.MaxHealth, humanoid.Health = spec.Health, spec.Health
		humanoid.WalkSpeed, humanoid.RequiresNeck = spec.Speed, false
		humanoid.BreakJointsOnDeath = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Parent = model
		model.PrimaryPart, model.Parent = root, enemies
		root:SetNetworkOwner(nil)
		local record = { LastHit = nil, Dead = false }
		records[model] = record
		local board = Instance.new("BillboardGui")
		board.Size, board.StudsOffset, board.MaxDistance = UDim2.fromOffset(170, 42), Vector3.new(0, 4, 0), 80
		board.Parent = root
		local label = Instance.new("TextLabel")
		label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 0.15
		label.BackgroundColor3, label.TextColor3 = Color3.fromRGB(25, 38, 45), Color3.fromRGB(255, 177, 119)
		label.Font, label.TextSize, label.TextWrapped = Enum.Font.GothamBold, 12, true
		label.Parent = board
		local function healthLabel()
			label.Text = string.format("%s\n%d / %d HP", spec.Name, math.ceil(humanoid.Health), spec.Health)
		end
		healthLabel()
		humanoid.HealthChanged:Connect(healthLabel)
		humanoid.Died:Connect(function()
			if record.Dead then
				return
			end
			record.Dead = true
			for _, p in model:GetDescendants() do
				if p:IsA("BasePart") then
					p.CanCollide, p.CanQuery = false, false
				end
			end
			if token == generation and phase() == "Scavenge" and record.LastHit and context.States[record.LastHit] then
				local winner = record.LastHit
				winner:SetAttribute("EnemyKOs", (winner:GetAttribute("EnemyKOs") or 0) + 1)
				context.Drop(winner, spec.Drop, root.Position)
			end
			task.delay(2, function()
				records[model] = nil
				model:Destroy()
			end)
			task.delay(Config.EnemyRespawn, function()
				spawnEnemy(marker, token)
			end)
		end)
		task.spawn(function()
			local lastAttack, lastPath, waypoints, waypointIndex = -math.huge, -math.huge, nil, 2
			while model.Parent and humanoid.Health > 0 and token == generation and phase() == "Scavenge" do
				local from = actor(model)
				local target, best = nil, spec.Aggro
				for _, player in Players:GetPlayers() do
					local candidate = actor(player.Character)
					if not candidate or not from or not Rules.canDamage(from, candidate, phase()) then
						continue
					end
					local distance = (candidate.Root.Position - root.Position).Magnitude
					if distance < best and (candidate.Root.Position - marker.Position).Magnitude < spec.Leash then
						target, best = candidate, distance
					end
				end
				local now = workspace:GetServerTimeNow()
				if target and best < 5.8 and Rules.ready(now, lastAttack, spec.Cooldown) then
					lastAttack = now
					humanoid:MoveTo(root.Position)
					eye.Color = Color3.fromRGB(255, 65, 87)
					effects:FireAllClients("Tell", root.Position, 5.8)
					task.wait(0.45)
					if token ~= generation or not model.Parent or humanoid.Health <= 0 then
						break
					end
					local refreshed = actor(target.Model)
					if
						refreshed
						and (refreshed.Root.Position - root.Position).Magnitude < 6.2
						and clearShot(model, refreshed.Root.Position, refreshed.Model)
					then
						hurt(model, refreshed.Model, spec.Damage)
					end
					eye.Color = Color3.fromRGB(255, 172, 91)
				else
					local destination = target and target.Root.Position or marker.Position
					if (destination - root.Position).Magnitude > 3 then
						if now - lastPath > 1.3 then
							lastPath = now
							local path = PathfindingService:CreatePath({
								AgentRadius = 2.5,
								AgentHeight = 6,
								AgentCanJump = true,
								WaypointSpacing = 6,
							})
							local ok = pcall(function()
								path:ComputeAsync(root.Position, destination)
							end)
							waypoints = ok and path.Status == Enum.PathStatus.Success and path:GetWaypoints() or nil
							waypointIndex = 2
						end
						if not model.Parent or humanoid.Health <= 0 then
							break
						end
						local point = waypoints and waypoints[waypointIndex]
						if point and (point.Position - root.Position).Magnitude < 3 then
							waypointIndex += 1
							point = waypoints[waypointIndex]
						end
						if point and point.Action == Enum.PathWaypointAction.Jump then
							humanoid.Jump = true
						end
						humanoid:MoveTo(point and point.Position or destination)
					else
						humanoid:MoveTo(root.Position)
					end
				end
				task.wait(0.2)
			end
		end)
	end

	local function clearEnemies()
		table.clear(records)
		enemies:ClearAllChildren()
	end
	runtime:GetAttributeChangedSignal("Round"):Connect(function()
		generation += 1
		clearEnemies()
		local token = generation
		if phase() == "Scavenge" then
			for _, marker in world.EnemySpawns:GetChildren() do
				spawnEnemy(marker, token)
			end
		end
	end)
	runtime:GetAttributeChangedSignal("Phase"):Connect(function()
		if phase() ~= "Scavenge" then
			generation += 1
			clearEnemies()
		end
	end)
	for _, part in world.Interactables:GetChildren() do
		if string.sub(part.Name, 1, 6) ~= "Medkit" then
			continue
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText, prompt.ObjectText, prompt.HoldDuration = "Heal +40 HP", "FIELD MEDKIT / 20s COOLDOWN", 0.6
		prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 10, false
		prompt.Parent = part
		prompt.Triggered:Connect(function(player)
			local target = actor(player.Character)
			if not target or not target.Alive or (target.Root.Position - part.Position).Magnitude > 13 then
				return
			end
			local used = medkitCooldowns[player] or {}
			medkitCooldowns[player] = used
			local now = workspace:GetServerTimeNow()
			if (used[part] or 0) > now then
				context.Notice:FireClient(player, "Medkit recharging. Return to the workshop for healing.", "warning")
			elseif target.Humanoid.Health >= target.Humanoid.MaxHealth then
				context.Notice:FireClient(player, "You're already at full health.", "info")
			else
				used[part] = now + 20
				target.Humanoid.Health = math.min(target.Humanoid.MaxHealth, target.Humanoid.Health + 40)
				context.Notice:FireClient(player, "+40 HP / Medkit recharging for 20 seconds.", "success")
			end
		end)
	end
	local function bindPlayer(player)
		local function characterAdded(character)
			local root = character:WaitForChild("HumanoidRootPart", 10)
			local backpack = player:WaitForChild("Backpack", 10)
			if not root or not backpack or player.Character ~= character then
				return
			end
			player:SetAttribute("ProtectedUntil", workspace:GetServerTimeNow() + Config.SpawnProtection)
			cooldowns[player] = nil
			giveWeapons(player)
		end
		player.CharacterAdded:Connect(characterAdded)
		if player.Character then
			task.spawn(characterAdded, player.Character)
		end
	end
	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player], medkitCooldowns[player] = nil, nil
	end)
	for _, player in Players:GetPlayers() do
		bindPlayer(player)
	end
	task.spawn(function()
		while true do
			for player in context.States do
				local target = actor(player.Character)
				if target and target.Alive then
					player:SetAttribute(
						"CombatZone",
						target.Safe and "SAFE WORKSHOP" or target.Arena and "PVP ARENA" or "PVE ISLAND"
					)
					if target.Safe then
						target.Humanoid.Health = math.min(target.Humanoid.MaxHealth, target.Humanoid.Health + 5)
					end
				end
			end
			task.wait(0.5)
		end
	end)
	return { GiveWeapons = giveWeapons }
end

return Combat
