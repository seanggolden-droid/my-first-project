-- ============================================================
-- GameManager (Script) — ServerScriptService
-- Handles: economy ticks, passive income, in-game time,
-- leaderboard updates, and market price fluctuation.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local GameConfig  = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BeingData   = require(ReplicatedStorage:WaitForChild("BeingData"))
local DataStore   = require(script.Parent:WaitForChild("DataStore"))

-- ── RemoteEvents setup ────────────────────────────────────────
-- Create RemoteEvents in ReplicatedStorage if not present
local function GetOrCreate(parent, className, name)
	local obj = parent:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = parent
	end
	return obj
end

local RE = ReplicatedStorage
local UpdateHUD         = GetOrCreate(RE, "RemoteEvent",    "UpdateHUD")
local MutationTicker    = GetOrCreate(RE, "RemoteEvent",    "MutationTicker")
local MarketUpdate      = GetOrCreate(RE, "RemoteEvent",    "MarketUpdate")
local RequestInventory  = GetOrCreate(RE, "RemoteFunction", "RequestInventory")
local RequestProfile    = GetOrCreate(RE, "RemoteFunction", "RequestProfile")

-- ── Market state ─────────────────────────────────────────────
-- Maps beingId → current multiplier (1.0 = base value)
local MarketMultipliers = {}
local CirculationCount  = {}  -- beingId → total copies owned across all players

local function InitMarket()
	for _, being in ipairs(BeingData.Beings) do
		MarketMultipliers[being.Id] = 1.0
		CirculationCount[being.Id]  = 0
	end
end

local function RecalcCirculation()
	-- Reset
	for id in pairs(CirculationCount) do
		CirculationCount[id] = 0
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = DataStore.Get(player)
		if profile then
			for _, item in ipairs(profile.Inventory) do
				CirculationCount[item.Id] = (CirculationCount[item.Id] or 0) + 1
			end
		end
	end
end

local function TickMarket()
	RecalcCirculation()
	local maxFluc = GameConfig.Economy.PriceFluctuationMax
	local inflPer = GameConfig.Economy.InflationPerUnit

	for _, being in ipairs(BeingData.Beings) do
		local id = being.Id
		-- Random fluctuation
		local swing = (math.random() * 2 - 1) * maxFluc
		-- Inflation penalty
		local copies = CirculationCount[id] or 0
		local inflation = copies * inflPer

		MarketMultipliers[id] = math.max(0.1, (MarketMultipliers[id] or 1.0) + swing - inflation)
	end

	-- Broadcast new prices to all clients
	MarketUpdate:FireAllClients(MarketMultipliers)
	print("[GameManager] Market ticked.")
end

-- ── In-game clock ────────────────────────────────────────────
local GameDayLength = GameConfig.InGame.DayLengthSeconds
local GameStartTime = os.clock()
local function GetInGameDay()
	local elapsed = os.clock() - GameStartTime
	return math.floor(elapsed / GameDayLength) % 7  -- 0=Sunday … 6=Saturday
end
-- Day 2 = Tuesday
local function IsTuesday()
	return GetInGameDay() == 2
end

-- ── Passive income loop ───────────────────────────────────────
local PassiveTimers = {}  -- userId → { lastVoidHamster, lastMumble, ... }

local function InitPassives(player)
	PassiveTimers[player.UserId] = {
		lastVoidHamster = os.clock(),
		lastMumble      = os.clock(),
		lastNumberman   = os.clock(),
		lastGlutchAura  = os.clock(),
		lastVoidAura    = os.clock(),
	}
end

local function HasBeing(profile, beingId)
	for _, item in ipairs(profile.Inventory) do
		if item.Id == beingId then return true end
	end
	return false
end

