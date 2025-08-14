fx_version 'cerulean'
game 'gta5'

name 'respawn_workshops'
description 'Respawn - talleres CIVIS/HEAT, costes, tiempos y cola de trabajo'
version '0.2.0'
lua54 'yes'

shared_scripts {
  '@ox_lib/init.lua',   -- ← habilita `lib` de ox_lib
  'config.lua'
}

server_scripts { 'server.lua' }
client_scripts { 'client.lua' }
