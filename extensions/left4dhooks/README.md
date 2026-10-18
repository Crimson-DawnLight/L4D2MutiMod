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

- **`left4dhooks.smx` cannot run next to this extension.** Both register the same native and
  forward names. There is a second problem: this extension patches engine code with SafetyHook,
  and plugins always run after extensions — the plugin's own signature scans can resolve wrong
  addresses against the patched code unless it is written to tolerate it. Remove the plugin
  before using this extension.
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
## Autoload

**Recompile every plugin that depends on Left4DHooks with `#include <left4dhooksExt>`.** The
include declares the extension as `file = "left4dhooks.ext"`, so the compiled plugin requests it
and SourceMod loads the extension in a deterministic order when the plugin loads.

This is more flexible than relying on a global autoload entry: if the dependent plugin is removed
and the server restarts, `left4dhooks.ext` is not loaded either — no leftover hooks, no extension
sitting in the process for nothing.

A plugin compiled against the old `left4dhooks.inc` does not declare this extension, so it will
not load it on its own.

## Plugins built for left4dhooks.smx

Plugins that depend on the old `left4dhooks.smx` do **not** need to be recompiled. Put the shipped
`left4dhooks.smx` in `addons/sourcemod/plugins/` and keep its file name. It is an empty plugin that
includes `<left4dhooksExt>` and registers the `left4dhooks` plugin library; the required-plugin
check then passes, loading it makes SourceMod load `left4dhooks.ext`, and the legacy `L4D_*` /
`L4D2_*` natives are provided by the extension. Remove any real Left4DHooks plugin before using
the stub.

Do not include `left4dhooks.inc` and `left4dhooksExt.inc` together in the same plugin — they define
the same symbols.

## Install

| File | Where |
|---|---|
| `left4dhooks.ext.so` (Linux) / `left4dhooks.ext.dll` (Windows) | `addons/sourcemod/extensions/` |
| `left4dhooksExt.inc` | `addons/sourcemod/scripting/include/` |
| `left4dhooks.smx` (compatibility stub) | `addons/sourcemod/plugins/` — only when running plugins built against `left4dhooks.inc` |

Restart the server, or load the extension by hand.

The compatibility stub registers the `left4dhooks` library, so plugins can gate on it with
`LibraryExists("left4dhooks")`. The extension registers `left4dhooksExt`.

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
