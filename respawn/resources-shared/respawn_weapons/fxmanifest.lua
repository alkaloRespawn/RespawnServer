fx_version 'cerulean'
game 'gta5'
name 'respawn_weapons'
description 'Respawn - Weapons catalog & claiming'
version '0.3.0'
lua54 'yes'

files { 'data/weapons_catalog.json' }
shared_scripts { '@qb-core/shared/locale.lua' } -- por si quieres locales QB
server_scripts { 'server.lua' }
client_scripts { 'client.lua' }
