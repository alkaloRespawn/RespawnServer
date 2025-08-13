local QBCore = exports['qb-core']:GetCoreObject()
local ox = exports.oxmysql

-- Carga catálogo
local catalogJson = LoadResourceFile(GetCurrentResourceName(), 'data/weapons_catalog.json')
local Catalog = json.decode(catalogJson or '{}')

-- SQL
CreateThread(function()
  ox:execute([[
    CREATE TABLE IF NOT EXISTS respawn_weapons_blueprints (
      citizenid VARCHAR(46) NOT NULL,
      family VARCHAR(32) NOT NULL,
      branch VARCHAR(8)  NOT NULL,
      level  INT NOT NULL,
      PRIMARY KEY (citizenid, family, branch, level)
    )]])
  ox:execute([[
    CREATE TABLE IF NOT EXISTS respawn_weapons_equipped (
      citizenid VARCHAR(46) NOT NULL,
      family VARCHAR(32) NOT NULL,
      level  INT NOT NULL,
      PRIMARY KEY (citizenid, family)
    )]])
end)

-- Helpers
local function getEligibleLevel(src, branch)
  return exports.respawn_alignment:GetEligibleLevel(src, branch)
end
local function canClaimHighTier(src, branch)
  return exports.respawn_alignment:CanClaimHighTier(src, branch)
end
local function getActiveBranch(src)
  return exports.respawn_alignment:GetActiveBranch(src)
end

-- Carga estado del jugador
local function loadState(src)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
  local cid = Player.PlayerData.citizenid
  local blue = ox:executeSync('SELECT family, branch, level FROM respawn_weapons_blueprints WHERE citizenid=?',{cid}) or {}
  local eq   = ox:executeSync('SELECT family, level FROM respawn_weapons_equipped WHERE citizenid=?',{cid}) or {}
  local claimed = {}
  for _,r in ipairs(blue) do
    claimed[r.family] = claimed[r.family] or {heat={}, civis={}}
    table.insert(claimed[r.family][r.branch], r.level)
  end
  local equipped = {}
  for _,r in ipairs(eq) do equipped[r.family] = r.level end
  return { claimed=claimed, equipped=equipped }
end

-- ====== CALLBACK: estado para la UI ======
QBCore.Functions.CreateCallback('respawn:weapons:getState', function(src, cb)
  local st = loadState(src) or {claimed={}, equipped={}}
  local state = {
    catalog = Catalog,
    activeBranch = getActiveBranch(src),
    eligible = { heat = getEligibleLevel(src,'heat'), civis = getEligibleLevel(src,'civis') },
    claimed = st.claimed, equipped = st.equipped
  }
  cb(state)
end)

-- ====== EVENTO: reclamar blueprint ======
RegisterNetEvent('respawn:weapons:claim', function(family, branch, level)
  local src = source
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
  level = tonumber(level or 0) or 0
  branch = (branch=='heat' and 'heat') or 'civis'

  -- valida elegibilidad
  local eligible = getEligibleLevel(src, branch)
  if level < 1 or level > eligible then
    TriggerClientEvent('QBCore:Notify', src, 'No eres elegible aún.', 'error'); return
  end

  -- valida +7+8+9 cooldown/branch
  local isHigh = (level>=7)
  if isHigh then
    local ok, why = canClaimHighTier(src, branch)
    if not ok then
      TriggerClientEvent('QBCore:Notify', src, 'Bloqueado por lealtad o bando ('..(why or '')..')', 'error'); return
    end
  end

  -- (Costo: placeholder 0$) — aquí integrarás materiales/economía
  -- Player.Functions.RemoveMoney('cash', COSTO, 'respawn-claim') -> TODO

  -- guarda
  local cid = Player.PlayerData.citizenid
  ox:execute('INSERT IGNORE INTO respawn_weapons_blueprints (citizenid,family,branch,level) VALUES (?,?,?,?)',
    {cid, family, branch, level})

  TriggerClientEvent('QBCore:Notify', src, ('Desbloqueado %s +%d (%s)'):format(family, level, branch), 'success')
end)

-- ====== EVENTO: equipar nivel ======
RegisterNetEvent('respawn:weapons:equip', function(family, level)
  local src = source
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
  level = tonumber(level or 0) or 0

  -- valida que esté reclamado en alguna rama
  local cid = Player.PlayerData.citizenid
  local rows = ox:executeSync(
    'SELECT branch FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND level=? LIMIT 1',
    {cid, family, level}
  )
  if not rows or not rows[1] then
    TriggerClientEvent('QBCore:Notify', src, 'No tienes el blueprint de ese nivel.', 'error'); return
  end

  -- si es high-tier, exige bando activo coincidente
  if level>=7 then
    local active = getActiveBranch(src)
    if active ~= rows[1].branch then
      TriggerClientEvent('QBCore:Notify', src, 'Nivel exclusivo del otro bando.', 'error'); return
    end
  end

  -- aplica "equipado" (cosmético/adjuntos los manejarás en cliente/juego más adelante)
  ox:execute('REPLACE INTO respawn_weapons_equipped (citizenid,family,level) VALUES (?,?,?)',
    {cid, family, level})
  TriggerClientEvent('QBCore:Notify', src, ('Equipado %s +%d'):format(family, level), 'success')
end)
