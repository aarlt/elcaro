import urwid
import threading
import time
from web3 import Web3
from passlib.hash import argon2
import getpass
import hashlib
import argparse
import json

elcaro_logo = u'         .__\n' \
              '    ____ |  |   ____ _____ _______  ____\n' \
              '  _/ __ \\|   _/ ___\\\\__  \\\\_   __ \\/  _ \\ \n' \
              '  \\  ___/|  |_\\  \\___ / __ \\|  | \\(  <_> )\n' \
              '   \\___  >____/\\___  >____  /__|   \\____/\n' \
              '       \\/          \\/     \\/'

elcaro_logo_centered = u'                          .__\n' \
                       '                     ____ |  |   ____ _____ _______  ____\n' \
                       '                   _/ __ \\|   _/ ___\\\\__  \\\\_   __ \\/  _ \\ \n' \
                       '                   \\  ___/|  |_\\  \\___ / __ \\|  | \\(  <_> )\n' \
                       '                    \\___  >____/\\___  >____  /__|   \\____/\n' \
                       '                        \\/          \\/     \\/'


class ViewTerminal(urwid.Terminal):
    _selectable = False


class SidePanel(urwid.WidgetWrap):
    def __init__(self, w3, config, elcaro):
        self.w3 = w3
        self.contract_json = None
        with open(config.elcaro_json, 'r') as json_file:
            self.contract_json = json.load(json_file)
        self.elcaro = elcaro
        self.account = elcaro.account
        self.contract = w3.eth.contract(address=config.contract, abi=self.contract_json["abi"])
        self.logo = urwid.Text(elcaro_logo)
        self.network_chain_id = urwid.Text("?", align=urwid.CENTER)
        self.network_peers = urwid.Text("?", align=urwid.CENTER)
        self.network_block = urwid.Text("?", align=urwid.CENTER)
        self.active_nodes = urwid.Text("?", align=urwid.CENTER)
        self.contract_address = urwid.Text(config.contract, align=urwid.CENTER)
        self.contract_requests = urwid.Text("?", align=urwid.CENTER)
        self.contract_responses = urwid.Text("?", align=urwid.CENTER)
        self.node_address = urwid.Text(self.account.address, align=urwid.CENTER)
        self.node_requests = urwid.Text("?", align=urwid.CENTER)
        self.node_responses = urwid.Text("?", align=urwid.CENTER)
        self.node_balance = urwid.Text("?", align=urwid.CENTER)
        self.register_unregister_button = urwid.Button("Register Node", self.register_unregister)
        # self.register_unregister_button = urwid.AttrWrap(self.register_unregister_button, 'button normal')
        self.exit_button = urwid.Button("Shutdown Node", self.elcaro.ask_quit)
        # self.exit_button = urwid.AttrWrap(self.exit_button, 'button normal')
        self.pile = urwid.Pile([
            self.logo,
            self.elcaro.status,
            urwid.Columns([('fixed', 5, urwid.Text("")), self.elcaro.progress_bar, ('fixed', 5, urwid.Text(""))]),
            urwid.Text(""),
            urwid.Columns(
                [
                    urwid.Pile([urwid.Text(('title', u"Chain ID"), align=urwid.CENTER),
                                self.network_chain_id]),
                    urwid.Pile([urwid.Text(('title', u"Peers"), align=urwid.CENTER),
                                self.network_peers]),
                    urwid.Pile([urwid.Text(('title', u"Block"), align=urwid.CENTER),
                                self.network_block]),
                ]),
            urwid.Text(""),
            urwid.Text(('title', u"Contract"), align=urwid.CENTER),
            self.contract_address,
            urwid.Columns(
                [
                    urwid.Pile([urwid.Text(('title', u"Active Nodes"), align=urwid.CENTER),
                                self.active_nodes]),
                    urwid.Pile([urwid.Text(('title', u"Requests"), align=urwid.CENTER),
                                self.contract_requests]),
                    urwid.Pile([urwid.Text(('title', u"Responses"), align=urwid.CENTER),
                                self.contract_responses]),
                ]),
            urwid.Text(""),
            urwid.Text(('title', u"Node"), align=urwid.CENTER),
            self.node_address,
            urwid.Columns(
                [
                    urwid.Pile([urwid.Text(('title', u"Balance"), align=urwid.CENTER),
                                self.node_balance]),
                    urwid.Pile([urwid.Text(('title', u"Requests"), align=urwid.CENTER),
                                self.node_requests]),
                    urwid.Pile([urwid.Text(('title', u"Responses"), align=urwid.CENTER),
                                self.node_requests]),
                ]),
            urwid.Text(""),
            self.register_unregister_button,
            urwid.Text(""),
            self.exit_button
        ], focus_item=14)
        fill = urwid.LineBox(urwid.Filler(self.pile, valign=urwid.TOP))
        fill = urwid.AttrWrap(fill, 'body')
        self.__super.__init__(urwid.AttrWrap(fill, 'chars'))

    def refresh(self):
        self.network_peers.set_text(str(self.w3.net.peer_count))
        self.network_chain_id.set_text(str(self.w3.eth.chainId))
        if self.w3.eth.syncing or self.w3.net.peer_count == 0:
            self.network_block.set_text("?")
            self.node_balance.set_text("?")
        else:
            try:
                self.network_block.set_text("#" + str(self.w3.eth.blockNumber))
                self.node_balance.set_text(
                    str(self.w3.fromWei(self.w3.eth.getBalance(self.account.address), "ether")) + "Ξ")
            except:
                self.network_block.set_text("?")
                self.node_balance.set_text("?")

    def register_unregister(self, button):
        nonce = self.w3.eth.getTransactionCount(self.account.address)
        transaction = self.contract.functions.register().buildTransaction({
            'chainId': self.w3.eth.chainId,
            'gas': 70000,
            'gasPrice': w3.toWei('1', 'gwei'),
            'nonce': nonce,
        })
        signed = self.w3.eth.account.sign_transaction(transaction, self.account.key)
        # transaction_hash = signed.hash
        self.w3.eth.sendRawTransaction(signed.rawTransaction)


