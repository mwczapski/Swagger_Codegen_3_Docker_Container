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
      - [Create generate_nodejs_stubs_server.sh Script](#create-generate_nodejs_stubs_serversh-script)
      - [Create run_nodejs_stubs_server.sh Script](#create-run_nodejs_stubs_serversh-script)
      - [Create swagger-codegen yaml to json and back convert example](#create-swagger-codegen-yaml-to-json-and-back-convert-example)
      - [Create Dockerfile in the Host directory](#create-dockerfile-in-the-host-directory)
      - [Create baseline Docker Image](#create-baseline-docker-image)
    - [Start the Docker Container Instance](#start-the-docker-container-instance)
      - [Create a container based on the new Image](#create-a-container-based-on-the-new-image)
      - [Connect to the running container](#connect-to-the-running-container)
      - [Test Swagger Codegen](#test-swagger-codegen)
  - [Important Notes](#important-notes)
    - [Disable / Enable automatic Swagger Codegen server startup on container start/restart](#disable--enable-automatic-swagger-codegen-server-startup-on-container-startrestart)
    - [Initial API Specification Example YAML](#initial-api-specification-example-yaml)
    - [JSON Version of Specification](#json-version-of-specification)
    - [Watching for changes and restarting Swagger Codegen server](#watching-for-changes-and-restarting-swagger-codegen-server)
    - [Must I copy the openapi.yaml file to the container?](#must-i-copy-the-openapiyaml-file-to-the-container)
    - [How to edit the yaml file in the Container](#how-to-edit-the-yaml-file-in-the-container)
      - [Use docker cp command](#use-docker-cp-command)
      - [Use VSCode Remote](#use-vscode-remote)
      - [Use bound volume](#use-bound-volume)
    - [Where to change where Swagger Codegen Docs Server looks for the YAML specification and under what name?](#where-to-change-where-swagger-codegen-docs-server-looks-for-the-yaml-specification-and-under-what-name)
    - [What port does Swagger Codegen Stub Server listen on?](#what-port-does-swagger-codegen-stub-server-listen-on)
  - [Licensing](#licensing)

<!-- /TOC -->


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
mkdir -pv /mnt/d/github_materials/swagger_codegen/{api,scripts}
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
    This API is a __test__ API for validation of local Swagger Codegen
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

#### Create generate_nodejs_stubs_server.sh Script

Create a start script that will generate nodejs server stubs.


``` shell
HOST_DIR=/mnt/d/github_materials

cat <<-'EOF' > ${HOST_DIR}/swagger_codegen/scripts/generate_nodejs_stubs_server.sh
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

EOF

```

[[Top]](#swagger-codegen-30-docker-container)


#### Create run_nodejs_stubs_server.sh Script

Create a server start script, to be executed from the docker-entrypoint.sh in the container on container start and restart.


``` shell
HOST_DIR=/mnt/d/github_materials

cat <<-'EOF' > ${HOST_DIR}/swagger_codegen/scripts/run_nodejs_stubs_server.sh
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
## nodemon -L -w /api/* -w /stubs_nodejs/* -x "node /stubs_nodejs/index.js"

nodemon -L -w /api/* -x "/swagger_tools/generate_nodejs_stubs_server.sh && node /stubs_nodejs/index.js"

EOF

```

[[Top]](#swagger-codegen-30-docker-container)

#### Create swagger-codegen yaml to json and back convert example

Create an example of converting YAML to JSON and back using swagger-codegen. Not needed for working with the Swagger Codegen server in the container.

``` shell
HOST_DIR=/mnt/d/github_materials

cat <<-'EOF' > ${HOST_DIR}/swagger_codegen/scripts/swagger-codegen_convert_example.sh
#!/bin/bash

cd /swagger_tools/swagger-codegen

# convert yaml to jason and back again example
# not needed for work with the Swagger Codegen server
#
cd /swagger_tools/swagger-codegen

java -jar /swagger_tools/swagger-codegen/swagger-codegen-cli.jar generate -i /swagger_tools/swagger-codegen/openapi.yaml -l openapi -o /swagger_tools/swagger-codegen

java -jar /swagger_tools/swagger-codegen/swagger-codegen-cli.jar generate -i /swagger_tools/swagger-codegen/openapi.json -l openapi-yaml -o /swagger_tools/swagger-codegen/converted

EOF

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
    openjdk-8-jdk \
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
  mkdir -pv /stubs_nodejs && \
  mkdir -pv /swagger_tools/swagger-codegen

RUN \
  #
  # "install" swagger-codegen
  #
  mkdir -pv /swagger_tools/swagger-codegen && \
  wget https://repo1.maven.org/maven2/io/swagger/codegen/v3/swagger-codegen-cli/3.0.20/swagger-codegen-cli-3.0.20.jar -O /swagger_tools/swagger-codegen/swagger-codegen-cli.jar 

COPY api/openapi.yaml /api
COPY scripts/run_nodejs_stubs_server.sh /swagger_tools
COPY scripts/generate_nodejs_stubs_server.sh /swagger_tools
COPY scripts/swagger-codegen_convert_example.sh /swagger_tools

RUN \
  # make scripts runnable
  #
  chmod u+x /swagger_tools/run_nodejs_stubs_server.sh && \
  chmod u+x /swagger_tools/swagger-codegen_convert_example.sh && \
\
  # convert yaml to jason and back again, as an example
  #
  cp -v /api/openapi.yaml /swagger_tools/swagger-codegen/ && \
  /swagger_tools/swagger-codegen_convert_example.sh && \
\
  #
  # instrument docker-entrypoint.sh to execute the /swagger_tools/run_nodejs_stubs_server.sh on start/re-start
  #
  sed -i '/set -e/a [[ $( ps -C run_codegen_ser -o stat --no-headers ) == "S" ]] || nohup /swagger_tools/run_nodejs_stubs_server.sh &' /usr/local/bin/docker-entrypoint.sh

EOF

```

[[Top]](#swagger-codegen-30-docker-container)

#### Create baseline Docker Image

The following command will create the baseline image with specific packages pre-installed and the timezone set.

```shell

touch ./api/.no_autostart
## touch ./api/.no_autogenerate

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

The swagger-codegen server will be running at container start/restart unless a "prevent server startup" flag file, `/api/.no_autostart`, is visible to the container when it is started or restarted.

In a host web browser open the API documentation served by the swagger-codgen container.

[http://localhost:3003/docs/](http://localhost:3003/docs/)

## Important Notes

### Disable / Enable automatic Swagger Codegen server startup on container start/restart

The Swagger Codegen Image is built to run the Swagger Codegen server when the container starts or restarts.

To prevent autostart on container start and restart, create a file `/api/.no_autostart` in the container and restart the container.

There are several ways to do this. The easiest is to execute the following commands from the Host:

``` shell
docker exec -it swagger_codegen ps -ef ## check whether server processes are running

docker exec -it swagger_codegen touch /api/.no_autostart ## create file

docker exec -it swagger_codegen ls -al /api/.no_autostart ## verify that file exists

docker restart swagger_codegen ## restart container

docker exec -it swagger_codegen ps -ef ## check whether server processes are running

```

To re-enable autostart on container start and restart, delete the file `/api/.no_autostart` in the container and restart the container.

``` shell
docker exec -it swagger_codegen ps -ef ## check whether server processes are running

docker exec -it swagger_codegen ls -al /api/.no_autostart ## verify that file exists

docker exec -it swagger_codegen rm -vf /api/.no_autostart || true ## delete the file

docker restart swagger_codegen ## restart container

docker exec -it swagger_codegen ps -ef ## check whether server processes are running

```

[[Top]](#swagger-codegen-30-docker-container)

### Initial API Specification Example YAML

Our original OpenAPI Specification was copied to the container file `/api/openapi.yaml` during Docker Image build.

[[Top]](#swagger-codegen-30-docker-container)

### JSON Version of Specification

Our subsequent manipulations, during Docker Image build, resulted in the creation of the following equivalents:

```shell
/swagger_tools/swagger-codegen/openapi.json
/swagger_tools/swagger-codegen/converted/openapi.yaml
```

[[Top]](#swagger-codegen-30-docker-container)

### Watching for changes and restarting Swagger Codegen server

The Swagger Codegen server's `index.html` has been rigged to serve the file `openapi.yaml` from its  directory.

The command in the `/swagger_tools/run_nodejs_stubs_server.sh` script is reproduced below.

```shell
# nodemon -L -w /api/* -x "/swagger_tools/generate_nodejs_stubs_server.sh && node /stubs_nodejs/index.js"

```

It instructs `nodemon` to watch for changes to files in directory `/api`.  
If a change is detected, `nodemon` will re-generate stub server code and will restart the stub server.

Please note that the generated stub server runs in the container.  
Unless the container startup command is configured so that it mounts a host directory over the top of the containers `/api` directory, Swagger Codegen will only (re-)generate stubs if the `/api/openapi.yaml` file inside the container changes.

There are a couple of ways to make changes to the `openapi.yaml` file that the Swagger Codegen sees and uses to (re-)generate nodejs stubs. One is to mount a Host directory over the top of container's the `/api` directory and another to use the `docker cp` command to copy a file to the container's `/api` directory.

See section [How to edit the yaml file in the Container](#how-to-edit-the-yaml-file-in-the-container)

[[Top]](#swagger-codegen-30-docker-container)

### Must I copy the openapi.yaml file to the container?

**No.**

See section [How to edit the yaml file in the Container](#how-to-edit-the-yaml-file-in-the-container) for three ways to have edits reflected inside the container.

[[Top]](#swagger-codegen-30-docker-container)

### How to edit the yaml file in the Container

There are at least 3 different ways in which the container's `/api/openapi.yaml` file can be supplied to teh Swagger Codegen container such that changes persist across container re-creation.

#### Use docker cp command

Docker has the ability to copy files from the Host to the Container and vice versa.

Here is the `docker cp` usage:

```shell
"docker cp" requires exactly 2 arguments.
See 'docker cp --help'.

Usage:  docker cp [OPTIONS] CONTAINER:SRC_PATH DEST_PATH|-
        docker cp [OPTIONS] SRC_PATH|- CONTAINER:DEST_PATH

Copy files/folders between a container and the local filesystem
```

Assuming the container as discussed so far, with `openapi.yaml` in the container directory `/api` being the **_source-of-truth_**, here are the steps:

1. Copy `openapi.yaml` from the container to the Host
    1. Open a terminal window on the Host in the Host directory to which you want to copy the container's openapi.yaml
    2. execute `docker cp swagger_codegen:/api/openapi.yaml ./`
2. Copy `openapi.yaml` from the Host to the Container
    1. Open a terminal window on Host in the Host directory to where oyu have the openapi.yaml file which you want to copy the container
    2. execute `docker cp ./openapi.yaml swagger_codegen:/api`

Using this method one can edit the original `openapi.yaml` file in the local Swagger Codegen, save it to the Host, and copy it to the container for the next Swagger Codegen session.

#### Use VSCode Remote

If you use VSCode for development, and VSCode has the Remote Containers extension installed, you can connect to the container and use VSCode to edit files directly in the container.

Here are the steps:

1. Start the container as discussed so far.
2. Connect to the container as discussed in [Connect to the running container](#connect-to-the-running-container)
3. Start VSCode on the **_Host_**
4. Click on the green '**><sup>\<</sup>**' rectangle in the bottom-left corner (Shows "`Open Remote Window`" legend if one hovers the mouse over it)
5. From the dropdown, top-centre of the VSCode window, choose "`Remote-Containers: Attach to Running Container...`"
6. From the dropdown, select "`/swagger_codegen: swagger_codegen:1.0.0 ...`"
7. When the new VSCode window opens, click on the "`Open Folder`" button and enter `/api`
8. Edit the `openapi.yaml` file to your heart's content
9. Save
10. Refresh the Host Web Browser window to see changes

The remote VSCode might need OpenAPI / Swagger extensions for pretty-printing, snippets and so on. Pick any you like.

You can copy the `openapi.yaml` file between the Host and the Guest, in either direction, using docker cp command. See [Use docker cp command](#Use-docker-cp-command).

#### Use bound volume

It is possible to share a Host directory with the container in such a way that changes made in one environment are visible in the other.

To effect this, one needs to start the docker container with a modified command line so that docker gets told what Host directory to share and where to "mount" it in the container's file system.

**Steps:**

1. On the Host, stop and remove the container if it is running: `docker container stop swagger_codegen; docker container rm swagger_codegen`
2. On the host, start the container with the following command, assuming `/mnt/d/github_materials/swagger_codegen/api` is the host directory to share:

```shell
SOURCE_HOST_DIR=d:/github_materials/swagger_codegen

IMAGE_VERSION="1.0.0"
IMAGE_NAME="swagger_codegen"
CONTAINER_NAME="swagger_codegen"
CONTAINER_HOSTNAME="swagger_codegen"
CONTAINER_VOLUME_MAPPING=" -v ${SOURCE_HOST_DIR}/api:/api"
CONTAINER_MAPPED_PORTS=" -p 127.0.0.1:3003:3003/tcp "

docker run \
    --name ${CONTAINER_NAME} \
    --hostname ${CONTAINER_HOSTNAME} \
    ${CONTAINER_VOLUME_MAPPING} \
    ${CONTAINER_MAPPED_PORTS} \
    --detach \
    --interactive \
    --tty\
        ${IMAGE_NAME}:${IMAGE_VERSION}

```

5. Use the Swagger Codegen or VSCode or IntelliJ or whatever in the Host to access and change the `openapi.yaml` file
6. When done, pull down the `File->Save as YAML` and save the file as `openapi.yaml` in the Host directory `d\:github_materials\swagger_codegen\api`
7. In Guest, note that stubs were regenerated and the stubs server was re-started because `nodemon` recognised that the file in the directory it is watching changed.
8. In the container view the file `/api/openapi.yaml` and see the changes

Because the host and the container share the (bound) volume where the API specification exists, it is possible to edit the file on Host and in the container and see the changes in either environment.

[[Top]](#swagger-codegen-30-docker-container)

### Where to change where Swagger Codegen Docs Server looks for the YAML specification and under what name?

`/stubs_nodejs/index.js`.

[[Top]](#swagger-codegen-30-docker-container)

### What port does Swagger Codegen Stub Server listen on?

Swagger Codegen server inside the container listens on port 3003.
To change the port on which the Host listens, change the port mapping the container start command uses.

For example:

```shell
CONTAINER_MAPPED_PORTS=" -p 127.0.0.1:3230:3003/tcp "

```

will change the port the Hosts maps to the container's 3003 from 3003 to 3230. The Host's web browser will need to use the url `http://localost:3230/docs` to connect to the Swagger Codegen documentation served from container.

If you change the listening port make sure to adjust your `docker run ...` and `docker exec ...` commands otherwise you will not be able to connect to the listener in the container from outside.

[[Top]](#swagger-codegen-30-docker-container)

## Licensing

The MIT License (MIT)

Copyright � 2020 Michael Czapski

Rights to Docker (and related), Git (and related), Debian, its packages and libraries, and 3rd party packages and libraries, belong to their respective owners.

[[Top]](#swagger-codegen-30-docker-container)

2020/07 MCz


<!--
# TODO

-   Upload the image to the docker hub
-   write the 'how to use the image' writeup to go with the image
-   write a 'how to use the container' to go with the container
-   git and push to github
-   write a blog entry and post
-   write a tweet and post
 -->
-   