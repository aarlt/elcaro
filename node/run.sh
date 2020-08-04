#!/bin/bash

NODE_ROOT=$(cd $(dirname "$0}") && pwd)
cd ${NODE_ROOT}

mkdir -p ${NODE_ROOT}/data

if [ ! -f ${NODE_ROOT}/Dockerfile.sha256 ] ; then
    docker build -t elcaro:local .
else 
    sha256sum -c Dockerfile.sha256 > /dev/null
    if [ ! $? -eq 0 ]; then
       docker build -t elcaro:local .
    fi
fi
sha256sum ${NODE_ROOT}/Dockerfile > Dockerfile.sha256

docker run --rm -it -v ${NODE_ROOT}/data:/data elcaro:local $@
