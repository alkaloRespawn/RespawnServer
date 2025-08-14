local QBCore = exports['qb-core']:GetCoreObject()
local ox = exports.oxmysql
local inv = exports.ox_inventory

-- ========= NUEVO: enumerar opciones quick-claim por familia =========
local function listQuickOptions(src, branch)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return {} end
  branch = (branch=='heat' and 'heat') or 'civis'
  local cid = Player.PlayerData.citizenid
  local families = exports.respawn_weapons:GetCatalogFamilies() or {}
  local eligible = exports.respawn_alignment:GetEligibleLevel(src, branch)
  if eligible < 1 then return {} end

  local opts = {}
  for famKey, famData in pairs(families) do
    -- ¿qué niveles de esa rama existen?
    local branchLevels = famData.levels and famData.levels[branch]
    if branchLevels and #branchLevels > 0 then
      -- blueprint ya reclamados por esta familia/rama
      local rows = ox:executeSync(
        'SELECT level FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND branch=?',
        {cid, famKey, branch}
      ) or {}
      local claimed = {}
      for _,r in ipairs(rows) do claimed[tonumber(r.level)] = true end

      -- busca el máximo nivel ≤ elegible que no está reclamado
      local candidate = nil
      for lvl = eligible, 1, -1 do
        if not claimed[lvl] then
          candidate = lvl; break
        end
      end

      if candidate then
        local prev = {
          placeLabel = (Workshops[branch] and Workshops[branch].label) or branch,
          costCash   = (Pricing.cash[candidate] or 0),
          timeSec    = (Pricing.timeSec[candidate] or 0),
          materials  = GetMatBlock(branch, candidate).items or {}
        }
        table.insert(opts, {
          family = famKey,
          family_label = famData.display_name or famKey,
          branch = branch,
          level = candidate,
          preview = prev
        })
      end
    end
  end

  -- Ordena opciones: mayor nivel primero, luego por nombre de familia
  table.sort(opts, function(a,b)
    if a.level == b.level then return (a.family_label < b.family_label) end
    return a.level > b.level
  end)
  return opts
end

QBCore.Functions.CreateCallback('respawn:workshop:listQuickOptions', function(src, cb, branch)
  cb(listQuickOptions(src, branch))
end)

-- ========= NUEVO: quick-claim específico (familia elegida) =========
RegisterNetEvent('respawn:workshop:quickClaimSpecific', function(branch, family, level)
  local src = source
  local ok, info = exports.respawn_workshops:RequestClaim(src, family, branch, level)
  if not ok then
    TriggerClientEvent('QBCore:Notify', src, 'No se pudo iniciar: '..(info or 'error'), 'error')
  else
    TriggerClientEvent('QBCore:Notify', src,
      ('Encargo %s +%d → %ds'):format(family, tonumber(level or 0), (info.wait or 0)), 'primary')
  end
end)

-- Cola SQL
CreateThread(function()
  ox:execute([[
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
  ]])
  resumePendingOrders()
end)

local function now() return os.time() end

-- reprogramar pendientes
function resumePendingOrders()
  local rows = ox:executeSync("SELECT * FROM respawn_work_orders WHERE status='pending'", {})
  for _,r in ipairs(rows or {}) do
    local remain = math.max(1, r.ready_at - now())
    SetTimeout(remain*1000, function() deliverOrder(r.id, r.citizenid, r.family, r.branch, r.level) end)
  end
end

-- elegibilidad/alignment
local function getEligibleLevel(src, branch)
  return exports.respawn_alignment:GetEligibleLevel(src, branch)
end
local function canClaimHighTier(src, branch)
  return exports.respawn_alignment:CanClaimHighTier(src, branch)
end
local function getActiveBranch(src)
  return exports.respawn_alignment:GetActiveBranch(src)
end

-- preview coste/tiempo/materiales
local function getPreview(branch, level)
  local place = Workshops[branch]
  return {
    placeLabel = place and place.label or (branch=='civis' and 'Taller Corporativo' or 'Taller Clandestino'),
    costCash   = Pricing.cash[level] or 0,
    timeSec    = Pricing.timeSec[level] or 0,
    materials  = GetMatBlock(branch, level).items or {}
  }
end

QBCore.Functions.CreateCallback('respawn:workshop:getPreview', function(src, cb, family, branch, level)
  cb(getPreview(branch, tonumber(level or 1)))
end)

