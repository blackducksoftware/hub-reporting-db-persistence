#!/bin/bash
#

export SPRING_APPLICATION_JSON='{"blackduck.hub.url":"https://localhost","blackduck.hub.api.token":"MjYyMGIxNmItNjUyNS00NGUzLTg1MWMtOTVhNTc3ZmJkOThmOjFhNmZjYmYxLTNmYWUtNDVkMS04ODZiLTNmNWEyNmQ1OTQyMA=="}'
bash <(curl -s https://detect.synopsys.com/detect.sh) \
     --blackduck.hub.trust.cert=true \
     --detect.docker.image=$1
