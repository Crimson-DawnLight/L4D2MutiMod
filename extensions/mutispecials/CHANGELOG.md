# Changelog

## 1.0.0.0 — Initial release

First release of the Mutispecials line, carved out of the CrmExt extension.

- **Special infected limit control**: hooks the Director's special-spawn virtuals
  (`GetMaxPlayerZombies` / `IsClassAllowed` / `ShouldAllowSpecialSpawns`) and grows its
  special-slot vector, so more SI can be alive at once.
- `crm_mutisi_max` / `crm_mutisi_enable_inc` / `crm_mutisi_inc_per_player` for the base limit
  and the per-alive-survivor bonus.
- `crm_mutisi_delay` holds spawns for N seconds after the survivors leave the start area.
- **Engine slot handling**: client slots follow `sv_maxplayers`, for servers above 4 players.
- **Map-change menu** behind `crm_map` (mission/chapter picker, optional vote).
- **No gamedata**: signatures and offsets resolve in-code; a failed lookup refuses the load.
