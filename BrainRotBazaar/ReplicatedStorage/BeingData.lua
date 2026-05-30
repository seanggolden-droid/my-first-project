-- ============================================================
-- BeingData (ModuleScript) — ReplicatedStorage
-- All Brainrot Being definitions, rarities, passives, mutation paths
-- ============================================================

local BeingData = {}

-- Rarity tiers in ascending order
BeingData.RarityOrder = {"Common", "Rare", "Epic", "Cursed", "Void"}

BeingData.RarityColors = {
	Common  = Color3.fromRGB(180, 180, 180),
	Rare    = Color3.fromRGB(80, 140, 255),
	Epic    = Color3.fromRGB(180, 80, 255),
	Cursed  = Color3.fromRGB(255, 60, 60),
	Void    = Color3.fromRGB(20, 255, 180),
}

-- ============================================================
-- BEING DEFINITIONS
-- Each Being: Name, Rarity, BaseValue (Slop Coins), PassiveKey, MutatesInto
-- PassiveKey maps to server logic in GameManager
-- ============================================================
BeingData.Beings = {

	-- ── COMMONS ──────────────────────────────────────────────
	{
		Id = "blorbsworth",
		Name = "Blorbsworth",
		Rarity = "Common",
		BaseValue = 40,
		Description = "A round beige blob in a tiny top hat. Suspiciously calm.",
		PassiveKey = "DOUBLE_ON_TUESDAY",
		PassiveDesc = "Doubles sell value on in-game Tuesdays.",
		MutatesInto = "blorbsworth_prime",
		Emoji = "🎩",
	},
	{
		Id = "the_lurker",
		Name = "The Lurker",
		Rarity = "Common",
		BaseValue = 65,
		Description = "Invisible unless you stand still for 5 seconds. Why is it watching?",
		PassiveKey = "HIGH_VALUE_COMMON",
		PassiveDesc = "Highest trade value among Commons. Rewards patience.",
		MutatesInto = "lurker_revealed",
		Emoji = "👁️",
	},
	{
		Id = "glutch",
		Name = "Glutch",
		Rarity = "Common",
		BaseValue = 35,
		Description = "A sentient loading bar stuck at 97%. It has been waiting for years.",
		PassiveKey = "GLUTCH_COMPLETE_CHANCE",
		PassiveDesc = "10% chance on trade to complete and evolve into Glutch: DONE (Void rarity).",
		MutatesInto = "glutch_done",
		Emoji = "⏳",
	},
	{
		Id = "slab_larry",
		Name = "Slab Larry",
		Rarity = "Common",
		BaseValue = 30,
		Description = "A perfectly flat rectangle with a face. Slides everywhere. Hates stairs.",
		PassiveKey = "SLIDE_BONUS",
		PassiveDesc = "Gains +2 Slop Coins value each time it is traded.",
		MutatesInto = "slab_larry_thick",
		Emoji = "🟫",
	},
	{
		Id = "mumble_cube",
		Name = "Mumble Cube",
		Rarity = "Common",
		BaseValue = 28,
		Description = "A cube that mumbles constantly. Nobody knows what it is saying.",
		PassiveKey = "PASSIVE_COIN_TINY",
		PassiveDesc = "Generates 1 Slop Coin every 60 seconds.",
		MutatesInto = "shout_cube",
		Emoji = "📦",
	},

	-- ── RARES ────────────────────────────────────────────────
	{
		Id = "skreelix",
		Name = "Skreelix the Unfinished",
		Rarity = "Rare",
		BaseValue = 120,
		Description = "A half-rendered 3D model. Missing textures. Still screaming.",
		PassiveKey = "MUTATION_IMMUNE",
		PassiveDesc = "Immune to all mutations. Cannot be upgraded either.",
		MutatesInto = nil, -- immune
		Emoji = "🔲",
	},
	{
		Id = "the_numberman",
		Name = "The Numberman",
		Rarity = "Rare",
		BaseValue = 110,
		Description = "A humanoid made of floating 404 error codes. Walks through walls sometimes.",
		PassiveKey = "STEAL_COIN",
		PassiveDesc = "Steals 1 Slop Coin from a nearby player every minute.",
		MutatesInto = "the_numberman_500",
		Emoji = "🔢",
	},
	{
		Id = "princess_spaghetti",
		Name = "Princess Spaghetti",
		Rarity = "Rare",
		BaseValue = 130,
		Description = "Royal. Saucy. Her crown is marinara-stained and she does not care.",
		PassiveKey = "ADJACENCY_BOOST",
		PassiveDesc = "Adjacent Beings in inventory gain +5% value.",
		MutatesInto = "duchess_lasagna",
		Emoji = "🍝",
	},
	{
		Id = "wrenchy_mcdoom",
		Name = "Wrenchy McDoom",
		Rarity = "Rare",
		BaseValue = 115,
		Description = "A wrench with legs and an existential crisis. Tightens things that should not be tightened.",
		PassiveKey = "TRADE_XP_BOOST",
		PassiveDesc = "Grants +10% XP from all trades while in inventory.",
		MutatesInto = "wrenchy_supreme",
		Emoji = "🔧",
	},

	-- ── EPICS ────────────────────────────────────────────────
	{
		Id = "void_hamster",
		Name = "Void Hamster",
		Rarity = "Epic",
		BaseValue = 400,
		Description = "A hamster on a wheel. The wheel generates the universe. It is tired.",
		PassiveKey = "PASSIVE_COIN_MEDIUM",
		PassiveDesc = "Generates 1 Slop Coin every 30 seconds passively.",
		MutatesInto = "void_hamster_ascended",
		Emoji = "🐹",
	},
	{
		Id = "crispr",
		Name = "Crispr the Glitched Dog",
		Rarity = "Epic",
		BaseValue = 380,
		Description = "A good boy whose face swaps with other Beings. Chaos incarnate. Still wags tail.",
		PassiveKey = "DAILY_STAT_SWAP",
		PassiveDesc = "Randomly swaps stats with another owned Being once per day.",
		MutatesInto = "crispr_stabilized",
		Emoji = "🐕",
	},
	{
		Id = "baroness_null",
		Name = "Baroness Null",
		Rarity = "Epic",
		BaseValue = 420,
		Description = "She returned from the void with more questions than answers and a briefcase full of nothing.",
		PassiveKey = "NULL_FIELD",
		PassiveDesc = "Nearby players cannot use Mutation Lab on their Beings for 30 seconds after a trade.",
		MutatesInto = "baroness_undefined",
		Emoji = "💼",
	},

	-- ── CURSED ───────────────────────────────────────────────
	{
		Id = "glutch_done",
		Name = "Glutch: DONE",
		Rarity = "Void",
		BaseValue = 9999,
		Description = "It finally loaded. The universe held its breath. It was worth it.",
		PassiveKey = "GLUTCH_AURA",
		PassiveDesc = "All nearby players gain +5 Slop Coins per minute just from being in its presence.",
		MutatesInto = nil,
		Emoji = "✅",
	},
	{
		Id = "blorbsworth_prime",
		Name = "Blorbsworth Prime",
		Rarity = "Cursed",
		BaseValue = 700,
		Description = "The blob has evolved. The hat is bigger. The calm is terrifying.",
		PassiveKey = "DOUBLE_ON_TUESDAY",
		PassiveDesc = "Doubles sell value on in-game Tuesdays. Effect is now triple on Wednesdays.",
		MutatesInto = nil,
		Emoji = "🎩",
	},
	{
		Id = "the_observer",
		Name = "The Observer",
		Rarity = "Cursed",
		BaseValue = 850,
		Description = "It used to be The Lurker. Now it sees everything. EVERYTHING.",
		PassiveKey = "SEE_ALL",
		PassiveDesc = "Reveals the rarity of all Beings in nearby players' inventories.",
		MutatesInto = nil,
		Emoji = "🔮",
	},

	-- ── VOID (secret/ultra-rare) ──────────────────────────────
	{
		Id = "the_nothing",
		Name = "The Nothing",
		Rarity = "Void",
		BaseValue = 5000,
		Description = "It does not exist. Your inventory disagrees.",
		PassiveKey = "VOID_AURA",
		PassiveDesc = "Increases all Slop Coin generation by 50% for the owner.",
		MutatesInto = nil,
		Emoji = "⬛",
	},
}

-- ============================================================
-- Helper: get Being definition by Id
-- ============================================================
function BeingData.GetById(id)
	for _, being in ipairs(BeingData.Beings) do
		if being.Id == id then
			return being
		end
	end
	return nil
end

-- ============================================================
-- Helper: get next rarity tier
-- ============================================================
function BeingData.NextRarity(rarity)
	for i, r in ipairs(BeingData.RarityOrder) do
		if r == rarity then
			return BeingData.RarityOrder[i + 1] -- nil if already max
		end
	end
	return nil
end

-- ============================================================
-- Helper: get previous rarity tier
-- ============================================================
function BeingData.PrevRarity(rarity)
	for i, r in ipairs(BeingData.RarityOrder) do
		if r == rarity and i > 1 then
			return BeingData.RarityOrder[i - 1]
		end
	end
	return nil
end

-- ============================================================
-- Helper: get all Beings of a given rarity
-- ============================================================
function BeingData.GetByRarity(rarity)
	local result = {}
	for _, being in ipairs(BeingData.Beings) do
		if being.Rarity == rarity then
			table.insert(result, being)
		end
	end
	return result
end

return BeingData
