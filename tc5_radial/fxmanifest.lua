fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_radial'
author 'OpenAI'
description 'TC5 radial menu system'
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
    'RegisterItem',
    'RemoveItem',
    'OpenMenu'
}
