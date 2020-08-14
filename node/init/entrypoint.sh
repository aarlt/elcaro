#!/bin/sh

mkdir -p ${NODE_ROOT}/data/ipfs
mkdir -p ${NODE_ROOT}/data/geth
mkdir -p ${NODE_ROOT}/data/executor/request
mkdir -p ${NODE_ROOT}/data/executor/response

touch /data/ipfs/ipfs.log /data/geth/geth.log /data/executor/executor.log
chmod 660 /data/geth/geth.log /data/executor/executor.log /data/executor/executor.log
chown -R executor:users ${NODE_ROOT}/data/executor
chmod 770 -R ${NODE_ROOT}/data/executor/request ${NODE_ROOT}/data/executor/response
chown -R elcaro:users ${NODE_ROOT}/data/ipfs ${NODE_ROOT}/data/geth

if [ ! -f  /data/ipfs/datastore_spec ]; then
    /usr/bin/ipfs init > /dev/null
fi

/usr/bin/ipfs daemon --migrate=true > /data/ipfs/ipfs.log 2>&1 &
IPFS=$!

/usr/bin/geth --datadir /data/geth --ws --wsport 8545 --goerli --syncmode light > /data/geth/geth.log 2>&1 &
GETH=$!

sleep 5

su-exec executor python3 /elcaro/executor.py &
EXECUTOR=$!

su-exec elcaro python3 /elcaro/main.py $@

kill ${IPFS}
kill ${GETH}
kill ${EXECUTOR}

while [ -e /proc/${IPFS} ]; do sleep 1; done
while [ -e /proc/${GETH} ]; do sleep 1; done
while [ -e /proc/${EXECUTOR} ]; do sleep 1; done
