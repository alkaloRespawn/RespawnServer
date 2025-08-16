# respawn_weapons

Weapon catalog and player progression for Respawn.

## Exports & Callbacks

### Server exports
```lua
local families = exports.respawn_weapons:GetCatalogFamilies()
local progression = exports.respawn_weapons:GetProgressionChain()
```

### QBCore callbacks
- `respawn:weapons:getState` → returns `{ catalog, activeBranch, eligible = { heat, civis }, claimed, equipped, exclusiveHighTiers }`
  ```lua
  QBCore.Functions.TriggerCallback('respawn:weapons:getState', cb)
  ```

## Events

### Client → Server
- `respawn:weapons:claim(family, branch, level)` – inicia un trabajo de taller.
- `respawn:weapons:equip(family, level)` – equipa un nivel ya reclamado.

### Server → Client
- `respawn:weapons:equipped(family, level)` – disparado tras equipar correctamente.

### Server → Server
- `respawn:weapons:grantBlueprint(src, family, branch, level)` – usado por talleres al completar un encargo.

## Database
`respawn_weapons_blueprints`:
- `citizenid` VARCHAR(46)
- `family` VARCHAR(32)
- `branch` VARCHAR(8)
- `level` INT
- PRIMARY KEY (`citizenid`, `family`, `branch`, `level`)

`respawn_weapons_equipped`:
- `citizenid` VARCHAR(46)
- `family` VARCHAR(32)
- `level` INT
- PRIMARY KEY (`citizenid`, `family`)

## Convars
- `respawn_webhook` – URL opcional para telemetría/audit log.
- `respawn_locale` – locale para UI (usado por `respawn_ui`).

## Load order & dependencies
- Requiere `qb-core`, `oxmysql` y `respawn_alignment`.
- Debe iniciarse **antes** de `respawn_workshops` (que lee su catálogo/progresión).
- `respawn_workshops` debe estar activo para procesar `respawn:weapons:claim`.
