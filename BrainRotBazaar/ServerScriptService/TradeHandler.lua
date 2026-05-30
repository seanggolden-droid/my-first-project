-- ============================================================
-- TradeHandler (Script) — ServerScriptService
-- Validates and processes player-to-player trades.
-- Rolls Brainrot Mutations and applies results.
-- Also handles: sell to NPC, Gacha, Mutation Lab.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local GameConfig  = require(ReplicatedStorage:WaitForChild("GameConfig"))
local BeingData   = require(ReplicatedStorage:WaitForChild("BeingData"))
local DataStore   = require(script.Parent:WaitForChild("DataStore"))
local GameManager = require(script.Parent:WaitForChild("GameManager"))

-- ── RemoteEvents ──────────────────────────────────────────────
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
local TradeRequest      = GetOrCreate(RE, "RemoteEvent",    "TradeRequest")
local TradeOffer        = GetOrCreate(RE, "RemoteEvent",    "TradeOffer")
local TradeResponse     = GetOrCreate(RE, "RemoteEvent",    "TradeResponse")
local TradeResult       = GetOrCreate(RE, "RemoteEvent",    "TradeResult")
local SellBeing         = GetOrCreate(RE, "RemoteFunction", "SellBeing")
local DoGachaPull       = GetOrCreate(RE, "RemoteFunction", "DoGachaPull")
local DoMutationLab     = GetOrCreate(RE, "RemoteFunction", "DoMutationLab")
local UpdateHUD         = ReplicatedStorage:WaitForChild("UpdateHUD")
local MutationTicker    = ReplicatedStorage:WaitForChild("MutationTicker")

-- ── Pending trade offers ──────────────────────────────────────
-- Key: initiatorUserId .. "_" .. targetUserId
local PendingTrades = {}

-- ── Helpers ───────────────────────────────────────────────────
local function FireHUD(player)
	local p = DataStore.Get(player)
	if p then
		UpdateHUD:FireClient(player, { Coins = p.Coins, Level = p.Level, XP = p.XP })
	end
end

local function GetCurrentValue(beingId)
	local def = BeingData.GetById(beingId)
	if not def then return 0 end
	local multi = GameManager.MarketMultipliers[beingId] or 1.0
	return math.floor(def.BaseValue * multi)
end

