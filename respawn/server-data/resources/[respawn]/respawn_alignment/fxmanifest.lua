fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'respawn_alignment'
description 'Respawn - HEAT/CIVIS alignment core'
version '0.3.1'

shared_scripts {
  'config.lua'
}

client_scripts {
  'client.lua'
}

server_scripts {
  'server/alignment.lua'
}

dependencies {
  'qb-core',
  'oxmysql'
}
