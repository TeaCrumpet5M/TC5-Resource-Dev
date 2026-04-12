fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_mechanicjob'
author 'OpenAI'
description 'TC5 mechanic job with repair/crafting/boss/shop UI and tc5_banking billing integration'
version '4.1.0'

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
    'tc5_ui',
    'tc5_banking'
}
