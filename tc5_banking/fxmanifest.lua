fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_banking'
author 'OpenAI'
description 'Standalone TC5 banking with ATM and business accounts'
version '1.0.0'

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
    'tc5_inventory'
}
