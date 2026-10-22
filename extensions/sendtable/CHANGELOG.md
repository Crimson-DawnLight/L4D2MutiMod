# Changelog

## 1.0.0 — Initial release

- `SendTable.SetBits`, `SendTable.SetElementBits` and `SendTable.GetBits`.
- Call the natives from `OnPluginStart`. Not hot-reloadable — restart the server
  after changing values.
- Send tables that grow past the wire limit are split at integer boundaries and
  re-framed on the same message.
- No gamedata.
