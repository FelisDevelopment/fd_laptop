fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'
author 'Felis Development'
description ''
version '0.5.2'
repository 'https://github.com/FelisDevelopment/fd_laptop'

dependencies {
    '/onesync',
    'ox_lib',
    'oxmysql'
}

files {
    'web/dist/index.html',
    'web/dist/**/*',
    'locales/*.json',
    'config/*.lua',
    'config/server/*.lua',
    'bridge/**/imports/client.lua',
    'bridge/**/client.lua',
    'bridge/options/*',
    'bridge/*.lua',
}

-- ui_page 'https://local.felis.gg:5173/'
ui_page 'web/dist/index.html'

data_file 'DLC_ITYP_REQUEST' 'stream/props_facade.ytyp'

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
