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
| [sendproxy](extensions/sendproxy/) | extension | 3.4.1 | Changes what one client sees, without changing the server's real data | [releases](https://github.com/Crimson-DawnLight/L4D2MutiMod/releases?q=sendproxy) |
| [left4dhooks](extensions/left4dhooks/) | extension | 1.0.1 | The Left 4 DHooks Direct native and forward surface, with a methodmap API — no gamedata | [releases](https://github.com/Crimson-DawnLight/L4D2MutiMod/releases?q=left4dhooks) |
| [mutispecials](extensions/mutispecials/) | extension | 1.0.3 | More special infected alive at once, driven by the game's own Director — no gamedata | [releases](https://github.com/Crimson-DawnLight/L4D2MutiMod/releases?q=mutispecials) |
| [sendtable](extensions/sendtable/) | extension | 1.0.0 | Widens integer SendProp bit widths and re-frames oversized send tables — no gamedata | [releases](https://github.com/Crimson-DawnLight/L4D2MutiMod/releases?q=sendtable) |
| [l4d2_survivors_healthbar](plugins/l4d2_survivors_healthbar/) | plugin | 2.0 | Native L4D2 survivor health bars, via per-client SendProxy overrides | [`.smx`](plugins/l4d2_survivors_healthbar/l4d2_survivors_healthbar.smx) |
| [l4d2_reload](plugins/l4d2_reload/) | plugin | 1.0.0 | `CTerrorGun` finish/abort reload calls, plus an `sm_reload` command | [`.smx`](plugins/l4d2_reload/l4d2_reload.smx) |
| [l4d2_block_msgs](plugins/l4d2_block_msgs/) | plugin | 1.0.0 | Silences the game's own notices, one bitmask bit per message class | [`.smx`](plugins/l4d2_block_msgs/l4d2_block_msgs.smx) |
| [l4d2_dmg_number](plugins/l4d2_dmg_number/) | plugin | 1.0.0 | Floating damage numbers, drawn with beam temp entities to the attacker only | [`.smx`](plugins/l4d2_dmg_number/l4d2_dmg_number.smx) |
| [l4d2_immun_control](plugins/l4d2_immun_control/) | plugin | 1.0.0 | Lets survivors ignore chosen special-infected controls | [`.smx`](plugins/l4d2_immun_control/l4d2_immun_control.smx) |
| [l4d2_reserve_ammo](plugins/l4d2_reserve_ammo/) | plugin | 1.0.0 | Per-weapon-type reserve ammo caps, from a config file | [`.smx`](plugins/l4d2_reserve_ammo/l4d2_reserve_ammo.smx) |
| [l4d2_spawn_SI](plugins/l4d2_spawn_SI/) | plugin | 1.0.0 | Per-class special infected limits, weights and spawn timing | [`.smx`](plugins/l4d2_spawn_SI/l4d2_spawn_SI.smx) |
| [l4d2_wep_attribute](plugins/l4d2_wep_attribute/) | plugin | 1.0.0 | Retunes any weapon or melee script's attributes at runtime, from KeyValues tables | [`.smx`](plugins/l4d2_wep_attribute/l4d2_wep_attribute.smx) |

## Install

Each item's own `README.md` states exactly which file goes to which path — an extension binary
under `addons/sourcemod/extensions/`, a plugin's `.smx` under `addons/sourcemod/plugins/`.
Extensions are built and tested against SourceMod **1.12.0.7193**; if one refuses to start, see
[When an extension fails to load](#when-an-extension-fails-to-load).

## When an extension fails to load

Everything here is built and tested against **SourceMod 1.12.0.7193**. The console line, or the
entry in `addons/sourcemod/logs/`, names the cause — match it against the sections below before
reporting anything.

### glibc / libstdc++ errors

**These cannot come from our builds.** The Linux binaries import only `libc.so.6` — plus
`libdl.so.2` and `libm.so.6` — with the C++ runtime linked in statically, so no `libstdc++.so.6`
symbol is referenced at all. A `GLIBCXX_3.4.xx` or `CXXABI_*` failure is therefore never ours.

What the build does need *from* glibc is fixed and low, and stated per item (SendProxy: **2.7**;
Left4DHooks and Mutispecials: **2.29**). So `version 'GLIBC_2.xx' not found` — the usual way an extension built
on a newer distro fails — is not something these builds produce. It is something else on the box:
another extension, or a library that one pulls in.

### `Extension version too new` / `too old`

SourceMod's extension API version is not compatible across major releases: **1.12 is version 8,
1.13 is version 9**. A build for one does not load on the other, in either direction. The fix is
to run a **SourceMod 1.12** server. These extensions target 1.12 and **1.13 and later will not be
maintained** — no 1.13 builds, none planned.

### Interface version mismatches

SourceMod changes its extension-facing interfaces often, and each one carries a version that has
to match exactly — so a build can load on the SourceMod it was built against and fail on another.
There is no clever workaround:

- **Run the SourceMod build the item was built against.** This is the intended answer, and what
  each item's own `README.md` states.
- **Ask for a build matched to your SourceMod.** Possible, but discouraged: it costs the author
  time for a build that goes stale with your next SourceMod update.
- **Drop the SourceMod interface dependency** and ship a MetaMod plugin instead. That does work,
  but a MetaMod plugin cannot expose natives or forwards to SourcePawn, so it is not a drop-in
  replacement for anything that has to be reachable from a plugin.

### Everything else

- Check the failure against the sections above first — anything explained there is not a bug.
- On Linux, **restart the server** after installing. That is the only supported way to load an
  extension: problems that appear only after a hot reload (`sm exts reload`, MetaMod
  `meta reload`) are treated as expected behaviour and will not be looked at.

## License

No license is granted for this project's own work; all rights reserved. Third-party plugins keep
their original authorship and are credited per item.
