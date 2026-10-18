# Changelog

## 1.0.1 — Load fix

- **Fixed load failures on some game builds**: the extension now resolves only the signatures it
  uses. Left4DHooks-only signatures and the unused `CMapTransition` signatures no longer refuse
  the Mutispecials load.

## 1.0.0 — Initial release

First release of the Mutispecials line, carved out of the CrmExt extension.

- **Special infected limit control**: raises and caps how many special infected are alive at the
  same time. Type, spawn point and cooldown pacing stay with the Director.
- `crm_mutisi_max` / `crm_mutisi_enable_inc` / `crm_mutisi_inc_per_player` for the base limit
  and the per-alive-survivor bonus.
- `crm_mutisi_delay` holds the first wave for N seconds after the survivors leave the start area.
- **Spawn delay fixed**: the delay re-arms after a round restart, not only on the first round of a map.
- **Engine slot handling**: client slots follow `sv_maxplayers`, for servers above 4 players.
- **Map-change menu** behind `crm_map` (mission/chapter picker, optional vote).
- **No gamedata**: what it needs from the game resolves in-code; a failed lookup refuses the load.
- Registers the `mutispecials` extension library.
