-- Cliente no toca DB; sólo existe para utilidades o aplicar efectos en el futuro.
-- Aquí podrías escuchar un evento 'equip-changed' para aplicar adjuntos/skins.

RegisterNetEvent('respawn:weapons:equipped', function(family, level)
  print(('[Respawn] Equipped %s +%d'):format(family, level))
end)
