# Mutispecials

> More special infected, on your terms.

Controls how many special infected L4D2 keeps alive at once — by steering the game's own
Director rather than spawning specials by hand. Type, spawn point and cooldown pacing stay the
Director's call, so the game keeps its own rhythm; only the caps move. Two smaller pieces ride
along: engine slot handling for servers above 4 players, and a map-change menu behind a command.

## What it does

| Piece | What it does |
|---|---|
| Special limit | Hard cap on how many special infected are alive at the same time — adjustable |
| Dynamic scaling | Optionally adds a per-alive-survivor bonus on top of the base limit |
| Spawn delay | Holds the first wave for N seconds after the survivors leave the start area |
| Engine slots | Keeps the engine's client slots in step with `sv_maxplayers`, for servers above 4 players |
| Map menu | `crm_map` opens a mission/chapter picker, optionally as a vote |

## Install

| File | Where |
|---|---|
| `mutispecials.ext.so` (Linux) / `mutispecials.ext.dll` (Windows) | `addons/sourcemod/extensions/` |

Restart the server, or load the extension by hand. The extension registers the `mutispecials`
library; plugins can gate on it with `LibraryExists("mutispecials")`.

On Linux the binary needs **glibc 2.29** (an Ubuntu 20.04 toolchain) and no `libstdc++` at
runtime. The repository README covers load failures.

**No gamedata.** Nothing goes under `addons/sourcemod/gamedata/`, and nothing there has to be
rewritten when the game updates: what this extension needs from the game is resolved inside the
extension. If a game update moves the internals it relies on, that takes a new build — not an
edited gamedata file.

Depends on SourceMod **1.12** (tested on 1.12.0.7193 — **1.13 and later are not supported**) and
Metamod:Source **1.12+**, on a L4D2 server (Windows / Linux).

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

## Notes

- **Turn off other multi-special and boss-slot plugins.** They fight over the same spawn logic.
- **l4dtoolz can stay installed.** If `sv_maxplayers` / `sv_setmax` already exist, Mutispecials
  reuses them instead of registering its own, so the two do not warn or fight over callbacks.
- **Start low.** Test with a small cap, then raise it gradually.
- **The cap is bounded by bot slots.** Run out and the server stops filling them — lower the cap
  or raise `sv_maxclients`.

## Why it stays cheap

A SourcePawn multi-special plugin has to call across the script boundary on every spawn, find
spawn points by hand, and manage entity lifetimes itself; under load that stutters and leaves
entities behind. This extension steers the Director instead, so spawns ride the engine's own
batch loop and caches:

- **No script layer in the path** — it is all native code, nothing in SourcePawn.
- **No orphaned entities** — specials go through the game's own spawn path.
- **Tested under load** — 25 specials spawned at once on a 2 GB lightweight cloud instance,
  without stutter.

## Credits

By Crimson.
