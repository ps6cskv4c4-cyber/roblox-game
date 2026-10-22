--!nonstrict
-- All rewards, inventory changes, purchases and round outcomes run on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Rounds = require(Shared:WaitForChild("Rounds"))
local world = workspace:WaitForChild("World")
local safeZone = world:WaitForChild("SafeZone")
local workshop = world:WaitForChild("Workshop")
local spawnPoint = workshop:WaitForChild("Spawn")
local interactions = world:WaitForChild("Interactables")
local random = Random.new()
local states, lastAction, lastRecovery = {}, {}, {}
local activeLoot = {}
local currentRound, currentPhase = 0, ""

local runtime = Instance.new("Folder")
runtime.Name = "Runtime"
runtime.Parent = ReplicatedStorage
local notice = Instance.new("RemoteEvent")
notice.Name = "Notice"
notice.Parent = runtime
local treasures = Instance.new("Folder")
treasures.Name = "Treasures"
treasures.Parent = world
local gallery = Instance.new("Folder")
gallery.Name = "CrewCollection"
gallery.Parent = world
local displayed = {}
local displayCount = 0

local function notify(player, text, tone)
	notice:FireClient(player, text, tone or "info")
end

local function rootOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return root
end

local function isSafe(root)
	local point = safeZone.CFrame:PointToObjectSpace(root.Position)
	local half = safeZone.Size / 2
	return math.abs(point.X) <= half.X and math.abs(point.Y) <= half.Y and math.abs(point.Z) <= half.Z
end

local function near(player, part)
	local root = rootOf(player)
	return root and (root.Position - part.Position).Magnitude <= Config.PickupDistance
end

local function sync(player)
	local state = states[player]
	if not state then
		return
	end
	local weight, value, count = Economy.summary(state, Config)
	local discovered = 0
	for _ in state.Collection do
		discovered += 1
	end
	local nextPack = Config.Upgrades[state.Level + 1]
	local attrs = {
		Coins = state.Coins,
		CarryWeight = weight,
		CarryValue = value,
		CarryCount = count,
		Capacity = Config.Upgrades[state.Level].Capacity,
		UpgradeLevel = state.Level,
		NextUpgradeCost = nextPack and nextPack.Cost or 0,
		CollectionCount = discovered,
		BestHaul = state.BestHaul,
	}
	for name, value in attrs do
		player:SetAttribute(name, value)
	end
	for id in Config.Items do
		player:SetAttribute("Found_" .. id, state.Collection[id] == true)
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Coins.Value = state.Coins
		stats.BestHaul.Value = state.BestHaul
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Economy.speed(state, Config)
	end
	local pack = character and character:FindFirstChild("SalvagePack")
	if pack then
		pack.Color = count > 0 and Color3.fromRGB(96, 210, 173) or Color3.fromRGB(161, 119, 76)
	end
end

local function createPrompt(part, action, object, duration)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = duration or 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local function floatingLabel(part, text, color, maxDistance)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(190, 44)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.MaxDistance = maxDistance or 36
	billboard.AlwaysOnTop = false
	billboard.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(19, 36, 44)
	label.BackgroundTransparency = 0.15
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextWrapped = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function gem(parent, name, position, item, size)
	local color = Color3.fromRGB(table.unpack(item.Color))
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(size, size, size)
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.pi / 4, math.pi / 6)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.Color = color
	part.Material = item.Rarity == "Common" and Enum.Material.Wood or Enum.Material.Neon
	if item.Rarity == "Uncommon" then
		part.Shape = Enum.PartType.Ball
	end
	part.Parent = parent
	if item.Rarity ~= "Common" then
		local glow = Instance.new("PointLight")
		glow.Color = color
		glow.Brightness = 0.8
		glow.Range = 9
		glow.Parent = part
	end
	return part
end

local function showDiscovery(id)
	local item = Config.Items[id]
	if displayed[id] or (item.Rarity ~= "Rare" and item.Rarity ~= "Legendary") then
		return
	end
	displayed[id] = true
	displayCount += 1
	local slot = world.DisplaySlots:FindFirstChild("Slot" .. tostring(displayCount))
	if slot then
		local trophy = gem(gallery, id, slot.Position, item, 2.5)
		floatingLabel(trophy, item.Name, Color3.fromRGB(table.unpack(item.Color)), 40)
	end
end

