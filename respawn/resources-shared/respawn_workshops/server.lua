local QBCore = exports['qb-core']:GetCoreObject()
local ox = exports.oxmysql
local inv = exports.ox_inventory

-- SQL: cola de trabajo
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

-- Reprograma órdenes pendientes tras reinicio
function resumePendingOrders()
  local rows = ox:executeSync("SELECT * FROM respawn_work_orders WHERE status='pending'", {})
  for _,r in ipairs(rows or {}) do
    local remain = math.max(1, r.ready_at - now())
    SetTimeout(remain*1000, function()
      deliverOrder(r.id, r.citizenid, r.family, r.branch, r.level)
    end)
  end
end

-- Prev: coste/tiempo/lugar/materiales
local function getPreview(branch, level)
  local place = Workshops[branch]
  return {
    placeLabel = place and place.label or (branch=='civis' and 'Taller Corporativo' or 'Taller Clandestino'),
    costCash   = Pricing.cash[level] or 0,
    timeSec    = Pricing.timeSec[level] or 0,
    materials  = GetMatBlock(branch, level).items or {}
  }
end

-- Export/callback para UI
lib = lib or {} -- evita error si usas ox_lib; no es requerido
QBCore.Functions.CreateCallback('respawn:workshop:getPreview', function(src, cb, family, branch, level)
  cb(getPreview(branch, tonumber(level or 1)))
end)

-- Validaciones de alignment/elegibilidad
local function getEligibleLevel(src, branch)
  return exports.respawn_alignment:GetEligibleLevel(src, branch)
end
local function canClaimHighTier(src, branch)
  return exports.respawn_alignment:CanClaimHighTier(src, branch)
end
local function getActiveBranch(src)
  return exports.respawn_alignment:GetActiveBranch(src)
end

-- Util: contar items en ox_inventory
local function hasMaterials(src, mat) -- mat = { itemName = count, ... }
  for name,need in pairs(mat) do
    local count = exports.ox_inventory:GetItemCount(src, name)
    if (count or 0) < need then return false, name, need, count or 0 end
  end
  return true
end

local function removeMaterials(src, mat)
  for name,need in pairs(mat) do
    inv:RemoveItem(src, name, need)
  end
end

-- Entregar la orden: concede blueprint
function deliverOrder(id, citizenid, family, branch, level)
  ox:execute('UPDATE respawn_work_orders SET status=? WHERE id=?', {'ready', id})
  -- Busca src online de ese citizenid
  for _,src in pairs(QBCore.Functions.GetPlayers()) do
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData.citizenid == citizenid then
      TriggerEvent('respawn:weapons:grantBlueprint', src, family, branch, level)
      TriggerClientEvent('QBCore:Notify', src, ('Trabajo listo: %s +%d (%s)'):format(family, level, branch), 'success')
      logEvent('level_claimed', {pid=citizenid,family=family,branch=branch,level=level,shop=branch})
      return
    end
  end
  -- Si no está online, quedará como 'ready'; al conectar y abrir panel, puedes mostrar recogida
end

-- =========== API principal ===========
-- RequestClaim: valida, cobra, guarda orden y programa entrega
exports('RequestClaim', function(src, family, branch, level)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return false, 'no-player' end
  level = tonumber(level or 0) or 0; branch = (branch=='heat' and 'heat') or 'civis'

  -- elegibilidad
  local eligible = getEligibleLevel(src, branch)
  if level < 1 or level > eligible then return false, 'not-eligible' end
  if level >= 7 then
    local ok, why = canClaimHighTier(src, branch)
    if not ok then return false, why or 'loyalty' end
  end

  -- coste y materiales
  local prev = getPreview(branch, level)
  local costCash = prev.costCash
  local mats = prev.materials

  -- check fondos
  if Player.Functions.GetMoney('cash') < costCash then return false, 'no-cash' end
  -- check items
  local ok, name, want, have = hasMaterials(src, mats)
  if not ok then return false, ('no-item:%s|need:%d|have:%d'):format(name, want, have) end

  -- cobrar
  if costCash > 0 then Player.Functions.RemoveMoney('cash', costCash, 'respawn-workshop-claim') end
  removeMaterials(src, mats)

  -- crear orden
  local ready = now() + (prev.timeSec or 0)
  local cid = Player.PlayerData.citizenid
  local id = ox:executeSync('INSERT INTO respawn_work_orders (citizenid,family,branch,level,ready_at) VALUES (?,?,?,?,?)',
    {cid, family, branch, level, ready})
  -- programar entrega
  local waitMs = math.max(1, (prev.timeSec or 0)*1000)
  SetTimeout(waitMs, function()
    deliverOrder(id, cid, family, branch, level)
  end)
  -- log
  logEvent('level_order', {pid=cid,family=family,branch=branch,level=level,cash=costCash,shop=branch,sec=prev.timeSec})

  return true, { id=id, ready_at=ready, wait=prev.timeSec }
end)

-- Telemetría simple (consola + webhook opcional)
local webhook = GetConvar('respawn_webhook','')
function logEvent(ev, data)
  local row = json.encode({ev=ev, ts=os.date('!%Y-%m-%dT%H:%M:%SZ'), data=data})
  print('[RESPAWN]', row)
  if webhook ~= '' then
    PerformHttpRequest(webhook, function() end, 'POST', row, {['Content-Type']='application/json'})
  end
end
