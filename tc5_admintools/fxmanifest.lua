fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_admintools'
author 'TC5 Framework'
description 'TC5 Advanced Admin Tools with job manager, dev mode, and vehicle catalog'
version '2.3.1'

ui_page 'html/index.html'

shared_scripts {
    'shared/config.lua',
    'shared/permissions.lua'
}

client_scripts {
    'client/main.lua',
    'client/noclip.lua',
    'client/godmode.lua',
    'client/spectate.lua',
    'client/reports.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/permissions.lua',
    'server/players.lua',
    'server/logs.lua',
    'server/reports.lua',
    'server/actions.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'oxmysql',
    'tc5_core',
    'tc5_ui',
    'tc5_inventory',
    'tc5_vehiclekeys',
    'tc5_jobs'
}