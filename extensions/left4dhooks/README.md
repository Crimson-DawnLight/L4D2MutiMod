# Left4DHooks

> The Left 4 DHooks Direct native and forward surface, for SourceMod 1.12.

A SourceMod extension for Left 4 Dead 2 that provides the natives and forwards plugin authors
expect from Left 4 DHooks Direct. The API is methodmap-based; the original L4DD global names are
registered too, so existing plugins keep compiling, and are marked deprecated in the include.

## What it provides

| Piece | What it gives you |
|---|---|
| Methodmaps | `CGameRules`, `CPlayer`, `CEntity`, `CZombie`, `CTimer`, `CNav`, `CTrigger`, `CDirector`, `CEntityFind`, `CProjectile`, `CWeapon` |
| Legacy names | The global `L4D_*` / `L4D2_*` natives, registered for compatibility and deprecated in the include |
| Forwards | 167 forwards over game events and engine functions, including the `_Post` variants |

The include also declares the L4DD support enums (`PointerType`, `CountdownTimer`, `IntervalTimer`
and the weapon-attribute enums), so a plugin written against L4DD compiles against this include.

## Install

| File | Where |
|---|---|
| `left4dhooks.ext.so` (Linux) / `left4dhooks.ext.dll` (Windows) | `addons/sourcemod/extensions/` |
| `left4dhooksExt.inc` | `addons/sourcemod/scripting/include/` |

Restart the server, or load the extension by hand.

The extension registers the `left4dhooks` library; plugins can gate on it with
`LibraryExists("left4dhooks")`.

On Linux the binary needs **glibc 2.29** (an Ubuntu 20.04 toolchain) and no `libstdc++` at
runtime. The repository README covers load failures.

**No gamedata.** Nothing goes under `addons/sourcemod/gamedata/`, and nothing there has to be
rewritten when the game updates: signatures and offsets are resolved inside the extension. If a
game update moves the internals it relies on, that takes a new build — not an edited gamedata file.

Depends on SourceMod **1.12** (tested on 1.12.0.7193 — **1.13 and later are not supported**) and
Metamod:Source **1.12+**, on a L4D2 server (Windows / Linux).

## Notes

- Existing L4DD plugins compile unchanged, but the compiler warns on every deprecated legacy name.
  Migrate to the methodmaps when convenient.
- `left4dhooksExt.inc` replaces the L4DD `left4dhooks.inc` — include one or the other, not both.
