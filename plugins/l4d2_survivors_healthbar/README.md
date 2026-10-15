# [L4D2] Survivors Healthbar

> See your team's health bars without holding a healing item.

Draws the **native** L4D2 survivor health bar — the one the game shows you when you hold a
healing item — while you keep your real weapon. It does this by lying to **one client** at
packet time through the SendProxy extension: the lie exists only in that client's copy of
the world, and the server is untouched.

Three overrides, all queued per observer:

| # | Overridden | Effect |
|---|---|---|
| ① | the observer's own `m_hActiveWeapon` → a healing item netclass | the client's HUD believes it holds meds, so it draws the teammate bars |
| ② | the observer's own `m_lifeState` → `0` (`LIFE_ALIVE`) | dead players and spectators draw HUD elements too |
| ③ | each downed teammate's `m_isIncapacitated` → `0` | the observer sees that teammate's bar |

## ⚠ Caveat — this breaks client prediction

Override ① lies to the client about what it is holding, and the client uses that to predict and
play its own weapon effects. While ① is applied:

- **gunshots are silent** — no firing sound
- **the view and muzzle shake violently** — recoil no longer matches the weapon

This is not introduced by this port; the old plugin told the same lie with the same result. There
is no server-side alternative — the server cannot draw HUD elements.

Mitigation (untested): skip ① on frames where `GetClientButtons(client) & IN_ATTACK` is set. The
cost is the bars flickering while you hold the trigger. ② and ③ do not touch prediction and are
unaffected by this.

## Install

| File | Where |
|---|---|
| `l4d2_survivors_healthbar.smx` | `addons/sourcemod/plugins/` |

SourceMod **1.12**. Requires the [SendProxy](../../extensions/sendproxy/) extension from this
repository — the `.sp` sits next to it if you want to build it yourself.

## ConVars

Config file: `cfg/sourcemod/l4d2_survivors_healthbar.cfg`

| ConVar | Default | Meaning |
|---|---|---|
| `l4d2_survivors_healthbar_enable` | `1` | 1 = enabled, 0 = disabled |
| `l4d2_survivors_healthbar_key` | `16` | key bit (`1 << bit`) to hold; `-1` = no key needed. `IN_SCORE` (Tab) = 16 |
| `l4d2_survivors_healthbar_fov` | `90.0` | bars show only when at least one teammate is inside this cone |
| `l4d2_survivors_healthbar_dead` | `1` | let dead players and spectators see them (override ②) |
| `l4d2_survivors_healthbar_incap` | `1` | show downed teammates' bars (override ③) |
| `l4d2_survivors_healthbar_distance` | `1000.0` | max distance, `0` = unlimited |

## Commands

| Command | Effect |
|---|---|
| `sm_hp_toggle` / `sm_togglehp` | toggle the health bar |
| `+hp_view` / `-hp_view` | hold to show, release to hide |

## Credits

Original plugin by xZk (AlliedModders). Ported to the current SendProxy API by Crimson — the
porting notes are in the header of `l4d2_survivors_healthbar.sp`.

## Changelog

### 2.0 — Ported to SendProxy 3.x

- Rewritten without hooks. The old version hooked an entity property and mutated the value from
  a callback; this one queues per-observer overrides every frame from `OnSendProxyPre()`.
- With the hooks gone, the whole hook-lifecycle bookkeeping went with them — including the
  `player_team` / spawn / death / incap event sync that existed only to manage it.
