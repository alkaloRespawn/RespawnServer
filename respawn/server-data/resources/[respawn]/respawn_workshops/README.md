# respawn_workshops

Crafting workshops that allow players to claim weapon blueprints.

## Exports & Callbacks

### Server exports
```lua
local ok, info = exports.respawn_workshops:RequestClaim(source, family, branch, level)
```

### QBCore callbacks
- `respawn:workshop:getPreview` → preview table `{ placeLabel, costCash, timeSec, materials }`
  ```lua
  QBCore.Functions.TriggerCallback('respawn:workshop:getPreview', cb, family, branch, level)
  ```
- `respawn:workshop:listQuickOptions` → array of quick-claim options for a branch.
- `respawn:workshop:quickCandidate` → first quick-claim option (or nil).

## Events

### Client → Server
- `respawn:workshop:quickClaimSpecific(branch, family, level)` – inicia encargo de una familia concreta.
- `respawn:workshop:quickClaim(branch)` – intenta reclamar automáticamente la mejor opción disponible.

### Server → Client
- (none; al completar se dispara `respawn:weapons:grantBlueprint` hacia el recurso de armas).

## Database
`respawn_work_orders`:
- `id` INT AUTO_INCREMENT PRIMARY KEY
- `citizenid` VARCHAR(46)
- `family` VARCHAR(32)
- `branch` VARCHAR(8)
- `level` INT
- `ready_at` INT
- `status` VARCHAR(12) DEFAULT 'pending'
- INDEX `citizenid`
- INDEX `status_ready_at` (`status`, `ready_at`)

## Convars
- `respawn_webhook` – URL opcional para telemetría/audit log.
- `respawn_locale` – locale global (no usado directamente).

## Load order & dependencies
- Requiere `qb-core`, `oxmysql`, `respawn_alignment` y `respawn_weapons`.
- Debe iniciarse **después** de `respawn_weapons` para poder leer su catálogo/progresión.
