fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_apartment'
author 'OpenAI'
description 'TC5 apartment system with tc5_inventory stash integration'
version '1.2.1'

ui_page 'html/index.html'

shared_scripts {
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'oxmysql',
    'tc5_ui',
    'tc5_core',
    'tc5_inventory'
}
