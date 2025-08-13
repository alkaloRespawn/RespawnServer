-- Opcional: marcar ubicaciones. Si usas ox_target, añade zonas aquí.
CreateThread(function()
  -- Sólo un hint visual (puedes cambiar por qb-target/ox_target)
  local civ = Workshops.civis.coords
  local hea = Workshops.heat.coords
  while true do
    Wait(0)
    DrawMarker(2, civ.x, civ.y, civ.z, 0,0,0, 0,0,0, 0.4,0.4,0.4, 0,180,255, 140, false, true, 2, false, nil, nil, false)
    DrawMarker(2, hea.x, hea.y, hea.z, 0,0,0, 0,0,0, 0.4,0.4,0.4, 255,80,80, 140, false, true, 2, false, nil, nil, false)
  end
end)
