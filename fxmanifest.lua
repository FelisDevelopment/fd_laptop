fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

author 'Felis Development'
description ''
version '0.1.0'
repository 'https://github.com/FelisDevelopment/fd_laptop'

dependencies {
    '/onesync',
    'ox_lib',
}

files {
    'web/dist/index.html',
    'web/dist/**/*',
    'locales/*.json',
    'config/*',
    'bridge/**/imports/client.lua',
    'bridge/**/client.lua',
    'bridge/options/*',
    'bridge/framework.lua',
    'bridge/inventory.lua'
}

ui_page 'web/dist/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'bridge/imports.lua',
    'init.lua',
}

client_scripts {
    'modules/**/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/**/server.lua',
}
