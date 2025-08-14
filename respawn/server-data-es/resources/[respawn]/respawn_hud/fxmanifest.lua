fx_version 'cerulean'
game 'gta5'

name 'respawn_hud'
description 'Respawn - Mini HUD HEAT/CIVIS/Rep (ox_lib + draw)'
version '0.1.0'
lua54 'yes'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua'
}

client_scripts { 'client.lua' }
