local QBCore = exports['qb-core']:GetCoreObject()

local function computeActive(heat, civis)
    if heat >= civis and heat >= 10 then return 'HEAT'
    elseif civis > heat and civis >= 10 then return 'CIVIS'
    else return 'NEUTRAL' end
end

RegisterNetEvent('respawn:addScore', function(deltaHeat, deltaCivis)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    deltaHeat = tonumber(deltaHeat or 0) or 0
    deltaCivis = tonumber(deltaCivis or 0) or 0
    local citizenid = Player.PlayerData.citizenid

    exports.oxmysql:execute(
      'UPDATE players SET heat = GREATEST(0, LEAST(100, heat + ?)), civis = GREATEST(0, LEAST(100, civis + ?)) WHERE citizenid = ?',
      { deltaHeat, deltaCivis, citizenid },
      function()
        exports.oxmysql:single('SELECT heat, civis FROM players WHERE citizenid = ?', { citizenid }, function(row)
            if not row then return end
            local heat = tonumber(row.heat) or 0
            local civis = tonumber(row.civis) or 0
            local active = computeActive(heat, civis)
            exports.oxmysql:execute('UPDATE players SET alignment_active = ? WHERE citizenid = ?', { active, citizenid })
            TriggerClientEvent('respawn:alignmentUpdated', src, { heat = heat, civis = civis, active = active })
          end
        )
      end
    )
end)
