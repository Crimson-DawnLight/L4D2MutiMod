# [L4D2] Immun Control

> Let survivors shrug off the control of chosen special infected.

Hooks the game's own grab and hit functions with DHooks and refuses the call, so a survivor whose
immunity bit is on is never grabbed, pounced, ridden, carried, pummelled, knocked down or clawed
by that special. Immunity is a per-special bitmask; a survivor is immune only where the global
mask and that player's own mask both have the bit set. The personal mask starts as a copy of the
global mask when the player joins.

| Bit | Special | Controls refused |
|---|---|---|
| `1` | Smoker | tongue grab |
| `2` | Hunter | pounce |
| `4` | Jockey | ride |
| `8` | Charger | carry, pummel and knockdown |
| `16` | Tank | rock knockdown and claw |

The default mask `31` is every bit. A refused pummel also moves the victim off the Charger, so
refusing the attack does not leave the survivor stuck in place.

## Install

| File | Where |
|---|---|
| `l4d2_immun_control.smx` | `addons/sourcemod/plugins/` |
| `gamedata/l4d2_immun_control.txt` | `addons/sourcemod/gamedata/` |

SourceMod **1.12**. The plugin uses the DHooks extension bundled with SourceMod and loads its
signatures from the gamedata file above — without that file it refuses to start. It does not
depend on left4dhooks.

## ConVars

| ConVar | Default | Meaning |
|---|---|---|
| `l4d_immun_flags` | `31` | immunity bitmask, `0`–`31`. A change is applied to everyone immediately |
| `l4d_immun_release_delay` | `0.0` | seconds before an immune survivor is released, `0`–`10`. Below `0.1` the grab is refused outright |
| `l4d_immun_getup_invuln` | `0.0` | seconds of invulnerability after a survivor is revived, `0`–`30`. Below `0.1` it is off |

### Delayed release

`l4d_immun_release_delay` decides what immunity does the moment a special infected tries to take
hold:

- **Below `0.1`** — the grab never happens. This is the default.
- **`0.1` and above** — the grab is allowed, and the survivor is released that many seconds
  later. Both the survivor and the attacker get a chat line when it happens.

The same delay applies when immunity is switched on for a survivor who is already held.

### Get-up invulnerability

With `l4d_immun_getup_invuln` above `0.1`, a survivor who has just been revived has their
`m_takedamage` set to `DAMAGE_EVENTS_ONLY` for that many seconds: damage events still fire, but
health does not change, so nobody can beat them back down from the ground. Two things worth
knowing: healing is refused for the length of the window, and this stops damage only — a special
infected can still grab the survivor, which is what `l4d_immun_flags` is for.

## API

Other plugins can drive immunity through the `ImmmunControl` methodmap:

| Method | Effect |
|---|---|
| `ImmmunControl(client).ImmunSmoker` / `ImmunHunter` / `ImmunJockey` / `ImmunCharger` / `ImmunTank` | per-player bit, read or write |
| `ImmmunControl.SetAllImmun(type, bool)` | set one global bit and re-apply to everyone in game |
| `ImmmunControl.ApplyGlobal(client)` | re-copy the global mask onto one player |
| `ImmmunControl(client).ReleaseControlDelay(type)` | release that control, honouring the delay ConVar |

## Credits

The release-control approach comes from **豆瓣酱な**'s survivor control module; rewritten around
DHooks detours by **crimson**.

## Changelog

### 1.0.0

- Survivors can be made immune to Smoker, Hunter, Jockey, Charger and Tank control, selectable per
  special through the `l4d_immun_flags` bitmask.
- Per-player immunity masks layered on top of the global mask, plus a plugin API to drive both.
- `l4d_immun_release_delay`: immunity can either refuse a grab outright or let it land and release
  the survivor after a delay, with a chat notice to both sides.
- `l4d_immun_getup_invuln`: a revived survivor takes no damage for a configurable window.
