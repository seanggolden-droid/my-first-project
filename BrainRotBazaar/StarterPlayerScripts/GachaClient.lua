-- ============================================================
-- GachaClient (LocalScript) — StarterPlayerScripts
-- "The Gacha Hole" UI — pull animation, pity tracker,
-- pull history display.
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DoGachaPull    = ReplicatedStorage:WaitForChild("DoGachaPull")

-- ── Open/close signal (fire from proximity prompt or NPC) ─────
local OpenGacha = ReplicatedStorage:FindFirstChild("OpenGacha")
if not OpenGacha then
	OpenGacha = Instance.new("BindableEvent")
	OpenGacha.Name = "OpenGacha"
	OpenGacha.Parent = ReplicatedStorage
end

-- ── Rarity colors and sounds (placeholder SFX paths) ─────────
local RarityColors = {
	Common  = Color3.fromRGB(180, 180, 180),
	Rare    = Color3.fromRGB(80, 140, 255),
	Epic    = Color3.fromRGB(180, 80, 255),
	Cursed  = Color3.fromRGB(255, 60, 60),
	Void    = Color3.fromRGB(20, 255, 180),
}
-- SFX Note: add Sound objects inside the GUI or workspace and play here
-- e.g. Common pull → short "bloop", Void pull → fanfare

-- ── Build Gacha GUI ───────────────────────────────────────────
local function BuildGachaGui()
	local sg = Instance.new("ScreenGui")
	sg.Name = "GachaGui"
	sg.ResetOnSpawn = false
	sg.Enabled = false
	sg.Parent = playerGui

	-- Dark overlay
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.45
	overlay.BorderSizePixel = 0
	overlay.Parent = sg

	-- Main panel
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0.55, 0, 0.70, 0)
	panel.Position = UDim2.new(0.225, 0, 0.15, 0)
	panel.BackgroundColor3 = Color3.fromRGB(5, 5, 18)
	panel.BorderSizePixel = 0
	panel.Parent = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 180, 0)
	stroke.Thickness = 2
	stroke.Parent = panel

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "🕳️  THE GACHA HOLE"
	title.TextColor3 = Color3.fromRGB(255, 220, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0, 22)
	subtitle.Position = UDim2.new(0, 0, 0, 50)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "50 🪙 per pull  •  Rare+ every 10  •  Epic+ every 50"
	subtitle.TextColor3 = Color3.fromRGB(160, 160, 200)
	subtitle.TextScaled = true
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = panel

	-- Reveal area
	local revealFrame = Instance.new("Frame")
	revealFrame.Name = "RevealFrame"
	revealFrame.Size = UDim2.new(0.7, 0, 0.35, 0)
	revealFrame.Position = UDim2.new(0.15, 0, 0.14, 0)
	revealFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
	revealFrame.BackgroundTransparency = 0
	revealFrame.BorderSizePixel = 0
	revealFrame.Parent = panel

	local revealCorner = Instance.new("UICorner")
	revealCorner.CornerRadius = UDim.new(0, 12)
	revealCorner.Parent = revealFrame

	local revealStroke = Instance.new("UIStroke")
	revealStroke.Name = "RevealStroke"
	revealStroke.Color = Color3.fromRGB(80, 80, 80)
	revealStroke.Thickness = 2
	revealStroke.Parent = revealFrame

	local emojiLabel = Instance.new("TextLabel")
	emojiLabel.Name = "EmojiLabel"
	emojiLabel.Size = UDim2.new(1, 0, 0.5, 0)
	emojiLabel.Position = UDim2.new(0, 0, 0.05, 0)
	emojiLabel.BackgroundTransparency = 1
	emojiLabel.Text = "❓"
	emojiLabel.TextScaled = true
	emojiLabel.Parent = revealFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0, 28)
	nameLabel.Position = UDim2.new(0, 5, 0.58, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Pull to find out..."
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = revealFrame

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, -10, 0, 22)
	rarityLabel.Position = UDim2.new(0, 5, 0.82, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = ""
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.Parent = revealFrame

	-- Pull button
	local pullBtn = Instance.new("TextButton")
	pullBtn.Name = "PullBtn"
	pullBtn.Size = UDim2.new(0.55, 0, 0, 44)
	pullBtn.Position = UDim2.new(0.225, 0, 0.54, 0)
	pullBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
	pullBtn.Text = "🎰  PULL  (50 🪙)"
	pullBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	pullBtn.TextScaled = true
	pullBtn.Font = Enum.Font.GothamBold
	pullBtn.BorderSizePixel = 0
	pullBtn.Parent = panel

	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 10)
	pc.Parent = pullBtn

	-- Pity tracker
	local pityLabel = Instance.new("TextLabel")
	pityLabel.Name = "PityLabel"
	pityLabel.Size = UDim2.new(1, -20, 0, 22)
	pityLabel.Position = UDim2.new(0, 10, 0.67, 0)
	pityLabel.BackgroundTransparency = 1
	pityLabel.Text = "Pulls until guaranteed Rare: 10"
	pityLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
	pityLabel.TextScaled = true
	pityLabel.Font = Enum.Font.Gotham
	pityLabel.Parent = panel

	-- Pull history
	local historyTitle = Instance.new("TextLabel")
	historyTitle.Size = UDim2.new(1, -20, 0, 20)
	historyTitle.Position = UDim2.new(0, 10, 0.74, 0)
	historyTitle.BackgroundTransparency = 1
	historyTitle.Text = "RECENT PULLS"
	historyTitle.TextColor3 = Color3.fromRGB(120, 120, 180)
	historyTitle.TextScaled = true
	historyTitle.Font = Enum.Font.GothamBold
	historyTitle.Parent = panel

	local historyScroll = Instance.new("ScrollingFrame")
	historyScroll.Name = "HistoryScroll"
	historyScroll.Size = UDim2.new(1, -20, 0.18, 0)
	historyScroll.Position = UDim2.new(0, 10, 0.80, 0)
	historyScroll.BackgroundTransparency = 1
	historyScroll.ScrollBarThickness = 4
	historyScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	historyScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	historyScroll.Parent = panel

	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection = Enum.FillDirection.Horizontal
	hLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hLayout.Padding = UDim.new(0, 6)
	hLayout.Parent = historyScroll

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -42, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextScaled = true
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 0
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent = closeBtn
	closeBtn.Parent = panel

	return sg, panel, pullBtn, closeBtn, emojiLabel, nameLabel, rarityLabel, revealFrame, pityLabel, historyScroll
