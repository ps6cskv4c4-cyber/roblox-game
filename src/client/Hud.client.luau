--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local runtime = ReplicatedStorage:WaitForChild("Runtime")
local notice = runtime:WaitForChild("Notice")
local world = workspace:WaitForChild("World")
-- The custom wallet occupies the default player list's corner.
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
local colors = {
	Ink = Color3.fromRGB(19, 38, 47),
	Panel = Color3.fromRGB(25, 48, 57),
	Mint = Color3.fromRGB(113, 240, 202),
	Gold = Color3.fromRGB(255, 207, 119),
	White = Color3.fromRGB(241, 246, 239),
	Muted = Color3.fromRGB(167, 193, 196),
	Coral = Color3.fromRGB(255, 132, 134),
}

local function make(className, props, parent)
	local object = Instance.new(className)
	for name, value in props do
		object[name] = value
	end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 14) }, parent)
end

local function panel(parent, props)
	props.BackgroundColor3 = props.BackgroundColor3 or colors.Ink
	props.BackgroundTransparency = props.BackgroundTransparency or 0.08
	props.BorderSizePixel = 0
	local result = make("Frame", props, parent)
	corner(result)
	make("UIStroke", { Color = colors.Mint, Transparency = 0.8, Thickness = 1 }, result)
	return result
end

local function text(parent, value, size, position, dimensions, color, font)
	return make("TextLabel", {
		Text = value,
		TextSize = size,
		Position = position,
		Size = dimensions,
		TextColor3 = color or colors.White,
		Font = font or Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, parent)
end

local screen = make("ScreenGui", {
	Name = "StormSalvagersHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))
local wash = make("Frame", {
	Name = "StormWash",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(49, 83, 130),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
}, screen)
local hud = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, screen)
local brand = make("Frame", {
	Position = UDim2.fromScale(0.035, 0.035),
	Size = UDim2.fromOffset(270, 88),
	BackgroundTransparency = 1,
}, hud)
text(brand, "STORM", 30, UDim2.fromOffset(0, 0), UDim2.fromOffset(250, 32), colors.White)
text(brand, "SALVAGERS", 30, UDim2.fromOffset(0, 31), UDim2.fromOffset(250, 34), colors.Mint)
text(brand, "FIND SOMETHING WORTH THE RISK.", 10, UDim2.fromOffset(1, 69), UDim2.fromOffset(270, 16), colors.White)

local phaseCard = panel(hud, {
	Position = UDim2.fromScale(0.5, 0.035),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.fromOffset(240, 88),
})
local phaseLabel = text(phaseCard, "STORM IN", 11, UDim2.fromOffset(18, 10), UDim2.new(1, -36, 0, 18), colors.Mint)
local clock = text(phaseCard, "2:30", 33, UDim2.fromOffset(18, 28), UDim2.new(0.6, 0, 0, 39))
local roundText = text(phaseCard, "RUN 1", 10, UDim2.new(0.59, 0, 0, 39), UDim2.new(0.36, 0, 0, 18), colors.Muted)

local wallet = panel(hud, {
	Position = UDim2.fromScale(0.965, 0.035),
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(220, 88),
})
text(wallet, "BANKED COINS", 10, UDim2.fromOffset(17, 10), UDim2.new(1, -34, 0, 16), colors.Gold)
local coinsText = text(wallet, "0", 26, UDim2.fromOffset(17, 28), UDim2.new(1, -34, 0, 30))
local collectionButton = make("TextButton", {
	Text = "COLLECTION  0 / 8  >",
	TextColor3 = colors.Mint,
	TextSize = 10,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(17, 61),
	Size = UDim2.new(1, -34, 0, 20),
}, wallet)

local goal = panel(hud, {
	Position = UDim2.fromScale(0.035, 0.22),
	Size = UDim2.fromOffset(245, 126),
	BackgroundTransparency = 0.18,
})
text(goal, "YOUR NEXT MOVE", 10, UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 18), colors.Mint)
local goalTitle = text(goal, "Find your first treasure", 15, UDim2.fromOffset(16, 36), UDim2.new(1, -32, 0, 24))
local goalBody = text(
	goal,
	"Follow the trail. Hold E near a glowing find to collect it.",
	12,
	UDim2.fromOffset(16, 65),
	UDim2.new(1, -32, 0, 45),
	colors.Muted,
	Enum.Font.Gotham
)
goalBody.TextWrapped = true

local carry = panel(hud, {
	Position = UDim2.fromScale(0.5, 0.965),
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.new(0.57, 0, 0, 113),
})
make("UISizeConstraint", { MaxSize = Vector2.new(520, 113), MinSize = Vector2.new(250, 113) }, carry)
local haulText = text(carry, "EMPTY BAG", 19, UDim2.fromOffset(18, 12), UDim2.new(1, -36, 0, 26))
local weightText = text(carry, "0 / 12 WEIGHT", 11, UDim2.fromOffset(18, 42), UDim2.new(1, -36, 0, 19), colors.Muted)
local track = make("Frame", {
	Position = UDim2.fromOffset(18, 70),
	Size = UDim2.new(1, -36, 0, 6),
	BackgroundColor3 = Color3.fromRGB(61, 81, 86),
	BorderSizePixel = 0,
}, carry)
corner(track, 3)
local fill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = colors.Mint, BorderSizePixel = 0 }, track)
corner(fill, 3)
local carryHint = text(
	carry,
	"More weight means a slower trip home.",
	10,
	UDim2.fromOffset(18, 86),
	UDim2.new(1, -36, 0, 17),
	colors.Muted,
	Enum.Font.Gotham
)

