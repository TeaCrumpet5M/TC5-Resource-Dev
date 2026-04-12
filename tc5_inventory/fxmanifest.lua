fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tc5_inventory'
version '2.1.0'

ui_page 'html/index.html'

shared_scripts {
    'shared/config.lua',
    'shared/items.lua',
    'shared/shops.lua',
    'shared/stashes.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua',
    'client/hotbar.lua',
    'client/shops.lua',
    'client/vehicles.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/inventory.lua',
    'server/items.lua',
    'server/money.lua',
    'server/shops.lua',
    'server/stashes.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/images/*.png'
}
