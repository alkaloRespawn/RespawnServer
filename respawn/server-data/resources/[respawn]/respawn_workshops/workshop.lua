local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('respawn:workshop:createOrder', function(src, cb, data)
    -- data: { branch='HEAT'|'CIVIS', family='pistol9mm', level=1, cost=5000, mats={...} }
    local Player = QBCore.Functions.GetPlayer(src); if not Player then return cb({ok=false, err='no-player'}) end
    local cid = Player.PlayerData.citizenid

    -- TODO: validar elegibilidad (rama activa, nivel anterior, etc.)
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
    exports.oxmysql:execute([[
        SELECT * FROM respawn_workshop_orders
        WHERE citizenid = ? AND status = 'QUEUED' AND ready_at IS NOT NULL AND ready_at <= NOW()
    ]], { cid }, function(rows)
        for _,r in ipairs(rows) do
            -- aquí “entregar” el ítem/skin/adjunto correspondiente:
            -- TriggerClientEvent('respawn:unlockLevel', src, r.family, r.level)
            exports.oxmysql:execute('UPDATE respawn_workshop_orders SET status="READY" WHERE id=?', { r.id })
        end
        cb({ ok=true, delivered=#rows })
    end)
end)
