# [L4D2] Damage Number

> Floating damage numbers when you hit an infected — special infected and the tank included.

Every hit a survivor lands on a client target draws the damage as a seven-segment number in the
world. Each digit is built out of laser-beam temp entities (`materials/sprites/laserbeam.vmt`):
the seven segments are looked up from a bitmask table, and every beam is sent with
`TE_SendToClient()` **to the attacker only** — nobody else sees your numbers.

The number is placed `40.0` units above the victim's eye position and turned to face the
attacker (the heading is the eye-to-eye vector with pitch flattened to yaw). Baked-in defaults:

| Value | Default |
|---|---|
| digit height / width | `24.0` / `7.0` |
| horizontal spacing per digit | `10.0 + 2 × width` |
| colour | `{255, 0, 0, 255}` (red) |
| beam life | `0.2`s |
| damage | clamped to `999` |

A hit is drawn only when all of these hold: damage > 0, `weapon != -1`, the attacker is a valid
client on team 2 (survivor), and the victim is a valid client. The display mode then narrows the
victim side — see the ConVar table.

## Install

| File | Where |
|---|---|
| `scripting/l4d2_dmg_number.smx` | `addons/sourcemod/plugins/` |
| `scripting/include/[API]l4d2_dmg_number.inc` | `addons/sourcemod/scripting/include/` — only needed by a plugin that calls the natives |

## Using the natives

Load the `.smx` like any plugin; it registers the library `L4D2_TE_ShowDamageNumber`. Another
plugin `#include <[API]l4d2_dmg_number>` and calls the natives — the implementation stays in this
plugin, and the natives cross the plugin boundary.

## ConVars

One ConVar, created by the plugin section. No `.cfg` is generated (the plugin calls no
`AutoExecConfig()`), so set it in `cfg/server.cfg` or with the command below.

| ConVar | Default | Meaning |
|---|---|---|
| `l4d_dmg_number_mode` | `0` | display mode, clamped to `0`–`3` (`FCVAR_NOTIFY`) |

The mode is the single source of truth for which hits are drawn and who draws them:

| Mode | Victim filter | Number size | Drawing |
|---|---|---|---|
| `0` | any client | fixed `24 × 7` | the module's own hook — automatic |
| `1` | team 3 only — special infected and the tank | from the `high` / `width` arguments | your plugin, via `DisplayToClient()` |
| `2` | team 2 only — survivors | from the `high` / `width` arguments | your plugin, via `DisplayToClient()` |
| `3` | any client | from the `high` / `width` arguments | your plugin, via `DisplayToClient()` |

At any non-zero mode the module's own hook stops drawing and leaves it to the caller: you check
`ShouldDisplay()` inside your own `SDKHook_OnTakeDamageAlive` callback and then call
`DisplayToClient()`. Modes 1–3 also scale the digit offsets from the `high` / `width` you pass;
mode 0 ignores them and uses the fixed table.

## Commands

| Command | Flag | Effect |
|---|---|---|
| `sm_dmgnum <0-3>` | none (`RegConsoleCmd`) | sets `l4d_dmg_number_mode`; with no argument it prints the current value |

Only the plugin build has this command — the library mode leaves it out.

## Natives

Declared in `[API]l4d2_dmg_number.inc`.

| Native | Parameters | Returns |
|---|---|---|
| `DmgNum_t.ShouldDisplay` | `int victim, int attacker, int dmg, int weapon` | `true` = draw this hit, `false` = filtered (rules above) |
| `DmgNum_t.DisplayToClient` | `int victim, int attacker, int dmg, float high = 24.0, float width = 7.0, const int color[4]` | `true` on success |
| `DmgNum_t.SetMode` | `int mode` | `true` on success; writes `l4d_dmg_number_mode` so the ConVar stays the single source of truth, and ignores a mode outside `0`–`3` |

In plugin mode, `SetMode` and `sm_dmgnum` change the same ConVar.

## Requirements

- SourceMod **1.12**.
- **Left 4 Dead 2** only — the plugin refuses to load on any other engine.
- No external plugin or extension at runtime. `<sourcemod>`, `<sdkhooks>` and `<sdktools>` all
  ship with SourceMod.
- In plugin mode, a plugin that calls the natives needs this plugin loaded.

## Credits

crimson — plugin name `L4D2_TE_ShowDamageNumber`.

## Changelog

### 1.0.0

- Damage numbers for hits on special infected and the tank, drawn as seven-segment digits from
  laser-beam temp entities and sent only to the attacker.
- One ConVar (`l4d_dmg_number_mode`), the `sm_dmgnum` command, and three natives for cross-plugin
  use.
