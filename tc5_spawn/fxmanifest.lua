fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_spawn'
author 'OpenAI'
description 'Spawn selector for TC5 with logout location and apartment selection support'
version '1.2.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'oxmysql',
    'tc5_ui',
    'tc5_core',
    'tc5_creator',
    'tc5_apartment'
}
