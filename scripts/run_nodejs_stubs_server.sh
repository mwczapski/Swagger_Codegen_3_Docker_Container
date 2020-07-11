#!/bin/bash

# pass the api config to the ui for serving
#
cp -v /api/* /stubs_nodejs/node_modules/oas3-tools/dist/middleware/swagger-ui || true

# run the generate and start stubs server logic if conditions are met
#
cd /stubs_nodejs
[[ -f /api/.no_autostart ]] && exit

# generate stubs
#
[[ ! -f /api/.no_autogenerate ]] && /swagger_tools/generate_nodejs_stubs_server.sh

[[ ! -f /stubs_nodejs/index.js ]] && { echo "Stubs are not available - can't start server" && exit; } 
[[ ! -d /stubs_nodejs/node_modules ]] && { echo "Stubs were not installed - can't start server" && exit; } 

# run the watcher service
nodemon -L -w /api/* -w /stubs_nodejs/* -x "node /stubs_nodejs/index.js"

