#!/bin/sh

/usr/bin/ipfs init

/usr/bin/ipfs daemon --migrate=true > /dev/null &
IPFS=$!

/usr/bin/geth --ws --wsport 8545 --verbosity 0 > /dev/null &
GETH=$!

python3 /elcaro/main.py

kill ${IPFS}
kill ${GETH}

while [ -e /proc/${IPFS} ]; do sleep 1; done
while [ -e /proc/${GETH} ]; do sleep 1; done

echo
