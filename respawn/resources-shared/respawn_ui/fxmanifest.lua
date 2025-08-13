fx_version 'cerulean'
game 'gta5'

name 'respawn_ui'
description 'Respawn - NUI: weapons panel (HEAT/CIVIS) + HUD (mock)'
version '0.2.0'
lua54 'yes'

ui_page 'web/index.html'

files {
  'web/index.html',
  'web/app.css',
  'web/app.js',
  'web/locales/es-ES.json',
  'web/locales/en-US.json',
  'web/data/weapons_catalog.json',
  'web/data/alignment.config.json'
}

client_scripts {
  'client.lua'
}
