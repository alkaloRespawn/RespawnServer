-- Cliente no toca DB; sólo existe para utilidades o aplicar efectos en el futuro.
-- Aquí podrías escuchar un evento 'equip-changed' para aplicar adjuntos/skins.

-- Escucha cuando equipes (ya existe el evento). Aplica pequeño efecto de cámara opcional:
RegisterNetEvent('respawn:weapons:equipped', function(family, level)
  print(('[Respawn] Equipped %s +%d'):format(family, level))
  -- TODO: una integración real con natives de armas por jugador
  -- Ejemplo suave (no invasivo): pequeño feedback al equipar high tier
  if level >= 7 then
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.15)
  end
end)
