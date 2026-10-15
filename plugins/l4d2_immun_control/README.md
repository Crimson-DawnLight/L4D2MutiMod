# [L4D2] Immun Control

> Let survivors shrug off the controls of specific special infected.

Refuses the left4dhooks callbacks that let a special infected take hold of a survivor, so a
survivor whose immunity bit is on is never grabbed, pounced, ridden, carried, pummelled, knocked
down or clawed by that special. Immunity is a per-special bitmask, applied per survivor as
`global & personal` — a survivor is immune only when the global mask and that player's own mask
both have the bit set. The personal mask is initialised from the global one when the player joins.

| Bit | Special | Controls refused |
|---|---|---|
| `1` | Smoker | tongue grab (`L4D_OnGrabWithTongue`) |
| `2` | Hunter | pounce (`L4D_OnPouncedOnSurvivor`) |
| `4` | Jockey | ride (`L4D2_OnJockeyRide`) |
| `8` | Charger | carry (`L4D2_OnStartCarryingVictim`), pummel (`L4D2_OnPummelVictim`) and knockdown (`L4D_OnKnockedDown`, reason 3) |
| `16` | Tank | rock knockdown (`L4D_OnKnockedDown`, reason 2) and claw (`L4D_TankClaw_OnPlayerHit_Pre`) |

The default mask `31` is every bit — immunity to all five. A blocked pummel also nudges the victim
off the Charger, so refusing the attack does not leave the survivor stuck in place.

## Install

| File | Where |
|---|---|
| `l4d2_immun_control.smx` | `addons/sourcemod/plugins/` |

SourceMod **1.12**. This module **requires the third-party [Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?t=321696) plugin**
(`left4dhooks.smx`) — it `#include <left4dhooks>` and does all of its work from left4dhooks
forwards. Install that too, or this plugin will not load.

## ConVars

| ConVar | Default | Meaning |
|---|---|---|
| `l4d_immun_flags` | `31` | immunity bitmask, clamped `0`–`31`: `1` = Smoker tongue, `2` = Hunter pounce, `4` = Jockey ride, `8` = Charger, `16` = Tank. A change is applied to everyone immediately |

## Commands

| Command | Effect |
|---|---|
| `sm_immun <flag>` | set `l4d_immun_flags`; console command with no admin flag. With no argument it prints the current value |

## Credits

Original module by **豆瓣酱な**; refactored into the current form by **crimson**
(`author = "豆瓣酱な/crimson"`).

## Changelog

### 1.0.0

- Survivors can be made immune to Smoker, Hunter, Jockey, Charger and Tank control, selectable per
  special through the `l4d_immun_flags` bitmask.
- Per-player immunity masks layered on top of the global mask, plus a plugin API to drive both.
