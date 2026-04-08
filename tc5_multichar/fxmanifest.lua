fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_multichar'
author 'OpenAI'
description 'Multicharacter selector for TC5'
version '1.0.0'

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
    'server/main.lua'
}

dependencies {
    'tc5_core',
    'tc5_ui'
}
