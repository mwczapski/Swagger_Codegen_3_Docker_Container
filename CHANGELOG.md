<!--lint disable prohibited-strings-->
<!--lint disable maximum-line-length-->
<!--lint disable no-literal-urls-->
<!--lint disable no-trailing-spaces-->

# Swagger Codegen 3.0 Docker Image

## 2020-07-11

### 2020-07-18

Modified `docker-entrypoint.sh` to allow nohup to create and update the `/nohup.out` file so that a user can watch  the codegen and stub server restart with

`docker exec -it -w='/api' swagger_codegen tail -f /nohup.out`
