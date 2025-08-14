local usingTarget = (GetResourceState('ox_target') == 'started')
local hasLib = (GetResourceState('ox_lib') == 'started')

local function loadModel(model)
  if type(model)=='string' then model = joaat(model) end
  RequestModel(model); while not HasModelLoaded(model) do Wait(0) end
  return model
end

local function makePreviewLines(prev)
  local mats = prev.materials or {}
  local matStr = '—'
  local parts = {}
  for name,qty in pairs(mats) do parts[#parts+1] = (('%s×%d'):format(name, qty)) end
  if #parts > 0 then matStr = table.concat(parts, ', ') end
  return ('$%d | %ds | %s'):format(prev.costCash or 0, prev.timeSec or 0, matStr)
end

local function openQuickMenu(branch)
  local cbReady = false
  local options = nil

  -- pide opciones al server
  QBCore.Functions.TriggerCallback('respawn:workshop:listQuickOptions', function(list)
    options = list or {}
    cbReady = true
  end, branch)

  while not cbReady do Wait(0) end

  if (not options) or #options == 0 then
    lib and lib.notify({title='Respawn', description='Nada disponible para reclamar en esta rama.', type='error'}) or
    print('[Respawn] Nada disponible para reclamar.')
    return
  end

  if hasLib and lib and lib.registerContext then
    local ctxId = ('respawn_quick_%s_ctx'):format(branch)
    local rows = {}
    for _,opt in ipairs(options) do
      rows[#rows+1] = {
        title = (('%s +%d'):format(opt.family_label, opt.level)),
        description = makePreviewLines(opt.preview),
        icon = (branch=='civis' and 'circle-check' or 'screwdriver-wrench'),
        arrow = true,
        onSelect = function()
          TriggerServerEvent('respawn:workshop:quickClaimSpecific', branch, opt.family, opt.level)
        end
      }
    end
    lib.registerContext({
      id = ctxId,
      title = (branch=='civis' and 'Taller Corporativo — Reclamar' or 'Taller Clandestino — Reclamar'),
      options = rows
    })
    lib.showContext(ctxId)
  else
    -- Fallback: elige la primera opción (mejor nivel)
    local opt = options[1]
    TriggerServerEvent('respawn:workshop:quickClaimSpecific', branch, opt.family, opt.level)
  end
end

local function spawnWorkshopNPC(branch, data)
  local m = loadModel(data.pedModel or `s_m_m_autoshop_02`)
  local ped = CreatePed(4, m, data.coords.x, data.coords.y, data.coords.z-1.0, data.heading or 0.0, false, true)
  SetEntityAsMissionEntity(ped, true, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetEntityInvincible(ped, true)
  FreezeEntityPosition(ped, true)
  if data.scenario then TaskStartScenarioInPlace(ped, data.scenario, 0, true) end

  if usingTarget then
    exports.ox_target:addLocalEntity(ped, {
      {
        name = ('respawn_open_%s'):format(branch),
        label = 'Abrir panel de armas',
        icon = 'fa-solid fa-gun',
        onSelect = function() ExecuteCommand('respawn_weapons') end
      },
      {
        name = ('respawn_quick_%s'):format(branch),
        label = ('Reclamar (Elegir familia) — %s'):format(branch:upper()),
        icon = 'fa-solid fa-wrench',
        onSelect = function() openQuickMenu(branch) end
      }
    })
  else
    -- Fallback sin target: marcador + [E] abre el menú rápido (o panel con [G])
    CreateThread(function()
      local pos = data.coords
      while true do
        Wait(0)
        local p = GetEntityCoords(PlayerPedId())
        local dist = #(p - pos)
        if dist < 2.2 then
          -- Texto ayuda
          SetTextFont(4); SetTextScale(0.35, 0.35); SetTextColour(220,220,220,215); SetTextCentre(true)
          SetTextEntry("STRING"); AddTextComponentString(('[E] Reclamar — [G] Panel (%s)'):format(branch:upper()))
          DrawText(0.5, 0.88)
          if IsControlJustPressed(0, 38) then -- E
            openQuickMenu(branch)
          elseif IsControlJustPressed(0, 47) then -- G
            ExecuteCommand('respawn_weapons')
          end
        end
        -- Marcador
        DrawMarker(2, pos.x, pos.y, pos.z, 0,0,0, 0,0,0, 0.4,0.4,0.4,
          branch=='civis' and 0 or 255, branch=='civis' and 180 or 80, branch=='civis' and 255 or 80,
          140, false, true, 2, false, nil, nil, false)
      end
    end)
  end

  return ped
end

CreateThread(function()
  for branch,info in pairs(Workshops) do
    spawnWorkshopNPC(branch, info)
  end
end)