local toast = panel(hud, {
	Position = UDim2.fromScale(0.5, 0.19),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0.8, 0, 0, 54),
	Visible = false,
})
make("UISizeConstraint", { MaxSize = Vector2.new(520, 70) }, toast)
local toastText = text(toast, "", 13, UDim2.fromOffset(16, 5), UDim2.new(1, -32, 1, -10))
toastText.TextWrapped = true
toastText.TextXAlignment = Enum.TextXAlignment.Center
local toastToken = 0
local function showToast(message, tone)
	toastToken += 1
	local token = toastToken
	toast.Visible = true
	toastText.Text = message
	toastText.TextColor3 = tone == "warning" and colors.Coral
		or tone == "rare" and colors.Gold
		or tone == "success" and colors.Mint
		or colors.White
	task.delay(4, function()
		if toastToken == token then
			toast.Visible = false
		end
	end)
end
notice.OnClientEvent:Connect(showToast)

local welcome = panel(hud, {
	Position = UDim2.fromScale(0.5, 0.48),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.88, 0, 0, 270),
})
make("UISizeConstraint", { MaxSize = Vector2.new(440, 270) }, welcome)
text(welcome, "ONE MORE FIND?", 25, UDim2.fromOffset(24, 20), UDim2.new(1, -48, 0, 38), colors.Mint)
local intro = text(
	welcome,
	"Explore the island. Collect strange treasure.\nBank it here before the storm arrives.\n\nA heavier bag slows you down.\nStorms take your unbanked haul.",
	15,
	UDim2.fromOffset(24, 66),
	UDim2.new(1, -48, 0, 121),
	colors.White,
	Enum.Font.Gotham
)
intro.TextWrapped = true
intro.TextYAlignment = Enum.TextYAlignment.Top
local start = make("TextButton", {
	Position = UDim2.fromOffset(24, 205),
	Size = UDim2.new(1, -48, 0, 42),
	Text = "LET'S GO SALVAGING",
	TextColor3 = colors.Ink,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	BackgroundColor3 = colors.Mint,
	BorderSizePixel = 0,
}, welcome)
corner(start, 9)
start.Activated:Connect(function()
	welcome.Visible = false
end)

local collection = panel(hud, {
	Position = UDim2.fromScale(0.5, 0.48),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.new(0.9, 0, 0, 405),
	Visible = false,
})
make("UISizeConstraint", { MaxSize = Vector2.new(590, 405) }, collection)
text(collection, "YOUR FIELD GUIDE", 21, UDim2.fromOffset(20, 15), UDim2.new(1, -80, 0, 32), colors.Mint)
text(
	collection,
	"Bank a find to add it. Progress lasts for this session.",
	11,
	UDim2.fromOffset(20, 50),
	UDim2.new(1, -40, 0, 32),
	colors.Muted,
	Enum.Font.Gotham
).TextWrapped =
	true
