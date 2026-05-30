-- ============================================================
-- TradeClient (LocalScript) — StarterPlayerScripts
-- Handles: sending trade requests, offer/counter-offer UI,
-- mutation FX (screen shake + particle-like flash), result popup.
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TradeRequest   = ReplicatedStorage:WaitForChild("TradeRequest")
local TradeOffer     = ReplicatedStorage:WaitForChild("TradeOffer")
local TradeResponse  = ReplicatedStorage:WaitForChild("TradeResponse")
local TradeResult    = ReplicatedStorage:WaitForChild("TradeResult")
local RequestInventory = ReplicatedStorage:WaitForChild("RequestInventory")

-- ── Build Trade GUI ───────────────────────────────────────────
local function BuildTradeGui()
	local sg = Instance.new("ScreenGui")
	sg.Name = "TradeGui"
	sg.ResetOnSpawn = false
	sg.Enabled = false
	sg.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0.70, 0, 0.65, 0)
	panel.Position = UDim2.new(0.15, 0, 0.175, 0)
	panel.BackgroundColor3 = Color3.fromRGB(8, 8, 22)
	panel.BorderSizePixel = 0
	panel.Parent = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 100, 200)
	stroke.Thickness = 2
	stroke.Parent = panel

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 36)
	title.Position = UDim2.new(0, 0, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "⚠️  TRADE PENDING — MUTATION RISK: 15%"
	title.TextColor3 = Color3.fromRGB(255, 200, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = panel

	-- Your offer (left)
	local yourSide = Instance.new("Frame")
	yourSide.Name = "YourSide"
	yourSide.Size = UDim2.new(0.45, 0, 0.75, 0)
	yourSide.Position = UDim2.new(0.02, 0, 0.12, 0)
	yourSide.BackgroundColor3 = Color3.fromRGB(12, 12, 30)
	yourSide.BorderSizePixel = 0
	yourSide.Parent = panel

	local yc = Instance.new("UICorner")
	yc.CornerRadius = UDim.new(0, 8)
	yc.Parent = yourSide

	local yourTitle = Instance.new("TextLabel")
	yourTitle.Size = UDim2.new(1, 0, 0, 28)
	yourTitle.BackgroundTransparency = 1
	yourTitle.Text = "YOUR OFFER"
	yourTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
	yourTitle.TextScaled = true
	yourTitle.Font = Enum.Font.GothamBold
	yourTitle.Parent = yourSide

	local yourScroll = Instance.new("ScrollingFrame")
	yourScroll.Name = "YourScroll"
	yourScroll.Size = UDim2.new(1, -8, 1, -32)
	yourScroll.Position = UDim2.new(0, 4, 0, 30)
	yourScroll.BackgroundTransparency = 1
	yourScroll.ScrollBarThickness = 4
	yourScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	yourScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	yourScroll.Parent = yourSide

	local yourLayout = Instance.new("UIListLayout")
	yourLayout.SortOrder = Enum.SortOrder.LayoutOrder
	yourLayout.Padding = UDim.new(0, 4)
	yourLayout.Parent = yourScroll

	-- Their offer (right)
	local theirSide = Instance.new("Frame")
	theirSide.Name = "TheirSide"
	theirSide.Size = UDim2.new(0.45, 0, 0.75, 0)
	theirSide.Position = UDim2.new(0.53, 0, 0.12, 0)
	theirSide.BackgroundColor3 = Color3.fromRGB(12, 12, 30)
	theirSide.BorderSizePixel = 0
	theirSide.Parent = panel

	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 8)
	tc.Parent = theirSide

	local theirTitle = Instance.new("TextLabel")
	theirTitle.Name = "TheirTitle"
	theirTitle.Size = UDim2.new(1, 0, 0, 28)
	theirTitle.BackgroundTransparency = 1
	theirTitle.Text = "THEIR OFFER"
	theirTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
	theirTitle.TextScaled = true
	theirTitle.Font = Enum.Font.GothamBold
	theirTitle.Parent = theirSide

	local theirScroll = Instance.new("ScrollingFrame")
	theirScroll.Name = "TheirScroll"
	theirScroll.Size = UDim2.new(1, -8, 1, -32)
	theirScroll.Position = UDim2.new(0, 4, 0, 30)
	theirScroll.BackgroundTransparency = 1
	theirScroll.ScrollBarThickness = 4
	theirScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	theirScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	theirScroll.Parent = theirSide

	local theirLayout = Instance.new("UIListLayout")
	theirLayout.SortOrder = Enum.SortOrder.LayoutOrder
	theirLayout.Padding = UDim.new(0, 4)
	theirLayout.Parent = theirScroll

	-- Accept / Decline buttons
	local acceptBtn = Instance.new("TextButton")
	acceptBtn.Name = "AcceptBtn"
	acceptBtn.Size = UDim2.new(0.30, 0, 0, 36)
	acceptBtn.Position = UDim2.new(0.36, 0, 0.90, 0)
	acceptBtn.BackgroundColor3 = Color3.fromRGB(30, 160, 80)
	acceptBtn.Text = "✔  ACCEPT"
	acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	acceptBtn.TextScaled = true
	acceptBtn.Font = Enum.Font.GothamBold
	acceptBtn.BorderSizePixel = 0
	local ac = Instance.new("UICorner")
	ac.CornerRadius = UDim.new(0, 8)
	ac.Parent = acceptBtn
	acceptBtn.Parent = panel

	local declineBtn = Instance.new("TextButton")
	declineBtn.Name = "DeclineBtn"
	declineBtn.Size = UDim2.new(0.30, 0, 0, 36)
	declineBtn.Position = UDim2.new(0.04, 0, 0.90, 0)
	declineBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	declineBtn.Text = "✕  DECLINE"
	declineBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	declineBtn.TextScaled = true
	declineBtn.Font = Enum.Font.GothamBold
	declineBtn.BorderSizePixel = 0
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0, 8)
	dc.Parent = declineBtn
	declineBtn.Parent = panel

	return sg, panel, yourScroll, theirScroll, acceptBtn, declineBtn, theirSide
