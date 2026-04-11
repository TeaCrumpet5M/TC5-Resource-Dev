fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_mechanicjob'
author 'OpenAI'
description 'Fresh mechanic job resource for TC5 with repair/crafting/boss/shop NUI and tc5_jobs integration'
version '4.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/style.css'
}

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'tc5_core',
    'tc5_inventory',
    'tc5_jobs',
    'tc5_ui'
}
