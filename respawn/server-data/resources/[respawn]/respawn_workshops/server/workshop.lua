local QBCore = exports['qb-core']:GetCoreObject()

-- Example catalog; move to config in production
local Catalog = {
  families = {
    pistol9mm = {
      display_name = 'Pistola 9mm',
      levels = {
        heat = {
          { level = 0, skin_name = 'OEM', attachments = {} },
          { level = 1, skin_name = 'HEAT Mk.I', attachments = {'grip'} },
          { level = 2, skin_name = 'HEAT Mk.II', attachments = {'grip','sight'} },
        },
        civis = {
          { level = 1, skin_name = 'CIVIS Mk.I', attachments = {'silencer'} },
          { level = 2, skin_name = 'CIVIS Mk.II', attachments = {'silencer','sight'} },
        }
      }
    }
  }
}
local AlignCfg = { exclusiveHighTiers = { 2 } }

QBCore.Functions.CreateCallback('respawn:workshop:getPreview', function(src, cb, family, branch, level)
    local place = (branch == 'HEAT') and 'HEAT Workshop' or 'CIVIS Workshop'
    cb({ placeLabel = place, costCash = (level or 0) * 500, timeSec = (level or 0) * 60, materials = { steel = 5 * (level or 1) } })
end)

QBCore.Functions.CreateCallback('respawn:weapons:getState', function(src, cb)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return cb({}) end
    local citizenid = Player.PlayerData.citizenid
    exports.oxmysql:single('SELECT heat, civis, alignment_active FROM players WHERE citizenid = ?', { citizenid }, function(row)
        local heat = tonumber(row and row.heat) or 0
        local civis = tonumber(row and row.civis) or 0
        local active = (row and row.alignment_active) or 'NEUTRAL'
        local elig = { heat = math.floor(heat/10), civis = math.floor(civis/10) }
        cb({ catalog = Catalog, align = AlignCfg, activeBranch = string.lower(active), eligible = elig, claimed = {} })
    end)
end)

QBCore.Functions.CreateCallback('respawn:workshop:createOrder', function(src, cb, data)
    local Player = QBCore.Functions.GetPlayer(src); if not Player then return cb({ok=false, err='no-player'}) end
    local cid = Player.PlayerData.citizenid
    exports.oxmysql:insert([[ 
        INSERT INTO respawn_workshop_orders (citizenid, branch, family, level, cost, mats, ready_at)
        VALUES (?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? MINUTE))
    ]], { cid, data.branch, data.family, data.level, data.cost, json.encode(data.mats or {}), 20 }, function(id)
        cb({ ok=true, id=id })
    end)
end)

QBCore.Functions.CreateCallback('respawn:workshop:collectReady', function(src, cb)
    local Player = QBCore.Functions.GetPlayer(src); if not Player then return cb({ok=false}) end
    local cid = Player.PlayerData.citizenid
    exports.oxmysql:fetchAll([[ 
        SELECT * FROM respawn_workshop_orders
        WHERE citizenid = ? AND status = 'QUEUED' AND ready_at IS NOT NULL AND ready_at <= NOW()
    ]], { cid }, function(rows)
        local delivered = 0
        for _,r in ipairs(rows or {}) do
            delivered = delivered + 1
            exports.oxmysql:execute('UPDATE respawn_workshop_orders SET status="READY" WHERE id=?', { r.id })
        end
        cb({ ok=true, delivered=delivered })
    end)
end)

RegisterNetEvent('respawn:weapons:claim', function(family, branch, level)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
    print(('[respawn] %s requested claim %s %s L%s'):format(Player.PlayerData.citizenid, tostring(family), tostring(branch), tostring(level)))
end)

RegisterNetEvent('respawn:weapons:equip', function(family, level)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src); if not Player then return end
    print(('[respawn] %s requested equip %s L%s'):format(Player.PlayerData.citizenid, tostring(family), tostring(level)))
end)

