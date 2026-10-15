# [L4D2] Spawn SI

> Per-class limits, spawn weights and spawn timing for the special infected — from one file.

Takes over special infected spawning on a server: how many may be alive, which classes get
produced and how often, and where. It slays specials that idle or get stuck, and can swap the
whole parameter set while a tank is alive. Every knob lives in a single KeyValues config file —
the pile of individually-named `ss_*` convars from the original plugin is gone.

| Controlled | What it covers |
|---|---|
| per-class limits | how many of each of the six classes may exist at once (`Class` section) |
| spawn weights | the relative odds each class is picked when a slot opens, optionally scaled by remaining headroom |
| timing | the spawn interval and its mode (random / increasing / decreasing), plus the first wave after the safe area |
| lull | an idle or stuck special is auto-slayed after `suicide_time` / `stuck_time` |
| tank status | an alternate limits/weights set applied while a tank is alive (`TankStatus` section) |

It registers **no ConVars**. It does read and set the engine's own `z_spawn_range`,
`z_safe_spawn_range` and `z_discard_range` from `range_min` / `range_max` (restored on unload),
and reads `versus_boss_buffer` for the versus boss-flow buffer.

## Install

| File | Where |
|---|---|
| `l4d2_spawn_SI.smx` | `addons/sourcemod/plugins/` |

SourceMod **1.12**.

> **Requires [Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?t=321696)**
> (`left4dhooks.smx`) installed on the server — the plugin `#include <left4dhooks>` and will not
> load without it.

## Config file

`addons/sourcemod/logs/l4d2_spawn_SI.cfg`

Written on first run if missing — and regenerated from defaults if it cannot be parsed — with the
comments and defaults shown below. Edit it and run `sm_spawn_reload`, or change one value in place
with `sm_spawn <key> <value>` (which writes the file back for you).

```
"SI_Spawn"
{
    "General"
    {
        "silimit"          "15"      // max specials alive at once
        "spawnsize"        "2"       // specials per batch
        "scale_weights"    "1"       // 1 = scale weights by remaining headroom
        "time_min"         "8.0"     // min spawn interval (s)
        "time_max"         "10.0"    // max spawn interval (s)
        "time_mode"        "1"       // 0 = random | 1 = increasing | 2 = decreasing
        "base_limit"       "4"       // total specials with 4 survivors
        "extra_limit"      "1.0"     // added per extra survivor
        "base_size"        "2"       // batch size at 4 survivors
        "extra_size"       "2.0"     // survivors per extra batch slot
        "suicide_time"     "20.0"    // idle special auto-slay (s)
        "stuck_time"       "10.0"    // stuck detection delay (s)
        "stuck_inspect"    "50.0"    // stuck detection radius
        "first_time"       "0.0"     // first wave after leaving the safe area (s)
        "range_min"        "200.0"   // min spawn distance
        "range_max"        "1500.0"  // max spawn distance
    }

    "Class"
    {
        "smoker"   { "limit" "1"   "weight" "200" }
        "boomer"   { "limit" "1"   "weight" "200" }
        "hunter"   { "limit" "4"   "weight" "100" }
        "spitter"  { "limit" "1"   "weight" "200" }
        "jockey"   { "limit" "4"   "weight" "100" }
        "charger"  { "limit" "4"   "weight" "200" }
    }

    "TankStatus"
    {
        "action"   "0"   // 1 = apply the values below while a tank is alive
        "smoker"   { "limit" "1"   "weight" "200" }
        "boomer"   { "limit" "1"   "weight" "200" }
        "hunter"   { "limit" "4"   "weight" "100" }
        "spitter"  { "limit" "1"   "weight" "200" }
        "jockey"   { "limit" "4"   "weight" "100" }
        "charger"  { "limit" "4"   "weight" "200" }
    }
}
```

## Commands

| Command | Flag | Arguments | Effect |
|---|---|---|---|
| `sm_spawn` | `ADMFLAG_RCON` | `<key> <value>` | set one parameter and write it back to the config file |
| `sm_spawn_reload` | `ADMFLAG_RCON` | — | re-read the config file |
| `sm_tgsx` | `ADMFLAG_RCON` | — | slay all special infected and restart the spawn timer |
| `sm_tgjs` | `ADMFLAG_RCON` | `[seconds]` | start the spawn timer; with no argument it uses the configured interval |
| `sm_tgms` | `ADMFLAG_ROOT` | `<type>` | single-class rotation: `off`, `random`, or a class name |

### `sm_spawn` keys

| Key | Sets |
|---|---|
| `smoker` / `boomer` / `hunter` / `spitter` / `jockey` / `charger` | that class's spawn limit (`0`–`32`) |
| `<class>.weight` | that class's spawn weight |
| `all` | every class's limit at once |
| `max` (alias `silimit`) | total special limit |
| `size` (aliases `spawnsize`, `wave`) | specials per batch |
| `time_min` | min spawn interval, seconds (floor `0.1`) |
| `time_max` | max spawn interval, seconds (floor `1.0`) |
| `time_mode` | `0` = random, `1` = increasing, `2` = decreasing |
| `base_limit` / `extra_limit` | total limit at 4 survivors / added per extra survivor |
| `base_size` / `extra_size` | batch size at 4 survivors / survivors per extra batch slot |
| `suicide_time` | seconds before an idle special is slain |
| `stuck_time` / `stuck_inspect` | stuck-detection delay / radius |
| `first_time` | delay before the first wave after leaving the safe area |
| `range_min` / `range_max` | min / max spawn distance |
| `tank_action` | `0`/`1` — apply the `TankStatus` block while a tank is alive |

An unrecognised key prints the usage text. Running `sm_spawn` with fewer than two arguments does
the same.

## Credits

Plugin by crimson.

## Changelog

### 1.0.0

- Initial release: per-class limits and weights, spawn timing, idle/stuck auto-slay and the
  tank-status override.
- All tunables moved out of the original plugin's `ss_*` convars into the one KeyValues file; edit
  it directly or use `sm_spawn`.
