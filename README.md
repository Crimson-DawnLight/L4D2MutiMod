# L4D2MutiMod

Release builds of Left 4 Dead 2 server-side SourceMod extensions and plugins by **Crimson**.

**Extensions ship as binaries only** — no source, distributed as GitHub
[Release](https://github.com/Crimson-DawnLight/L4D2MutiMod/releases) assets. **Plugins ship in the
tree**: the `.smx` and the `.sp` it was built from sit together, so you can read, rebuild or fork
them. Either way, what each thing does and where its files go is documented next to it.

## Contents

| | Directory | What goes there |
|---|---|---|
| Extensions | [`extensions/`](extensions/) | SourceMod C++ extensions — docs in the tree, binaries in Releases |
| Plugins | [`plugins/`](plugins/) | SourcePawn plugins — `.sp` + `.smx` + docs in the tree |

## Releases

| Item | Kind | Version | What it does | Download |
|---|---|---|---|---|
| [sendproxy](extensions/sendproxy/) | extension | 3.4.1 | Overrides one entity property for one client, at packet time | [latest](https://github.com/Crimson-DawnLight/L4D2MutiMod/releases/latest) |
| [l4d2_survivors_healthbar](plugins/l4d2_survivors_healthbar/) | plugin | 2.0 | Native L4D2 survivor health bars, via per-client SendProxy overrides | [`.smx`](plugins/l4d2_survivors_healthbar/scripting/l4d2_survivors_healthbar.smx) |

## Install

Each item's own `README.md` states which file goes to which path. Extension release archives mirror
the server directory tree, so extracting one into your server root puts everything where it belongs.
A plugin's `.smx` under `scripting/` goes to `addons/sourcemod/plugins/`.

## License

No license is granted for this project's own work; all rights reserved. Third-party plugins keep
their original authorship and are credited per item.
