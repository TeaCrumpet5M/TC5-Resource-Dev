fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_bossmenu'
author 'OpenAI'
description 'TC5 Boss Menu Dynamic - jobs, hiring, salaries, society inventory, boss stash'
version '2.0.0'

ui_page 'web/index.html'

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
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

dependencies {
    'oxmysql',
    'tc5_core',
    'tc5_ui',
    'tc5_jobs',
    'tc5_inventory'
}