-- ── Mutation roller ───────────────────────────────────────────
local function RollMutation(initiator, target, iItems, tItems)
	-- iItems / tItems: arrays of instanceIds being traded
	local cfg = GameConfig.Mutation
	if math.random() > cfg.TriggerChance then return nil end

	local roll = math.random()
	local mutationType

	if roll < cfg.Upgrade then
		mutationType = "Upgrade"
	elseif roll < cfg.Upgrade + cfg.Fusion then
		mutationType = "Fusion"
	elseif roll < cfg.Upgrade + cfg.Fusion + cfg.Devolution then
		mutationType = "Devolution"
	elseif roll < cfg.Upgrade + cfg.Fusion + cfg.Devolution + cfg.Explosion then
		mutationType = "Explosion"
	else
		mutationType = "Jackpot"
	end

	local ip = DataStore.Get(initiator)
	local tp = DataStore.Get(target)
	local msg = ""

	-- Pick a random item from either side to mutate
	local allItems = {}
	for _, id in ipairs(iItems) do table.insert(allItems, { player = initiator, profile = ip, iid = id }) end
	for _, id in ipairs(tItems) do table.insert(allItems, { player = target,    profile = tp, iid = id }) end

	if #allItems == 0 then return nil end
	local victim = allItems[math.random(#allItems)]

	-- Find item def
	local itemEntry
	for _, entry in ipairs(victim.profile.Inventory) do
		if entry.InstanceId == victim.iid then
			itemEntry = entry
			break
		end
	end
	if not itemEntry then return nil end
	local def = BeingData.GetById(itemEntry.Id)
	if not def then return nil end

	if mutationType == "Upgrade" then
		local nextRarity = BeingData.NextRarity(def.Rarity)
		if def.MutatesInto and nextRarity then
			-- Replace the being with its mutation
			DataStore.RemoveFromInventory(victim.player, victim.iid)
			DataStore.AddToInventory(victim.player, def.MutatesInto)
			msg = def.Name .. " evolved into " .. (BeingData.GetById(def.MutatesInto) or {Name="something new"}).Name .. "! 🔼"
		else
			msg = def.Name .. " glowed... but nothing happened. (Already max tier)"
		end

	elseif mutationType == "Fusion" then
		-- Pick a second item from the same player
		local fusionCandidates = {}
		for _, entry in ipairs(victim.profile.Inventory) do
			if entry.InstanceId ~= victim.iid then
				table.insert(fusionCandidates, entry)
			end
		end
		if #fusionCandidates > 0 then
			local second = fusionCandidates[math.random(#fusionCandidates)]
			DataStore.RemoveFromInventory(victim.player, victim.iid)
			DataStore.RemoveFromInventory(victim.player, second.InstanceId)
			-- Fusion result: higher rarity of the two, with a special id
			local def2 = BeingData.GetById(second.Id)
			local higherDef = (def.BaseValue >= (def2 and def2.BaseValue or 0)) and def or def2
			DataStore.AddToInventory(victim.player, higherDef.Id) -- simplified: keeps the higher-value one
			msg = def.Name .. " and " .. (def2 and def2.Name or "???") .. " fused! Something emerged... 🔀"
		else
			msg = def.Name .. " wanted to fuse but had no partner. Awkward."
		end

	elseif mutationType == "Devolution" then
		local prevRarity = BeingData.PrevRarity(def.Rarity)
		if prevRarity then
			local prevBeings = BeingData.GetByRarity(prevRarity)
			if #prevBeings > 0 then
				DataStore.RemoveFromInventory(victim.player, victim.iid)
				local replacement = prevBeings[math.random(#prevBeings)]
				DataStore.AddToInventory(victim.player, replacement.Id)
				msg = def.Name .. " devolved into " .. replacement.Name .. "... 🔽"
			end
		else
			msg = def.Name .. " tried to devolve but hit rock bottom."
		end

	elseif mutationType == "Explosion" then
		DataStore.RemoveFromInventory(victim.player, victim.iid)
		-- Drop a Cursed Fragment (sellable item, stored as a special being id)
		DataStore.AddToInventory(victim.player, "cursed_fragment")
		DataStore.AddXP(victim.player, GameConfig.Progression.XPPerMutation)
		local vp = DataStore.Get(victim.player)
		if vp then vp.MutationsSurvived = vp.MutationsSurvived + 1 end
		msg = def.Name .. " EXPLODED. A Cursed Fragment was left behind. 💥"

	elseif mutationType == "Jackpot" then
		-- Both players get a Void being
		local voidBeings = BeingData.GetByRarity("Void")
		if #voidBeings > 0 then
			local prize = voidBeings[math.random(#voidBeings)]
			DataStore.AddToInventory(initiator, prize.Id)
			DataStore.AddToInventory(target, prize.Id)
			msg = "✨ JACKPOT! Both players received " .. prize.Name .. " from the Void!"
		end
	end

	-- XP for surviving a mutation
	DataStore.AddXP(initiator, GameConfig.Progression.XPPerMutation)
	DataStore.AddXP(target,    GameConfig.Progression.XPPerMutation)

	return { Type = mutationType, Message = msg }
end

-- ── Trade request flow ────────────────────────────────────────
-- Step 1: initiator sends trade request to target
TradeRequest.OnServerEvent:Connect(function(initiator, targetName, offeredInstanceIds)
	local target = Players:FindFirstChild(targetName)
	if not target or target == initiator then return end

	-- Validate offered items belong to initiator
	local ip = DataStore.Get(initiator)
	if not ip then return end
	for _, iid in ipairs(offeredInstanceIds) do
		if not DataStore.HasInInventory(initiator, iid) then
			warn("[TradeHandler] Initiator doesn't own offered item:", iid)
			return
		end
	end

	-- Store pending trade
	local key = initiator.UserId .. "_" .. target.UserId
	PendingTrades[key] = {
		Initiator       = initiator,
		Target          = target,
		OfferedItems    = offeredInstanceIds,
		RequestedItems  = {},
		Status          = "pending",
		Timestamp       = os.clock(),
	}

	-- Forward to target client
	TradeOffer:FireClient(target, {
		InitiatorName = initiator.Name,
		OfferedItems  = offeredInstanceIds,
		TradeKey      = key,
	})
end)

-- Step 2: target accepts / declines, optionally adds counter-offer items
TradeResponse.OnServerEvent:Connect(function(target, tradeKey, accepted, counterItems)
	local trade = PendingTrades[tradeKey]
	if not trade or trade.Status ~= "pending" then return end
	if trade.Target ~= target then return end

	if not accepted then
		trade.Status = "declined"
		TradeResult:FireClient(trade.Initiator, { Success = false, Message = "Trade declined." })
		TradeResult:FireClient(trade.Target,    { Success = false, Message = "Trade declined." })
		PendingTrades[tradeKey] = nil
		return
	end

	-- Validate counter items belong to target
	for _, iid in ipairs(counterItems or {}) do
		if not DataStore.HasInInventory(target, iid) then
			TradeResult:FireClient(target, { Success = false, Message = "You don't own that item." })
			return
		end
	end

	trade.RequestedItems = counterItems or {}
	trade.Status = "processing"

	-- Execute the swap
	local initiator = trade.Initiator
	local ip = DataStore.Get(initiator)
	local tp = DataStore.Get(target)

	-- Remove from each side and add to the other
	local iBeings, tBeings = {}, {}
	for _, iid in ipairs(trade.OfferedItems) do
		for _, entry in ipairs(ip.Inventory) do
			if entry.InstanceId == iid then
				table.insert(iBeings, entry.Id)
				break
			end
		end
		DataStore.RemoveFromInventory(initiator, iid)
	end
	for _, iid in ipairs(trade.RequestedItems) do
		for _, entry in ipairs(tp.Inventory) do
			if entry.InstanceId == iid then
				table.insert(tBeings, entry.Id)
				break
			end
		end
		DataStore.RemoveFromInventory(target, iid)
	end
	for _, beingId in ipairs(tBeings) do DataStore.AddToInventory(initiator, beingId) end
	for _, beingId in ipairs(iBeings) do DataStore.AddToInventory(target, beingId) end

	-- XP for trading
	DataStore.AddXP(initiator, GameConfig.Progression.XPPerTrade)
	DataStore.AddXP(target,    GameConfig.Progression.XPPerTrade)
	ip.TotalTrades = (ip.TotalTrades or 0) + 1
	tp.TotalTrades = (tp.TotalTrades or 0) + 1

	-- Glutch special: 10% chance on trade to complete
	for _, id in ipairs(iBeings) do
		if id == "glutch" and math.random() < 0.10 then
			DataStore.RemoveFromInventory(target, "glutch") -- target received it
			DataStore.AddToInventory(target, "glutch_done")
			MutationTicker:FireAllClients(target.Name .. "'s Glutch COMPLETED! ✅")
		end
	end

	-- Roll mutation
	local mutation = RollMutation(initiator, target, trade.OfferedItems, trade.RequestedItems)
	local mutMsg = mutation and mutation.Message or nil

	if mutMsg then
		MutationTicker:FireAllClients("[MUTATION] " .. mutMsg)
	end

	-- Notify both clients
	local result = {
		Success     = true,
		Message     = "Trade complete!" .. (mutMsg and ("\n" .. mutMsg) or ""),
		MutationType = mutation and mutation.Type or nil,
	}
	TradeResult:FireClient(initiator, result)
	TradeResult:FireClient(target,    result)

	FireHUD(initiator)
	FireHUD(target)

	PendingTrades[tradeKey] = nil
end)

-- ── Sell Being to NPC ─────────────────────────────────────────
SellBeing.OnServerInvoke = function(player, instanceId)
	local profile = DataStore.Get(player)
	if not profile then return false, "No profile." end

	-- Find the item
	local beingId
	for _, entry in ipairs(profile.Inventory) do
		if entry.InstanceId == instanceId then
			beingId = entry.Id
			break
		end
	end
	if not beingId then return false, "Item not found." end

	local value = GetCurrentValue(beingId)
	-- Tuesday bonus for Blorbsworth
	value = math.floor(value * GameManager.GetSellMultiplier(player, beingId))
	-- Apply sell tax
	value = math.floor(value * (1 - GameConfig.Economy.SellTax))

	DataStore.RemoveFromInventory(player, instanceId)
	DataStore.AddCoins(player, value)
	DataStore.AddXP(player, GameConfig.Progression.XPPerSell)

	FireHUD(player)
	return true, value
end

-- ── Gacha pull ────────────────────────────────────────────────
DoGachaPull.OnServerInvoke = function(player)
	local profile = DataStore.Get(player)
	if not profile then return false, "No profile." end

	local cfg = GameConfig.Gacha
	if profile.Coins < cfg.CostPerPull then
		return false, "Not enough Slop Coins."
	end

	DataStore.AddCoins(player, -cfg.CostPerPull)
	profile.PullCount = (profile.PullCount or 0) + 1
	local pullCount = profile.PullCount

	-- Determine rarity (pity system)
	local rarity
	if pullCount % cfg.PityEpic == 0 then
		rarity = (math.random() < 0.20) and "Cursed" or "Epic"
	elseif pullCount % cfg.PityRare == 0 then
		rarity = "Rare"
	else
		-- Standard weighted roll
		local roll = math.random()
		local cumulative = 0
		local rates = cfg.BaseRates
		local order = {"Void","Cursed","Epic","Rare","Common"}
		for _, r in ipairs(order) do
			cumulative = cumulative + rates[r]
			if roll <= cumulative then
				rarity = r
				break
			end
		end
		rarity = rarity or "Common"
	end

	local pool = BeingData.GetByRarity(rarity)
	if #pool == 0 then pool = BeingData.GetByRarity("Common") end
	local chosen = pool[math.random(#pool)]

	local iid = DataStore.AddToInventory(player, chosen.Id)
	if not iid then
		DataStore.AddCoins(player, cfg.CostPerPull) -- refund
		return false, "Inventory full."
	end

	-- Log pull history (keep last 20)
	table.insert(profile.PullHistory, 1, { Id = chosen.Id, Rarity = rarity, Pull = pullCount })
	if #profile.PullHistory > 20 then
		table.remove(profile.PullHistory)
	end

	FireHUD(player)
	return true, {
		Name       = chosen.Name,
		Rarity     = chosen.Rarity,
		BaseValue  = chosen.BaseValue,
		Emoji      = chosen.Emoji,
		InstanceId = iid,
	}
end

-- ── Mutation Lab ──────────────────────────────────────────────
DoMutationLab.OnServerInvoke = function(player, instanceId)
	local profile = DataStore.Get(player)
	if not profile then return false, "No profile." end

	local cfg = GameConfig.MutationLab
	if profile.Coins < cfg.BaseCost then
		return false, "Not enough Slop Coins. Need " .. cfg.BaseCost .. "."
	end

	local beingId
	for _, entry in ipairs(profile.Inventory) do
		if entry.InstanceId == instanceId then
			beingId = entry.Id
			break
		end
	end
	if not beingId then return false, "Being not found." end

	local def = BeingData.GetById(beingId)
	if not def then return false, "Unknown Being." end

	-- Skreelix is immune
	if def.PassiveKey == "MUTATION_IMMUNE" then
		return false, "Skreelix cannot be mutated. It refuses."
	end

	DataStore.AddCoins(player, -cfg.BaseCost)

	local roll = math.random()
	if roll < cfg.DestroyChance then
		DataStore.RemoveFromInventory(player, instanceId)
		DataStore.AddToInventory(player, "cursed_fragment")
		profile.MutationsSurvived = (profile.MutationsSurvived or 0) + 1
		FireHUD(player)
		return true, { Result = "Destroyed", Message = def.Name .. " was destroyed. A Cursed Fragment remains. 💥" }

	elseif roll < cfg.DestroyChance + cfg.SuccessChance then
		if def.MutatesInto then
			DataStore.RemoveFromInventory(player, instanceId)
			local newIid = DataStore.AddToInventory(player, def.MutatesInto)
			local newDef = BeingData.GetById(def.MutatesInto)
			DataStore.AddXP(player, GameConfig.Progression.XPPerMutation)
			FireHUD(player)
			return true, {
				Result     = "Upgraded",
				Message    = def.Name .. " evolved into " .. (newDef and newDef.Name or "???") .. "! 🔼",
				NewBeing   = newDef,
				InstanceId = newIid,
			}
		else
			FireHUD(player)
			return true, { Result = "NoPath", Message = def.Name .. " glowed... but has nowhere to evolve." }
		end
	else
		-- Nothing happens, coins spent
		FireHUD(player)
		return true, { Result = "Nothing", Message = "The lab hummed. " .. def.Name .. " stared back. Nothing changed." }
	end
end

print("[TradeHandler] Loaded.")
