# [L4D2] Block Messages

> Silence the game's own chat and notice spam, one bit at a time.

Suppresses messages the game prints on its own — the "XXX is now idle" chat line, the
ConVar-change notice, death / incapacitated / defibrillator / disconnect announcements and
more. Each message class is one bit in a single ConVar mask, so you keep exactly the notices
you want and drop the rest.

| Bit | Value | Blocked | Mechanism |
|---|---|---|---|
| 0 | `1` | the idle-spectator chat notice (`#L4D_idle_spectator`) | `TextMsg` user message |
| 1 | `2` | `PZDmgMsg` notices | `PZDmgMsg` user message |
| 2 | `4` | ConVar-change notice | `server_cvar` event |
| 3 | `8` | player death notice | `player_death` event, broadcast disabled |
| 4 | `16` | player incapacitated notice | `player_incapacitated` event, broadcast disabled |
| 5 | `32` | defibrillator used notice | `defibrillator_used` event, broadcast disabled |
| 6 | `64` | player disconnect notice | `player_disconnect` event, broadcast disabled |

All bits are set by default. A mask of `0` blocks nothing.

## ⚠ Caveat — blocking `player_death` may break round-end stats

The source notes that disabling the `player_death` broadcast (bit 3) can also disturb the
game's own end-of-round scoreboard statistics. Clear bit 3 if you rely on that screen.

## Install

| File | Where |
|---|---|
| `scripting/l4d2_block_msgs.smx` | `addons/sourcemod/plugins/` |

## ConVars

| ConVar | Default | Meaning |
|---|---|---|
| `l4d_block_msgs_flags` | `127` | bitmask of messages to block; see the bit table above. Range `0`–`127` |

## Commands

| Command | Flag | Effect |
|---|---|---|
| `sm_blockmsg <flag>` | none (all clients) | set the block mask; `<flag>` is `0`–`127`. Running it with no argument prints the current value |

## Requirements

- SourceMod **1.12**.
- No external plugin or extension is required at runtime — only SourceMod's `sdkhooks`
  include, which ships with SourceMod.

## Credits

Author: **crimson**.

## Changelog

### 1.0.0

- Blocks the game's idle-spectator `TextMsg` notice, `PZDmgMsg`, the `server_cvar` notice,
  and the death / incapacitated / defibrillator / disconnect events.
- Per-class control through the `l4d_block_msgs_flags` bitmask and the `sm_blockmsg` command.
