# BrainRot Bazaar: The Cursed Marketplace
A Roblox simulator built in Luau. Collect, trade, and mutate bizarre sentient creatures called Brainrot Beings.

---

## How to install into Roblox Studio

1. Open **Roblox Studio** and create a new **Baseplate** project.

2. Open the **Explorer** panel (View → Explorer) and the **Properties** panel.

### ReplicatedStorage scripts
- Right-click **ReplicatedStorage** → Insert Object → **ModuleScript**
- Name it `BeingData`, paste contents of `ReplicatedStorage/BeingData.lua`
- Repeat for `GameConfig`

### ServerScriptService scripts
- Right-click **ServerScriptService** → Insert Object → **Script**
- Name it `DataStore`, paste contents of `ServerScriptService/DataStore.lua`
- Repeat for `GameManager` and `TradeHandler`

### StarterPlayerScripts (LocalScripts)
- Right-click **StarterPlayer** → expand → **StarterPlayerScripts**
- Insert Object → **LocalScript** for each file in `StarterPlayerScripts/`
  - `HUDController`
  - `InventoryClient`
  - `TradeClient`
  - `GachaClient`

### RemoteEvents (auto-created)
The scripts create all RemoteEvents and RemoteFunctions automatically on first run.
You do not need to add them manually.

---

## Map setup (manual — do in Studio)
The scripts handle all logic. You need to build the physical areas:

| Area | Purpose |
|------|---------|
| Spawn Void | Entry area. Place a Part named `SpawnLocation`. Add an NPC named `MrBrainrot`. |
| The Trade Pit | Central arena. Any player near another can initiate a trade via a ProximityPrompt. |
| The Gacha Hole | A literal hole. Add a `ProximityPrompt` that fires `ReplicatedStorage.OpenGacha`. |
| The Mutation Lab | A lab area. Add a ProximityPrompt that opens InventoryClient in "Lab mode". |
| The Black Stall | Hidden shop. Unlocked at Level 10 (check `profile.Unlocks` for `"black_stall"`). |

### Triggering the Gacha from a ProximityPrompt
```lua
-- Script inside the Gacha Hole Part:
local ProximityPrompt = script.Parent.ProximityPrompt
local OpenGacha = game.ReplicatedStorage:WaitForChild("OpenGacha")

ProximityPrompt.Triggered:Connect(function(player)
    OpenGacha:FireClient(player)
end)
```

### Triggering a trade request
```lua
-- LocalScript on a ProximityPrompt near another player:
local TradeRequest = game.ReplicatedStorage:WaitForChild("TradeRequest")
-- targetName = the other player's Name
-- offeredInstanceIds = table of InstanceIds from your inventory
TradeRequest:FireServer(targetName, offeredInstanceIds)
```

---

## Currency
**Slop Coins** — earned by:
- Selling Beings (minus 10% tax)
- Passive income from certain Beings (Void Hamster, Mumble Cube)
- Daily login bonus (50 coins)
- Surviving mutations (+XP which levels you up)

---

## Beings quick-reference

| Name | Rarity | Value | Passive |
|------|--------|-------|---------|
| Blorbsworth | Common | 40 | 2× sell on Tuesdays |
| The Lurker | Common | 65 | Highest Common value |
| Glutch | Common | 35 | 10% trade chance → Void |
| Slab Larry | Common | 30 | +2 coins per trade |
| Mumble Cube | Common | 28 | +1 coin/60s |
| Skreelix | Rare | 120 | Immune to mutations |
| The Numberman | Rare | 110 | Steals 1 coin/min from nearby |
| Princess Spaghetti | Rare | 130 | Adjacent Beings +5% value |
| Wrenchy McDoom | Rare | 115 | +10% trade XP |
| Void Hamster | Epic | 400 | +1 coin/30s |
| Crispr | Epic | 380 | Daily random stat swap |
| Baroness Null | Epic | 420 | Blocks nearby Mutation Lab use |
| Glutch: DONE | Void | 9999 | All nearby +5 coins/min |
| The Nothing | Void | 5000 | +50% all coin generation |
| The Observer | Cursed | 850 | Reveals nearby inventories |
| Blorbsworth Prime | Cursed | 700 | 2× Tuesday, 3× Wednesday |

---

## Mutation odds (per trade)
- **15%** chance any trade triggers a mutation
- Of those: Upgrade 33% · Fusion 27% · Devolution 20% · Explosion 13% · Jackpot 7%

All values tunable in `ReplicatedStorage/GameConfig.lua`.
