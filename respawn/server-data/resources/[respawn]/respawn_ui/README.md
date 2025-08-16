# respawn_ui

NUI panel for browsing and claiming weapons, plus basic HUD hooks.

## Exports & Callbacks
Este recurso no expone exports propios.

### Callbacks consumidos
- `respawn:weapons:getState` – estado completo para poblar el panel.
- `respawn:workshop:getPreview` – datos de coste/tiempo/materiales para "inspeccionar".
  ```lua
  QBCore.Functions.TriggerCallback('respawn:weapons:getState', cb)
  QBCore.Functions.TriggerCallback('respawn:workshop:getPreview', cb, family, branch, level)
  ```

## Events

### Client → Server
- `respawn:weapons:claim(family, branch, level)`
- `respawn:weapons:equip(family, level)`

### UI (NUI) ↔ Client
- `ui_ready` – NUI pide estado inicial.
- `close` – cierra el panel y libera foco.
- `claim` – solicita reclamar blueprint.
- `equip` – solicita equipar nivel.
- `inspect` – consulta preview de taller.

## Database
- Ninguna tabla propia.

## Convars
- `respawn_locale` – controla el idioma de la NUI.
- `respawn_webhook` – telemetría global (no usado directamente).

## Load order & dependencies
- Requiere `qb-core`.
- Depende de `respawn_weapons` y `respawn_workshops` para callbacks; iniciar después de ambos.
