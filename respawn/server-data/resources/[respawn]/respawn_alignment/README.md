# respawn_alignment

Core HEAT/CIVIS alignment tracking used by other Respawn systems.

## Exports & Callbacks

### Server exports
```lua
local branch = exports.respawn_alignment:GetActiveBranch(source)
local level = exports.respawn_alignment:GetEligibleLevel(source, 'heat')
local ok, err = exports.respawn_alignment:CanClaimHighTier(source, 'civis')
local tiers = exports.respawn_alignment:GetExclusiveHighTiers()
```

### QBCore callbacks
- `respawn:alignment:getClientState` → returns `{ heat, civis, active, eligible = { heat, civis } }`
  ```lua
  QBCore.Functions.TriggerCallback('respawn:alignment:getClientState', cb)
  ```

## Events

### Client → Server
- `respawn:alignment:addHeat(amount)`
- `respawn:alignment:addCivis(amount)`

### Server → Client
- `respawn:alignment:clientState` → `{ heat, civis, active, eligible }`

### Debug
- `respawn:alignment:debug` (emits full state for diagnostics)

## Database
`respawn_alignment` table:

| column       | type         | notes                             |
|--------------|--------------|-----------------------------------|
| citizenid    | VARCHAR(46)  | primary key                       |
| heat_score   | INT          | default 0                         |
| civis_score  | INT          | default 0                         |
| active_branch| VARCHAR(8)   | default 'neutral'                 |
| last_switch  | INT          | unix timestamp of last branch swap|

## Convars
- `respawn_webhook` – optional URL to receive telemetry/audit events.
- `respawn_locale` – locale for UI resources (not used directly here).

## Load order & dependencies
- Requires `qb-core` and `oxmysql`.
- Start this resource **before** `respawn_weapons`, `respawn_workshops` and `respawn_hud` so they can read alignment data.