local spawnTreasure
spawnTreasure = function(marker)
	if currentPhase ~= "Scavenge" then
		return
	end
	local pool = string.sub(marker.Name, 1, 4) == "Wild" and Config.WildPool or Config.ShorePool
	local id = pool[random:NextInteger(1, #pool)]
	if marker.Name == "Shore01" then
		id = "SeaGlass"
	elseif marker.Name == "Wild05" then
		id = "StormHeart"
	end
	local item = Config.Items[id]
	local part = gem(treasures, id, marker.Position, item, item.Rarity == "Common" and 1.8 or 2.2)
	part:SetAttribute("TreasureId", id)
	local label = string.format("%s  /  %d coins", item.Name, item.Value)
	floatingLabel(part, label, Color3.fromRGB(table.unpack(item.Color)))
	local prompt = createPrompt(part, "Collect", string.format("%s | %d weight", item.Name, item.Weight))
	activeLoot[part] = true
	local roundToken = currentRound
	prompt.Triggered:Connect(function(player)
		if currentPhase ~= "Scavenge" or not activeLoot[part] or not near(player, part) then
			return
		end
		local state = states[player]
		if not state then
			return
		end
		local ok, message = Economy.collect(state, id, Config)
		if not ok then
			notify(player, message, "warning")
			return
		end
		-- No yielding between checking availability and removing a shared pickup.
		activeLoot[part] = nil
		part:Destroy()
		sync(player)
		notify(
			player,
			string.format("%s  +%d haul value", message, item.Value),
			item.Rarity == "Legendary" and "rare" or "success"
		)
		task.delay(Config.RespawnSeconds, function()
			if currentRound == roundToken and currentPhase == "Scavenge" then
				spawnTreasure(marker)
			end
		end)
	end)
end

local function clearTreasure()
	table.clear(activeLoot)
	treasures:ClearAllChildren()
end

local function recover(player, message)
	local root = rootOf(player)
	local state = states[player]
	local now = workspace:GetServerTimeNow()
	if not root or not state or (lastRecovery[player] or 0) > now then
		return
	end
	lastRecovery[player] = now + 2
	local _, count = Economy.loseHaul(state, Config)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	player.Character:PivotTo(spawnPoint.CFrame + Vector3.new(random:NextNumber(-3, 3), 5, 0))
	sync(player)
	notify(
		player,
		message .. (count > 0 and " Unbanked treasure was lost." or " Your banked coins are safe."),
		"warning"
	)
end

local function allowStation(player, part)
	if not states[player] or not near(player, part) then
		return false
	end
	local now = workspace:GetServerTimeNow()
	if (lastAction[player] or 0) > now then
		return false
	end
	lastAction[player] = now + 0.4
	return true
end

createPrompt(interactions.Bank, "Bank all treasure", "SALVAGE BANK", 0.35).Triggered:Connect(function(player)
	if not allowStation(player, interactions.Bank) then
		return
	end
	local state = states[player]
	local carried = table.clone(state.Inventory)
	local value, count, discoveries = Economy.bank(state, Config)
	if count == 0 then
		notify(player, "Find treasure on the island, then bring it here.")
		return
	end
	for _, id in carried do
		showDiscovery(id)
	end
	sync(player)
	local discovery = discoveries > 0 and string.format(" / %d new finds!", discoveries) or ""
	notify(player, string.format("BANKED +%d coins%s", value, discovery), "success")
end)

createPrompt(interactions.Upgrade, "Upgrade pack", "PACK WORKBENCH", 0.4).Triggered:Connect(function(player)
	if not allowStation(player, interactions.Upgrade) then
		return
	end
	local ok, message = Economy.upgrade(states[player], Config)
	sync(player)
	notify(player, ok and ("Pack upgraded: " .. message) or message, ok and "success" or "warning")
end)

local function onPlayer(player)
	if states[player] then
		return
	end
	local state = Economy.new()
	states[player] = state
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	for _, name in { "Coins", "BestHaul" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = stats
	end
	local function onCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not humanoid or not root or states[player] ~= state then
			return
		end
		local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		if torso then
			local pack = Instance.new("Part")
			pack.Name = "SalvagePack"
			pack.Size = Vector3.new(1.6, 1.8, 0.7)
			pack.Material = Enum.Material.Fabric
			pack.CanCollide = false
			pack.CanTouch = false
			pack.Massless = true
			pack.CFrame = torso.CFrame * CFrame.new(0, 0.1, 0.85)
			pack.Parent = character
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = torso
			weld.Part1 = pack
			weld.Parent = pack
		end
		humanoid.Died:Connect(function()
			if states[player] == state then
				Economy.loseHaul(state, Config)
				sync(player)
			end
		end)
		sync(player)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	sync(player)
end

Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player)
	states[player], lastAction[player], lastRecovery[player] = nil, nil, nil
end)
for _, player in Players:GetPlayers() do
	onPlayer(player)
end

local origin = workspace:GetServerTimeNow()
while true do
	local snapshot = Rounds.at(workspace:GetServerTimeNow(), origin, Config)
	local newRound = snapshot.Round ~= currentRound
	local newPhase = snapshot.Phase ~= currentPhase
	currentRound, currentPhase = snapshot.Round, snapshot.Phase
	if newRound or newPhase then
		runtime:SetAttribute("Phase", currentPhase)
		runtime:SetAttribute("Round", currentRound)
		runtime:SetAttribute("EndsAt", snapshot.EndsAt)
		if newRound then
			clearTreasure()
			for _, marker in world.TreasureSpawns:GetChildren() do
				spawnTreasure(marker)
			end
		elseif currentPhase == "Storm" then
			clearTreasure()
		end
	end
	for player in states do
		local root = rootOf(player)
		if root then
			local safe = isSafe(root)
			player:SetAttribute("IsSafe", safe)
			if root.Position.Y < -10 then
				recover(player, "The sea washed you back to the workshop.")
			elseif currentPhase == "Storm" and not safe then
				recover(player, "The storm caught you outside!")
			end
		end
	end
	task.wait(0.25)
end
