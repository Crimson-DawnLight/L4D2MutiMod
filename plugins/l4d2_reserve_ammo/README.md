# [L4D2] Reserve Ammo

> Give each weapon type its own reserve-ammo cap, from a config file.

Every weapon draws on one of seven ammo pools. This module lets you set the cap of each pool in a
KeyValues config, then applies it in two steps.

**The caps are written into the game's own convars.** For each pool the module looks up the game
`ammo_<pool>_max` convar and, when it exists, writes the configured value into it:

| Pool | Ammo type | Game convar | Default |
|---|---|---|---|
| rifle | 3 | `ammo_assaultrifle_max` | 360 |
| autoshotgun | 8 | `ammo_autoshotgun_max` | 90 |
| grenade launcher | 17 | `ammo_grenadelauncher_max` | 30 |
| shotgun | 7 | `ammo_shotgun_max` | 72 |
| hunting rifle | 9 | `ammo_huntingrifle_max` | 150 |
| smg | 5 | `ammo_smg_max` | 650 |
| sniper rifle | 10 | `ammo_sniperrifle_max` | 180 |

**Reserve ammo already carried is shifted, not reset.** 15 seconds into each round, every alive
survivor holding a primary-slot weapon gets the *difference* between the configured cap and the
vanilla default added to their current reserve count, clamped to `1023`. A player is never handed
the full cap — what they carry is preserved and adjusted in place. Only the primary weapon slot is
touched.

Timing:

- plugin start and map start: the config is (re)read and the caps are applied;
- every `round_start`: the 15-second per-player adjustment is queued.

## Install

| File | Where |
|---|---|
| `scripting/l4d2_reserve_ammo.smx` | `addons/sourcemod/plugins/` |

## Commands

| Command | Flag | Effect |
|---|---|---|
| `sm_ammo` | none — registered for all clients | reset the cached values, read the config file again and re-run the apply step |

The command exists only in the standalone build; it is registered inside the same
`#if defined _crimson_reserve_ammo_usedfor_plugins` block.

## Config file

`addons/sourcemod/data/l4d2_reserve_ammo.cfg` — KeyValues, root `"ammo"`, one key per pool. The
keys are the game convar names with their `ammo_` prefix stripped:

```
"ammo"
{
	"assaultrifle_max"		"360"
	"autoshotgun_max"		"90"
	"grenadelauncher_max"	"30"
	"shotgun_max"			"72"
	"huntingrifle_max"		"150"
	"smg_max"				"650"
	"sniperrifle_max"		"180"
}
```

**Generated on first run — do not ship it.** If the file is missing the module writes it with the
defaults above; if it cannot be read the defaults are used. A value that is `<= 0` or above `1023`
(`0x3FF`) is discarded and that pool keeps its default. Edit the file on the server and run
`sm_ammo`, or change the map, to load the new values.

## Requirements

SourceMod **1.12**. Nothing else at runtime — the module uses only `sourcemod` and `sdktools`, no
extension and no companion plugin.

## Credits

crimson.

## Changelog

### 1.0.0

- Per-weapon reserve-ammo caps, read from `data/l4d2_reserve_ammo.cfg` and written to the game's
  `ammo_*_max` convars.
- Carried reserve ammo is shifted by the cap difference 15 seconds into each round; the config can
  be reloaded at runtime with `sm_ammo`.
