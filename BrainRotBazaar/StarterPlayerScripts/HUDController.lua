-- ============================================================
-- HUDController (LocalScript) — StarterPlayerScripts
-- Main HUD: Slop Coins counter, level badge, mutation ticker,
-- inventory button, and animated open/close menus.
-- ============================================================

local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

local UpdateHUD       = ReplicatedStorage:WaitForChild("UpdateHUD")
local MutationTicker  = ReplicatedStorage:WaitForChild("MutationTicker")
local MarketUpdate    = ReplicatedStorage:WaitForChild("MarketUpdate")
local RequestProfile  = ReplicatedStorage:WaitForChild("RequestProfile")

-- ── Build main HUD ScreenGui ──────────────────────────────────
local function CreateHUDGui()
	local sg = Instance.new("ScreenGui")
	sg.Name = "BrainRotHUD"
	sg.ResetOnSpawn = false
	sg.Parent = playerGui

	-- ── Background bar (top) ──────────────────────────────────
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 52)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
	topBar.BackgroundTransparency = 0.15
	topBar.BorderSizePixel = 0
	topBar.Parent = sg

	-- Neon bottom border
	local border = Instance.new("Frame")
	border.Size = UDim2.new(1, 0, 0, 2)
	border.Position = UDim2.new(0, 0, 1, -2)
	border.BackgroundColor3 = Color3.fromRGB(0, 255, 160)
	border.BorderSizePixel = 0
	border.Parent = topBar

	-- ── Slop Coins counter ────────────────────────────────────
	local coinFrame = Instance.new("Frame")
	coinFrame.Size = UDim2.new(0, 160, 0, 40)
	coinFrame.Position = UDim2.new(0, 10, 0, 6)
	coinFrame.BackgroundTransparency = 1
	coinFrame.Parent = topBar

	local coinIcon = Instance.new("TextLabel")
	coinIcon.Size = UDim2.new(0, 30, 1, 0)
	coinIcon.Position = UDim2.new(0, 0, 0, 0)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "🪙"
	coinIcon.TextScaled = true
	coinIcon.Parent = coinFrame

	local coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinLabel"
	coinLabel.Size = UDim2.new(1, -35, 1, 0)
	coinLabel.Position = UDim2.new(0, 35, 0, 0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.Text = "0"
	coinLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.TextScaled = true
	coinLabel.Font = Enum.Font.GothamBold
	-- Glitch shadow offset
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(200, 100, 0)
	uiStroke.Thickness = 1
	uiStroke.Parent = coinLabel
	coinLabel.Parent = coinFrame

	-- ── Level badge ───────────────────────────────────────────
	local levelBadge = Instance.new("Frame")
	levelBadge.Name = "LevelBadge"
	levelBadge.Size = UDim2.new(0, 80, 0, 40)
	levelBadge.Position = UDim2.new(0.5, -40, 0, 6)
	levelBadge.BackgroundColor3 = Color3.fromRGB(80, 20, 160)
	levelBadge.BorderSizePixel = 0
	levelBadge.Parent = topBar

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = levelBadge

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, 0, 1, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "LV 1"
	levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	levelLabel.TextScaled = true
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.Parent = levelBadge

	-- ── Inventory button ──────────────────────────────────────
	local invBtn = Instance.new("TextButton")
	invBtn.Name = "InventoryButton"
	invBtn.Size = UDim2.new(0, 90, 0, 40)
	invBtn.Position = UDim2.new(1, -100, 0, 6)
	invBtn.BackgroundColor3 = Color3.fromRGB(20, 180, 120)
	invBtn.Text = "📦 BAG"
	invBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	invBtn.TextScaled = true
	invBtn.Font = Enum.Font.GothamBold
	invBtn.BorderSizePixel = 0
	invBtn.Parent = topBar

	local invCorner = Instance.new("UICorner")
	invCorner.CornerRadius = UDim.new(0, 8)
	invCorner.Parent = invBtn

	-- ── Mutation ticker (scrolling bottom bar) ─────────────────
	local tickerBg = Instance.new("Frame")
	tickerBg.Name = "TickerBG"
	tickerBg.Size = UDim2.new(1, 0, 0, 28)
	tickerBg.Position = UDim2.new(0, 0, 1, -28)
	tickerBg.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
	tickerBg.BackgroundTransparency = 0.2
	tickerBg.BorderSizePixel = 0
	tickerBg.Parent = sg

	local tickerLabel = Instance.new("TextLabel")
	tickerLabel.Name = "TickerLabel"
	tickerLabel.Size = UDim2.new(2, 0, 1, 0)
	tickerLabel.Position = UDim2.new(1, 0, 0, 0)
	tickerLabel.BackgroundTransparency = 1
	tickerLabel.Text = "⚡ Welcome to BrainRot Bazaar: The Cursed Marketplace ⚡"
	tickerLabel.TextColor3 = Color3.fromRGB(0, 255, 160)
	tickerLabel.TextXAlignment = Enum.TextXAlignment.Left
	tickerLabel.TextScaled = false
	tickerLabel.TextSize = 14
	tickerLabel.Font = Enum.Font.Code
	tickerLabel.Parent = tickerBg

	return sg, coinLabel, levelLabel, tickerLabel, invBtn
end

local hud, coinLabel, levelLabel, tickerLabel, invBtn = CreateHUDGui()

-- ── Ticker scroll animation ───────────────────────────────────
local tickerQueue = {}
local tickerRunning = false

local function RunTicker()
	if tickerRunning then return end
	tickerRunning = true
	task.spawn(function()
		while #tickerQueue > 0 do
			local msg = table.remove(tickerQueue, 1)
			tickerLabel.Text = msg
			tickerLabel.Position = UDim2.new(1, 0, 0, 0)
			local tween = TweenService:Create(tickerLabel,
				TweenInfo.new(8, Enum.EasingStyle.Linear),
				{ Position = UDim2.new(-1, 0, 0, 0) }
			)
			tween:Play()
			tween.Completed:Wait()
		end
		tickerRunning = false
	end)
end

local function AddTicker(msg)
	table.insert(tickerQueue, msg)
	RunTicker()
end

-- ── HUD update ────────────────────────────────────────────────
local function RefreshHUD(data)
	if data.Coins ~= nil then
		-- Animate coin label
		local target = tostring(data.Coins)
		local tween = TweenService:Create(coinLabel,
			TweenInfo.new(0.3),
			{ TextTransparency = 0 }
		)
		tween:Play()
		coinLabel.Text = target
	end
	if data.Level ~= nil then
		levelLabel.Text = "LV " .. data.Level
	end
end

UpdateHUD.OnClientEvent:Connect(RefreshHUD)
MutationTicker.OnClientEvent:Connect(AddTicker)

-- ── Initial load ──────────────────────────────────────────────
task.spawn(function()
	local ok, profile = pcall(function()
		return RequestProfile:InvokeServer()
	end)
	if ok and profile then
		RefreshHUD(profile)
	end
end)

-- ── Inventory button → fire InventoryClient ───────────────────
invBtn.MouseButton1Click:Connect(function()
	-- Signal the InventoryClient to open/close
	local invEvent = ReplicatedStorage:FindFirstChild("ToggleInventory")
	if not invEvent then
		invEvent = Instance.new("BindableEvent")
		invEvent.Name = "ToggleInventory"
		invEvent.Parent = ReplicatedStorage
	end
	invEvent:Fire()
end)

-- Hover glow effect
invBtn.MouseEnter:Connect(function()
	TweenService:Create(invBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(30, 220, 150)
	}):Play()
end)
invBtn.MouseLeave:Connect(function()
	TweenService:Create(invBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(20, 180, 120)
	}):Play()
end)

print("[HUDController] Loaded.")
