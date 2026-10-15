# Mutispecials

> More special infected, on your terms.

Raises and controls how many special infected L4D2 keeps alive at once, and how soon they come
back — instead of the vanilla caps. Two smaller pieces ride along: engine slot handling for
servers above 4 players, and a map-change menu behind a command.

## What it gives you

| Piece | What it does |
|---|---|
| Special limit | Hooks the Director's `GetMaxPlayerZombies` / `IsClassAllowed` / `ShouldAllowSpecialSpawns` and grows its special-slot vector, so more SI can be alive at the same time |
| Dynamic scaling | Optionally adds a per-alive-survivor bonus on top of the base limit |
| Spawn delay | Holds specials for N seconds after the survivors leave the start area |
| Engine slots | Keeps the engine's client slots in step with `sv_maxplayers`, for servers above 4 players |
| Map menu | `crm_map` opens a mission/chapter picker, optionally as a vote |

## Install

| File | Where |
|---|---|
| `mutispecials.ext.so` (Linux) / `mutispecials.ext.dll` (Windows) | `addons/sourcemod/extensions/` |

**No gamedata.** Every signature and offset this extension needs lives in its own code, so
there is nothing to install under `gamedata/` and nothing to rewrite when the game updates.
If a lookup fails the extension **refuses to load** and logs why, instead of loading and then
half-working.

## ConVars

| ConVar | Default | Range | Meaning |
|---|---|---|---|
| `crm_mutisi_max` | `13` | 0 – 30 | special infected base limit |
| `crm_mutisi_enable_inc` | `0` | 0 / 1 | enable the dynamic limit below |
| `crm_mutisi_inc_per_player` | `0.5` | 0 – 10 | limit added per alive survivor |
| `crm_mutisi_delay` | `5.0` | — | seconds to hold spawns after the survivors leave the start area |

The effective limit is `crm_mutisi_max` plus `crm_mutisi_inc_per_player × alive survivors` when
`crm_mutisi_enable_inc` is on.

## Commands

| Command | Effect |
|---|---|
| `crm_map [novote]` | opens the map change menu for whoever runs it. Pass `1` to change directly, `0` to start a vote; no argument = direct |

## Credits

By Crimson.
