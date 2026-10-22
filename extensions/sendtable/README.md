# SendTable

> Change the network schema from a plugin, before anyone connects.

Widens the bit width of integer SendProps so values larger than the vanilla range
survive being sent to clients — health, max health, ammo — and re-frames send
tables that grow past the wire limit.

## Install

| File | Where |
|---|---|
| `sendtable.ext.so` (Linux) / `sendtable.ext.dll` (Windows) | `addons/sourcemod/extensions/` |
| `scripting/include/sendtable.inc` | `addons/sourcemod/scripting/include/` |

Depends on SourceMod **1.12** (tested on 1.12.0.7193); **1.13 and later are not
supported**. On Linux the binary needs **glibc 2.29** (an Ubuntu 20.04 toolchain)
and no `libstdc++` at runtime. The release repository's README covers load
failures.

**No gamedata.** Nothing goes under `addons/sourcemod/gamedata/`; the extension
patches the server's own send tables at runtime.

## Use

Call the natives from `OnPluginStart()`.

```sourcepawn
#include <sendtable>

public void OnPluginStart()
{
    SendTable.SetElementBits("CTerrorPlayer", "m_iAmmo", 16, 10);
    SendTable.SetBits("CTerrorPlayer", "m_iHealth", 31, 16);
    SendTable.SetBits("CTerrorPlayer", "m_iMaxHealth", 31, 16);
    SendTable.SetElementBits("CTerrorPlayerResource", "m_iHealth", 31, 16);
    SendTable.SetElementBits("CTerrorPlayerResource", "m_maxHealth", 31, 16);
}
```

| Native | Does |
|---|---|
| `SendTable.SetBits(netClass, propName, bits, expectedBits = 0)` | Set an integer prop's bit width |
| `SendTable.SetElementBits(netClass, tableName, bits, expectedBits = 0)` | Set every integer element of a DataTable |
| `SendTable.GetBits(netClass, propName)` | Read the width; `-1` when not found |

`bits` is `1..31`. `expectedBits` is a guard: when non-zero the call only applies
if the current width matches it, so a game update that changes a vanilla width
fails the call instead of silently applying the wrong one. Both setters return
`false` when the class or prop cannot be found.

**Restart, do not reload.** Plugins that call these natives cannot be
hot-reloaded. Change the values, then restart the server to apply them.
