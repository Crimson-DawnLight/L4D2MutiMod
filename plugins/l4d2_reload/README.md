# [L4D2] Weapon Reload

> Complete a weapon's reload on demand — from the console, or from your own plugin.

Provides the L4D2 `CTerrorGun` reload primitives as SDK calls and wraps them in a methodmap, so a
weapon entity can be told to finish or abort its reload. It ships two ways: as a standalone plugin
that adds an `sm_reload` command, and as a library your plugin can `#include`.

## What it does

Two virtual calls on the weapon entity, resolved from this module's own gamedata:

| Method | Effect |
|---|---|
| `FinishReload()` | completes the reload |
| `AbortReload()` | aborts the reload |
| `Reload()` | `AbortReload()` then `FinishReload()` — a full reload; the order matters and cannot be swapped |

Only **firearms** have a valid `CTerrorGun` vtable. As a standalone plugin, `sm_reload` reads the
player's active weapon, maps its classname to a weapon type, and acts only on rifles, SMGs, shotguns,
snipers, the grenade launcher, pistols and the magnum (`WeaponType_RifleM60 … WeaponType_Magnum`).
Melee, throwables and items are ignored — the vtable does not apply to them.

## Install

| File | Where |
|---|---|
| `scripting/l4d2_reload.smx` | `addons/sourcemod/plugins/` |
| `gamedata/weapon_reloading.txt` | `addons/sourcemod/gamedata/` |

SourceMod **1.12**. The `.sp` is included in `scripting/` if you want to build it yourself.

The shipped `.sp` has the standalone-plugin switch **on** (`#define _crimson_weapon_reload_usedfor_plugins`),
so it compiles into the `sm_reload` plugin as-is. Comment that line out and the file becomes a plain
library — `#include` it from your own plugin to use `WepReload` with nothing registered.

## Commands

| Command | Flags | Effect |
|---|---|---|
| `sm_reload` | none — any client | full reload of your active weapon; does nothing from the server console or for a non-firearm |

## Config / data files

| Path | Notes |
|---|---|
| `addons/sourcemod/gamedata/weapon_reloading.txt` | **must be shipped** — the two `CTerrorGun` virtual offsets (`FinishReload`, `AbortReload`, linux/windows). Loaded at `OnPluginStart`; the plugin fails to start without it. |

This module creates no ConVars, so it writes no config file.

## Requirements

SourceMod **1.12**. No runtime plugin or extension — only SourceMod's own `sdktools` and the gamedata
above. Building from source additionally needs the `[API]l4d2_base` include (`WeaponType` and
`GetWeaponTypeFromCls`).

## Credits

By crimson.

## Changelog

### 1.0.0

- `CTerrorGun` `FinishReload` / `AbortReload` SDK calls with a `WepReload` methodmap.
- Standalone plugin (`sm_reload`) and includable library in one file, toggled by a `#define`.
