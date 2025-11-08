fx_version 'cerulean'
game 'gta5'

name 'vCore Framework'
author 'vCore Development'
version '1.0.0'
description 'Next-Gen FiveM Framework with Multi-Framework Bridge Support'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/main.lua',
    'shared/functions.lua',
    'shared/items.lua',
    'shared/locale.lua',
    'bridge/shared.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server/*.lua',
    'server/main.lua',
    'server/core/*.lua',
    'server/modules/*.lua',
    'server/api.lua'
}

client_scripts {
    'bridge/client/*.lua',
    'client/main.lua',
    'client/core/*.lua',
    'client/modules/*.lua',
    'client/api.lua'
}

files {
    'locales/*.json',
    'bridge/config.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

provide 'qb-core'
provide 'es_extended'
provide 'ox_core'

lua54 'yes'