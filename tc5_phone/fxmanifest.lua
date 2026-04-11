fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_phone'
author 'OpenAI'
description 'TC5 Phone - upgraded UI with mechanic integration'
version '1.1.1'

ui_page 'web/index.html'

shared_scripts {
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

dependencies {
    'oxmysql',
    'tc5_core',
    'tc5_ui'
}

exports {
    'RegisterApp',
    'GetPhoneNumber'
}
