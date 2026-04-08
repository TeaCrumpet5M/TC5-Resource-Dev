fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_tracker'
author 'OpenAI'
description 'TC5 vehicle tracker starter'
version '1.0.0'

server_scripts { 'server/main.lua' }
client_scripts { 'client/main.lua' }
dependencies { 'tc5_ui', 'tc5_garage' }
