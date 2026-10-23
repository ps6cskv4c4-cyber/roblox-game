--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CombatConfig"))
local runtime = ReplicatedStorage:WaitForChild("Runtime")
local attack = runtime:WaitForChild("Attack")
local effects = runtime:WaitForChild("CombatFX")
local localEffects = Instance.new("Folder")
localEffects.Name = "LocalCombatEffects"
localEffects.Parent = workspace
local white, mint, coral = Color3.fromRGB(240, 247, 242), Color3.fromRGB(113, 240, 202), Color3.fromRGB(255, 128, 145)

local function make(className, props, parent)
	local object = Instance.new(className)
	for key, value in props do
		object[key] = value
	end
	object.Parent = parent
	return object
end
local screen = make(
	"ScreenGui",
	{ Name = "CombatHUD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9 },
	player:WaitForChild("PlayerGui")
)
local card = make("Frame", {
	Position = UDim2.fromScale(0.965, 0.27),
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(220, 137),
	BackgroundColor3 = Color3.fromRGB(19, 38, 47),
	BackgroundTransparency = 0.12,
	BorderSizePixel = 0,
}, screen)
make("UICorner", { CornerRadius = UDim.new(0, 13) }, card)
local scale = make("UIScale", { Scale = 1 }, card)
local function label(value, y, size, color)
	return make("TextLabel", {
		Text = value,
		TextSize = size,
		Font = Enum.Font.GothamBold,
		TextColor3 = color or white,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(15, y),
		Size = UDim2.fromOffset(190, 23),
	}, card)
end
local zone = label("SAFE WORKSHOP", 8, 12, mint)
local hp = label("100 / 100 HP", 33, 13)
local healthTrack = make("Frame", {
	Position = UDim2.fromOffset(15, 60),
	Size = UDim2.fromOffset(190, 5),
	BackgroundColor3 = Color3.fromRGB(65, 81, 86),
	BorderSizePixel = 0,
}, card)
local healthFill =
	make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = mint, BorderSizePixel = 0 }, healthTrack)
local weaponLabel = label("1: CUTTER / CLICK TO SWING", 73, 10)
local hint = label("ARMORY: BLASTER 120 COINS", 94, 9, mint)
local knockouts = label("SENTINELS 0 / ARENA 0", 113, 9, Color3.fromRGB(167, 193, 196))
local reticle = make("TextLabel", {
	Text = "+",
	Font = Enum.Font.GothamBold,
	TextSize = 27,
	TextColor3 = white,
	TextStrokeTransparency = 0.3,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(32, 32),
	Visible = false,
}, screen)

local function equipped()
	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	local id = tool and tool:GetAttribute("WeaponId")
	return tool, id and Config.Weapons[id], id
end
local lastSent = -math.huge
local function centerAim()
	return (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
		or string.find(UserInputService:GetLastInputType().Name, "Gamepad") == 1
end
local function sendAttack()
	local _, weapon = equipped()
	local camera = workspace.CurrentCamera
	if not weapon or not camera or os.clock() - lastSent < weapon.Cooldown then
		return
	end
	lastSent = os.clock()
	local aim
	if centerAim() then
		local center = camera.ViewportSize / 2
		local ray = camera:ViewportPointToRay(center.X, center.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character, localEffects }
		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
		aim = result and result.Position or ray.Origin + ray.Direction * 1000
	else
		aim = mouse.Hit.Position
	end
	attack:FireServer(aim)
end
local hooked = setmetatable({}, { __mode = "k" })
local function hookTool(tool)
	if not tool:IsA("Tool") or hooked[tool] or not tool:GetAttribute("WeaponId") then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		if tool.Parent == player.Character then
			sendAttack()
		end
	end)
end
local function hookContainer(container)
	for _, tool in container:GetChildren() do
		hookTool(tool)
	end
	container.ChildAdded:Connect(hookTool)
end
player.CharacterAdded:Connect(hookContainer)
player.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then
		hookContainer(child)
	end
end)
hookContainer(player:WaitForChild("Backpack"))
if player.Character then
	hookContainer(player.Character)
