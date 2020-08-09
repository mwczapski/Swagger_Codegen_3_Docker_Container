#  Swagger Codegen in WSL Alpine
<!-- TOC -->

- [Swagger Codegen in WSL Alpine](#swagger-codegen-in-wsl-alpine)
  - [Prepare Development Environment](#prepare-development-environment)
    - [Create Working Directory](#create-working-directory)
    - [Check what WSL Distros Are Installed](#check-what-wsl-distros-are-installed)
    - [Install Alpine WSL Distro](#install-alpine-wsl-distro)
    - [Add requisite software](#add-requisite-software)
    - [Install NodeJS](#install-nodejs)
    - [Add useful NodeJS packages](#add-useful-nodejs-packages)
    - [Update shell init scripts](#update-shell-init-scripts)
    - [Backup Alpine Distro as configured so far](#backup-alpine-distro-as-configured-so-far)
  - [Add Swagger Codegen to the Environment](#add-swagger-codegen-to-the-environment)
    - ["Install" Swagger Codegen](#install-swagger-codegen)
    - [Create the example openapi.yaml API Specification (OpenAPI 3.0.1)](#create-the-example-openapiyaml-api-specification-openapi-301)
    - [Create generate_nodejs_stubs_server.sh Script](#create-generate_nodejs_stubs_serversh-script)
    - [Create run_nodejs_stubs_server.sh Script](#create-run_nodejs_stubs_serversh-script)
    - [Create swagger-codegen yaml to json and back convert example](#create-swagger-codegen-yaml-to-json-and-back-convert-example)
  - [Bonus Material - Windows 10 Shortcuts](#bonus-material---windows-10-shortcuts)
    - [Start Stub server](#start-stub-server)
    - [Run Swagger Editor in Chrome](#run-swagger-editor-in-chrome)
    - [Run VS Code](#run-vs-code)
    - [Run PowerShell Here](#run-powershell-here)
    - [Run Alpine ash shell here](#run-alpine-ash-shell-here)
  - [Licensing](#licensing)

<!-- /TOC -->
## Prepare Development Environment

### Create Working Directory

In a Windows PowerShell window (I am using PowerShell 7.0.3):

``` powershell
mkdir d:\swagger_api_dev
mkdir d:\swagger_api_dev\api
mkdir d:\swagger_api_dev\scripts
mkdir d:\swagger_api_dev\bin
mkdir d:\swagger_api_dev\stubs_nodejs
cd d:\swagger_api_dev

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Check what WSL Distros Are Installed

In a Windows PowerShell window :

``` powershell
wsl.exe --list
```

``` text
Windows Subsystem for Linux Distributions:
Debian (Default)
kali-linux
docker-desktop-data
docker-desktop
Ubuntu-18.04
```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Install Alpine WSL Distro

In Windows 10 Microsoft Store search for "Alpine WSL".

Click on "Free Trial" Button, then on "Install Trial".

When the product is downloaded and installed, click "Launch" to complete setup and confirm that Alpine is installed and running.

In a Windows PowerShell window check what distros are installed:

``` cmd
wsl.exe --list
```

``` text
Windows Subsystem for Linux Distributions:
Debian (Default)
kali-linux
docker-desktop-data
docker-desktop
Alpine
Ubuntu-18.04
```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Add requisite software

In a Windows PowerShell window switch to Alpine distro shell terminal:

``` command
wsl.exe -d Alpine -u root
```

In Alpine root shell (from personal experience and [from a blog article](https://blog.developer.atlassian.com/minimal-java-docker-containers/)), install additional software, including JDK8 which is needed to run  the swagger codegen.

``` shell
apk update
apk upgrade
apk --update add curl ca-certificates tar wget dos2unix sqlite
## from https://github.com/jeanblanchard/docker-alpine-glibc/blob/master/Dockerfile
export GLIBC_VERSION=2.32-r0
curl -Lo /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
curl -Lo glibc.apk "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk"
curl -Lo glibc-bin.apk "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk"
apk add glibc-bin.apk glibc.apk
rm -rf glibc.apk glibc-bin.apk /var/cache/apk/*

mkdir -pv /opt 
mkdir -pv ~/Downloads
cd /root/Downloads
wget -q https://cdn.azul.com/zulu/bin/zulu8.44.0.11-ca-jdk8.0.242-linux_musl_x64.tar.gz -O zulu8.44.0.11-ca-jdk8.0.242-linux_musl_x64.tar.gz
cd /opt
tar xf /root/Downloads/zulu8.44.0.11-ca-jdk8.0.242-linux_musl_x64.tar.gz
export JAVA_HOME=/opt/zulu8.44.0.11-ca-jdk8.0.242-linux_musl_x64
${JAVA_HOME}/bin/java -version
${JAVA_HOME}/bin/javac -version
rm -v /root/Downloads/zulu8.44.0.11-ca-jdk8.0.242-linux_musl_x64.tar.gz
ln -s /opt/zulu8.44.0.11-ca-jdk8.0.242-linux_musl_x64 /opt/jdk

rm -rf /opt/jdk/*src.zip /opt/jdk/lib/missioncontrol /opt/jdk/lib/visualvm /opt/jdk/lib/*javafx* /opt/jdk/jre/lib/plugin.jar /opt/jdk/jre/lib/ext/jfxrt.jar /opt/jdk/jre/bin/javaws /opt/jdk/jre/lib/javaws.jar /opt/jdk/jre/lib/desktop /opt/jdk/jre/plugin /opt/jdk/jre/lib/deploy* /opt/jdk/jre/lib/*javafx* /opt/jdk/jre/lib/*jfx* /opt/jdk/jre/lib/amd64/libdecora_sse.so /opt/jdk/jre/lib/amd64/libprism_*.so /opt/jdk/jre/lib/amd64/libfxplugins.so /opt/jdk/jre/lib/amd64/libglass.so /opt/jdk/jre/lib/amd64/libgstreamer-lite.so /opt/jdk/jre/lib/amd64/libjavafx*.so /opt/jdk/jre/lib/amd64/libjfx*.so

# Set environment
export JAVA_HOME=/opt/jdk
export PATH=${PATH}:${JAVA_HOME}/bin
java -version

cat <<-'EOF' > ~/.profile

export JAVA_HOME=/opt/jdk
export PATH=${PATH}:${JAVA_HOME}/bin

EOF
chmod u+x  ~/.profile
. ~/.profile

```

The above yields the Alpine environment with JDK 8 installed.

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Install NodeJS

I am installing NodeJS because I want to run NodeJS-based stubs and use the `nodemon` server to run them.

From [StackOverflow article](https://stackoverflow.com/questions/58725215/how-to-install-nodejs-v13-0-1-in-alpine3-8), in WSL Alpine terminal install latest stable version of NodeJS:

``` shell
ALPINE_MIRROR="http://dl-cdn.alpinelinux.org/alpine"
echo "${ALPINE_MIRROR}/edge/main" >> /etc/apk/repositories
apk add --no-cache nodejs  --repository="http://dl-cdn.alpinelinux.org/alpine/edge/community"
node --version

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Add useful NodeJS packages

In Alpine distro's ash shell terminal, as non-root user:

``` shell
HOST_DIR=/mnt/d/swagger_api_dev
cd ${HOST_DIR}
npm i http-server nodemon

```

### Update shell init scripts

In Alpine distro's shell terminal, as non-root user (`wsl.exe -d Alpine`):

``` shell
HOST_DIR=/mnt/d/swagger_api_dev
cd ${HOST_DIR}

cat <<-'EOF' > ~/.profile

export JAVA_HOME=/opt/jdk
export PATH=${PATH}:${JAVA_HOME}/bin

ENV=$HOME/.shinit; export ENV 

EOF
chmod u+x  ~/.profile
. ~/.profile

cat <<-EOF > ~/.ashinit
alias nodemon='${HOST_DIR}/node_modules/nodemon/bin/nodemon.js'

EOF
chmod u+x  ~/.ashinit
. ~/.ashinit

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Backup Alpine Distro as configured so far

In a Windows PowerShell window :

``` command
cd d:\swagger_api_dev
$TS="20200809_1207"
# note that -export will kill any running Apline terminal windows, presumably by shutting down the distro
wsl.exe --export Alpine Alpine_export_${TS}.tar
zip Alpine_export_${TS}.tar.zip Alpine_export_${TS}.tar
del Alpine_export_${TS}.tar

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

## Add Swagger Codegen to the Environment

### "Install" Swagger Codegen

Create distribution directory hierarchy and "install" Swagger Codegen JAR.

___In Alpine shell window___ (wsl.exe -d Alpine from PowerShell): 

``` shell
HOST_DIR=/mnt/d/swagger_api_dev
cd ${HOST_DIR}/bin
wget https://repo1.maven.org/maven2/io/swagger/codegen/v3/swagger-codegen-cli/3.0.20/swagger-codegen-cli-3.0.20.jar -O ${HOST_DIR}/bin/swagger-codegen-cli.jar 

java -jar ${HOST_DIR}/bin/swagger-codegen-cli.jar version

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Create the example openapi.yaml API Specification (OpenAPI 3.0.1)

We need an example openapi specifications in yaml to enable initial testing.

Let's create an example, in Alpine shell window as non-root user:

```shell
HOST_DIR=/mnt/d/swagger_api_dev

cat <<-'EOF' > ${HOST_DIR}/api/openapi.yaml
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

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Create generate_nodejs_stubs_server.sh Script

Create a script that will generate nodejs server stubs, using Alpine shell terminal, as non-root user.


``` shell
HOST_DIR=/mnt/d/swagger_api_dev

cat <<-EOF > ${HOST_DIR}/scripts/generate_nodejs_stubs_server.sh
#!/bin/ash

cd ${HOST_DIR}/stubs_nodejs

# generate stubs
#
java -jar ${HOST_DIR}/bin/swagger-codegen-cli.jar generate -i ${HOST_DIR}/api/openapi.yaml -l nodejs-server -o ${HOST_DIR}/stubs_nodejs
sed -i 's|8080|3003|' ${HOST_DIR}/stubs_nodejs/index.js

grep 'Access-Control-Allow-Origin' ${HOST_DIR}/stubs_nodejs/index.js | {
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
' ${HOST_DIR}/stubs_nodejs/index.js
}

[[ -d ${HOST_DIR}/stubs_nodejs/node_modules ]] || npm install

EOF

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Create run_nodejs_stubs_server.sh Script

Create a server start script, to be executed from the docker-entrypoint.sh in the container on container start and restart.

In Alpine shell window, as non-root user:


``` shell
HOST_DIR=/mnt/d/swagger_api_dev

cat <<-EOF > ${HOST_DIR}/scripts/run_nodejs_stubs_server.sh
#!/bin/ash

# run the generate and start stubs server logic if conditions are met
#
cd ${HOST_DIR}/stubs_nodejs
[[ -f ${HOST_DIR}/api/.no_autostart ]] && exit

# generate stubs
#
export JAVA_HOME=/opt/jdk
export PATH=\${PATH}:\${JAVA_HOME}/bin

[[ ! -f ${HOST_DIR}/api/.no_autogenerate ]] && ${HOST_DIR}/scripts/generate_nodejs_stubs_server.sh

[[ ! -f ${HOST_DIR}/stubs_nodejs/index.js ]] && { echo "Stubs are not available - can't start server" && exit; }
[[ ! -d ${HOST_DIR}/stubs_nodejs/node_modules ]] && { echo "Stubs were not installed - can't start server" && exit; }

# pass the api config to the ui for serving
#
cp -v ${HOST_DIR}/api/* ${HOST_DIR}/stubs_nodejs/node_modules/oas3-tools/dist/middleware/swagger-ui || true

# run the watcher service
alias nodemon='${HOST_DIR}/node_modules/nodemon/bin/nodemon.js'
nodemon -L -w ${HOST_DIR}/api/* -x "${HOST_DIR}/scripts/generate_nodejs_stubs_server.sh && node ${HOST_DIR}/stubs_nodejs/index.js"

EOF
chmod u+x ${HOST_DIR}/scripts/run_nodejs_stubs_server.sh

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Create swagger-codegen yaml to json and back convert example

Create an example of converting YAML to JSON and back using swagger-codegen. Not needed for working with the Swagger Codegen server in the container.

In Alpine shell window, as non-root user:

``` shell
HOST_DIR=/mnt/d/swagger_api_dev

cat <<-EOF > ${HOST_DIR}/scripts/swagger-codegen_convert_example.sh
#!/bin/ash

# convert yaml to jason and back again example
# not needed for work with the Swagger Codegen server
#
cd ${HOST_DIR}

java -jar ${HOST_DIR}/bin/swagger-codegen-cli.jar generate -i ${HOST_DIR}/api/openapi.yaml -l openapi -o ${HOST_DIR}/api

java -jar ${HOST_DIR}/bin/swagger-codegen-cli.jar generate -i ${HOST_DIR}/api/openapi.json -l openapi-yaml -o ${HOST_DIR}/api/converted

EOF
chmod u+x ${HOST_DIR}/scripts/swagger-codegen_convert_example.sh

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

## Bonus Material - Windows 10 Shortcuts

Create them using PowerShell.

### Start Stub server

``` powershell
cd d:\swagger_api_dev
mkdir scripts -ErrorAction 'ignore'

$NORMAL_WINDOW=0
$MAXIMIZED=3
$MINIMIZED=7

$pIconLocation="C:\Windows\System32\wsl.exe"
$pShortcutPath="d:\swagger_api_dev\_run Stub Server on 3003.LNK"
$TargetPath="C:\Windows\System32\wsl.exe"
$WorkingDirectory="%~dp0"
$pWindowStyle=${NORMAL_WINDOW}
$pArguments=" -d Alpine --exec /mnt/d/swagger_api_dev/scripts/run_nodejs_stubs_server.sh"

$s=(New-Object -COM WScript.Shell).CreateShortcut($pShortcutPath)
$s.TargetPath=$TargetPath;
$s.WorkingDirectory=${WorkingDirectory};
$s.WindowStyle=${pWindowStyle};
$s.IconLocation=${pIconLocation};
$s.Arguments=${pArguments};
$s.Save()

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Run Swagger Editor in Chrome

``` powershell
cd d:\swagger_api_dev

$NORMAL_WINDOW=0
$MAXIMIZED=3
$MINIMIZED=7

$pIconLocation="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
$pShortcutPath="d:\swagger_api_dev\_Swagger Codegen Stub Docs on 3003.LNK"
$TargetPath="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
$WorkingDirectory="%~dp0"
$pWindowStyle=${NORMAL_WINDOW}
$pArguments="-new-window  http://localhost:3003/docs"

$s=(New-Object -COM WScript.Shell).CreateShortcut($pShortcutPath)
$s.TargetPath="${TargetPath}";
$s.WorkingDirectory="${WorkingDirectory}";
$s.WindowStyle=${pWindowStyle};
$s.IconLocation="${pIconLocation}";
$s.Arguments="${pArguments}";
$s.Save()

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Run VS Code

``` powershell
cd d:\swagger_api_dev

$NORMAL_WINDOW=0
$MAXIMIZED=3
$MINIMIZED=7

$pIconLocation="C:\Program Files\Microsoft VS Code\Code.exe"
$pShortcutPath="d:\swagger_api_dev\_VS Code Here.LNK"
$TargetPath="C:\Program Files\Microsoft VS Code\Code.exe"
$WorkingDirectory="%~dp0"
$pWindowStyle=${NORMAL_WINDOW}
$pArguments="."

$s=(New-Object -COM WScript.Shell).CreateShortcut($pShortcutPath)
$s.TargetPath="${TargetPath}";
$s.WorkingDirectory="${WorkingDirectory}";
$s.WindowStyle=${pWindowStyle};
$s.IconLocation="${pIconLocation}";
$s.Arguments="${pArguments}";
$s.Save()

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Run PowerShell Here

``` powershell
cd d:\swagger_api_dev
$NORMAL_WINDOW=0
$MAXIMIZED=3
$MINIMIZED=7

$pIconLocation="C:\Program Files\PowerShell\7\pwsh.exe"
$pShortcutPath="d:\swagger_api_dev\_powershell Here.LNK"
$TargetPath="C:\Program Files\PowerShell\7\pwsh.exe"
$WorkingDirectory="%~dp0"
$pWindowStyle=${NORMAL_WINDOW}
$pArguments=""

$s=(New-Object -COM WScript.Shell).CreateShortcut($pShortcutPath)
$s.TargetPath="${TargetPath}";
$s.WorkingDirectory="${WorkingDirectory}";
$s.WindowStyle=${pWindowStyle};
$s.IconLocation="${pIconLocation}";
$s.Arguments="${pArguments}";
$s.Save()

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

### Run Alpine ash shell here

``` powershell
cd d:\swagger_api_dev
$NORMAL_WINDOW=0
$MAXIMIZED=3
$MINIMIZED=7

$pIconLocation="C:\Windows\System32\wsl.exe"
$pShortcutPath="d:\swagger_api_dev\_Alpine Shell Here.LNK"
$TargetPath="C:\Windows\System32\wsl.exe"
$WorkingDirectory="%~dp0"
$pWindowStyle=${NORMAL_WINDOW}
$pArguments=" -d Alpine"

$s=(New-Object -COM WScript.Shell).CreateShortcut($pShortcutPath)
$s.TargetPath="${TargetPath}";
$s.WorkingDirectory="${WorkingDirectory}";
$s.WindowStyle=${pWindowStyle};
$s.IconLocation="${pIconLocation}";
$s.Arguments="${pArguments}";
$s.Save()

```

[[Top](#Swagger-Codegen-in-WSL-Alpine)]



## Licensing

The MIT License (MIT)

Copyright &copy; 2020 Michael Czapski

[[Top](#Swagger-Codegen-in-WSL-Alpine)]

2020/08 MCz
