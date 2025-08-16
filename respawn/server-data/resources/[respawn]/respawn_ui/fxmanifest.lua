fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'respawn_ui'
description 'Respawn — Panel HEAT/CIVIS (NUI)'
version '1.0.0'

ui_page 'web/index.html'

files {
  'web/index.html',
  'web/app.js',
  'web/app.css',
  'web/locales/*.json'
}

client_scripts {
  'client.lua'
}

dependencies {
  'qb-core'
}

