local QBCore = exports['qb-core']:GetCoreObject()
local ox = exports.oxmysql

-- =======================
-- Mensajes de error legibles
-- =======================
local function humanError(code)
  if not code then return 'Error desconocido.' end
  local map = {
    ['no-player'] = 'Jugador no encontrado.',
    ['not-eligible'] = 'No eres elegible todavía.',
    ['loyalty'] = 'Bloqueado por lealtad tras cambio de bando.',
    ['no-cash'] = 'Fondos insuficientes.',
    ['need-knife'] = 'Primero reclama el Cuchillo.',
    ['locked-by-progression'] = 'Aún no puedes reclamar esta familia (progresión bloqueada).',
    ['need-level0'] = 'Primero reclama el nivel 0 de esta familia.'
  }
  -- no-item:name|need:N|have:H
  if type(code) == 'string' and code:sub(1,7) == 'no-item' then
    local name, need, have = code:match('no%-item:(.-)|need:(%d+)|have:(%d+)')
    return ('Faltan materiales: %s (necesitas %s, tienes %s).'):format(name or '?', need or '?', have or '0')
  end
  return map[code] or ('Error: '..tostring(code))
end

local function ensureSchema()
  ox:executeSync([[
    CREATE TABLE IF NOT EXISTS respawn_work_orders (
      id INT NOT NULL AUTO_INCREMENT,
      citizenid VARCHAR(46) NOT NULL,
      family VARCHAR(32) NOT NULL,
      branch VARCHAR(8) NOT NULL,
      level INT NOT NULL,
      ready_at INT NOT NULL,
      status VARCHAR(12) NOT NULL DEFAULT 'pending',
      PRIMARY KEY (id)
    )
  ]], {})
end

function resumePendingOrders()
  local rows = ox:executeSync("SELECT * FROM respawn_work_orders WHERE status='pending'", {})
  for _,r in ipairs(rows or {}) do
    local remain = math.max(1, (r.ready_at or 0) - os.time())
    SetTimeout(remain*1000, function()
      deliverOrder(r.id, r.citizenid, r.family, r.branch, r.level)
    end)
  end
end

CreateThread(function()
  ensureSchema()          -- ← bloqueante, asegura la tabla
  resumePendingOrders()   -- ← ahora sí hacemos el SELECT
end)


-- =======================
-- Helpers Alignment & Preview
-- =======================
local function getEligibleLevel(src, branch)
  return exports.respawn_alignment:GetEligibleLevel(src, branch)
end
local function canClaimHighTier(src, branch)
  return exports.respawn_alignment:CanClaimHighTier(src, branch)
end

local function getPreview(branch, level)
  local place = Workshops[branch]
  return {
    placeLabel = place and place.label or (branch=='civis' and 'Taller Corporativo' or 'Taller Clandestino'),
    costCash   = (Pricing.cash[level] or 0),
    timeSec    = (Pricing.timeSec[level] or 0),
    materials  = GetMatBlock(branch, level).items or {}
  }
end

QBCore.Functions.CreateCallback('respawn:workshop:getPreview', function(src, cb, family, branch, level)
  cb(getPreview(branch, tonumber(level or 0)))
end)

-- =======================
-- Inventario materiales
-- =======================
local function hasMaterials(src, mat)
  for name,need in pairs(mat or {}) do
    if not QBCore.Functions.HasItem(src, name, need) then
      local player = QBCore.Functions.GetPlayer(src)
      local item = player and player.Functions.GetItemByName(name)
      local count = item and item.amount or 0
      return false, name, need, count
    end
  end
  return true
end

local function removeMaterials(src, mat)
  local player = QBCore.Functions.GetPlayer(src)
  for name,need in pairs(mat or {}) do
    if player then player.Functions.RemoveItem(name, need) end
  end
end

-- =======================
-- Entrega de órdenes
-- =======================
function deliverOrder(id, citizenid, family, branch, level)
  ox:execute('UPDATE respawn_work_orders SET status=? WHERE id=?', {'ready', id})
  for _,src in pairs(QBCore.Functions.GetPlayers()) do
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData.citizenid == citizenid then
      TriggerEvent('respawn:weapons:grantBlueprint', src, family, branch, level)
      TriggerClientEvent('QBCore:Notify', src, ('Trabajo listo: %s +%d (%s)'):format(family, level, branch), 'success')
      logEvent('level_claimed', {pid=citizenid,family=family,branch=branch,level=level,shop=branch})
      return
    end
  end
end

