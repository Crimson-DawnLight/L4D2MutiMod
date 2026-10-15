# SendProxy 3.0

> Change stuff without actually changing stuff.

Overrides an entity property for **one client**, at the moment the server packs
that entity for transmission. The new value exists only in the packet that client
receives — the entity on the server keeps its real value, for everyone else and
for gameplay code.

## Install

| File | Where |
|---|---|
| `sm1.12/sendproxy.ext.so` (Linux) / `sm1.12/sendproxy.ext.dll` (Windows) | `addons/sourcemod/extensions/` |
| `gamedata/sendproxy.txt` | `addons/sourcemod/gamedata/` |
| `scripting/include/sendproxy.inc` | `addons/sourcemod/scripting/include/` |

SourceMod **1.12** is the supported version — it is what this extension is built
and tested against. Use the `sm1.12/` build. **SourceMod 1.13 is not supported**:
the `sm1.13/` build is still shipped for anyone stuck on 1.13, but it is
unmaintained — no fixes, no testing, no gamedata updates. Gamedata shipped for
Left 4 Dead 2. The extension refuses to load — with a logged error — when any
lookup in `gamedata/sendproxy.txt` fails, instead of loading and then silently
doing nothing.

## Use

Queue overrides from `OnSendProxyPre()`, which runs once per frame, before the
server packs entities:

```sourcepawn
#include <sendproxy>

public void OnSendProxyPre()
{
    int entRef = EntIndexToEntRef(entity);
    int offset = ...;                       // byte offset of the property

    SendProxy.AddChangeCell(client, entRef, offset, 100);
    SendProxy.AddChangeString(client, entRef, offset, text, sizeof text);
}
```

| Native | Writes |
|---|---|
| `SendProxy.AddChangeCell(client, entRef, offset, value)` | int |
| `SendProxy.AddChangeFloat(client, entRef, offset, value)` | float |
| `SendProxy.AddChangeEHandle(client, entRef, offset, value)` | entity handle |
| `SendProxy.AddChangeString(client, entRef, offset, str, maxLen)` | string |

**Return value.** Each native returns `false` and queues nothing when `client` is
outside `1 .. MaxClients`, or when `entRef` does not resolve to a live entity.
`AddChangeString` also returns `false` when the string does not fit in `maxLen`
bytes *including* the terminator — it is never silently truncated.

**Lifetime.** The queue is drained once per tick, so queue again from
`OnSendProxyPre()` every frame you want the override applied.

**Game rules.** Overriding the game rules entity works too; the write is
redirected to the game rules object behind the `CTerrorGameRulesProxy`.

**Examples.** Two complete, working plugins ship in `scripting/`:
`test_scripthud.sp` covers the game rules entity (per-client HUD text), and
`test_hud_nearest.sp` covers an ordinary entity (showing a client only the two
nearest survivors).

## Scope

- Not a hook, and not visible to the server — `SDKHook`s, gameplay logic and
  other plugins all keep seeing the real value.
- Not global — the same entity can be shown differently to different clients in
  the same frame.
- Only properties that reach the client through entity packing can be overridden.
  Anything the client reads from a different channel is out of reach.

## Credits

Forked from the original SendProxy by afronanny and the AlliedModders community.
Rewritten by Forgetest and Crimson.

Release notes: `CHANGELOG.md`.
