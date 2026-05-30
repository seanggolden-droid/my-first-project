-- ============================================================
-- InventoryClient (LocalScript) — StarterPlayerScripts
-- Renders the player's inventory as Being cards.
-- Sort by rarity, value, or name. Sell and trade from here.
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RequestInventory = ReplicatedStorage:WaitForChild("RequestInventory")
local SellBeing        = ReplicatedStorage:WaitForChild("SellBeing")
local DoMutationLab    = ReplicatedStorage:WaitForChild("DoMutationLab")
local UpdateHUD        = ReplicatedStorage:WaitForChild("UpdateHUD")

-- Toggle signal from HUDController
local ToggleInventory  = ReplicatedStorage:WaitForChild("ToggleInventory", 10)

-- ── Rarity colors ─────────────────────────────────────────────
local RarityColors = {
	Common  = Color3.fromRGB(180, 180, 180),
	Rare    = Color3.fromRGB(80, 140, 255),
	Epic    = Color3.fromRGB(180, 80, 255),
	Cursed  = Color3.fromRGB(255, 60, 60),
	Void    = Color3.fromRGB(20, 255, 180),
}

-- ── Build Inventory GUI ───────────────────────────────────────
local function BuildInventoryGui()
	local sg = Instance.new("ScreenGui")
	sg.Name = "InventoryGui"
	sg.ResetOnSpawn = false
	sg.Enabled = false
	sg.Parent = playerGui

	-- Dark overlay
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = sg

	-- Main panel
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0.85, 0, 0.80, 0)
	panel.Position = UDim2.new(0.075, 0, 0.10, 0)
	panel.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
	panel.BorderSizePixel = 0
	panel.Parent = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 200, 140)
	stroke.Thickness = 2
	stroke.Parent = panel

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "📦  YOUR BRAINROT BEINGS"
	title.TextColor3 = Color3.fromRGB(0, 255, 160)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = panel

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -44, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextScaled = true
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn

	-- Sort buttons
	local sortFrame = Instance.new("Frame")
	sortFrame.Size = UDim2.new(1, -20, 0, 32)
	sortFrame.Position = UDim2.new(0, 10, 0, 52)
	sortFrame.BackgroundTransparency = 1
	sortFrame.Parent = panel

	local sortOptions = {"Rarity", "Value", "Name"}
	for i, sortName in ipairs(sortOptions) do
		local btn = Instance.new("TextButton")
		btn.Name = "Sort_" .. sortName
		btn.Size = UDim2.new(0, 90, 1, 0)
		btn.Position = UDim2.new(0, (i-1) * 98, 0, 0)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
		btn.Text = sortName
		btn.TextColor3 = Color3.fromRGB(200, 200, 255)
		btn.TextScaled = true
		btn.Font = Enum.Font.Gotham
		btn.BorderSizePixel = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn
		btn.Parent = sortFrame
	end

	-- Scrolling card grid
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "CardScroll"
	scroll.Size = UDim2.new(1, -20, 1, -100)
	scroll.Position = UDim2.new(0, 10, 0, 92)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = panel

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 140, 0, 180)
	grid.CellPadding = UDim2.new(0, 10, 0, 10)
	grid.Parent = scroll

	return sg, panel, scroll, sortFrame, closeBtn
end

local invGui, invPanel, cardScroll, sortFrame, closeBtn = BuildInventoryGui()
local isOpen = false
local currentSort = "Rarity"
local cachedInventory = {}