-- =======================
-- Progresión
-- =======================
local function activeGroupIndex(cid, branch, chain)
  local idx = 1
  for _,group in ipairs(chain or {}) do
    local all9 = true
    for _,fam in ipairs(group) do
      local r = ox:executeSync('SELECT 1 FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND branch=? AND level=9 LIMIT 1',
        {cid, fam, branch})
      if not (r and r[1]) then all9 = false break end
    end
    if all9 then idx = idx + 1 else break end
  end
  return idx
end

-- =======================
-- Claim mediante Taller (VALIDACIÓN COMPLETA, incluye NIVEL 0 y PROGRESIÓN)
-- =======================
exports('RequestClaim', function(src, family, branch, level)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return false, 'no-player' end
  branch = (branch=='heat' and 'heat') or 'civis'
  level = tonumber(level or 0) or 0
  local cid = Player.PlayerData.citizenid

  -- Lee Progression desde respawn_weapons (debe existir export en ese recurso)
  local Prog = (exports.respawn_weapons and exports.respawn_weapons.GetProgressionChain and exports.respawn_weapons:GetProgressionChain()) or {}
  local chain = Prog[branch] or {}

  -- Requiere cuchillo (nivel 0 global) para iniciar cualquier rama
  local hasKnife = (ox:executeSync('SELECT 1 FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND level=0 LIMIT 1',
    {cid, 'knife_basic'}) or {})[1]
  if not hasKnife then return false, 'need-knife' end

  -- Validaciones de progresión y elegibilidad
  if level == 0 then
    -- Nivel 0 sólo se puede reclamar en familias del grupo ACTUAL de la rama
    local gid = activeGroupIndex(cid, branch, chain)
    local g = chain[gid]
    local inGroup = false
    if g then for _,f in ipairs(g) do if f == family then inGroup = true break end end end
    if not inGroup then return false, 'locked-by-progression' end
  else
    -- >0 requiere 0 previo en esa familia
    local has0 = (ox:executeSync('SELECT 1 FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND level=0 LIMIT 1',
      {cid, family}) or {})[1]
    if not has0 then return false, 'need-level0' end

    -- Elegibilidad por HEAT/CIVIS
    local eligible = getEligibleLevel(src, branch)
    if level > eligible then return false, 'not-eligible' end

    -- Lealtad para 7..9
    if level >= 7 then
      local ok, why = canClaimHighTier(src, branch)
      if not ok then return false, why or 'loyalty' end
    end
  end

  -- Cobros y creación de orden
  local prev = getPreview(branch, level)
  local costCash = prev.costCash or 0
  local mats = prev.materials or {}

  if Player.Functions.GetMoney('cash') < costCash then return false, 'no-cash' end
  local ok, name, need, have = hasMaterials(src, mats)
  if not ok then return false, ('no-item:%s|need:%d|have:%d'):format(name,need,have) end

  if costCash > 0 then Player.Functions.RemoveMoney('cash', costCash, 'respawn-claim') end
  removeMaterials(src, mats)

  local ready = os.time() + (prev.timeSec or 0)
  local id = ox:executeSync(
    'INSERT INTO respawn_work_orders (citizenid,family,branch,level,ready_at) VALUES (?,?,?,?,?)',
    {cid, family, branch, level, ready}
  )

  SetTimeout((prev.timeSec or 0) * 1000, function()
    deliverOrder(id, cid, family, branch, level)
  end)

  logEvent('level_order', {pid=cid,family=family,branch=branch,level=level,cash=costCash,shop=branch,sec=prev.timeSec})
  return true, { id=id, ready_at=ready, wait=prev.timeSec }
end)

