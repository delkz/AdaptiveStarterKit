# Adaptive Starter Kit (Build 42)

Adaptive Starter Kit is a Project Zomboid mod that gives new characters a starter kit matched to the age of the world. Fresh worlds stay harsh, while late spawns get a small, believable chance to begin with worn survival gear.

## Default Progression

| World age | Possible kit |
| --- | --- |
| 0-3 days | No items |
| 4-7 days | Water and a simple snack |
| 8-14 days | School bag, water, food, and an improvised weapon |
| 15-30 days | Bag, medical supplies, food, and a worn melee weapon |
| 31-60 days | Better bag, tools, supplies, and a worn weapon |
| 61+ days | Survivor kit with a small firearm chance |

Kit contents are selected from small, balanced item pools, so each new character may receive slightly different snacks, tools, or worn weapons. Items with condition have randomized wear. Firearms do not include ammo by default, so the kit helps late spawns without removing the risk from a run.

## Local Installation

1. Extract the `AdaptiveStarterKit` folder into:
   `C:\Users\YOUR_USER\Zomboid\mods\`
2. Enable **Adaptive Starter Kit** in the mods menu.
3. When creating a world, open the **Adaptive Starter Kit** section in the Sandbox options.

## Dedicated Server

Copy `AdaptiveStarterKit` to the server's mods folder and add:

```ini
Mods=AdaptiveStarterKit
```

When using the Steam Workshop version, also add its Workshop ID to `WorkshopItems`.

## Configuration

Sandbox options let you:

- enable or disable the mod;
- choose a difficulty preset: `1` Harsh, `2` Balanced, or `3` Generous;
- choose whether starter backpacks are equipped automatically;
- enable small profession-based kit touches, which become less likely as the world gets older;
- enable rough, partially used supplies;
- show a short message when starter supplies are actually granted;
- choose the start day for each kit tier;
- scale the amount of consumable supplies;
- set the final-tier firearm chance;
- print diagnostic messages to the console.

Set **Basic supplies start day** to `0` if you want new characters to receive the first kit on the first world day.

Changing the tier thresholds only affects characters created after the change.

## Notes

- Each character receives a kit only once.
- The mod uses vanilla items only.
- Snacks, tools, and weapons include controlled randomness inside each kit tier.
- Starter backpacks are equipped on the character's back when that slot is available.
- Kit supplies are packed into the starter backpack when a backpack is included.
- In multiplayer, the kit tier is based on the server world's age.
- Kit tiers are defined in `42/media/lua/shared/ASK_Kits.lua`; item pools and profession rules are split into nearby shared files for easier tuning.

## Testing

Detailed diagnostics are controlled by the Sandbox Debug option. Logs include execution side,
step number, local grant ID, player event, network commands, effective settings, world age,
grant flag, profession rules, random rolls, item pools, each item attempt and destination,
wear, backpack equipment, synchronization, notification decisions, and final item counts.
Grant IDs are local to each Lua runtime, not shared between client and server.
Tier 1 explicitly reports that its empty kit is intentional. Item failures include the error
or a nil-result reason and remain visible even with diagnostics disabled.

On Windows, follow client/single-player output in PowerShell:

```powershell
Get-Content "$env:USERPROFILE\Zomboid\console.txt" -Tail 100 -Wait |
    Select-String '\[AdaptiveStarterKit\]'
```

For multiplayer, inspect the server logs too: client logs show the request, while the server
logs show item creation. A sent container update does not confirm receipt by the client.
Registration messages appear only if Debug is already enabled when the scripts load.

Enable **Print diagnostic messages** in the Sandbox options before using test commands.

In the Lua/debug console, you can run:

```lua
AdaptiveStarterKit.debugReset(getPlayer())
AdaptiveStarterKit.debugGrantTier(getPlayer(), 6)
```

`debugReset` lets the current character receive a kit again. `debugGrantTier` grants a specific tier from `1` to `6`, which is useful for checking balance, backpack packing, and debug output.

## Contributing

This mod is open source. If you have improvements, fixes, balancing changes, or compatibility updates, please open a pull request.
