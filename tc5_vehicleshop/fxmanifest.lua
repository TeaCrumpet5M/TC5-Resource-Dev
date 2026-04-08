fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_vehicleshop'
author 'OpenAI'
description 'TC5 vehicle shop starter'
version '1.0.0'

shared_scripts { 'shared/config.lua' }
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
dependencies { 'oxmysql', 'tc5_core', 'tc5_ui', 'tc5_garage' }
