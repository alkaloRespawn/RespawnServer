local uiOpen = false
local canToggle = true
local locale = GetConvar('respawn_locale', 'es-ES')
local QBCore = exports['qb-core']:GetCoreObject()

-- Single command / keybind
RegisterCommand('respawn_toggle_ui', function()
    if not canToggle then return end
    canToggle = false

    uiOpen = not uiOpen
    SetNuiFocus(uiOpen, uiOpen)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = uiOpen and 'open' or 'close', locale = locale })

    SetTimeout(180, function() canToggle = true end)
end, false)
RegisterKeyMapping('respawn_toggle_ui', 'Respawn: abrir/cerrar panel', 'keyboard', 'F6')

-- NUI Ready -> send state
RegisterNUICallback('ui_ready', function(_, cb)
    QBCore.Functions.TriggerCallback('respawn:weapons:getState', function(state)
        cb({ ok = true, state = state })
    end)
end)

-- Close from NUI
RegisterNUICallback('close', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb({ ok = true })
end)

-- Backward-compat close endpoint
RegisterNUICallback('respawn_close', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb('ok')
end)

-- Inspect (preview) -> server callback
RegisterNUICallback('inspect', function(data, cb)
    QBCore.Functions.TriggerCallback('respawn:workshop:getPreview', function(prev)
        cb({ ok = true, preview = prev })
    end, data.family, data.branch, data.level)
end)

-- Claim / Equip actions
RegisterNUICallback('claim', function(data, cb)
    TriggerServerEvent('respawn:weapons:claim', data.family, data.branch, data.level)
    cb({ ok = true })
end)
RegisterNUICallback('equip', function(data, cb)
    TriggerServerEvent('respawn:weapons:equip', data.family, data.level)
    cb({ ok = true })
end)

-- Close if NUI loses focus (alt-tab)
CreateThread(function()
    while true do
        if uiOpen and not IsNuiFocused() then
            uiOpen = false
            SendNUIMessage({ action = 'close' })
        end
        Wait(250)
    end
end)
