fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_core'
author 'TC5 Framework + OpenAI'
description 'TC5 Core Framework with multicharacter support'
version '1.4.0'

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/player.lua',
    'server/character.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/spawn_bridge.lua'
}

dependencies {
    'oxmysql',
    'tc5_ui'
}
