#!/usr/bin/env python3
"""
Disables SIP in macOS Recovery via VNC.

Boot the VM with --recovery and --vnc-port, then run this script to open
Terminal from the Recovery Utilities menu, run csrutil disable, and reboot.

Usage:
  python3 vnc-disable-sip.py --host 127.0.0.1 --port 5901 --password <admin_password>

Requirements:
  pip install vncdotool
"""

import argparse
import sys
import time

try:
    import vncdotool.api as vncapi
except ImportError:
    print("vncdotool is required: pip install vncdotool", file=sys.stderr)
    sys.exit(1)


class VNCSession:
    def __init__(self, host, port):
        self.client = vncapi.connect(host, port=port)

    def close(self):
        self.client.disconnect()

    def wait(self, seconds):
        time.sleep(seconds)

    def key(self, name):
        self.client.keyPress(name)

    def type(self, text):
        self.client.type(text)

    def ctrl_f2(self):
        # Ctrl+F2 focuses the Apple menu on macOS (accessibility keyboard shortcut)
        self.client.keyDown('ctrl_l')
        self.client.keyPress('F2')
        self.client.keyUp('ctrl_l')


def disable_sip(vnc, password):
    print("Waiting for Recovery UI to load...")
    vnc.wait(90)

    # Focus Apple menu via Ctrl+F2, then navigate right to Utilities
    # Menu order: [Apple] [File] [Edit] [Utilities] [Window] [Help]
    print("Opening Utilities > Terminal...")
    vnc.ctrl_f2()
    vnc.wait(1)

    for _ in range(3):
        vnc.key('Right')
        vnc.wait(0.3)

    vnc.key('Return')
    vnc.wait(1)

    # Jump to Terminal by pressing 't' in the open menu
    vnc.key('t')
    vnc.wait(0.5)
    vnc.key('Return')

    print("Waiting for Terminal to open...")
    vnc.wait(5)

    print("Disabling SIP...")
    vnc.type('csrutil disable')
    vnc.key('Return')
    vnc.wait(3)

    # csrutil disable prompts for admin username and password in Recovery
    vnc.type('admin')
    vnc.key('Return')
    vnc.wait(2)

    vnc.type(password)
    vnc.key('Return')
    vnc.wait(5)

    print("Rebooting...")
    vnc.type('reboot')
    vnc.key('Return')


def main():
    parser = argparse.ArgumentParser(description='Disable SIP in macOS Recovery via VNC')
    parser.add_argument('--host', required=True, help='VNC server host')
    parser.add_argument('--port', type=int, default=5901, help='VNC port (default: 5901)')
    parser.add_argument('--password', required=True, help='Admin password for csrutil authentication')
    args = parser.parse_args()

    print(f'Connecting to VNC at {args.host}:{args.port}...')
    vnc = VNCSession(args.host, args.port)

    try:
        disable_sip(vnc, args.password)
        print('SIP disable sequence complete. Waiting for VM to reboot...')
    finally:
        vnc.close()


if __name__ == '__main__':
    main()
