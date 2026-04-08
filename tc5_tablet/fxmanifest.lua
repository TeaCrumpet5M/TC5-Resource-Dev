fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_tablet'
author 'OpenAI'
description 'TC5 modular tablet with in-hand NUI and USB locked apps'
version '2.0.0'

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
    'server/main.lua'
}

dependencies {
    'tc5_core',
    'tc5_inventory',
    'tc5_ui'
}
