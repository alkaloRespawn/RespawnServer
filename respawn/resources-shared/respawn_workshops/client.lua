local usingTarget = (GetResourceState('ox_target') == 'started')

local function loadModel(model)
  if type(model)=='string' then model = joaat(model) end
  RequestModel(model); while not HasModelLoaded(model) do Wait(0) end
  return model
end

local function spawnWorkshopNPC(branch, data)
  local m = loadModel(data.pedModel or `s_m_m_autoshop_02`)
  local ped = CreatePed(4, m, data.coords.x, data.coords.y, data.coords.z-1.0, data.heading or 0.0, false, true)
  SetEntityAsMissionEntity(ped, true, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetEntityInvincible(ped, true)
  FreezeEntityPosition(ped, true)
  if data.scenario then TaskStartScenarioInPlace(ped, data.scenario, 0, true) end

  -- Ox Target
  if usingTarget then
    exports.ox_target:addLocalEntity(ped, {
      {
        name = ('respawn_open_%s'):format(branch),
        label = 'Abrir panel de armas',
        icon = 'fa-solid fa-gun',
        onSelect = function()
          ExecuteCommand('respawn_weapons')
        end
      },
      {
        name = ('respawn_quick_%s'):format(branch),
        label = ('Reclamar siguiente elegible (%s)'):format(branch:upper()),
        icon = 'fa-solid fa-wrench',
        onSelect = function()
          TriggerServerEvent('respawn:workshop:quickClaim', branch)
        end
      }
    })
  else
    -- Fallback: 3D text + tecla [E] para abrir NUI
    CreateThread(function()
      local pos = data.coords
      local hint = ('[E] %s — %s'):format(data.label or 'Taller', (branch=='civis' and 'CIVIS' or 'HEAT'))
      while true do
        Wait(0)
        local p = GetEntityCoords(PlayerPedId())
        if #(p - pos) < 2.0 then
          SetTextFont(4); SetTextScale(0.35, 0.35); SetTextColour(220,220,220,215); SetTextCentre(true)
          SetTextEntry("STRING"); AddTextComponentString(hint)
          DrawText(0.5, 0.88)
          if IsControlJustPressed(0, 38) then -- E
            ExecuteCommand('respawn_weapons')
          end
        end
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