end

local tradeGui, tradePanel, yourScroll, theirScroll, acceptBtn, declineBtn, theirSide =
	BuildTradeGui()

-- ── Result popup ──────────────────────────────────────────────
local function ShowResultPopup(msg, isGood)
	local sg = playerGui:FindFirstChild("TradeResultGui")
	if sg then sg:Destroy() end

	sg = Instance.new("ScreenGui")
	sg.Name = "TradeResultGui"
	sg.ResetOnSpawn = false
	sg.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.5, 0, 0, 80)
	frame.Position = UDim2.new(0.25, 0, 0.4, 0)
	frame.BackgroundColor3 = isGood and Color3.fromRGB(20, 120, 60) or Color3.fromRGB(120, 20, 20)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = sg

	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 10)
	fc.Parent = frame

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = msg
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextScaled = true
	lbl.TextWrapped = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = frame

	-- Slide in from top
	frame.Position = UDim2.new(0.25, 0, -0.15, 0)
	TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.25, 0, 0.4, 0)
	}):Play()

	task.delay(3.5, function()
		TweenService:Create(frame, TweenInfo.new(0.3), {
			Position = UDim2.new(0.25, 0, -0.15, 0)
		}):Play()
		task.delay(0.35, function() sg:Destroy() end)
	end)
end

-- ── Screen shake (mutation FX) ────────────────────────────────
local function ScreenShake()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local originalCFrame = camera.CFrame
	for i = 1, 6 do
		local offset = Vector3.new(
			math.random(-1, 1) * 0.3,
			math.random(-1, 1) * 0.3,
			0
		)
		camera.CFrame = camera.CFrame + offset
		task.wait(0.05)
	end
	camera.CFrame = originalCFrame
end

-- ── Mutation flash overlay ────────────────────────────────────
local function MutationFlash(color)
	local sg = Instance.new("ScreenGui")
	sg.Name = "MutationFlash"
	sg.ResetOnSpawn = false
	sg.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = color or Color3.fromRGB(200, 0, 255)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Parent = sg

	TweenService:Create(frame, TweenInfo.new(0.6), {
		BackgroundTransparency = 1
	}):Play()

	task.delay(0.7, function() sg:Destroy() end)
end

-- ── Pending trade state ───────────────────────────────────────
local pendingTradeKey = nil
local selectedOfferItems = {}  -- InstanceIds the local player is offering

