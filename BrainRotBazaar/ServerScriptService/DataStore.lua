-- ============================================================
-- DataStore (Script) — ServerScriptService
-- Saves and loads player data: inventory, coins, level, XP,
-- gacha pull history, and settings.
-- ============================================================

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local PlayerDataStore = DataStoreService:GetDataStore("BrainRotBazaar_v1")

-- ── In-memory session cache ───────────────────────────────────
local SessionData = {}

-- ── Default profile ───────────────────────────────────────────
local function DefaultProfile()
	return {
		Coins        = GameConfig.Economy.StartingCoins,
		Level        = 1,
		XP           = 0,
		Inventory    = {},         -- array of { Id = string, InstanceId = string }
		MaxSlots     = GameConfig.Inventory.DefaultMaxSlots,
		PullCount    = 0,          -- total gacha pulls
		PullHistory  = {},         -- last 20 pull results
		LastLogin    = 0,          -- os.time() of last session
		TotalTrades  = 0,
		MutationsSurvived = 0,
		Unlocks      = {},
	}
end

-- ── Load ─────────────────────────────────────────────────────
local function LoadPlayer(player)
	local key = "player_" .. player.UserId
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(key)
	end)

	if success and data then
		-- Merge saved data with defaults (forward-compatible)
		local profile = DefaultProfile()
		for k, v in pairs(data) do
			profile[k] = v
		end
		SessionData[player.UserId] = profile
	else
		SessionData[player.UserId] = DefaultProfile()
	end

	-- Daily login bonus
	local profile = SessionData[player.UserId]
	local now = os.time()
	if now - profile.LastLogin > 86400 then
		profile.Coins = profile.Coins + GameConfig.Economy.DailyLoginBonus
		profile.LastLogin = now
	end

	print("[DataStore] Loaded data for", player.Name)
end

-- ── Save ─────────────────────────────────────────────────────
local function SavePlayer(player)
	local profile = SessionData[player.UserId]
	if not profile then return end

	local key = "player_" .. player.UserId
	local success, err = pcall(function()
		PlayerDataStore:SetAsync(key, profile)
	end)

	if not success then
		warn("[DataStore] Failed to save", player.Name, err)
	else
		print("[DataStore] Saved data for", player.Name)
	end
end

-- ── Public API ────────────────────────────────────────────────
local DataModule = {}

function DataModule.Get(player)
	return SessionData[player.UserId]
end

function DataModule.Save(player)
	SavePlayer(player)
end

function DataModule.AddCoins(player, amount)
	local p = SessionData[player.UserId]
	if p then p.Coins = math.max(0, p.Coins + amount) end
end

function DataModule.AddXP(player, amount)
	local p = SessionData[player.UserId]
	if not p then return end
	p.XP = p.XP + amount

	-- Level up loop
	local cfg = GameConfig.Progression
	while p.Level < cfg.MaxLevel do
		local needed = math.floor(cfg.XPBase * (p.Level ^ 1.5))
		if p.XP >= needed then
			p.XP = p.XP - needed
			p.Level = p.Level + 1
			-- Check unlock
			local unlock = cfg.Unlocks[p.Level]
			if unlock then
				table.insert(p.Unlocks, unlock)
				print("[DataStore] Player", player.Name, "unlocked:", unlock)
			end
		else
			break
		end
	end
end

function DataModule.AddToInventory(player, beingId)
	local p = SessionData[player.UserId]
	if not p then return false end
	if #p.Inventory >= p.MaxSlots then return false end

	local instanceId = beingId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
	table.insert(p.Inventory, { Id = beingId, InstanceId = instanceId })
	return instanceId
end

function DataModule.RemoveFromInventory(player, instanceId)
	local p = SessionData[player.UserId]
	if not p then return false end
	for i, item in ipairs(p.Inventory) do
		if item.InstanceId == instanceId then
			table.remove(p.Inventory, i)
			return true
		end
	end
	return false
end

function DataModule.HasInInventory(player, instanceId)
	local p = SessionData[player.UserId]
	if not p then return false end
	for _, item in ipairs(p.Inventory) do
		if item.InstanceId == instanceId then return true end
	end
	return false
end

-- ── Auto-save every 60 seconds ────────────────────────────────
local function AutoSaveLoop()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			SavePlayer(player)
		end
	end
end

-- ── Hooks ─────────────────────────────────────────────────────
Players.PlayerAdded:Connect(LoadPlayer)

Players.PlayerRemoving:Connect(function(player)
	SavePlayer(player)
	SessionData[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		SavePlayer(player)
	end
end)

task.spawn(AutoSaveLoop)

return DataModule