-- util inventario
local function hasMaterials(src, mat)
  for name,need in pairs(mat or {}) do
    local count = exports.ox_inventory:GetItemCount(src, name)
    if (count or 0) < need then return false, name, need, (count or 0) end
  end
  return true
end
local function removeMaterials(src, mat)
  for name,need in pairs(mat or {}) do exports.ox_inventory:RemoveItem(src, name, need) end
end

-- entregar orden → grant blueprint
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

-- solicitar claim (validación completa)
exports('RequestClaim', function(src, family, branch, level)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return false, 'no-player' end
  branch = (branch=='heat' and 'heat') or 'civis'
  level = tonumber(level or 0) or 0
  local eligible = getEligibleLevel(src, branch)
  if level < 1 or level > eligible then return false, 'not-eligible' end
  if level >= 7 then
    local ok, why = canClaimHighTier(src, branch)
    if not ok then return false, why or 'loyalty' end
  end
  local prev = getPreview(branch, level)
  local costCash = prev.costCash or 0
  local mats = prev.materials or {}

  if Player.Functions.GetMoney('cash') < costCash then return false, 'no-cash' end
  local ok, name, need, have = hasMaterials(src, mats)
  if not ok then return false, ('no-item:%s|need:%d|have:%d'):format(name,need,have) end

  if costCash>0 then Player.Functions.RemoveMoney('cash', costCash, 'respawn-claim') end
  removeMaterials(src, mats)

  local cid = Player.PlayerData.citizenid
  local ready = now() + (prev.timeSec or 0)
  local id = ox:executeSync('INSERT INTO respawn_work_orders (citizenid,family,branch,level,ready_at) VALUES (?,?,?,?,?)',
    {cid, family, branch, level, ready})

  SetTimeout((prev.timeSec or 0)*1000, function() deliverOrder(id, cid, family, branch, level) end)
  logEvent('level_order', {pid=cid,family=family,branch=branch,level=level,cash=costCash,shop=branch,sec=prev.timeSec})
  return true, { id=id, ready_at=ready, wait=prev.timeSec }
end)

-- ===== Quick-Claim: siguiente nivel elegible NO reclamado (por rama) =====
local function nextClaimableFor(src, branch)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return nil end
  local cid = Player.PlayerData.citizenid
  local families = exports.respawn_weapons:GetCatalogFamilies()
  local eligible = getEligibleLevel(src, branch)
  if eligible < 1 then return nil end

  for famKey,_ in pairs(families) do
    local rows = ox:executeSync('SELECT level FROM respawn_weapons_blueprints WHERE citizenid=? AND family=? AND branch=?',
      {cid, famKey, branch}) or {}
    local claimed = {}
    for _,r in ipairs(rows) do claimed[tonumber(r.level)] = true end
    for lvl=eligible,1,-1 do
      if not claimed[lvl] then
        return { family=famKey, level=lvl, branch=branch }
      end
    end
  end
  return nil
end

QBCore.Functions.CreateCallback('respawn:workshop:quickCandidate', function(src, cb, branch)
  cb(nextClaimableFor(src, branch))
end)

RegisterNetEvent('respawn:workshop:quickClaim', function(branch)
  local src = source
  local cand = nextClaimableFor(src, branch)
  if not cand then
    TriggerClientEvent('QBCore:Notify', src, 'Nada disponible para reclamar en esta rama.', 'error'); return
  end
  local ok, info = exports.respawn_workshops:RequestClaim(src, cand.family, cand.branch, cand.level)
  if not ok then
    TriggerClientEvent('QBCore:Notify', src, 'No se pudo iniciar: '..(info or 'error'), 'error')
  else
    TriggerClientEvent('QBCore:Notify', src, ('Encargo %s +%d → %ds'):format(cand.family, cand.level, (info.wait or 0)), 'primary')
  end
end)

-- Telemetría simple
local webhook = GetConvar('respawn_webhook','')
function logEvent(ev, data)
  local row = json.encode({ev=ev, ts=os.date('!%Y-%m-%dT%H:%M:%SZ'), data=data})
  print('[RESPAWN]', row)
  if webhook ~= '' then
    PerformHttpRequest(webhook, function() end, 'POST', row, {['Content-Type']='application/json'})
  end
end
