#!/bin/sh

if [ ! -f  /data/ipfs/datastore_spec ]; then
    /usr/bin/ipfs init > /dev/null
fi

/usr/bin/ipfs daemon --migrate=true > /dev/null &
IPFS=$!

/usr/bin/geth --datadir /data/geth --ws --wsport 8545 --verbosity 0 --goerli > /dev/null &
GETH=$!

su-exec elcaro python3 /elcaro/main.py $@

kill ${IPFS}
kill ${GETH}

while [ -e /proc/${IPFS} ]; do sleep 1; done
while [ -e /proc/${GETH} ]; do sleep 1; done

echo
