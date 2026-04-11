fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_jobs'
author 'OpenAI'
description 'Dynamic jobs module for the TC5 framework'
version '1.0.2'

shared_scripts {
    'shared/config.lua',
    'shared/jobs.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/jobs.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'oxmysql',
    'tc5_core',
    'tc5_ui'
}

exports {
    'RegisterJob',
    'GetJobs',
    'GetJobDefinition',
    'GetPlayerJob',
    'SetPlayerJob',
    'HasJob',
    'ToggleDuty'
}
