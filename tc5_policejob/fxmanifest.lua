fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_policejob'
author 'OpenAI for TeaCrumpet5M'
description 'Police job resource for the TC5 framework'
version '1.1.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

shared_scripts {
    'shared/config.lua'
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
    'tc5_ui',
    'tc5_jobs'
}
