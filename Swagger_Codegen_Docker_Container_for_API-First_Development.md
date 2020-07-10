# Swagger Codegen 3.0 Docker Container

<!-- TOC -->

- [Swagger Codegen 3.0 Docker Container](#swagger-codegen-30-docker-container)
  - [Introduction](#introduction)
  - [Assumptions](#assumptions)
  - [Docker Image for _Instant Gratification_ Docker Container](#docker-image-for-instant-gratification-docker-container)
    - [Host Artefacts](#host-artefacts)
      - [Create Host directories](#create-host-directories)
      - [Create the example openapi.yaml API Specification (OpenAPI 3.0.1)](#create-the-example-openapiyaml-api-specification-openapi-301)
    - [Create Docker Image](#create-docker-image)
      - [Create run_nodejs_stubs_server.sh Script](#create-run_nodejs_stubs_serversh-script)
      - [Create Dockerfile in the Host directory](#create-dockerfile-in-the-host-directory)
      - [Create baseline Docker Image](#create-baseline-docker-image)
    - [Start the Docker Container Instance](#start-the-docker-container-instance)
      - [Create a container based on the new Image](#create-a-container-based-on-the-new-image)
      - [Connect to the running container](#connect-to-the-running-container)
      - [Test Swagger Codegen](#test-swagger-codegen)
  - [Notes](#notes)
    - [Initial API Specification Example YAML](#initial-api-specification-example-yaml)
    - [JSON Versions of Specification](#json-versions-of-specification)
    - [Where to change where Swagger Codegen looks for the YAML specification?](#where-to-change-where-swagger-codegen-looks-for-the-yaml-specification)
    - [What listens on what ports?](#what-listens-on-what-ports)
  - [Next Steps](#next-steps)
  - [Licensing](#licensing)

<!-- /TOC -->

<!--
# TODO

-   write the 'how to use the image' writeup to go with the image
-   Upload the image to the docker hub
-   write a 'how to use the container' to go with the container
-   git and push to github
-   write a blog entry and post
-   write a tweet and post
 -->

## Introduction

The intent of this document is to provide a set of steps that a reader can use to create a self-contained Docker container for generating and running back-end stubs based on an openapi.yaml specification for API-First development.  
A Dockerfile is provided to short-circuit the process.

The container will have the means to:

-   Use the Swagger Codegen to generate and run NodeJS stubs (and Java8 stubs, and Bash stubs) to facilitate API testing
-   Convert YAML specification documents to JSON and the vice versa

The container is based on the latest Docker node image with extras as discussed herein.

The container uses:

-   `swagger-codegen-cli/3.0.20` to support YAML to JSON conversion and generation of client and server stubs based on the OpenAPI Specification / Swagger file for supported languages. `swagger-codegen-cli` requires Java 8, which is installed during container setup.
-   `sqlite3`
-   `nodemon` server
-   `http-server` server

[[Top]](#swagger-codegen-30-docker-container)

## Assumptions

It is assumed that Windows 10 with Debian WSL is the Host operating environment.

Make such changes, to the small number of commands that this affects, as you need to make it work in a regular Linux environment.

[[Top]](#swagger-codegen-30-docker-container)

## Docker Image for _Instant Gratification_ Docker Container

In this section we will create a docker container with all that can be pre-installed and pre-configured to run the Swagger Codegen and Stubs server, and convert between YAML and JSON openapi specifications.

It is assumed that the Host build environment is Windows 10 with Debian WSL (Windows Subsystem for Linux), Docker installed in Windows 10 and all Host work done using WSL Debian bash shell.

> Once the image is built it will not matter in what environment it was built and docker commands to create and manage the container are much the same regardless of the docker host environment.

If this does not match your environment then you will need to make such adjustments as might be required. At most Host paths are likely to require changes from something like `/mnt/d/...` to something like `D:/...` or `/usr/home/myself/...` or `/opt/dockerwork/...` or some such, and perhaps one or two places where `docker.exe` might need ot be replaced with `docker`.

[[Top]](#swagger-codegen-30-docker-container)

### Host Artefacts

#### Create Host directories

```shell
mkdir -pv /mnt/d/github_materials/swagger_codegen/api
cd /mnt/d/github_materials/swagger_codegen

```

[[Top]](#swagger-codegen-30-docker-container)

#### Create the example openapi.yaml API Specification (OpenAPI 3.0.1)

We need example openapi specifications in yaml and json in the Docker image.

The easiest way to example specs to the Image is to create them on the host and copy them to the image while building it.

```shell
HOST_DIR=/mnt/d/github_materials

cat <<-'EOF' > ${HOST_DIR}/swagger_codegen/api/openapi.yaml
openapi: "3.0.1"
info:
  title: Weather API
  description: |
    This API is a __test__ API for validation of local swagger editor
    and swagger ui deployment and configuration
  version: 1.0.0
servers:
  - url: 'http://localhost:3003/'
tags:
  - name: Weather
    description: Weather, and so on
paths:
  /weather:
    get:
      tags:
        - Weather
      description: |
        It is __Good__ to be a _King_
        And a *Queen*
        And a _Prince_
        And a __Princess__
        And all the Grandchildren
        And their Children
      operationId: getWeather
      responses:
        '200':
          description: 'All is _well_, but not quite'
          content: {}
        '500':
          description: Unexpected Error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/response_500'
components:
  schemas:
    response_500:
      type: object
      properties:
        message:
          type: string

EOF

```

[[Top]](#swagger-codegen-30-docker-container)

### Create Docker Image

The Dockerfile and following instructions will create a baseline Docker Image. The Image will be able to be used for spinning up Container instances as needed with minimum extra work required to make them useable for API development work on different APIs.

[[Top]](#swagger-codegen-30-docker-container)

#### Create run_nodejs_stubs_server.sh Script

Create a server start script, to be executed from the docker-entrypoint.sh in the container on container start and restart.


``` shell
HOST_DIR=/mnt/d/github_materials

cat <<-'EOF' > ${HOST_DIR}/swagger_codegen/scripts/run_nodejs_stubs_server.sh
#!/bin/bash

cd /swagger_tools

[[ -f /api/.no_autostart ]] && exit

cd /stubs_nodejs

# generate stubs
#
if [[ ! -f /api/.no_autogenerate ]]
then

  java -jar /swagger_tools/swagger-codegen/swagger-codegen-cli.jar generate -i /api/openapi.yaml -l nodejs-server -o /stubs_nodejs
  echo "sed -i 's|8080|3003|' /stubs_nodejs/index.js"

  echo "grep 'Access-Control-Allow-Origin' /stubs_nodejs/index.js || {

    echo "sed -i.bak '/expressAppConfig.getApp/a \
    \
    // Add headers \
    app.use(function (req, res, next) { \
    \
        // Website you wish to allow to connect \
        res.setHeader("Access-Control-Allow-Origin", "*"); \
    \
        // Request methods you wish to allow \
        // res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, PATCH, DELETE"); \
        res.setHeader\("Access-Control-Allow-Methods", "*); \
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
    }); \
  } /stubs_nodejs/index.js

  [[ -d /stubs_nodejs/node_modules ]] || npm install

fi

cp -v /api/* /stubs_nodejs/node_modules/oas3-tools/dist/middleware/swagger-ui || true

nodemon -L -w /api/* -w /stubs_nodejs/* -x "node /stubs_nodejs/index.js"

EOF

chmod u+x ${HOST_DIR}/swagger_codegen/scripts/run_nodejs_stubs_server.sh

```


[[Top]](#swagger-codegen-30-docker-container)

#### Create Dockerfile in the Host directory

Change timezone and exposed ports as required.

```shell
cat <<-'EOF' > /mnt/d/github_materials/swagger_codegen/Dockerfile
FROM node:latest

ENV TZ_PATH="Australia/Sydney"
ENV TZ_NAME="Australia/Sydney"
ENV DEBIAN_FRONTEND=noninteractive

EXPOSE 3003

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
    nano \
    dos2unix \
    openjdk-8-jdk && \
    sqlite3 && \
  \
  npm i -g \
    http-server \
    nodemon && \
  \
  # set timezone
  #
  cp -v /usr/share/zoneinfo/${TZ_PATH} /etc/localtime && \
  echo "${TZ_NAME}" > /etc/timezone && \
  \
  # create the api directory (to be masked by bound volume if required)
  #
  mkdir -pv /api/converted && \
  mkdir -pv /stubs_nodejs

COPY api/openapi.yaml /api

RUN \
  \
  # "install" swagger-codegen
  #
  mkdir -pv /swagger_tools/swagger-codegen && \
  wget https://repo1.maven.org/maven2/io/swagger/codegen/v3/swagger-codegen-cli/3.0.20/swagger-codegen-cli-3.0.20.jar -O /swagger_tools/swagger-codegen/swagger-codegen-cli.jar && \
  \
  # convert yaml to jason and back again
  #
  cd /swagger_tools/swagger-codegen/ && \
  java -jar ./swagger-codegen-cli.jar generate -i /api/openapi.yaml -l openapi -o /api && \
  java -jar ./swagger-codegen-cli.jar generate -i /api/openapi.json -l openapi-yaml -o /api/converted

RUN \
  # create "generate stubs and serve" script
  #
  echo '#!/bin/bash' > /stubs_nodejs/build_stubs.sh && \
  echo 'cd /stubs_nodejs' >> /stubs_nodejs/build_stubs.sh && \
  # echo 'touch /stubs_nodejs/nohup.out' >> /stubs_nodejs/build_stubs.sh && \
  # echo 'chmod ug+rw /stubs_nodejs/nohup.out' >> /stubs_nodejs/build_stubs.sh && \
  echo 'java -jar /swagger_tools/swagger-codegen/swagger-codegen-cli.jar generate -i /api/openapi.yaml -l nodejs-server -o /stubs_nodejs' >> /stubs_nodejs/build_stubs.sh && \
  echo "sed -i 's|8080|3003|' /stubs_nodejs/index.js" >> /stubs_nodejs/build_stubs.sh && \
  \
  echo "grep 'Access-Control-Allow-Origin' /stubs_nodejs/index.js || \ " >> /stubs_nodejs/build_stubs.sh && \
  echo "sed -i.bak '/expressAppConfig.getApp/a \ " >> /stubs_nodejs/build_stubs.sh && \
  echo '\ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '// Add headers \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo 'app.use\(function \(req, res, next)\ { \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '\ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    // Website you wish to allow to connect \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    res.setHeader\("Access-Control-Allow-Origin", "*"\); \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '\ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    // Request methods you wish to allow \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    res.setHeader\("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, PATCH, DELETE"\); \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '\ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    // Request headers you wish to allow \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    res.setHeader\("Access-Control-Allow-Headers", "*"\); \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '\ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    // Set to true if you need the website to include cookies in the requests sent \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    // to the API \(e.g. in case you use sessions\) \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    res.setHeader\("Access-Control-Allow-Credentials", true\); \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '\ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    // Pass to next layer of middleware \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '    next\(\); \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '}\); \ ' >> /stubs_nodejs/build_stubs.sh && \
  echo '\ ' >> /stubs_nodejs/build_stubs.sh && \
  echo "' /stubs_nodejs/index.js" >> /stubs_nodejs/build_stubs.sh && \
  \
  echo '[[ -d /stubs_nodejs/node_modules ]] || npm install' >> /stubs_nodejs/build_stubs.sh && \
  \
  echo 'cp -v /api/* /stubs_nodejs/node_modules/oas3-tools/dist/middleware/swagger-ui || true' >> /stubs_nodejs/build_stubs.sh && \
  \
  sed -i 's| $||g' /stubs_nodejs/build_stubs.sh && \
  \
  chmod u+x /stubs_nodejs/build_stubs.sh && \
  \
  # On change of /api/openapi.yaml
  #
  sed -i '/set -e/a [[ $( ps -C run_codegen_ser -o stat --no-headers ) == "S" ]] || nohup nodemon -L -w /api/openapi.yaml -x "/stubs_nodejs/build_stubs.sh && node /stubs_nodejs/index.js" </dev/null &' /usr/local/bin/docker-entrypoint.sh

EOF

```

<!--
java -jar /swagger_tools_/swagger-codegen/swagger-codegen-cli.jar generate -i ./api/project.yaml -l nodejs-server -o /nodejs_stubs
 -->

[[Top]](#swagger-codegen-30-docker-container)

#### Create baseline Docker Image

The following command will create the baseline image with specific packages pre-installed and the timezone set.

```shell
CONTAINER_NAME=swagger_codegen
IMAGE_VERSION=1.0.0

docker build \
    --tag ${CONTAINER_NAME}:${IMAGE_VERSION} \
    --force-rm .

```

At this point we have the new image `swagger_codegen:1.0.0`ready to roll.

From this point, until the image is deleted, we can spin up a container, based on this image, in a matter of seconds.

[[Top]](#swagger-codegen-30-docker-container)

### Start the Docker Container Instance

#### Create a container based on the new Image

Now that we have the baseline image we can create and explore a container that uses it.

```shell
IMAGE_VERSION="1.0.0"
IMAGE_NAME="swagger_codegen"
CONTAINER_NAME="swagger_codegen"
CONTAINER_HOSTNAME="swagger_codegen"
CONTAINER_VOLUME_MAPPING=" -v d:/github_materials/swagger_codegen/api:/api "
CONTAINER_MAPPED_PORTS=" -p 127.0.0.1:3003:3003/tcp "

docker.exe run \
    --rm \
    --name ${CONTAINER_NAME} \
    ${CONTAINER_VOLUME_MAPPING} \
    ${CONTAINER_MAPPED_PORTS} \
    --hostname ${CONTAINER_HOSTNAME} \
    --detach \
    --interactive \
    --tty\
        ${IMAGE_NAME}:${IMAGE_VERSION}

```

[[Top]](#swagger-codegen-30-docker-container)

#### Connect to the running container

The following command will connect us to teh running container and offer us the interactive shell to work in:

```shell
docker exec -it -w='/api' swagger_codegen bash -l
```

[[Top]](#swagger-codegen-30-docker-container)

#### Test Swagger Codegen

Let's run the swagger-codegen server.

```shell
cd /swagger_tools/swagger-codegen
## nodemon -L -w index.html -w /api/openapi.yaml -x "cp -v /api/openapi.yaml /swagger_tools/swagger-codegen/ && http-server -p 3003"

```

And in a host web browser let's open our API specification in the swagger-codegen.

http://localhost:3003/docs/

## Notes

### Initial API Specification Example YAML

OpenAPI Specification found in the `./api` directory was written to the Guest file `/api/openapi.yaml` during Docker Image _s_.

[[Top]](#swagger-codegen-30-docker-container)

### JSON Versions of Specification

Subsequent manipulations, during Docker Image build, resulted in creation of the following JSON equivalents:

```shell
/api/openapi.json
/api/converted/openapi.yaml
```

[[Top]](#swagger-codegen-30-docker-container)

### Where to change where Swagger Codegen looks for the YAML specification?

`/swagger_tools/swagger-codegen/index.js`.

[[Top]](#swagger-codegen-30-docker-container)

### What listens on what ports?

Swagger Codegen is expected to listen on port 3003.

If you change the listening port make sure to adjust your `docker.exe run ...` command otherwise you will not be able to connect to the listener in the container from outside.

[[Top]](#swagger-codegen-30-docker-container)

## Next Steps

[[Top]](#swagger-codegen-30-docker-container)

## Licensing

The MIT License (MIT)

Copyright © 2020 Michael Czapski

Rights to Docker (and related), Git (and related), Debian, its packages and libraries, and 3rd party packages and libraries, belong to their respective owners.

[[Top]](#swagger-codegen-30-docker-container)

2020/07 MCz

<!--
https://stackoverflow.com/questions/51225277/run-script-on-change-in-nodemon

https://stackoverflow.com/questions/28681491/within-docker-vm-gulp-watch-seems-to-not-work-well-on-volumes-hosted-from-the-h

\#\#require /swagger/project/editor/api/swagger/swagger.yaml to be copied to /swagger/project/project.json

cd /swagger/project

cat <<-'EOF' > cvtYaml2Json.js

const yaml = require("js-yaml");
const path = require("path");
const fs = require("fs");

const swaggerYamlFile = "/swagger/project/editor/api/swagger/swagger.yaml";
const swaggerJsonFile = "/swagger/project/project.json";

// Converts yaml to json
const doc = yaml.safeLoad(fs.readFileSync(swaggerYamlFile));
fs.writeFileSync(swaggerJsonFile, JSON.stringify(doc, null, " "));

EOF

cd /swagger/project
nodemon -L --watch ./editor/api/swagger/\* --exec "node ./cvtYaml2Json.js"

-->

<!--

References

https://github.com/Surnet/swagger-jsdoc
https://www.npmjs.com/package/swagger-ui-express
https://mherman.org/blog/swagger-and-nodejs/
https://github.com/Surnet/swagger-jsdoc

https://swagger.io/specification/#InfoObject

https://www.youtube.com/watch?v=3ZK7TsA8a9Q&list=PLnBvgoOXZNCOiV54qjDOPA9R7DIDazxBA&index=4
https://www.youtube.com/watch?v=3ZK7TsA8a9Q&list=PLnBvgoOXZNCOiV54qjDOPA9R7DIDazxBA&index=5
https://www.youtube.com/watch?v=QKKMxboJMcw&list=PLnBvgoOXZNCOiV54qjDOPA9R7DIDazxBA&index=6
https://www.youtube.com/watch?v=GBi9_NUYxS8&list=PLnBvgoOXZNCOiV54qjDOPA9R7DIDazxBA&index=7

https://github.com/swagger-api/swagger-codegen

https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md#schema-object
https://www.ecma-international.org/ecma-262/5.1/#sec-7.8.5
https://o7planning.org/en/12219/ecmascript-regular-expressions-tutorial
https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions

https://stackoverflow.com/questions/49379006/what-is-the-correct-way-to-declare-a-date-in-an-openapi-swagger-file

https://github.com/gulpjs/gulp
https://gulpjs.com/docs/en/getting-started/quick-start
https://gulpjs.com/docs/en/api/concepts
https://github.com/gulpjs/gulp/archive/master.zip

https://www.npmjs.com/package/swagger-codegen-dist
https://www.npmjs.com/package/swagger-ui-dist

https://github.com/swagger-api/swagger-codegen
https://github.com/swagger-api/swagger-codegen#table-of-contents
https://swagger.io/docs/open-source-tools/swagger-codegen/

https://github.com/apigee-127/swagger-tools

https://github.com/patrick-steele-idem/browser-refresh

-->
<!--

curl --include \
     --no-buffer \
     --header "Connection: Upgrade" \
     --header "Upgrade: websocket" \
     --header "Host: example.com:80" \
     --header "Origin: http://example.com:80" \
     --header "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
     --header "Sec-WebSocket-Version: 13" \
     http://example.com:80/

curl --include \
     --no-buffer \
     --header "Connection: Upgrade" \
     --header "Upgrade: websocket" \
     --header "Host: localhost:3003" \
     --header "Origin: http://localhost:3003" \
     http://localhost:3003/

https://linoxide.com/linux-command/use-ip-command-linux/

ss -rl

ss -4rlpt

ss -lt
 -->