local close = make("TextButton", {
	Position = UDim2.new(1, -53, 0, 15),
	Size = UDim2.fromOffset(35, 35),
	Text = "X",
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	TextColor3 = colors.White,
	BackgroundColor3 = colors.Panel,
	BorderSizePixel = 0,
}, collection)
corner(close, 8)
local grid = make(
	"Frame",
	{ Position = UDim2.fromOffset(20, 94), Size = UDim2.new(1, -40, 0, 290), BackgroundTransparency = 1 },
	collection
)
make("UIGridLayout", {
	CellSize = UDim2.new(0.5, -5, 0, 64),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, grid)
local collectionCells = {}
local collectionScale = make("UIScale", { Scale = 1 }, collection)
local welcomeScale = make("UIScale", { Scale = 1 }, welcome)
local ids = {}
for id in Config.Items do
	table.insert(ids, id)
end
table.sort(ids, function(a, b)
	return Config.Items[a].Value < Config.Items[b].Value
end)
for i, id in ids do
	local cell = panel(grid, { Size = UDim2.fromOffset(200, 64), LayoutOrder = i, BackgroundColor3 = colors.Panel })
	local title = text(cell, "UNDISCOVERED", 12, UDim2.fromOffset(12, 9), UDim2.new(1, -24, 0, 22), colors.Muted)
	local detail = text(
		cell,
		"Bring a find to the bank",
		10,
		UDim2.fromOffset(12, 35),
		UDim2.new(1, -24, 0, 18),
		colors.Muted,
		Enum.Font.Gotham
	)
	collectionCells[id] = { Title = title, Detail = detail }
end
collectionButton.Activated:Connect(function()
	collection.Visible = not collection.Visible
	welcome.Visible = false
end)
close.Activated:Connect(function()
	collection.Visible = false
end)

local beacon = make("BillboardGui", {
	Name = "HomeBeacon",
	Adornee = world.Workshop:WaitForChild("WorkshopSign"),
	Size = UDim2.fromOffset(155, 55),
	StudsOffset = Vector3.new(0, 7, 0),
	AlwaysOnTop = true,
	MaxDistance = 350,
	Enabled = false,
}, screen)
local beaconText =
	text(beacon, "WORKSHOP\nBANK + SHELTER", 14, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), colors.Mint)
beaconText.TextXAlignment = Enum.TextXAlignment.Center
beaconText.TextStrokeTransparency = 0.2

local function responsive()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local narrow = camera.ViewportSize.X < 850
	brand.Visible = not narrow
	goal.Visible = not narrow
	phaseCard.AnchorPoint = narrow and Vector2.zero or Vector2.new(0.5, 0)
	phaseCard.Position = narrow and UDim2.fromScale(0.035, 0.025) or UDim2.fromScale(0.5, 0.035)
	phaseCard.Size = narrow and UDim2.new(0.44, 0, 0, 88) or UDim2.fromOffset(240, 88)
	wallet.Size = narrow and UDim2.new(0.44, 0, 0, 88) or UDim2.fromOffset(220, 88)
	wallet.Position = narrow and UDim2.fromScale(0.965, 0.025) or UDim2.fromScale(0.965, 0.035)
	carryHint.TextSize = narrow and 9 or 10
	weightText.TextSize = narrow and 10 or 11
	collectionScale.Scale = math.min(1, math.max(0.5, (camera.ViewportSize.Y - 45) / 405))
	welcomeScale.Scale = math.min(1, math.max(0.6, (camera.ViewportSize.Y - 45) / 270))
end

local function refresh()
	local coins = player:GetAttribute("Coins") or 0
	local value = player:GetAttribute("CarryValue") or 0
	local weight = player:GetAttribute("CarryWeight") or 0
	local capacity = player:GetAttribute("Capacity") or 12
	local count = player:GetAttribute("CarryCount") or 0
	local level = player:GetAttribute("UpgradeLevel") or 1
	local nextCost = player:GetAttribute("NextUpgradeCost") or 80
	local discovered = player:GetAttribute("CollectionCount") or 0
	coinsText.Text = tostring(coins)
	collectionButton.Text = string.format("COLLECTION  %d / 8  >", discovered)
	haulText.Text = count > 0 and string.format("HAUL  +%d COINS", value) or "EMPTY BAG"
	weightText.Text =
		string.format("%d / %d WEIGHT   /   %s", weight, capacity, string.upper(Config.Upgrades[level].Name))
	fill.Size = UDim2.fromScale(math.clamp(weight / capacity, 0, 1), 1)
	fill.BackgroundColor3 = weight / capacity >= 0.8 and colors.Coral or colors.Mint
	for id, cell in collectionCells do
		local found = player:GetAttribute("Found_" .. id)
		local item = Config.Items[id]
		cell.Title.Text = found and item.Name or "UNDISCOVERED"
		cell.Title.TextColor3 = found and Color3.fromRGB(table.unpack(item.Color)) or colors.Muted
		cell.Detail.Text = found and string.format("%s  /  %d coins", item.Rarity, item.Value)
			or "Bring a find to the bank"
	end
	if count > 0 then
		goalTitle.Text = "Bank it, or risk one more?"
		goalBody.Text = "Return to the workshop's mint counter. Only banked treasure is safe."
	elseif (player:GetAttribute("BestHaul") or 0) == 0 then
		goalTitle.Text = "Find your first treasure"
		goalBody.Text = "Follow the trail. Hold E near a glowing find, or tap its prompt."
	elseif level < #Config.Upgrades then
		goalTitle.Text = "Make room for more"
		goalBody.Text = string.format("The workshop's gold workbench upgrades your pack for %d coins.", nextCost)
	else
		goalTitle.Text = "Complete your field guide"
		goalBody.Text = string.format("%d of 8 finds banked. Search the wreck, ruins and beacon point.", discovered)
	end
