fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_vehiclekeys'
author 'OpenAI'
description 'TC5 Vehicle Keys synced with simplified tc5_garage'
version '1.0.0'

shared_scripts {
    'shared/config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'tc5_garage'
}
