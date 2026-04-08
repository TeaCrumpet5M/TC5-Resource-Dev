fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_eye'
author 'OpenAI'
description 'TC5 third eye interaction system'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

exports {
    'AddBoxZone',
    'AddEntityOption',
    'AddModelOption',
    'RemoveZone',
    'RemoveEntityOption',
    'RemoveModelOption'
}
