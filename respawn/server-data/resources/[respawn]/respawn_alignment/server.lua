local QBCore = exports['qb-core']:GetCoreObject()
local ox = exports.oxmysql

local H = AlignmentConfig.Hysteresis
local CD = AlignmentConfig.LoyaltyCooldownHours * 3600

local SAVE_DELAY = 2500 -- ms
local SaveTimers = {}

-- cache en memoria
local P = {} -- [src] = {citizenid, heat=0, civis=0, active='neutral', lastSwitch=0}

-- SQL bootstrap
CreateThread(function()
    ox:execute([[
      CREATE TABLE IF NOT EXISTS respawn_alignment (
        citizenid VARCHAR(46) PRIMARY KEY,
        heat_score INT NOT NULL DEFAULT 0,
        civis_score INT NOT NULL DEFAULT 0,
        active_branch VARCHAR(8) NOT NULL DEFAULT 'neutral',
        last_switch INT NOT NULL DEFAULT 0
      )
    ]])
end)

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

-- map score (0..100) to eligible level using config table
local function levelFromScore(score)
  for _,m in ipairs(AlignmentConfig.ScoreToLevel) do
    if score>=m.min and score<=m.max then return m.lvl end
  end
  return 0
end

local function sendClientState(src)
  local d = P[src]; if not d then return end
  local st = {
    heat = d.heat or 0,
    civis = d.civis or 0,
    active = d.active or 'neutral',
    eligible = {
      heat = levelFromScore(d.heat or 0),
      civis = levelFromScore(d.civis or 0)
    }
  }
  TriggerClientEvent('respawn:alignment:clientState', src, st)
end

local function computeBranch(heat, civis, prevActive)
  if heat >= civis + H then return 'heat'
  elseif civis >= heat + H then return 'civis'
  else return prevActive or 'neutral' -- permanece hasta superar histéresis
  end
end

local function updateBranch(d)
  local prevActive = d.active
  local prevSwitch = d.lastSwitch
  d.active = computeBranch(d.heat, d.civis, d.active)
  if d.active ~= prevActive then d.lastSwitch = os.time() end
  if d.active ~= prevActive or d.lastSwitch ~= prevSwitch then
    print(('[alignment] %s active %s -> %s | lastSwitch %s -> %s'):format(
      d.citizenid, prevActive, d.active, prevSwitch, d.lastSwitch))
  end
end

local function loadPlayer(src)
  local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
  local cid = Player.PlayerData.citizenid
  local rows = ox:executeSync('SELECT * FROM respawn_alignment WHERE citizenid=?',{cid})
  local data
  if rows and rows[1] then
    data = rows[1]
  else
    ox:executeSync('INSERT INTO respawn_alignment (citizenid) VALUES (?)',{cid})
    data = {citizenid=cid, heat_score=0, civis_score=0, active_branch='neutral', last_switch=0}
  end
  P[src] = {
    citizenid = cid,
    heat = data.heat_score or 0,
    civis = data.civis_score or 0,
    active = data.active_branch or 'neutral',
    lastSwitch = tonumber(data.last_switch) or 0
  }
  -- aplica histéresis actual
  local act = computeBranch(P[src].heat, P[src].civis, P[src].active)
  P[src].active = act
end

local function savePlayer(src)
  local d = P[src]; if not d then return end
  ox:execute('UPDATE respawn_alignment SET heat_score=?, civis_score=?, active_branch=?, last_switch=? WHERE citizenid=?',
    {d.heat, d.civis, d.active, d.lastSwitch, d.citizenid})
end

local function scheduleSave(src)
  if SaveTimers[src] then ClearTimeout(SaveTimers[src]) end
  SaveTimers[src] = SetTimeout(SAVE_DELAY, function()
    SaveTimers[src] = nil
    savePlayer(src)
  end)
end

AddEventHandler('playerDropped', function()
  if SaveTimers[source] then
    ClearTimeout(SaveTimers[source])
    SaveTimers[source] = nil
  end
  savePlayer(source)
  P[source]=nil
end)
AddEventHandler('QBCore:Server:PlayerLoaded', function(src)
  loadPlayer(src)
  sendClientState(src) -- ← para que el HUD tenga valores al entrar
end)

-- ========= API / Exports =========
exports('GetActiveBranch', function(src)
  local d=P[src]; return d and d.active or 'neutral'
end)

exports('GetEligibleLevel', function(src, branch)
  local d=P[src]; if not d then return 0 end
  local score = branch=='heat' and d.heat or d.civis
  return levelFromScore(score)
end)

exports('CanClaimHighTier', function(src, branch)
  local d=P[src]; if not d then return false, 'notloaded' end
  local active = d.active
  if active ~= branch then return false, 'wrong-branch' end
  local now = os.time()
  if now < (d.lastSwitch + CD) then
    local left = math.ceil(((d.lastSwitch + CD) - now)/3600)
    return false, ('loyalty-cooldown:%sh'):format(left)
  end
  return true, nil
end)

-- ========= Mutadores (validar SIEMPRE server-side) =========
RegisterNetEvent('respawn:alignment:addHeat', function(amount)
  local src = source; local d=P[src]; if not d then loadPlayer(src); d=P[src] end
  d.heat = clamp((d.heat or 0) + (amount or 0), 0, 100)
  updateBranch(d)
  scheduleSave(src)
  sendClientState(src)

end)

RegisterNetEvent('respawn:alignment:addCivis', function(amount)
  local src = source; local d=P[src]; if not d then loadPlayer(src); d=P[src] end
  d.civis = clamp((d.civis or 0) + (amount or 0), 0, 100)
  updateBranch(d)
  scheduleSave(src)
  sendClientState(src)

end)

-- ========= Comandos de test (admin) =========
QBCore.Commands.Add('rsp_setheat','[Respawn] Set HEAT score (admin)',{{name='score',help='0-100'}}, true, function(src,args)
  local d=P[src]; if not d then loadPlayer(src); d=P[src] end
  d.heat = clamp(tonumber(args[1]) or 0,0,100)
  updateBranch(d)
  scheduleSave(src)
end,'admin')

QBCore.Commands.Add('rsp_setcivis','[Respawn] Set CIVIS score (admin)',{{name='score',help='0-100'}}, true, function(src,args)
  local d=P[src]; if not d then loadPlayer(src); d=P[src] end
  d.civis = clamp(tonumber(args[1]) or 0,0,100)
  updateBranch(d)
  scheduleSave(src)
end,'admin')

QBCore.Functions.CreateCallback('respawn:alignment:getClientState', function(src, cb)
  local d = P[src]; if not d then cb(nil) return end
  cb({ heat=d.heat, civis=d.civis, active=d.active,
       eligible={ heat=levelFromScore(d.heat), civis=levelFromScore(d.civis) } })
end)

