#/bin/bash
VERSION="1.0.10"
docker build -t engiecofely/docx_to_png:v$VERSION .
docker push engiecofely/docx_to_png:v$VERSION
echo -en "\007"