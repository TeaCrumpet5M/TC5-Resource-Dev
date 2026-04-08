fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_creator'
author 'OpenAI'
description 'Character creator for TC5'
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

dependencies {
    'tc5_ui',
    'tc5_core'
}
