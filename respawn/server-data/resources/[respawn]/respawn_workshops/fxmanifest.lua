fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'respawn_workshops'
description 'Respawn - talleres CIVIS/HEAT, costes, tiempos y cola de trabajo'
version '0.2.1' -- bump menor por corrección de manifest

-- ox_lib primero si lo usas (lib.*)
shared_scripts {
  '@ox_lib/init.lua',
  'config.lua'
}

-- Un solo bloque de server_scripts: añade aquí TODOS los server-side que existan
server_scripts {
  'server.lua',            -- quítalo si no existe en tu recurso
  'server/workshop.lua'
}

-- Client opcional; mantenlo solo si realmente tienes client-side
client_scripts {
  'client.lua'             -- quítalo si no existe
}

-- Asegura orden y presencia de dependencias reales
dependencies {
  'qb-core',
  'oxmysql',
  'ox_lib',
  'respawn_alignment'      -- para que el taller arranque después del alignment
}