class Display:
    palette = [
        ('body', 'black', 'light gray', 'standout'),
        ('header', 'white', 'dark red', 'bold'),
        ('footer', 'black', 'light gray', 'standout'),
        ('button normal', 'light gray', 'dark blue', 'standout'),
        ('button select', 'white', 'dark green'),
        ('button disabled', 'dark gray', 'dark blue'),
        ('edit', 'light gray', 'dark blue'),
        ('bigtext', 'white', 'black'),
        ('chars', 'light gray', 'black'),
        ('exit', 'black', 'light gray', 'standout'),
        (None, 'light gray', 'black'),
        ('heading', 'black', 'light gray'),
        ('line', 'black', 'light gray'),
        ('options', 'dark gray', 'black'),
        ('focus heading', 'white', 'dark red'),
        ('focus line', 'black', 'dark red'),
        ('focus options', 'black', 'light gray'),
        ('selected', 'white', 'dark blue'),
        ('title', 'black,bold', 'light gray'),
        ('pb-en', 'black', 'light gray', ''),
        ('pb-dis', 'white', 'dark gray', ''),
    ]

    def __init__(self, config, w3, account):
        urwid.set_encoding('utf8')
        self.w3 = w3
        self.account = account
        self.status = urwid.Text(('title', u" [ SYNCING ]"), align=urwid.CENTER)
        self.progress_bar = urwid.ProgressBar('pb-en', 'pb-dis', 0, 100)
        self.geth_log = ViewTerminal(['tail', '-f', config.geth_log], encoding='utf-8')
        self.side_panel = SidePanel(self.w3, config, self)
        self.screen = urwid.Columns(
            [('fixed', 46, self.side_panel), ('weight', 2, urwid.LineBox(self.geth_log, title="geth"))])
        self.screen = urwid.AttrWrap(self.screen, 'body')
        self.screen = urwid.Frame(body=self.screen)
        self.background = urwid.Frame(body=urwid.Pile([]))
        self.background = urwid.AttrWrap(self.background, 'exit')
        fonts = urwid.get_all_fonts()
        for name, fontcls in fonts:
            font = fontcls()
            if fontcls == urwid.HalfBlock5x4Font:
                self.exit_font = font
        self.exit_overlay = urwid.BigText(('exit', " Shutdown? (y/n)"), self.exit_font)
        self.exit_overlay = urwid.Overlay(self.exit_overlay, self.background, 'center', None, 'middle', None)
        self.refresh_thread = None
        self.update_display = True
        self.running = True
        self.done = False
        self.loop = urwid.MainLoop(self.screen, self.palette,
                                   unhandled_input=self.unhandled_input)

    def __del__(self):
        print("")
        self.refresh_thread.join()

    def ask_quit(self, button):
        self.update_display = False
        self.loop.widget = self.exit_overlay

    def refresh(self):
        while self.running:
            if self.w3.eth.syncing or self.w3.net.peer_count == 0:
                self.status.set_text("SYNCING...")
                if self.w3.eth.syncing:
                    self.progress_bar.current = float(self.w3.eth.syncing.currentBlock) / float(
                        self.w3.eth.syncing.highestBlock) * 100.0
            else:
                self.progress_bar.current = 100
                self.status.set_text("")

            if self.update_display:
                self.side_panel.refresh()

            self.loop.draw_screen()

            time.sleep(1)

        self.done = True

    def main(self):
        self.refresh_thread = threading.Thread(target=self.refresh)
        self.refresh_thread.start()
        self.loop.run()
        self.done = False
        self.running = False

    def unhandled_input(self, key):
        if key == 'f8':
            self.ask_quit('q')
            return True
        if self.loop.widget != self.exit_overlay:
            return
        if key in ('y', 'Y'):
            raise urwid.ExitMainLoop()
        if key in ('n', 'N'):
            self.loop.widget = self.screen
            self.update_display = True
            return True


if '__main__' == __name__:
    parser = argparse.ArgumentParser(description='elcaro oracle node.')
    parser.add_argument('--contract', help='contract address to an elcaro contract',
                        default="0x0000000000000000000000000000000000000000")
    parser.add_argument('--geth-log', help='path to geth logfile', default="/data/geth/geth.log")
    parser.add_argument('--ipfs-log', help='path to ipfs logfile')
    parser.add_argument('--elcaro-json', help='path elcaro standard-json compiler artefact',
                        default="/elcaro/contracts/Elcaro.json")

    print("\n"
          + elcaro_logo_centered +
          "\n\n"
          "     ATTENTION  The private key of the node will be derived from\n"
          "                the username and the password you enter. That means,\n"
          "                if you use a weak username-password pair others may\n"
          "                be able to access the node account.\n"
          "\n"
          " !! THIS IS HIGHLY EXPERIMENTAL SOFTWARE AND TO BE USED AT YOUR OWN RISK !!\n")

    username = input(' - Login: ')
    password = getpass.getpass(' - Password:')
    m = hashlib.sha256()
    m.update(argon2.using(salt='elcaro-oracle'.encode("utf-8")).hash(username + password).encode('utf-8'))

    w3 = Web3(Web3.WebsocketProvider('ws://127.0.0.1:8545'))
    if not w3.isConnected():
        print("error: could not connect to geth node @ ws://127.0.0.1:8545. aborting.")
        exit(1)

    account = w3.eth.account.from_key(m.digest())

    Display(parser.parse_args(), w3, account).main()
