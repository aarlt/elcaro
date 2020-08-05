from web3 import Web3
from passlib.hash import argon2
import getpass
import hashlib
from threading import Thread
import time

import urwid
import urwid.raw_display


def handle_event(event):
    # print(event)
    # and whatever
    return


def log_loop(web3, event_filter, poll_interval):
    while True:
        print(web3.eth.blockNumber)
        for event in event_filter.get_new_entries():
            handle_event(event)
        time.sleep(poll_interval)


if __name__ == '__main__':
    w3 = Web3(Web3.WebsocketProvider('ws://127.0.0.1:8545'))
    if not w3.isConnected():
        print("not connected.")
        exit(1)

    block_filter = w3.eth.filter('latest')
    worker = Thread(target=log_loop, args=(w3, block_filter, 5), daemon=True)
    worker.start()

    username = input('Username: ')
    password = getpass.getpass()
    m = hashlib.sha256()
    m.update(argon2.using(salt='elcaro-oracle'.encode("utf-8")).hash(username + password).encode('utf-8'))
    account = w3.eth.account.from_key(m.digest())
    print("Node Account: ", account.address)
