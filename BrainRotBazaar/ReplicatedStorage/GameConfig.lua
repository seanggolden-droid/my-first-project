-- ============================================================
-- GameConfig (ModuleScript) — ReplicatedStorage
-- All tunable constants for BrainRot Bazaar
-- ============================================================

local GameConfig = {}

-- ── Economy ──────────────────────────────────────────────────
GameConfig.Economy = {
	StartingCoins         = 150,       -- coins new players begin with
	GlitchHourSeconds     = 300,       -- real seconds per "Glitch Hour" (market tick)
	PriceFluctuationMax   = 0.20,      -- max ±20% price swing per tick
	InflationPerUnit      = 0.02,      -- each copy in circulation reduces value by 2%
	DailyLoginBonus       = 50,        -- coins awarded on first login of the day
	SellTax               = 0.10,      -- 10% cut taken by the Bazaar on every sale
}

-- ── Gacha ─────────────────────────────────────────────────────
GameConfig.Gacha = {
	CostPerPull           = 50,
	PityRare              = 10,        -- guaranteed Rare+ every N pulls
	PityEpic              = 50,        -- guaranteed Epic+ every N pulls
	BaseRates = {
		Common  = 0.55,
		Rare    = 0.28,
		Epic    = 0.12,
		Cursed  = 0.04,
		Void    = 0.01,
	},
}

-- ── Trade Mutation ────────────────────────────────────────────
GameConfig.Mutation = {
	TriggerChance   = 0.15,  -- 15% chance any trade triggers a mutation event
	-- Sub-chances (must sum to 1.0, evaluated only when mutation triggers)
	Upgrade         = 0.33,
	Fusion          = 0.27,
	Devolution      = 0.20,
	Explosion       = 0.13,
	Jackpot         = 0.07,
}

-- ── Mutation Lab ──────────────────────────────────────────────
GameConfig.MutationLab = {
	BaseCost        = 75,    -- Slop Coins to use the lab
	SuccessChance   = 0.55,  -- 55% chance of upgrade
	DestroyChance   = 0.15,  -- 15% chance Being is destroyed
	-- remaining 30% = nothing happens, coins still spent
}

-- ── Progression ───────────────────────────────────────────────
GameConfig.Progression = {
	MaxLevel        = 50,
	XPPerTrade      = 10,
	XPPerSell       = 5,
	XPPerMutation   = 25,
	-- XP required for each level: base * level^1.5
	XPBase          = 100,

	-- Unlocks at specific levels
	Unlocks = {
		[5]  = "inventory_slot_21_25",   -- +5 inventory slots
		[10] = "black_stall",            -- The Black Stall secret shop
		[15] = "inventory_slot_26_30",
		[20] = "stall_decoration_1",
		[25] = "exclusive_being_1",
		[30] = "inventory_slot_31_35",
		[40] = "stall_decoration_2",
		[50] = "exclusive_being_2",
	},
}

-- ── Inventory ─────────────────────────────────────────────────
GameConfig.Inventory = {
	DefaultMaxSlots = 20,
}

-- ── Passive Timers (seconds) ──────────────────────────────────
GameConfig.Passives = {
	VoidHamsterInterval  = 30,
	MumbleCubeInterval   = 60,
	NumbermanStealInt    = 60,
	GlutchAuraInterval   = 60,
	VoidAuraInterval     = 60,
}

-- ── In-game time ──────────────────────────────────────────────
-- One in-game day = 20 real minutes; day 2 = Tuesday, etc.
GameConfig.InGame = {
	DayLengthSeconds = 1200,
}

return GameConfig