-- ── Card builder ──────────────────────────────────────────────
local function BuildCard(item, scroll)
	local rarityColor = RarityColors[item.Rarity] or Color3.fromRGB(200, 200, 200)

	local card = Instance.new("Frame")
	card.Name = item.InstanceId
	card.Size = UDim2.new(0, 140, 0, 180)
	card.BackgroundColor3 = Color3.fromRGB(15, 15, 35)
	card.BorderSizePixel = 0
	card.Parent = scroll

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = rarityColor
	cardStroke.Thickness = 2
	card.UIStroke = cardStroke
	cardStroke.Parent = card

	-- Rarity badge
	local rarityBadge = Instance.new("Frame")
	rarityBadge.Size = UDim2.new(1, 0, 0, 20)
	rarityBadge.BackgroundColor3 = rarityColor
	rarityBadge.BorderSizePixel = 0
	rarityBadge.Parent = card

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 8)
	badgeCorner.Parent = rarityBadge

	local rarityText = Instance.new("TextLabel")
	rarityText.Size = UDim2.new(1, 0, 1, 0)
	rarityText.BackgroundTransparency = 1
	rarityText.Text = item.Rarity:upper()
	rarityText.TextColor3 = Color3.fromRGB(0, 0, 0)
	rarityText.TextScaled = true
	rarityText.Font = Enum.Font.GothamBold
	rarityText.Parent = rarityBadge

	-- Emoji icon
	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(1, 0, 0, 50)
	emoji.Position = UDim2.new(0, 0, 0, 22)
	emoji.BackgroundTransparency = 1
	emoji.Text = item.Emoji or "❓"
	emoji.TextScaled = true
	emoji.Parent = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -8, 0, 30)
	nameLabel.Position = UDim2.new(0, 4, 0, 74)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Value
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, -8, 0, 20)
	valueLabel.Position = UDim2.new(0, 4, 0, 106)
	valueLabel.BackgroundTransparency = 1
	local currentVal = math.floor(item.BaseValue * (item.Multiplier or 1.0))
	valueLabel.Text = "🪙 " .. currentVal
	valueLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	valueLabel.TextScaled = true
	valueLabel.Font = Enum.Font.Gotham
	valueLabel.Parent = card

	-- Sell button
	local sellBtn = Instance.new("TextButton")
	sellBtn.Size = UDim2.new(0.45, 0, 0, 26)
	sellBtn.Position = UDim2.new(0.03, 0, 1, -32)
	sellBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	sellBtn.Text = "SELL"
	sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	sellBtn.TextScaled = true
	sellBtn.Font = Enum.Font.GothamBold
	sellBtn.BorderSizePixel = 0
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 6)
	sc.Parent = sellBtn
	sellBtn.Parent = card

	-- Lab button
	local labBtn = Instance.new("TextButton")
	labBtn.Size = UDim2.new(0.45, 0, 0, 26)
	labBtn.Position = UDim2.new(0.52, 0, 1, -32)
	labBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 180)
	labBtn.Text = "LAB"
	labBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	labBtn.TextScaled = true
	labBtn.Font = Enum.Font.GothamBold
	labBtn.BorderSizePixel = 0
	local lc = Instance.new("UICorner")
	lc.CornerRadius = UDim.new(0, 6)
	lc.Parent = labBtn
	labBtn.Parent = card

	-- Sell handler
	sellBtn.MouseButton1Click:Connect(function()
		local ok, result = pcall(function()
			return SellBeing:InvokeServer(item.InstanceId)
		end)
		if ok and result then
			card:Destroy()
		end
	end)

	-- Lab handler
	labBtn.MouseButton1Click:Connect(function()
		local ok, result = pcall(function()
			return DoMutationLab:InvokeServer(item.InstanceId)
		end)
		if ok and result and result.Result then
			-- Refresh inventory to reflect change
			task.delay(0.5, function()
				if isOpen then
					RefreshInventory()
				end
			end)
		end
	end)

	return card
end

-- ── Sort helpers ──────────────────────────────────────────────
local RarityRank = { Common = 1, Rare = 2, Epic = 3, Cursed = 4, Void = 5 }

local SortFunctions = {
	Rarity = function(a, b) return (RarityRank[a.Rarity] or 0) > (RarityRank[b.Rarity] or 0) end,
	Value  = function(a, b)
		return (a.BaseValue * (a.Multiplier or 1)) > (b.BaseValue * (b.Multiplier or 1))
	end,
	Name   = function(a, b) return a.Name < b.Name end,
}

-- ── Refresh cards ─────────────────────────────────────────────
function RefreshInventory()
	local ok, items = pcall(function()
		return RequestInventory:InvokeServer()
	end)
	if not ok or not items then return end
	cachedInventory = items

	-- Clear existing cards
	for _, child in ipairs(cardScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	-- Sort
	local sorted = table.clone(items)
	table.sort(sorted, SortFunctions[currentSort])

	for _, item in ipairs(sorted) do
		BuildCard(item, cardScroll)
	end
end

-- ── Open / close ──────────────────────────────────────────────
local function OpenInventory()
	invGui.Enabled = true
	isOpen = true
	invPanel.Size = UDim2.new(0, 0, 0, 0)
	invPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	TweenService:Create(invPanel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size     = UDim2.new(0.85, 0, 0.80, 0),
		Position = UDim2.new(0.075, 0, 0.10, 0),
	}):Play()
	RefreshInventory()
end

local function CloseInventory()
	TweenService:Create(invPanel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size     = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
	task.delay(0.25, function()
		invGui.Enabled = false
		isOpen = false
	end)
end

if ToggleInventory then
	ToggleInventory.Event:Connect(function()
		if isOpen then CloseInventory() else OpenInventory() end
	end)
end

closeBtn.MouseButton1Click:Connect(CloseInventory)

-- Sort buttons
for _, btn in ipairs(sortFrame:GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			currentSort = btn.Name:gsub("Sort_", "")
			RefreshInventory()
		end)
	end
end

print("[InventoryClient] Loaded.")
