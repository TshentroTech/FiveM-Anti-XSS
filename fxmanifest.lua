fx_version 'cerulean'
game 'gta5'
author 'tshentro.tech'
lua54 'yes' -- Add this line
ui_page 'html/index.html'

shared_script 'config.lua'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
