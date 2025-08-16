local uiOpen = false
local locale = GetConvar('respawn_locale', 'es-ES')
local QBCore = exports['qb-core']:GetCoreObject()

RegisterCommand('respawn_weapons', function()
    uiOpen = not uiOpen
    SetNuiFocus(uiOpen, uiOpen)
    SendNUIMessage({ action = uiOpen and 'open' or 'close', locale = locale })
end, false)
RegisterKeyMapping('respawn_weapons', 'Abrir panel de armas Respawn', 'keyboard', 'F6')

-- UI ready -> devolvemos activeBranch/eligible/claimed desde server
RegisterNUICallback('ui_ready', function(_, cb)
    QBCore.Functions.TriggerCallback('respawn:weapons:getState', function(state)
        cb({ ok = true, state = state })
    end)
end)

RegisterNUICallback('close', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('claim', function(data, cb)
    TriggerServerEvent('respawn:weapons:claim', data.family, data.branch, data.level)
    cb({ ok = true })
end)

RegisterNUICallback('equip', function(data, cb)
    TriggerServerEvent('respawn:weapons:equip', data.family, data.level)
    cb({ ok = true })
end)

-- ... (resto igual que te di)
RegisterNUICallback('inspect', function(data, cb)
    -- data: { family, branch, level }
    QBCore.Functions.TriggerCallback('respawn:workshop:getPreview', function(prev)
        cb({ ok = true, preview = prev })
    end, data.family, data.branch, data.level)
end)

local uiOpen = false
local canToggle = true

RegisterCommand('respawn_toggle_ui', function()
    if not canToggle then return end
    canToggle = false
    uiOpen = not uiOpen

    SetNuiFocus(uiOpen, uiOpen)
    SetNuiFocusKeepInput(false) -- evita “tragarse” tecleo al salir
    SendNUIMessage({ action = uiOpen and 'open' or 'close' })

    -- anti-doble pulsación
    SetTimeout(180, function() canToggle = true end)
end, false)

-- Mapea F6 -> comando (visible en ajustes de FiveM)
RegisterKeyMapping('respawn_toggle_ui', 'Respawn: abrir/cerrar panel', 'keyboard', 'F6')

-- Cerrar desde NUI (ESC o botón X)
RegisterNUICallback('respawn_close', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb('ok')
end)

-- Opcional: cerrar si se pierde el focus por alt-tab
CreateThread(function()
    while true do
        if uiOpen and not IsNuiFocused() then
            uiOpen = false
            SendNUIMessage({ action = 'close' })
        end
        Wait(250)
    end
end)