-- ── Add item row to scroll ────────────────────────────────────
local function AddItemRow(scrollFrame, item, selectable)
	local row = Instance.new("Frame")
	row.Name = item.InstanceId
	row.Size = UDim2.new(1, -8, 0, 36)
	row.BackgroundColor3 = Color3.fromRGB(20, 20, 45)
	row.BorderSizePixel = 0
	row.Parent = scrollFrame

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 6)
	rc.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, selectable and -40 or -8, 1, 0)
	lbl.Position = UDim2.new(0, 4, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = (item.Emoji or "?") .. " " .. item.Name .. " [" .. item.Rarity .. "]"
	lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	lbl.TextScaled = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Font = Enum.Font.Gotham
	lbl.Parent = row

	if selectable then
		local checkBtn = Instance.new("TextButton")
		checkBtn.Size = UDim2.new(0, 32, 0, 28)
		checkBtn.Position = UDim2.new(1, -36, 0.5, -14)
		checkBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
		checkBtn.Text = "+"
		checkBtn.TextColor3 = Color3.fromRGB(0, 255, 160)
		checkBtn.TextScaled = true
		checkBtn.Font = Enum.Font.GothamBold
		checkBtn.BorderSizePixel = 0
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 4)
		cc.Parent = checkBtn
		checkBtn.Parent = row

		local selected = false
		checkBtn.MouseButton1Click:Connect(function()
			selected = not selected
			if selected then
				table.insert(selectedOfferItems, item.InstanceId)
				checkBtn.Text = "✓"
				checkBtn.BackgroundColor3 = Color3.fromRGB(30, 160, 80)
			else
				for i, v in ipairs(selectedOfferItems) do
					if v == item.InstanceId then
						table.remove(selectedOfferItems, i)
						break
					end
				end
				checkBtn.Text = "+"
				checkBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
			end
		end)
	end
end

-- ── Incoming trade offer ──────────────────────────────────────
TradeOffer.OnClientEvent:Connect(function(offerData)
	pendingTradeKey = offerData.TradeKey
	selectedOfferItems = {}

	-- Clear sides
	for _, c in ipairs(yourScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for _, c in ipairs(theirScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	-- Update title with trader name
	local theirTitleLabel = theirSide:FindFirstChildWhichIsA("TextLabel")
	if theirTitleLabel then
		theirTitleLabel.Text = offerData.InitiatorName:upper() .. "'S OFFER"
	end

	-- Show their offered items
	for _, iid in ipairs(offerData.OfferedItems) do
		AddItemRow(theirScroll, { InstanceId = iid, Name = iid, Emoji = "❓", Rarity = "?" }, false)
	end

	-- Load local inventory for counter-offer selection
	local ok, items = pcall(function()
		return RequestInventory:InvokeServer()
	end)
	if ok and items then
		for _, item in ipairs(items) do
			AddItemRow(yourScroll, item, true)
		end
	end

	-- Show GUI
	tradeGui.Enabled = true
	tradePanel.Size = UDim2.new(0, 0, 0, 0)
	tradePanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	TweenService:Create(tradePanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.70, 0, 0.65, 0),
		Position = UDim2.new(0.15, 0, 0.175, 0),
	}):Play()
end)

-- ── Accept / Decline ──────────────────────────────────────────
acceptBtn.MouseButton1Click:Connect(function()
	if not pendingTradeKey then return end
	TradeResponse:FireServer(pendingTradeKey, true, selectedOfferItems)
	TweenService:Create(tradePanel, TweenInfo.new(0.2), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
	task.delay(0.25, function() tradeGui.Enabled = false end)
	pendingTradeKey = nil
end)

declineBtn.MouseButton1Click:Connect(function()
	if not pendingTradeKey then return end
	TradeResponse:FireServer(pendingTradeKey, false, {})
	TweenService:Create(tradePanel, TweenInfo.new(0.2), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
	task.delay(0.25, function() tradeGui.Enabled = false end)
	pendingTradeKey = nil
end)

-- ── Trade result ──────────────────────────────────────────────
TradeResult.OnClientEvent:Connect(function(result)
	if result.MutationType then
		ScreenShake()
		local flashColors = {
			Upgrade    = Color3.fromRGB(100, 200, 255),
			Fusion     = Color3.fromRGB(200, 100, 255),
			Devolution = Color3.fromRGB(255, 150, 50),
			Explosion  = Color3.fromRGB(255, 50, 50),
			Jackpot    = Color3.fromRGB(255, 220, 50),
		}
		MutationFlash(flashColors[result.MutationType])
	end
	ShowResultPopup(result.Message, result.Success)
end)

print("[TradeClient] Loaded.")
