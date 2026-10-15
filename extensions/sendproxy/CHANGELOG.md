# Changelog

## Supported SourceMod versions

- **1.12 and earlier** — supported. This is the build to use.
- **1.13** — **not supported. Do not use it.** Support was dropped outright: no
  1.13 build is shipped, and there is no plan to bring it back.

The version number below is the one baked into the binaries; support status is
separate from it and does not bump the version.

## 3.4.1 — Internal cleanup

- Reworked the per-client override path internally and reduced how many entities get marked as changed
  on each client's pack. Nothing changes for plugins or players.

## 3.4.0 — Overrides reach every player

- Fixed an override only taking effect on one client per frame — every other client saw that client's
  values.
- Fixed a server crash on Windows shortly after the first override was queued.
- The extension now refuses to load when its gamedata lookups fail, instead of loading and then
  silently doing nothing.

## 3.3.1 — Game rules overrides keep updating

- Fixed an override on the game rules entity getting stuck on its first value.

## 3.3.0 — Add CTerrorGameRulesProxy support

- Fixed overrides on the game rules entity (`terror_gamerules`) having no effect.

## 3.2.2 — Override unwinding and unload cleanup

- Fixed an entity being left with a stale value when the same property was overridden more than
  once in a single frame.
- Fixed queued string changes leaking when the extension unloaded.
- The Linux artifact no longer exports internal symbols.

## 3.2.1 — Removed the IGameHelpers dependency

- Fixed a load failure on early SourceMod 1.12 builds caused by an `IGameHelpers` interface
  whose version did not match.
- The extension no longer uses `IGameHelpers` or `IPlayerManager`; it resolves the entity list
  through its own gamedata instead.
- The `AddChange*` natives now return `false` instead of queueing a change they cannot apply.

## 3.2.0 — SourceMod 1.12 and 1.13 compatibility

- Fixed load failures on builds whose `SMINTERFACE_EXTENSIONAPI_VERSION` did not match. Two
  builds are now provided, one per API version.
- Added an `EHandle` methodmap for `AddChangeEHandle`.

## 3.1.0 — Reduced C runtime requirements

- Fixed glibc and libstdc++ linkage; the extension now requires only glibc 2.7, lower than
  SourceMod itself needs.

## 3.0.0 — Initial release

- Initial public release.
