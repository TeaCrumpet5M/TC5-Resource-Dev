fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_vehicle_finance'
author 'OpenAI'
description 'TC5 vehicle finance starter'
version '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
dependencies { 'oxmysql', 'tc5_core', 'tc5_ui' }
