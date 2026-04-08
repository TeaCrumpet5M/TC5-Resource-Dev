fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_ui'
author 'OpenAI'
description 'Shared UI layer for the TC5 framework'
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

exports {
    'Notify',
    'OpenLoading',
    'CloseLoading',
    'SetNeeds',
    'SetFood',
    'SetDrink'
}
