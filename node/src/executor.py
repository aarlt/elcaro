#!/usr/bin/env python3

import logging.handlers
import os
import signal
import time

handler = logging.handlers.WatchedFileHandler(
    os.environ.get("LOGFILE", "/data/executor/executor.log"))
formatter = logging.Formatter(logging.BASIC_FORMAT)
handler.setFormatter(formatter)
root = logging.getLogger()
root.setLevel(os.environ.get("LOGLEVEL", "INFO"))
root.addHandler(handler)


class Terminator:
    terminated = False

    def __init__(self):
        signal.signal(signal.SIGINT, self.exit_gracefully)
        signal.signal(signal.SIGTERM, self.exit_gracefully)

    def exit_gracefully(self, signum, frame):
        self.terminated = True


if __name__ == '__main__':
    terminator = Terminator()
    while not terminator.terminated:
        time.sleep(1)
        logging.info("doing something in a loop ...")

    logging.info("End of the program. I was killed gracefully :)")