-- =======================
-- Quick-Claim (listado de opciones por familia)
-- =======================
local function listQuickOptions(src, branch)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return {} end
  branch = (branch=='heat' and 'heat') or 'civis'
  local cid = Player.PlayerData.citizenid

  local families = exports.respawn_weapons:GetCatalogFamilies() or {}
  local eligible = exports.respawn_alignment:GetEligibleLevel(src, branch)

  -- Lee la Progression
  local Prog = (exports.respawn_weapons and exports.respawn_weapons.GetProgressionChain and exports.respawn_weapons:GetProgressionChain()) or {}
  local chain = Prog[branch] or {}
  local gid = activeGroupIndex(cid, branch, chain)

  local opts = {}

  for famKey, famData in pairs(families) do
    local branchLevels = famData.levels and famData.levels[branch]
    -- ¿está la familia en el grupo activo?
    local inGroup = false
    local g = chain[gid]
    if g then for _,f in ipairs(g) do if f==famKey then inGroup=true break end end end

    -- ¿tiene nivel 0 ya?
    local has0 = (ox:executeSync('SELECT 1 FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND level=0 LIMIT 1',
      {cid, famKey}) or {})[1]

    -- Prioridad 1: si NO tiene 0 y está en el grupo activo → ofrecer 0 (aunque eligible sea 0)
    if (not has0) and inGroup then
      local prev = {
        placeLabel = (Workshops[branch] and Workshops[branch].label) or branch,
        costCash   = (Pricing.cash[0] or 0),
        timeSec    = (Pricing.timeSec[0] or 0),
        materials  = {} -- si configuras algo para 0, cámbialo aquí
      }
      table.insert(opts, {
        family = famKey,
        family_label = famData.display_name or famKey,
        branch = branch,
        level = 0,
        preview = prev
      })
    elseif branchLevels and #branchLevels > 0 and eligible >= 1 then
      -- Prioridad 2: buscar el mayor nivel ≤ eligible que NO tenga aún
      local rows = ox:executeSync('SELECT level FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND branch=?',
        {cid, famKey, branch}) or {}
      local claimed = {}
      for _,r in ipairs(rows) do claimed[tonumber(r.level)] = true end

      for lvl = eligible, 1, -1 do
        if not claimed[lvl] then
          local prev = {
            placeLabel = (Workshops[branch] and Workshops[branch].label) or branch,
            costCash   = (Pricing.cash[lvl] or 0),
            timeSec    = (Pricing.timeSec[lvl] or 0),
            materials  = GetMatBlock(branch, lvl).items or {}
          }
          table.insert(opts, {
            family = famKey,
            family_label = famData.display_name or famKey,
            branch = branch,
            level = lvl,
            preview = prev
          })
          break
        end
      end
    end
  end

  -- Orden: mayor nivel primero, luego alfabético
  table.sort(opts, function(a,b)
    if a.level == b.level then return (a.family_label < b.family_label) end
    return a.level > b.level
  end)

  return opts
end

QBCore.Functions.CreateCallback('respawn:workshop:listQuickOptions', function(src, cb, branch)
  cb(listQuickOptions(src, branch))
end)

-- =======================
-- Quick-claim específico (familia elegida desde menú)
-- =======================
RegisterNetEvent('respawn:workshop:quickClaimSpecific', function(branch, family, level)
  local src = source
  local ok, info = exports.respawn_workshops:RequestClaim(src, family, branch, level)
  if not ok then
    TriggerClientEvent('QBCore:Notify', src, humanError(info), 'error')
  else
    TriggerClientEvent('QBCore:Notify', src,
      ('Encargo %s +%d → %ds'):format(family, tonumber(level or 0), (info.wait or 0)), 'primary')
  end
end)

-- =======================
-- Fallback quick-claim genérico (toma la primera opción de la lista)
-- =======================
QBCore.Functions.CreateCallback('respawn:workshop:quickCandidate', function(src, cb, branch)
  local list = listQuickOptions(src, branch)
  cb(list and list[1] or nil)
end)

local function quickClaim(src, branch)
  local list = listQuickOptions(src, branch)
  local cand = list and list[1]
  if not cand then
    TriggerClientEvent('QBCore:Notify', src, 'Nada disponible para reclamar en esta rama.', 'error')
    return
  end
  local ok, info = exports.respawn_workshops:RequestClaim(src, cand.family, cand.branch, cand.level)
  if not ok then
    TriggerClientEvent('QBCore:Notify', src, humanError(info), 'error')
  else
    TriggerClientEvent('QBCore:Notify', src,
      ('Encargo %s +%d → %ds'):format(cand.family, cand.level, (info.wait or 0)), 'primary')
  end
end

RegisterNetEvent('respawn:workshop:quickClaim', function(branch)
  quickClaim(source, branch)
end)

-- ========= Comando de test =========
QBCore.Commands.Add('rsp_wquick', '[Respawn] Quick claim de taller', {
  {name='branch', help='heat/civis'}
}, true, function(src, args)
  quickClaim(src, args[1])
end, 'admin')

-- =======================
-- Telemetría
-- =======================
local webhook = GetConvar('respawn_webhook','')
function logEvent(ev, data)
  local row = json.encode({ev=ev, ts=os.date('!%Y-%m-%dT%H:%M:%SZ'), data=data})
  print('[RESPAWN]', row)
  if webhook ~= '' then
    PerformHttpRequest(webhook, function() end, 'POST', row, {['Content-Type']='application/json'})
  end
end
