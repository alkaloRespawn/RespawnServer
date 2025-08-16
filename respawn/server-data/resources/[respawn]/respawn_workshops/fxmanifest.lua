fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'respawn_workshops'
description 'Respawn - talleres CIVIS/HEAT, costes, tiempos y cola de trabajo'
version '0.2.1'

shared_scripts {
  '@ox_lib/init.lua', -- keep only if ox_lib is actually used
  'config.lua'
}

server_scripts {
  'server/workshop.lua'
}

client_scripts {
  'client.lua' -- remove if not present
}

dependencies {
  'qb-core',
  'oxmysql',
  'ox_lib',
  'respawn_alignment'
}