end

local gachaGui, gachaPanel, pullBtn, closeBtn,
      emojiLabel, nameLabel, rarityLabel, revealFrame, pityLabel, historyScroll =
	BuildGachaGui()

-- ── History pills ──────────────────────────────────────────────
local function AddHistoryPill(beingData)
	local color = RarityColors[beingData.Rarity] or Color3.fromRGB(150, 150, 150)
	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(0, 80, 1, -4)
	pill.BackgroundColor3 = color
	pill.BackgroundTransparency = 0.4
	pill.BorderSizePixel = 0
	pill.LayoutOrder = -os.clock() -- newest first
	pill.Parent = historyScroll

	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 6)
	pc.Parent = pill

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -4, 1, 0)
	lbl.Position = UDim2.new(0, 2, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = (beingData.Emoji or "?") .. "\n" .. beingData.Name
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextScaled = true
	lbl.TextWrapped = true
	lbl.Font = Enum.Font.Gotham
	lbl.Parent = pill
end

-- ── Pull animation ────────────────────────────────────────────
local pullCooldown = false
local localPullCount = 0

pullBtn.MouseButton1Click:Connect(function()
	if pullCooldown then return end
	pullCooldown = true
	pullBtn.Text = "..."
	pullBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 0)

	-- Suspense: cycle question marks
	emojiLabel.Text = "❓"
	nameLabel.Text  = "Reaching into the void..."
	rarityLabel.Text = ""
	revealFrame.UIStroke.Color = Color3.fromRGB(80, 80, 80)

	local spinEmoji = {"❓","🌀","💫","✨","⚡","🌀"}
	for _, e in ipairs(spinEmoji) do
		emojiLabel.Text = e
		task.wait(0.12)
	end

	-- Invoke server
	local ok, result = pcall(function()
		return DoGachaPull:InvokeServer()
	end)

	if ok and result and result.Name then
		localPullCount = localPullCount + 1
		local rarityColor = RarityColors[result.Rarity] or Color3.fromRGB(200, 200, 200)

		-- Reveal flash
		revealFrame.BackgroundColor3 = rarityColor
		TweenService:Create(revealFrame, TweenInfo.new(0.5), {
			BackgroundColor3 = Color3.fromRGB(15, 10, 30)
		}):Play()
		revealFrame.UIStroke.Color = rarityColor

		emojiLabel.Text  = result.Emoji or "⭐"
		nameLabel.Text   = result.Name
		nameLabel.TextColor3 = rarityColor
		rarityLabel.Text  = result.Rarity:upper()
		rarityLabel.TextColor3 = rarityColor

		-- Scale animation on reveal frame
		revealFrame.Size = UDim2.new(0.5, 0, 0.25, 0)
		revealFrame.Position = UDim2.new(0.25, 0, 0.18, 0)
		TweenService:Create(revealFrame,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.7, 0, 0.35, 0),
			Position = UDim2.new(0.15, 0, 0.14, 0),
		}):Play()

		AddHistoryPill(result)

		-- Update pity label
		local toNextRare = 10 - (localPullCount % 10)
		pityLabel.Text = "Pulls until guaranteed Rare: " .. toNextRare
	else
		nameLabel.Text = result or "Something went wrong."
		nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	end

	task.wait(0.8)
	pullBtn.Text = "🎰  PULL  (50 🪙)"
	pullBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
	pullCooldown = false
end)

-- ── Open / close ──────────────────────────────────────────────
local isOpen = false

local function OpenGachaGui()
	isOpen = true
	gachaGui.Enabled = true
	gachaPanel.Size = UDim2.new(0, 0, 0, 0)
	gachaPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	TweenService:Create(gachaPanel,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.55, 0, 0.70, 0),
		Position = UDim2.new(0.225, 0, 0.15, 0),
	}):Play()
end

local function CloseGachaGui()
	TweenService:Create(gachaPanel, TweenInfo.new(0.2), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
	task.delay(0.25, function()
		gachaGui.Enabled = false
		isOpen = false
	end)
end

OpenGacha.Event:Connect(function()
	if isOpen then CloseGachaGui() else OpenGachaGui() end
end)
closeBtn.MouseButton1Click:Connect(CloseGachaGui)

print("[GachaClient] Loaded.")