end
for _, attr in
	{
		"Coins",
		"CarryValue",
		"CarryWeight",
		"CarryCount",
		"Capacity",
		"UpgradeLevel",
		"NextUpgradeCost",
		"CollectionCount",
		"BestHaul",
	}
do
	player:GetAttributeChangedSignal(attr):Connect(refresh)
end

local weatherToken = 0
local function weather()
	weatherToken += 1
	local token = weatherToken
	local storm = runtime:GetAttribute("Phase") == "Storm"
	TweenService
		:Create(Lighting, TweenInfo.new(2), { ClockTime = storm and 18.5 or 15.5, Brightness = storm and 0.7 or 2.8 })
		:Play()
	local atmosphere = Lighting:FindFirstChild("CoastalHaze")
	if atmosphere then
		TweenService
			:Create(atmosphere, TweenInfo.new(2), { Density = storm and 0.48 or 0.27, Haze = storm and 3.5 or 1.5 })
			:Play()
	end
	TweenService:Create(wash, TweenInfo.new(1.5), { BackgroundTransparency = storm and 0.86 or 1 }):Play()
	if storm then
		showToast("STORM! Get inside the workshop. Banked coins are safe.", "warning")
		task.spawn(function()
			while weatherToken == token do
				task.wait(3.5)
				if weatherToken ~= token then
					break
				end
				Lighting.Brightness = 4
				TweenService:Create(Lighting, TweenInfo.new(0.35), { Brightness = 0.7 }):Play()
			end
		end)
	elseif runtime:GetAttribute("Phase") == "Scavenge" then
		showToast("Fresh treasure is out there. Make this run count.", "success")
	end
end
runtime:GetAttributeChangedSignal("Phase"):Connect(weather)

local animated = {}
local function animate(part)
	if part:IsA("BasePart") then
		animated[part] = { Position = part.Position, Offset = math.random() * 6 }
	end
end
for _, folderName in { "Treasures", "CrewCollection" } do
	local folder = world:WaitForChild(folderName)
	for _, part in folder:GetChildren() do
		animate(part)
	end
	folder.ChildAdded:Connect(animate)
	folder.ChildRemoved:Connect(function(part)
		animated[part] = nil
	end)
end

local lastTick, warnedRun = 0, 0
RunService.RenderStepped:Connect(function()
	local time = workspace:GetServerTimeNow()
	for part, data in animated do
		part.CFrame = CFrame.new(data.Position + Vector3.new(0, math.sin(time * 2 + data.Offset) * 0.25, 0))
			* CFrame.Angles(0, time * 0.45 + data.Offset, math.pi / 6)
	end
	if time - lastTick < 0.1 then
		return
	end
	lastTick = time
	responsive()
	local phase = runtime:GetAttribute("Phase") or "Scavenge"
	local remaining = math.max(0, math.ceil((runtime:GetAttribute("EndsAt") or time) - time))
	local run = runtime:GetAttribute("Round") or 1
	local warning = phase == "Scavenge" and remaining <= Config.WarningSeconds
	clock.Text = string.format("%d:%02d", math.floor(remaining / 60), remaining % 60)
	phaseLabel.Text = phase == "Storm" and "SHELTER NOW"
		or phase == "Calm" and "NEXT RUN IN"
		or warning and "STORM APPROACHING"
		or "STORM IN"
	phaseLabel.TextColor3 = (warning or phase == "Storm") and colors.Coral or colors.Mint
	roundText.Text = "RUN " .. tostring(run)
	local safe = player:GetAttribute("IsSafe")
	local count = player:GetAttribute("CarryCount") or 0
	beacon.Enabled = not safe and (count > 0 or warning or phase == "Storm")
	if phase == "Storm" then
		carryHint.Text = safe and "SHELTERED / Your haul is safe inside." or "Get back to the workshop!"
	elseif safe and count > 0 then
		carryHint.Text = "Hold E at the mint counter to bank your haul."
	elseif warning and count > 0 then
		carryHint.Text = "Time to head home. Follow the WORKSHOP marker."
	else
		carryHint.Text = "More weight means a slower trip home."
	end
	if warning and warnedRun ~= run then
		warnedRun = run
		showToast("30 seconds! Bank your haul before the storm hits.", "warning")
	end
end)

refresh()
responsive()
weather()
