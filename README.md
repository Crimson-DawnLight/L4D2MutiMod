# L4D2MutiMod

Release builds of Left 4 Dead 2 server-side SourceMod extensions and plugins by **Crimson**.

**Extensions ship as binaries only** — no source, distributed as GitHub
[Release](https://github.com/Crimson-DawnLight/L4D2MutiMod/releases) assets. **Plugins ship in the
tree** as `.smx` plus docs; where the source is published as well it sits next to the `.smx`. Either
way, what each thing does and where its files go is documented next to it.

## Contents

| | Directory | What goes there |
|---|---|---|
| Extensions | [`extensions/`](extensions/) | SourceMod C++ extensions — docs in the tree, binaries in Releases |
| Plugins | [`plugins/`](plugins/) | SourcePawn plugins — `.smx` + docs in the tree (the `.sp` too, where published) |

## Releases

| Item | Kind | Version | What it does | Download |
|---|---|---|---|---|
| [sendproxy](extensions/sendproxy/) | extension | 3.4.1 | Overrides one entity property for one client, at packet time | [releases](https://github.com/Crimson-DawnLight/L4D2MutiMod/releases?q=sendproxy) |
| [mutispecials](extensions/mutispecials/) | extension | 1.0.0.0 | Raises and controls the L4D2 special infected limit — no gamedata | [releases](https://github.com/Crimson-DawnLight/L4D2MutiMod/releases?q=mutispecials) |
| [l4d2_survivors_healthbar](plugins/l4d2_survivors_healthbar/) | plugin | 2.0 | Native L4D2 survivor health bars, via per-client SendProxy overrides | [`.smx`](plugins/l4d2_survivors_healthbar/scripting/l4d2_survivors_healthbar.smx) |
| [l4d2_reload](plugins/l4d2_reload/) | plugin | 1.0.0 | `CTerrorGun` finish/abort reload calls, plus an `sm_reload` command | [`.smx`](plugins/l4d2_reload/scripting/l4d2_reload.smx) |
| [l4d2_block_msgs](plugins/l4d2_block_msgs/) | plugin | 1.0.0 | Silences the game's own notices, one bitmask bit per message class | [`.smx`](plugins/l4d2_block_msgs/scripting/l4d2_block_msgs.smx) |
| [l4d2_dmg_number](plugins/l4d2_dmg_number/) | plugin | 1.0.0 | Floating damage numbers, drawn with beam temp entities to the attacker only | [`.smx`](plugins/l4d2_dmg_number/scripting/l4d2_dmg_number.smx) |
| [l4d2_immun_control](plugins/l4d2_immun_control/) | plugin | 1.0.0 | Lets survivors ignore chosen special-infected controls | [`.smx`](plugins/l4d2_immun_control/scripting/l4d2_immun_control.smx) |
| [l4d2_reserve_ammo](plugins/l4d2_reserve_ammo/) | plugin | 1.0.0 | Per-weapon-type reserve ammo caps, from a config file | [`.smx`](plugins/l4d2_reserve_ammo/scripting/l4d2_reserve_ammo.smx) |
| [l4d2_spawn_SI](plugins/l4d2_spawn_SI/) | plugin | 1.0.0 | Per-class special infected limits, weights and spawn timing | [`.smx`](plugins/l4d2_spawn_SI/scripting/l4d2_spawn_SI.smx) |
| [l4d2_wep_attribute](plugins/l4d2_wep_attribute/) | plugin | 1.0.0 | Retunes any weapon or melee script's attributes at runtime, from KeyValues tables | [`.smx`](plugins/l4d2_wep_attribute/scripting/l4d2_wep_attribute.smx) |

## Install

Each item's own `README.md` states exactly which file goes to which path — an extension binary
under `addons/sourcemod/extensions/`, a plugin's `.smx` under `addons/sourcemod/plugins/`.

## License

No license is granted for this project's own work; all rights reserved. Third-party plugins keep
their original authorship and are credited per item.
