fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_banking'
author 'OpenAI'
description 'Standalone banking, business finance, invoices, payroll, and mobile banking for TC5'
version '3.0.0'

ui_page 'html/index.html'

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
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
    'tc5_core',
    'tc5_ui',
    'tc5_inventory'
}
