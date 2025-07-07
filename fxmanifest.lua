fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'
this_is_a_map 'yes'

author 'Felis Development'
description ''
version '0.5.2'
repository 'https://github.com/FelisDevelopment/fd_laptop'

data_file 'DLC_ITYP_REQUEST' 'stream/prop_laptop_facade'

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
    'bridge/*.lua',
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
