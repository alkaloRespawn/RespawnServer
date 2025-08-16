# respawn_hud

Simple client HUD showing HEAT/CIVIS/REP bars.

## Exports & Callbacks
- Este recurso no expone exports ni callbacks.

## Events

### Server → Client
- `respawn:alignment:clientState` – actualiza valores de HEAT/CIVIS/REP.

### Client commands
- `respawn_hud` / tecla F7 – mostrar u ocultar el HUD.

## Database
- No utiliza tablas propias.

## Convars
- `respawn_locale` – locale global (sin uso directo).
- `respawn_webhook` – telemetría global (no usado).

## Load order & dependencies
- Requiere que `respawn_alignment` esté iniciado para recibir el evento `clientState`.
- Solo contiene scripts de cliente; puede iniciarse después de `respawn_alignment`.
