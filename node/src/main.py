from web3 import Web3
from passlib.hash import argon2
import getpass
import hashlib

if __name__ == '__main__':
    w3 = Web3(Web3.WebsocketProvider('ws://127.0.0.1:8545'))
    if not w3.isConnected():
        print("not connected.")
        exit(1)

    username = input('Username: ')
    password = getpass.getpass()
    m = hashlib.sha256()
    m.update(argon2.using(salt='elcaro-oracle'.encode("utf-8")).hash(username + password).encode('utf-8'))
    account = w3.eth.account.from_key(m.digest())
    print("Node Account: ", account.address)
