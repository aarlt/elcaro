#!/bin/sh

mkdir -p ${NODE_ROOT}/data/ipfs
mkdir -p ${NODE_ROOT}/data/geth
mkdir -p ${NODE_ROOT}/data/executor/request
mkdir -p ${NODE_ROOT}/data/executor/response

chmod +x -R ${NODE_ROOT}/data
# chown -R executor:users ${NODE_ROOT}/data/executor

if [ ! -f  /data/ipfs/datastore_spec ]; then
    /usr/bin/ipfs init > /dev/null
fi

/usr/bin/ipfs daemon --migrate=true > /data/ipfs/ipfs.log 2>&1 &
IPFS=$!

/usr/bin/geth --datadir /data/geth --ws --wsport 8545 --goerli --syncmode light > /data/geth/geth.log 2>&1 &
GETH=$!

sleep 3

su-exec executor python3 /elcaro/executor.py &
EXECUTOR=$!

sleep 1

chmod 777 -R ${NODE_ROOT}/data

su-exec elcaro python3 /elcaro/main.py $@

kill ${IPFS}
kill ${GETH}
kill ${EXECUTOR}

while [ -e /proc/${IPFS} ]; do sleep 1; done
while [ -e /proc/${GETH} ]; do sleep 1; done
while [ -e /proc/${EXECUTOR} ]; do sleep 1; done
