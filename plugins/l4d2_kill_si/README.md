# [L4D2] Kill SI

> Heal survivors for killing special infected.

Every kill of a Smoker, Hunter, Jockey or Charger adds one to the killer's count. Each full count
of `l4d2_kill_si_cycle` kills heals that survivor for `l4d2_kill_si_health` points and resets the
count. Killing a Witch heals `60` and killing a Tank heals `70`; those two are fixed and are not
governed by either ConVar.

Healing is skipped while the survivor hangs from a ledge or is incapacitated, and the new health
is clamped to the survivor's maximum. Counts reset on round start, on map start and when a client
joins.

## Install

| File | Where |
|---|---|
| `l4d2_kill_si.smx` | `addons/sourcemod/plugins/` |

SourceMod **1.12**. No gamedata is needed.

## ConVars

| ConVar | Default | Meaning |
|---|---|---|
| `l4d2_kill_si_health` | `5` | health restored per reward |
| `l4d2_kill_si_cycle` | `1` | special-infected kills required per reward |

The plugin writes `cfg/sourcemod/l4d2_kill_si.cfg` on first run and reads it back on later starts.

## Changelog

### 1.0.0

- Survivors are healed for killing Smoker, Hunter, Jockey and Charger, every
  `l4d2_kill_si_cycle` kills, for `l4d2_kill_si_health` health.
- Witch and Tank kills heal a fixed `60` and `70`.
