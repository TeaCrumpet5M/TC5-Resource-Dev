fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_doorlock'
author 'OpenAI'
description 'TC5 Doorlock v4 with roller shutter support'
version '1.3.0'

ui_page 'web/index.html'

shared_scripts { 'shared/config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_scripts { 'client/main.lua' }

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

dependencies { 'oxmysql', 'tc5_core', 'tc5_ui', 'tc5_eye' }

exports {
    'GetDoor',
    'SetDoorState',
    'HasDoorAccess'
}