end
ContextActionService:BindAction("SalvageAttack", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		sendAttack()
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("SalvageAttack", "ATTACK")
ContextActionService:SetPosition("SalvageAttack", UDim2.fromScale(0.82, 0.58))

local function visual(position, size, color)
	return make("Part", {
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Size = size,
		Position = position,
		Color = color,
		Material = Enum.Material.Neon,
	}, localEffects)
end
effects.OnClientEvent:Connect(function(kind, a, b)
	if kind == "Shot" or kind == "Swing" then
		local length = (b - a).Magnitude
		if length < 0.1 then
			return
		end
		local beam = visual(
			(a + b) / 2,
			Vector3.new(kind == "Swing" and 0.7 or 0.13, 0.13, length),
			kind == "Swing" and mint or Color3.fromRGB(126, 197, 255)
		)
		beam.CFrame = CFrame.lookAt((a + b) / 2, b)
		TweenService:Create(beam, TweenInfo.new(0.16), { Transparency = 1 }):Play()
		Debris:AddItem(beam, 0.2)
	elseif kind == "Hit" then
		local anchor = visual(a + Vector3.new(0, 2.5, 0), Vector3.new(0.1, 0.1, 0.1), white)
		anchor.Transparency = 1
		local board = make("BillboardGui", { Size = UDim2.fromOffset(80, 40), AlwaysOnTop = false }, anchor)
		local number = make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "-" .. tostring(b),
			TextSize = 24,
			Font = Enum.Font.GothamBold,
			TextColor3 = coral,
			TextStrokeTransparency = 0.3,
		}, board)
		TweenService:Create(anchor, TweenInfo.new(0.65), { Position = anchor.Position + Vector3.new(0, 2.5, 0) }):Play()
		TweenService:Create(number, TweenInfo.new(0.65), { TextTransparency = 1 }):Play()
		Debris:AddItem(anchor, 0.7)
	elseif kind == "Tell" then
		local ring = visual(a - Vector3.new(0, 2.8, 0), Vector3.new(0.1, b * 2, b * 2), coral)
		ring.Shape = Enum.PartType.Cylinder
		ring.CFrame = CFrame.new(ring.Position) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Transparency = 0.55
		Debris:AddItem(ring, 0.5)
	end
end)

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	local camera = workspace.CurrentCamera
	local _, weapon, id = equipped()
	reticle.Visible = weapon ~= nil and weapon.Ranged
	if camera then
		if centerAim() then
			reticle.Position = UDim2.fromOffset(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
		else
			local location = UserInputService:GetMouseLocation()
			reticle.Position = UDim2.fromOffset(location.X, location.Y)
		end
	end
	elapsed += dt
	if elapsed < 0.1 then
		return
	end
	elapsed = 0
	if camera then
		local narrow = camera.ViewportSize.X < 850
		scale.Scale = narrow and 0.75 or 1
		card.AnchorPoint = narrow and Vector2.zero or Vector2.new(1, 0)
		card.Position = UDim2.fromScale(narrow and 0.035 or 0.965, 0.27)
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local health, maximum = humanoid and humanoid.Health or 0, humanoid and humanoid.MaxHealth or 100
	hp.Text = string.format("%d / %d HP", math.ceil(health), maximum)
	healthFill.Size = UDim2.fromScale(math.clamp(health / maximum, 0, 1), 1)
	healthFill.BackgroundColor3 = health < maximum * 0.3 and coral or mint
	local area = player:GetAttribute("CombatZone") or "SAFE WORKSHOP"
	zone.Text = area == "PVP ARENA" and "PVP ENABLED / ARENA"
		or area == "PVE ISLAND" and "PVE / PLAYERS FRIENDLY"
		or "SAFE / HEALING"
	zone.TextColor3 = area == "PVP ARENA" and coral or mint
	weaponLabel.Text = weapon
			and (string.upper(weapon.Name) .. " / T" .. tostring(player:GetAttribute("WeaponLevel") or 1))
		or "EQUIP 1: SALVAGE CUTTER"
	hint.Text = id == "Blaster" and "AIM + CLICK / TAP / RT TO FIRE"
		or id == "Cutter" and "FACE TARGET + CLICK / TAP / RT"
		or player:GetAttribute("HasBlaster") and "2: BLASTER / CLICK TO FIRE"
		or "ARMORY: BLASTER 120 COINS"
	knockouts.Text = string.format(
		"SENTINELS %d / ARENA %d",
		player:GetAttribute("EnemyKOs") or 0,
		player:GetAttribute("PvPKOs") or 0
	)
end)
