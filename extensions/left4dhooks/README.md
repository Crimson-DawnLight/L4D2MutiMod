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

## Differences from Left4DHooks

- **`left4dhooks.smx` cannot run next to this extension.** Both register the same native names,
  and the plugin will fail to load. Remove the plugin before using this extension.
- **The legacy native API is compatible.** All 232 implemented legacy names are registered
  under their original `L4D_*` / `L4D2_*` names; the include marks them deprecated and points at
  the methodmap replacement.
- **Some L4DD natives are not implemented**: the animation-hook family (`AnimHookEnable`,
  `AnimHookDisable`, `AnimGetActivity`, `AnimGetFromActivity`), the timer-object API
  (`L4D2_CTimer*`, `L4D2_ITimer*`), the VScript/bot family (`L4D2_GetScriptScope`,
  `L4D2_GetDirectorScriptScope`, `L4D2_GetScriptValue*`, `L4D2_ExecVScriptCode`,
  `L4D2_GetVScriptEntity`, `L4D2_GetVScriptOutput`, `L4D2_VScriptWrapper_*`,
  `L4D2_CommandABot`), and `L4D_GetAllNavAreas`, `L4D_StartBurning`.
- **`_PostHandled` forwards are not provided.** Use the `_Post` variant instead. The handled
  state is not reproduced.
- **A few forwards are absent**: the L4D1-only ones (`L4D1_FirstAidKit_StartHealing*`,
  `L4D1_OnSavingEntities*`) and `L4D2_OnWaterMove`, `L4D_OnGameModeChange`,
  `L4D_OnGetRandomPZSpawnPosition`, `L4D_OnInfectedShoved`, `L4D_OnRecalculateVersusScore` /
  `_Post`.
- **This is a test build.** Problems are expected; report them promptly so they can be fixed.

## Autoload

`left4dhooksExt.inc` declares the extension as `file = "left4dhooks.ext"`. Plugins compiled against
the old `left4dhooks.inc` do not declare this extension. If you do not want to rely on autoload,
`#include <left4dhooksExt>` in every plugin that depends on Left4DHooks and recompile it; the
compiled plugin then names `left4dhooks.ext` and SourceMod loads the extension when the plugin
loads.

Do not include `left4dhooks.inc` and `left4dhooksExt.inc` together — they define the same symbols.

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
