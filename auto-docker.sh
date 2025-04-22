#/bin/bash
VERSION="1.0.11"
docker build -t engiecofely/files_converter:v$VERSION .
docker push engiecofely/files_converter:v$VERSION
echo -en "\007"