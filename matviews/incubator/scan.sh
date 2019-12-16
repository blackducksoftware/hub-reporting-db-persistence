#!/bin/bash
#

PROJECT=$1
VERSION=$2

if [ "$PROJECT" = "" ] 
then
  PROJECT=$(pwd)
fi

if [ "$VERSION" = "" ]
then
  VERSION=LATEST
fi


export SPRING_APPLICATION_JSON='{"blackduck.url":"https://localhost","blackduck.api.token":"MjYyMGIxNmItNjUyNS00NGUzLTg1MWMtOTVhNTc3ZmJkOThmOjFhNmZjYmYxLTNmYWUtNDVkMS04ODZiLTNmNWEyNmQ1OTQyMA=="}'
bash <(curl -s https://detect.synopsys.com/detect.sh) \
     --blackduck.trust.cert=true \
     --detect.project.name=${PROJECT} \
     --detect.project.version.name=${VERSION} \
     --detect.code.location.name=${PROJECT}_${VERSION}_code \
     --detect.bom.aggregate.name=${PROJECT}_${VERSION}_PKG 
