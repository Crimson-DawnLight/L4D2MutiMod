# Changelog

## 1.0.0 — Initial release

First public build of the Left4DHooks extension.

- **Methodmap API** across 11 domains: game rules, players, entities, infected, nav areas,
  triggers, the director, entity finding, projectiles and weapons.
- **Legacy L4DD names** registered for source compatibility; the include marks each one
  `deprecated` and points at its methodmap replacement.
- **167 forwards** over game events and engine functions, including the `_Post` variants.
- **Support enums** from the L4DD include (`PointerType`, the timer enums, the weapon-attribute
  enums), so existing plugins compile without extra includes.
- Registers the `left4dhooks` extension library.
- **No gamedata**: signatures and offsets are built into the extension.
