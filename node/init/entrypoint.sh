#!/bin/sh

mkdir -p ${NODE_ROOT}/data/ipfs
mkdir -p ${NODE_ROOT}/data/geth

if [ ! -f  /data/ipfs/datastore_spec ]; then
    /usr/bin/ipfs init > /dev/null
fi

/usr/bin/geth --datadir /data/geth --ws --wsport 8545 --goerli --syncmode light > /data/geth/geth.log 2>&1 &
GETH=$!

/usr/bin/ipfs daemon --migrate=true > /data/ipfs/ipfs.log 2>&1 &
IPFS=$!

su-exec elcaro python3 /elcaro/main.py $@

kill ${IPFS}
kill ${GETH}

while [ -e /proc/${IPFS} ]; do sleep 1; done
while [ -e /proc/${GETH} ]; do sleep 1; done
