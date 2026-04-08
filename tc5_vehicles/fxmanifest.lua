fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_vehicles'
author 'TC5 + OpenAI patch'
description 'Vehicle HUD + Seatbelt + Flip + Damage System'
version '1.0.1'

ui_page 'html/index.html'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependency 'tc5_ui'
