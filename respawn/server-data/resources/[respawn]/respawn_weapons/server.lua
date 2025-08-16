local QBCore = exports['qb-core']:GetCoreObject()
local ox = exports.oxmysql
local Catalog = {}

local function loadCatalog()
  local raw = LoadResourceFile(GetCurrentResourceName(), 'data/weapons_catalog.json')
  assert(raw, '^1[respawn_weapons]^7 weapons_catalog.json no encontrado')
  local ok, decoded = pcall(json.decode, raw)
  assert(ok and decoded, '^1[respawn_weapons]^7 JSON inválido en weapons_catalog.json')
  Catalog = decoded
end

loadCatalog()

exports('GetCatalogFamilies', function()
  return Catalog and Catalog.families or {}
end)

exports('GetProgressionChain', function()
  return Progression
end)


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

-- ====== EVENTO: reclamar blueprint (vía taller) ======
RegisterNetEvent('respawn:weapons:claim', function(family, branch, level)
  local src = source
  local ok, info = exports.respawn_workshops:RequestClaim(src, family, branch, level)
  if not (Catalog and Catalog.families and Catalog.families[family]) then
  TriggerClientEvent('QBCore:Notify', src, 'Familia de arma inválida.', 'error'); return
  end

  if not ok then
    TriggerClientEvent('QBCore:Notify', src, 'No se pudo iniciar el trabajo: '..(info or 'error'), 'error')
  else
    local wait = (info and info.wait) or 0
    TriggerClientEvent('QBCore:Notify', src, ('Encargo iniciado: listo en %ds'):format(wait), 'primary')
  end
  end)


-- ====== Grant interno (llamado por workshops al completar) ======
AddEventHandler('respawn:weapons:grantBlueprint', function(src, family, branch, level)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
  local cid = Player.PlayerData.citizenid
  ox:execute('INSERT IGNORE INTO respawn_weapons_blueprints (citizenid,family,branch,level) VALUES (?,?,?,?)',
    {cid, family, branch, level})
  TriggerClientEvent('QBCore:Notify', src, ('Desbloqueado %s +%d (%s)'):format(family, level, branch), 'success')
end)

local function playerHasBlueprint(cid, family, branch, level)
  local r = ox:executeSync('SELECT 1 FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND branch=? AND level=? LIMIT 1',
    {cid, family, branch, level})
  return r and r[1] ~= nil
end

local function playerHasAnyLevel0(cid, family)
  -- Nivel 0 puede existir en heat o civis (lo tratamos simétrico)
  local r = ox:executeSync('SELECT 1 FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND level=0 LIMIT 1',
    {cid, family})
  return r and r[1] ~= nil
end

local function groupCompleted(cid, branch, families)
  for _,fam in ipairs(families) do
    if not playerHasBlueprint(cid, fam, branch, 9) then
      return false
    end
  end
  return true
end

local function getActiveGroupIndex(cid, branch)
  -- 0 = antes del Grupo 1 (solo cuchillo). 1..N = grupos de Progression[branch]
  -- requisito previo: tener cuchillo (nivel 0) reclamado
  local hasKnife = playerHasAnyLevel0(cid, 'knife_basic')
  if not hasKnife then return 0 end
  local chain = Progression[branch] or {}
  local idx = 1
  for i, families in ipairs(chain) do
    if groupCompleted(cid, branch, families) then
      idx = i + 1
    else
      break
    end
  end
  return idx -- si devuelve 1: estás en Grupo 1; si devuelve #chain+1: por encima del último grupo
end

local function familyInGroup(branch, idx, family)
  local chain = Progression[branch] or {}
  local g = chain[idx]
  if not g then return false end
  for _,f in ipairs(g) do if f == family then return true end end
  return false
end



-- ====== EVENTO: equipar nivel ======
local function equipLevel(src, family, level)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
  level = tonumber(level or 0) or 0
  local cid = Player.PlayerData.citizenid
  local rows = ox:executeSync(
    'SELECT branch FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND level=? LIMIT 1',
    {cid, family, level}
  )
  if not rows or not rows[1] then
    TriggerClientEvent('QBCore:Notify', src, 'No tienes el blueprint de ese nivel.', 'error'); return
  end
  if level>=7 then
    local active = getActiveBranch(src)
    if active ~= rows[1].branch then
      TriggerClientEvent('QBCore:Notify', src, 'Nivel exclusivo del otro bando.', 'error'); return
    end
  end
  ox:execute('REPLACE INTO respawn_weapons_equipped (citizenid,family,level) VALUES (?,?,?)',
    {cid, family, level})
  TriggerClientEvent('QBCore:Notify', src, ('Equipado %s +%d'):format(family, level), 'success')
end

RegisterNetEvent('respawn:weapons:equip', function(family, level)
  equipLevel(source, family, level)
end)

-- ========= Comandos de test (admin) =========
QBCore.Commands.Add('rsp_grantbp', '[Respawn] Otorga blueprint de arma', {
  {name='family', help='familia'},
  {name='branch', help='heat/civis'},
  {name='level',  help='0-9'}
}, true, function(src, args)
  local fam = tostring(args[1] or '')
  local br  = tostring(args[2] or '')
  local lvl = tonumber(args[3] or 0) or 0
  TriggerEvent('respawn:weapons:grantBlueprint', src, fam, br, lvl)
end, 'admin')

QBCore.Commands.Add('rsp_equip', '[Respawn] Equipa nivel de arma', {
  {name='family', help='familia'},
  {name='level',  help='0-9'}
}, true, function(src, args)
  local fam = tostring(args[1] or '')
  local lvl = tonumber(args[2] or 0) or 0
  equipLevel(src, fam, lvl)
end, 'admin')

