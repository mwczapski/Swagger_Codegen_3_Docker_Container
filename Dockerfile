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
  sed -i '/set -e/a [[ $( ps -C run_codegen_ser -o stat --no-headers ) == "S" ]] || nohup /swagger_tools/run_nodejs_stubs_server.sh </dev/null 2>/dev/null 1>/dev/null &' /usr/local/bin/docker-entrypoint.sh

