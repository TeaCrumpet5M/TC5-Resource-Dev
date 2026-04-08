fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_chat'
author 'OpenAI'
description 'Custom TC5 styled chat UI for FiveM'
version '1.1.0'

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

exports {
    'addMessage',
    'addSuggestion',
    'removeSuggestion',
    'addSuggestions',
    'clear'
}
