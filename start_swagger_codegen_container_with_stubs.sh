
docker.exe run     --name swagger_codegen     --hostname swagger_codegen      -v d:/github_materials/swagger_codegen/api:/api -v d:/github_materials/swagger_codegen/stubs_nodejs:/stubs_nodejs       -p 127.0.0.1:3003:3003/tcp      --detach     --interactive     --tty    --rm         mwczapski/swagger_codegen:1.0.0

