fx_version 'cerulean'
game 'gta5'

name 'tc5_garage'
author 'TC5'
description 'Garage System'

shared_script 'shared/config.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
