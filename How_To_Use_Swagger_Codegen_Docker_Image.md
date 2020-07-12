# How to Use the Swagger Codegen 3.0 Docker Container

> Modification Date: 2020-07-12

<!-- <font size="6">Swagger Codegen Docker Container</font> -->

<!-- TOC -->

-   [How to Use the Swagger Codegen 3.0 Docker Container](#how-to-use-the-swagger-codegen-30-docker-container)
    -   [1.1. Introduction](#11-introduction)
    -   [1.2. Assumptions](#12-assumptions)
    -   [1.3. Create the Docker Container](#13-create-the-docker-container)
        -   [1.3.1. Create Host directory which to mount in the container](#131-create-host-directory-which-to-mount-in-the-container)
        -   [1.3.2. Notes on the Container - **Read Before Opening**](#132-notes-on-the-container---read-before-opening)
            -   [1.3.2.1. Synchronisation of changes between Host and Container](#1321-synchronisation-of-changes-between-host-and-container)
            -   [1.3.2.2. What port does Swagger Codegen listen on?](#1322-what-port-does-swagger-codegen-listen-on)
            -   [1.3.2.3 Disable / Enable automatic Swagger Codegen NodeJS Stub server startup on container start/restart](#1323-disable--enable-automatic-swagger-codegen-nodejs-stub-server-startup-on-container-startrestart)
    -   [1.4 Use the container](#14-use-the-container)
        -   [1.4.1 Create the example openapi.yaml API Specification (OpenAPI 3.0.1)](#141-create-the-example-openapiyaml-api-specification-openapi-301)
        -   [1.4.2 Start the container](#142-start-the-container)
        -   [1.4.3 Connect to the running container](#143-connect-to-the-running-container)
        -   [1.4.4 Test Swagger Codegen-generated NodeJS Stub on Host](#144-test-swagger-codegen-generated-nodejs-stub-on-host)
        -   [1.4.5 Use swagger-codegen to convert yaml to json and back](#145-use-swagger-codegen-to-convert-yaml-to-json-and-back)
        -   [1.4.6 Explicitly Generate NodeJS Stub Server](#146-explicitly-generate-nodejs-stub-server)
        -   [1.4.7 Modify and Test generated NodeJS Stub Server code](#147-modify-and-test-generated-nodejs-stub-server-code)
            -   [1.4.7.1 Container startup with mapped `/stubs_nodejs`](#1471-container-startup-with-mapped-stubs_nodejs)
            -   [1.4.7.1 Stub code editing workflow](#1471-stub-code-editing-workflow)
    -   [1.5 Licensing](#15-licensing)

<!-- /TOC -->

## 1.1. Introduction

The intent of this document is to provide information on how to create a self-contained Docker container for API-First development using the [mwczapski/swagger-codegen:1.0.0](https://hub.docker.com/r/mwczapski/swagger_codegen) image hosted on Docker Hub.

The container provides the means to:

-   Run the Swagger Codegen-generated NodeJS Stub Server
-   Convert YAML specification documents to JSON and the vice versa

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

## 1.2. Assumptions

It is assumed in the text that Windows 10 with Debian WSL is the Host operating environment.

Make such changes, to the small number of commands that this affects, as you need to make it work in a regular Linux environment.

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

## 1.3. Create the Docker Container

In this section a docker container with all that that is necessary to run the Swagger Codegen-generated NodeJs Stub server and the Swagger UI to display `/docs` to the Host's Web Browser, and convert between YAML and JSON openapi specifications will be created and started.

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

### 1.3.1. Create Host directory which to mount in the container

Adjust Host paths above directory named `api` as you see fit.

```shell
HOST_DIR=/mnt/d/github_materials

mkdir -pv ${HOST_DIR}/swagger_codegen/api
cd ${HOST_DIR}/swagger_codegen

```

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

### 1.3.2. Notes on the Container - **Read Before Opening**

#### 1.3.2.1. Synchronisation of changes between Host and Container

On startup, the container starts the Swagger Codegen-generated NodeJS Stub server. This happens when the container is first started and when it is re-started.

The source-of-truth `openapi.yaml` file for the container is the `/api/openapi.yaml` file in the container. This file, and all other files in the `/api` directory, are monitored for changes. When changes are detected the NodeJS Stub files are re-generated and the `/docs` "documentation" reflects these changes.

The command that accomplished it is reproduced below for your information. It is automatically run so there is no need to do anything to start the server and to restart the server when files in the container's `/api` directory change.

```shell
# nodemon -L -w /api/* -x "/swagger_tools/generate_nodejs_stubs_server.sh && node /stubs_nodejs/index.js"

```

Please note that the Swagger Codegen `/docs` document tree is served through the Web Browser in the Host environment.  
The recommended container startup command, shown in this document, mounts a host directory over the top of the container's `/api` directory. This gives the Swagger Codegen the ability to read the `/api` directory in the Host as if it was a directory in the container. This gives external tools, like for example VSCode or IntelliJ running on the Host, the ability to edit the files in the Host's directory and have them "immediately" available to Swagger Codegen in the container to re-generate the NodeJS stub server, and consequently to test the stub through the Swagger UI `/docs` document tree in the Web Browser as soon as the Web Browser page is refreshed.

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

#### 1.3.2.2. What port does Swagger Codegen listen on?

Swagger Codegen NodeJS Stub server inside the container listens on port `3003`. This is the port which the API clients would use to invoke the Stub Server-served APIS and it's `/docs` document tree.
To change the port on which the Host listens, change the port mapping the container start command uses.

For example,

```shell
CONTAINER_MAPPED_PORTS=" -p 127.0.0.1:3230:3003/tcp "

```

will change the port the Hosts maps to the container's `3003` from `3003` to `3230`. The Host's web browser will need to use the url `http://localost:3230/docs` to connect to the Swagger Codegen served `/docs` document tree from container.

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

#### 1.3.2.3 Disable / Enable automatic Swagger Codegen NodeJS Stub server startup on container start/restart

The Swagger Codegen Image is built to run the Swagger Codegen NodeJS Stub server when the container starts or restarts.

To prevent autostart on container start and restart, create a file `/api/.no_autostart` in the container and restart the container.

With container started as described in this document the easiest way to accomplish this is to create a `.no_autostart` file in the Host directory mapped to the container's `/api` directory to disable and to delete this file from the Host directory mapped to the container's `/api` directory to enable this functionality.

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

## 1.4 Use the container

### 1.4.1 Create the example openapi.yaml API Specification (OpenAPI 3.0.1)

As already mentioned, the container expect the `openapi.yaml` file to be available in it's `/api` directory. As recommended, the container startup command will bind a Host directory to a `/api` directory in the container.

Let's create the `openapi.yaml` file in the bound host directory so that the container can access it.

```shell
HOST_DIR=/mnt/d/github_materials

cat <<-'EOF' > ${HOST_DIR}/swagger_codegen/api/openapi.yaml
openapi: "3.0.1"
info:
  title: Weather API
  description: |
    This API is a __test__ API for validation of local swagger codegen
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

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

### 1.4.2 Start the container

On the host, start the container with the following command, assuming `/mnt/d/github_materials/swagger_codegen/api` is the host directory to share.

> Please note that the Windows version of Docker (which is what I use) wants a DOS'ish path (`d:/github_materials/swagger_codegen`) when run from the WSL Bash shell, rather than a WSL Linux'ish path, which would be something like `/mnt/d/github_materials/swagger_codegen` in my Windows/WSL environment. If you Docker runs in a proper Linux/Unix environment the Host path would be a regular Linux/Unix path. Change as required.

Create the docker container start script:

```shell
HOST_DIR=/mnt/d/github_materials
cd ${HOST_DIR}

SOURCE_HOST_DIR=d:/github_materials/swagger_codegen

HOST_LISTEN_PORT=3003
IMAGE_VERSION="1.0.0"
IMAGE_NAME="mwczapski/swagger_codegen"
CONTAINER_NAME="swagger_codegen"
CONTAINER_HOSTNAME="swagger_codegen"
CONTAINER_VOLUME_MAPPING=" -v ${SOURCE_HOST_DIR}/api:/api"
CONTAINER_MAPPED_PORTS=" -p 127.0.0.1:${HOST_LISTEN_PORT}:3003/tcp "

cat <<-EOF > start_swagger_codegen_container.sh

docker.exe run \
    --name ${CONTAINER_NAME} \
    --hostname ${CONTAINER_HOSTNAME} \
    ${CONTAINER_VOLUME_MAPPING} \
    ${CONTAINER_MAPPED_PORTS} \
    --detach \
    --interactive \
    --tty\
        ${IMAGE_NAME}:${IMAGE_VERSION}

EOF

chmod u+x start_swagger_codegen_container.sh

```

Start the container: `./start_swagger_codegen_container.sh`

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

### 1.4.3 Connect to the running container

The following command will connect us to the running container and offer the interactive bash shell to work in if required, such as for example when running the swagger-codegen to convert between yaml and json, or perhaps editing NodeJS stub code, though there are easier ways of doing the later.

```shell
docker exec -it -w='/api' swagger_codegen bash -l

```

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

### 1.4.4 Test Swagger Codegen-generated NodeJS Stub on Host

The swagger-codegen-generated NodeJS Stub server is started when the container is created and started, and re-starts when the container is restarted. Likewise, NodeJS Stub is (re-)generated each time a change to `/api/openapi.yaml` is detected or the container is (re-)started.

With the container running, in a host web browser open the pre-configured API specification.

[http://localhost:3003/docs](http://localhost:3003/docs)

Try the Get Weather API and execute the test.

### 1.4.5 Use swagger-codegen to convert yaml to json and back

Swagger Codegen Docker Image includes an example of how to use the Swagger Codegen to convert YAML tyo JSON and vice versa.

The example script is to be found in the container in `/swagger_tools/swagger-codegen_convert_example.sh`.

Assuming that the source openapi.yaml is in container's directory `/api/openapi.yaml`, the command to execute in the container to convert it to JSON in a subdirectory `converted` of that directory` will be:

```shell
java -jar /swagger_tools/swagger-codegen/swagger-codegen-cli.jar generate -i /api/openapi.yaml -l openapi -o /api/converted

```

As mentioned, this command needs to be executed inside the container. To do the same thing directly from the Host one can use `docker exec` like:

```shell
docker exec -it -w=/api swagger_codegen java -jar /swagger_tools/swagger-codegen/swagger-codegen-cli.jar generate -i /api/openapi.yaml -l openapi -o /api/converted

```

To person the reverse operation, converting `/api/converted/openapi.json` to `/api/converted/openapi.yaml` one could execute, inside the container:

```shell

java -jar /swagger_tools/swagger-codegen/swagger-codegen-cli.jar generate -i /api/converted/openapi.json -l openapi-yaml -o /api/converted

```

To do the same thing directly from the Host one can use `docker exec` like:

```shell
docker exec -it -w=/api swagger_codegen java -jar /swagger_tools/swagger-codegen/swagger-codegen-cli.jar generate -i /api/converted/openapi.json -l openapi-yaml -o /api/converted

```

To verify that these files exist, one can execute the following `docker exec` command frm the host:

```shell
docker exec -it swagger_codegen ls -al /api/converted

```

To copy the converted file form the container to the Host one could use a docker exec command from the Host similar to the following:

```shell
docker cp swagger_codegen:/api/converted/openapi.json ./

```

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

### 1.4.6 Explicitly Generate NodeJS Stub Server

NodeJS Stub Server code is generated each time a change to the `/api/openapi.yaml` is detected by the container.

To trigger this functionality explicitly one can execute the following command form the Host:

```shell
docker exec -it swagger_codegen /swagger_tools/generate_nodejs_stubs_server.sh

```

Please note that this is redundant and unproductive if the the automatic stub generation is enabled (default), and does not cause the stub server to be restarted since changes to stub code are not monitored.

If, on the other hand, automatic stub generation is disabled, and the stub server does not run, the better way to re-generate the stub server code and start the Stub Server would be:

```shell
docker exec -it swagger_codegen rm -vf /api/.no_autostart || true

docker exec -it swagger_codegen /swagger_tools/run_nodejs_stubs_server.sh

```

There are two side-effects of this.

1. NodeJS stub code is generated
2. Stb Server is started and console output is displayed in the terminal window

So, this might be a reasonable way of using the container functionality when editing NodeJS stub code and testing changes in conjunction with mapping the `/stubs_nodejs` container directory, in the container startup command, to a Host directory and editing the stub code from outside the container.

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

### 1.4.7 Modify and Test generated NodeJS Stub Server code

#### 1.4.7.1 Container startup with mapped `/stubs_nodejs`

On the host, start the container with the following command, assuming `/mnt/d/github_materials/swagger_codegen/api` is the host directory to share.

> Please note that the Windows version of Docker (which is what I use) wants a DOS'ish path (`d:/github_materials/swagger_codegen`) when run from the WSL Bash shell, rather than a WSL Linux'ish path, which would be something like `/mnt/d/github_materials/swagger_codegen` in my Windows/WSL environment. If you Docker runs in a proper Linux/Unix environment the Host path would be a regular Linux/Unix path. Change as required.

Create the docker container start script:

```shell
HOST_DIR=/mnt/d/github_materials/swagger_codegen
cd ${HOST_DIR}

mkdir -pv ${HOST_DIR}/stubs_nodejs
touch ${HOST_DIR}/api/.no_autostart

SOURCE_HOST_DIR=d:/github_materials/swagger_codegen

HOST_LISTEN_PORT=3003
IMAGE_VERSION="1.0.0"
IMAGE_NAME="mwczapski/swagger_codegen"
CONTAINER_NAME="swagger_codegen"
CONTAINER_HOSTNAME="swagger_codegen"
CONTAINER_VOLUME_MAPPING=" -v ${SOURCE_HOST_DIR}/api:/api -v ${SOURCE_HOST_DIR}/stubs_nodejs:/stubs_nodejs "
CONTAINER_MAPPED_PORTS=" -p 127.0.0.1:${HOST_LISTEN_PORT}:3003/tcp "

cat <<-EOF > start_swagger_codegen_container_with_stubs.sh

docker.exe run \
    --name ${CONTAINER_NAME} \
    --hostname ${CONTAINER_HOSTNAME} \
    ${CONTAINER_VOLUME_MAPPING} \
    ${CONTAINER_MAPPED_PORTS} \
    --detach \
    --interactive \
    --tty\
    --rm \
        ${IMAGE_NAME}:${IMAGE_VERSION}

EOF

chmod u+x start_swagger_codegen_container_with_stubs.sh

```

Start the container: `./start_swagger_codegen_container_with_stubs.sh`

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

#### 1.4.7.1 Stub code editing workflow

A possible way to explicitly work with the generated stub code would be to:

1. On the Host run the command: `./start_swagger_codegen_container_with_stubs.sh`
2. On the Host connect to the running container: `docker exec -it -w='/api' swagger_codegen bash -l`
3. In the container run the command: `/swagger_tools/generate_nodejs_stubs_server.sh`
4. In the container run the command: `nodemon -L -w /stubs_nodejs -x "node /stubs_nodejs/index.js"`
5. Edit stub code from the Host
6. Watch the output of 4. in the console window
7. Test API: [http://localhost:3003/docs](http://localhost:3003/docs)

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

## 1.5 Licensing

The MIT License (MIT)

Copyright © 2020 Michael Czapski

Rights to Docker (and related), Git (and related), Debian, its packages and libraries, and 3rd party packages and libraries, belong to their respective owners.

[[Top]](#how-to-use-the-swagger-codegen-30-docker-container)

2020/07 MCz