local function ProcessPassives(player)
	local profile = DataStore.Get(player)
	if not profile then return end
	local t = PassiveTimers[player.UserId]
	if not t then return end
	local now = os.clock()
	local cfg  = GameConfig.Passives
	local dirty = false

	-- Void Hamster: +1 coin every 30s
	if HasBeing(profile, "void_hamster") or HasBeing(profile, "void_hamster_ascended") then
		if now - t.lastVoidHamster >= cfg.VoidHamsterInterval then
			DataStore.AddCoins(player, 1)
			t.lastVoidHamster = now
			dirty = true
		end
	end

	-- Mumble Cube: +1 coin every 60s
	if HasBeing(profile, "mumble_cube") then
		if now - t.lastMumble >= cfg.MumbleCubeInterval then
			DataStore.AddCoins(player, 1)
			t.lastMumble = now
			dirty = true
		end
	end

	-- The Numberman: steal 1 coin from a random nearby player
	if HasBeing(profile, "the_numberman") then
		if now - t.lastNumberman >= cfg.NumbermanStealInt then
			t.lastNumberman = now
			local players = Players:GetPlayers()
			local victims = {}
			for _, p in ipairs(players) do
				if p ~= player then table.insert(victims, p) end
			end
			if #victims > 0 then
				local victim = victims[math.random(#victims)]
				local vp = DataStore.Get(victim)
				if vp and vp.Coins > 0 then
					DataStore.AddCoins(victim, -1)
					DataStore.AddCoins(player, 1)
					dirty = true
				end
			end
		end
	end

	-- Glutch: DONE aura — all nearby players +5 coins/min
	if HasBeing(profile, "glutch_done") then
		if now - t.lastGlutchAura >= cfg.GlutchAuraInterval then
			t.lastGlutchAura = now
			for _, p in ipairs(Players:GetPlayers()) do
				DataStore.AddCoins(p, 5)
			end
			dirty = true
		end
	end

	-- The Nothing (Void Aura): +50% of all generation
	-- Handled as a multiplier elsewhere; here we just grant a flat bonus
	if HasBeing(profile, "the_nothing") then
		if now - t.lastVoidAura >= cfg.VoidAuraInterval then
			t.lastVoidAura = now
			DataStore.AddCoins(player, 3) -- bonus flat
			dirty = true
		end
	end

	if dirty then
		-- Push updated HUD data to client
		UpdateHUD:FireClient(player, {
			Coins = profile.Coins,
			Level = profile.Level,
			XP    = profile.XP,
		})
	end
end

-- ── RemoteFunction handlers ───────────────────────────────────
RequestInventory.OnServerInvoke = function(player)
	local profile = DataStore.Get(player)
	if not profile then return {} end
	-- Enrich with Being metadata
	local result = {}
	for _, item in ipairs(profile.Inventory) do
		local def = BeingData.GetById(item.Id)
		if def then
			table.insert(result, {
				InstanceId = item.InstanceId,
				Id         = item.Id,
				Name       = def.Name,
				Rarity     = def.Rarity,
				BaseValue  = def.BaseValue,
				Multiplier = MarketMultipliers[item.Id] or 1.0,
				PassiveDesc = def.PassiveDesc,
				Emoji      = def.Emoji,
			})
		end
	end
	return result
end

RequestProfile.OnServerInvoke = function(player)
	local profile = DataStore.Get(player)
	if not profile then return {} end
	return {
		Coins    = profile.Coins,
		Level    = profile.Level,
		XP       = profile.XP,
		MaxSlots = profile.MaxSlots,
		TotalTrades = profile.TotalTrades,
		MutationsSurvived = profile.MutationsSurvived,
	}
end

-- ── Tuesday passive for Blorbsworth ──────────────────────────
-- Exposed so TradeHandler can call it
local function GetSellMultiplier(player, beingId)
	local multi = MarketMultipliers[beingId] or 1.0
	if beingId == "blorbsworth" or beingId == "blorbsworth_prime" then
		if IsTuesday() then
			multi = multi * 2
		end
	end
	return multi
end

-- ── Leaderboard (using OrderedDataStore) ─────────────────────
local RichDS = DataStoreService and DataStoreService:GetOrderedDataStore("Leaderboard_Coins_v1")
-- (DataStoreService not in scope here; leaderboard writes happen in SavePlayer)

-- ── Player connect / disconnect ───────────────────────────────
Players.PlayerAdded:Connect(function(player)
	-- Wait for DataStore to load profile first
	task.wait(2)
	InitPassives(player)
	local profile = DataStore.Get(player)
	if profile then
		UpdateHUD:FireClient(player, {
			Coins = profile.Coins,
			Level = profile.Level,
			XP    = profile.XP,
		})
	end
end)

Players.PlayerRemoving:Connect(function(player)
	PassiveTimers[player.UserId] = nil
end)

-- ── Main loops ────────────────────────────────────────────────
InitMarket()

-- Market tick every Glitch Hour
task.spawn(function()
	while true do
		task.wait(GameConfig.Economy.GlitchHourSeconds)
		TickMarket()
	end
end)

-- Passive income check every 5 seconds
task.spawn(function()
	while true do
		task.wait(5)
		for _, player in ipairs(Players:GetPlayers()) do
			ProcessPassives(player)
		end
	end
end)

-- Export helpers for TradeHandler
return {
	GetSellMultiplier = GetSellMultiplier,
	MarketMultipliers = MarketMultipliers,
	IsTuesday         = IsTuesday,
	MutationTicker    = MutationTicker,
}
