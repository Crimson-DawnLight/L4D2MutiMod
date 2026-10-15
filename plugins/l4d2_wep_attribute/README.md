# [L4D2] Weapon Attribute

> Retune any weapon or melee script at runtime — damage, spread, range, clip size and more.

Reads and writes the **live** weapon-info and melee-info structs of every weapon script the game
has loaded. Instead of overriding ConVars or hooking damage, it resolves each weapon's info pointer
— `GetWeaponInfo` for weapons, `CMeleeWeaponInfoStore::GetMeleeWeaponInfo` for melee — and pokes
the fields directly at their offsets, so the engine picks up the changed values everywhere.

Two KeyValues tables under `addons/sourcemod/data/` drive it: a pristine default table that **must
ship**, and a live table you edit and re-apply.

## What it does

**Weapons** — the 45 weapon classes the game registers (`weapon_pistol` … `weapon_ammo_spawn`):

| Kind | Attributes |
|---|---|
| int | `damage`, `bullets`, `clipsize`, `bucket`, `tier`, `defaultsize`, `weapontype` |
| float | `maxplayerspeed`, `spreadpershot`, `maxspread`, `spreaddecay`, `minduckspread`, `minstandspread`, `minairspread`, `maxmovespread`, `penlayers`, `penpower`, `penmaxdist`, `charpenmaxdist`, `range`, `rangemod`, `cycletime`, `scatterpitch`, `scatteryaw`, `verticalpunch`, `horizpunch`, `gainrange`, `reloadduration` |

**Melee** — the 13 melee scripts (`fireaxe`, `frying_pan`, `machete`, `baseball_bat`, `crowbar`,
`cricket_bat`, `tonfa`, `katana`, `electric_guitar`, `knife`, `golfclub`, `pitchfork`, `shovel`):

| Kind | Attributes |
|---|---|
| int | `DamageFlags`, `RumbleEffect` |
| bool | `Decapitates` |
| float | `Damage`, `RefireDelay`, `WeaponIdleTime` |

`tier` is read-only: writes to it are refused. Setters also ignore negative values.

## Config files

| File | Path | Role |
|---|---|---|
| `weapon_attributes_def.cfg` | `addons/sourcemod/data/` | the **pristine default table** — read at startup, **must ship** (missing → `SetFailState`) |
| `weapon_attributes.cfg` | `addons/sourcemod/data/` | the **live table** — read at startup when present; generated from the default table when absent; written by `sm_attr` |
| `l4d2_wep_attribute.txt` | `addons/sourcemod/gamedata/` | offsets and signatures — loaded at startup |

Only the first two live under `addons/sourcemod/data/`. `weapon_attributes.cfg` is not shipped — it
is created from the default table on first start.

## Install

| File | Where |
|---|---|
| `scripting/l4d2_wep_attribute.smx` | `addons/sourcemod/plugins/` |
| `gamedata/l4d2_wep_attribute.txt` | `addons/sourcemod/gamedata/` |
| `data/weapon_attributes_def.cfg` | `addons/sourcemod/data/` |

## Commands

| Command | Flag | Effect |
|---|---|---|
| `sm_attr` | any player | re-capture the default weapon and melee attributes from live memory and write them to `data/weapon_attributes.cfg` |
| `sm_loadattr` | any player | load `data/weapon_attributes.cfg` and apply it to the live structs |

Both are `RegConsoleCmd` with no access flag.

## Gamedata

The shipped `l4d2_wep_attribute.txt` is this plugin's **own** file, cut down from left4dhooks: the 7
`L4D2IntWeapon_*` and 21 `L4D2FloatWeapon_*` weapon offsets, the 6 melee property offsets, the
`MeleeWeaponInfoStore` address, and the `GetWeaponInfo` /
`CMeleeWeaponInfoStore::GetMeleeWeaponInfo` signatures. The plugin loads it by name
(`new GameData("l4d2_wep_attribute")`) and never reads left4dhooks' file. A consumer that
`#include`s this module must ship the same gamedata file.

## Requirements

SourceMod **1.12**. L4D2 only — the offsets and signatures target `left4dead2`. No left4dhooks
install is needed: this plugin ships its own gamedata.

## Credits

crimson.

## Changelog

### 1.0.0

- Runtime read/write of weapon and melee script attribute structs, driven by KeyValues tables.
- Two commands (`sm_attr`, `sm_loadattr`) for capturing defaults and re-applying the live table.
- Ships its own cut-down gamedata; usable standalone or as an `#include` library.
