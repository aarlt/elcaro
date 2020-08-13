#!/usr/bin/env python3

import argparse
import logging.handlers
import os
import signal
import time


class Terminator:
    terminated = False

    def __init__(self):
        signal.signal(signal.SIGINT, self.exit_gracefully)
        signal.signal(signal.SIGTERM, self.exit_gracefully)

    def exit_gracefully(self, signum, frame):
        self.terminated = True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='elcaro oracle executor')
    parser.add_argument('--log', help='path to executor logfile', default='/data/executor/executor.log')
    parser.add_argument('--request', help='path to executor request directory',
                        default='/data/executor/request')
    parser.add_argument('--response', help='path to executor response directory',
                        default='/data/executor/response')
    config = parser.parse_args()
    handler = logging.handlers.WatchedFileHandler(config.log)
    formatter = logging.Formatter(logging.BASIC_FORMAT)
    handler.setFormatter(formatter)
    root = logging.getLogger()
    root.setLevel(os.environ.get('LOGLEVEL', 'INFO'))
    root.addHandler(handler)

    terminator = Terminator()
    i = 0
    while not terminator.terminated:
        time.sleep(1)
        logging.info('doing something in a loop ... ' + str(i))
        i = i + 1

    logging.info('End of the program. I was killed gracefully :)')
