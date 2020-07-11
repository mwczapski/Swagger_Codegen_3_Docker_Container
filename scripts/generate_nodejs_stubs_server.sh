#!/bin/bash

cd /stubs_nodejs

# generate stubs
#
java -jar /swagger_tools/swagger-codegen/swagger-codegen-cli.jar generate -i /api/openapi.yaml -l nodejs-server -o /stubs_nodejs
sed -i 's|8080|3003|' /stubs_nodejs/index.js

grep 'Access-Control-Allow-Origin' /stubs_nodejs/index.js | {
  sed -i.bak '/expressAppConfig.getApp/a \
\
    // Add headers \
    app.use(function (req, res, next) { \
      // Website you wish to allow to connect \
      res.setHeader("Access-Control-Allow-Origin", "*"); \
\
      // Request methods you wish to allow \
      // res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, PATCH, DELETE"); \
      res.setHeader("Access-Control-Allow-Methods", "*"); \
\
      // Request headers you wish to allow \
      res.setHeader("Access-Control-Allow-Headers", "*"); \
\
      // Set to true if you need the website to include cookies in the requests sent \
      // to the API (e.g. in case you use sessions) \
      res.setHeader("Access-Control-Allow-Credentials", true); \
\
      // Pass to next layer of middleware \
      next(); \
    });\
' /stubs_nodejs/index.js
}

[[ -d /stubs_nodejs/node_modules ]] || npm install

