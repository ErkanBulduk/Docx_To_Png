#/bin/bash
VERSION="1.1.0"
docker build -t ghcr.io/belux-bms/files_converter:v$VERSION .
docker push ghcr.io/belux-bms/files_converter:v$VERSION
echo -en "\007"