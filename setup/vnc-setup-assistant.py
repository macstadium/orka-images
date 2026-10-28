#!/usr/bin/env python3
"""
Automates macOS Setup Assistant on a fresh IPSW VM via VNC.

Sends the keystroke sequence to navigate Setup Assistant before SSH is
available. Call this immediately after the VM boots from a fresh IPSW restore,
then wait for SSH to come up before running subsequent setup scripts.

Usage:
  python3 vnc-setup-assistant.py --host <IP> --port <PORT> [--password <PWD>] --macos <tahoe|sequoia|sonoma>

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
    def __init__(self, host, port, password=None):
        self.client = vncapi.connect(host, password=password, port=port)

    def close(self):
        self.client.disconnect()

    def wait(self, seconds):
        time.sleep(seconds)

    def key(self, name):
        self.client.keyPress(name)

    def type(self, text):
        self.client.type(text)

    def shift_tab(self):
        self.client.keyDown('shift_l')
        self.client.keyPress('Tab')
        self.client.keyUp('shift_l')

    def alt_key(self, key):
        self.client.keyDown('alt_l')
        self.client.keyPress(key)
        self.client.keyUp('alt_l')

    def ctrl_key(self, key):
        self.client.keyDown('ctrl_l')
        self.client.keyPress(key)
        self.client.keyUp('ctrl_l')

    def spotlight(self, query, wait_after=10):
        self.alt_key('space')
        self.wait(wait_after)
        self.type(query)

    def tabs(self, n):
        for _ in range(n):
            self.client.keyPress('Tab')


def setup_tahoe(vnc):
    # hello, hola, bonjour — dismiss the greeting
    vnc.wait(60)
    vnc.key('space')

    # Language: switch to Italiano then back to English to land on "English (US)"
    vnc.wait(30)
    vnc.type('italiano')
    vnc.key('Escape')
    vnc.type('english')
    vnc.key('Return')

    # Select Your Country or Region
    # The search field may not be auto-focused on Tahoe; type directly and rely
    # on the field gaining focus. If this step fails in testing, add a Tab first.
    vnc.wait(60)
    vnc.type('united states')
    vnc.shift_tab()
    vnc.key('space')

    # Transfer Your Data to This Mac — skip (Not Now + Continue)
    vnc.wait(10)
    vnc.tabs(3)
    vnc.key('space')
    vnc.tabs(2)
    vnc.key('space')

    # Written and Spoken Languages — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Accessibility — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Data & Privacy — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Create a Mac Account
    vnc.wait(10)
    vnc.tabs(6)
    vnc.type('Managed via Orka')
    vnc.key('Tab')
    vnc.type('admin')
    vnc.key('Tab')
    vnc.type('admin')
    vnc.key('Tab')
    vnc.type('admin')
    vnc.tabs(2)
    vnc.key('space')
    vnc.tabs(2)
    vnc.key('space')

    # Enable VoiceOver (required for keyboard navigation of remaining screens)
    vnc.wait(120)
    vnc.alt_key('f5')

    # Sign In with Your Apple ID — skip
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')
    vnc.key('Up')
    vnc.key('space')

    # Are you sure you want to skip Apple ID?
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Terms and Conditions — agree
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # I have read and agree
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Age Range — Adult (new in macOS 26)
    vnc.wait(10)
    vnc.tabs(3)
    vnc.key('space')

    # Enable Location Services — skip
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Are you sure you don't want Location Services?
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Select Your Time Zone
    vnc.wait(10)
    vnc.tabs(3)
    vnc.type('Atlanta')
    vnc.key('Return')
    vnc.shift_tab()
    vnc.key('space')

    # Analytics — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Screen Time — skip
    vnc.wait(10)
    vnc.tabs(2)
    vnc.key('space')

    # Siri — disable, then continue
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')
    vnc.shift_tab()
    vnc.key('space')

    # Your Mac is Ready for FileVault — don't encrypt
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('Tab')
    vnc.key('space')

    # Mac Data Will Not Be Securely Encrypted — confirm
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Choose Your Look — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Update Mac Automatically — skip
    vnc.wait(10)
    vnc.tabs(2)
    vnc.key('space')

    # Welcome to Mac
    vnc.wait(30)
    vnc.key('space')

    # Disable VoiceOver
    vnc.wait(10)
    vnc.alt_key('f5')

    # Enable keyboard navigation (required for System Settings navigation)
    vnc.wait(10)
    vnc.alt_key('space')
    vnc.type('Terminal')
    vnc.wait(10)
    vnc.key('Return')
    vnc.wait(10)
    vnc.type('defaults write NSGlobalDomain AppleKeyboardUIMode -int 3')
    vnc.key('Return')

    # Open System Settings (Spotlight unreliable on Tahoe, use open directly)
    vnc.wait(10)
    vnc.type("open '/System/Applications/System Settings.app'")
    vnc.key('Return')
    vnc.wait(120)

    # Navigate to Sharing
    vnc.wait(10)
    vnc.ctrl_key('f2')
    vnc.key('Right')
    vnc.key('Right')
    vnc.key('Right')
    vnc.key('Down')
    vnc.type('Sharing')
    vnc.key('Return')

    # Enable Screen Sharing
    vnc.wait(10)
    vnc.tabs(5)
    vnc.key('space')
    vnc.wait(10)
    vnc.type('admin')
    vnc.key('Return')

    # Enable Remote Login
    vnc.wait(10)
    vnc.tabs(12)
    vnc.key('space')

    # Quit System Settings
    vnc.wait(10)
    vnc.alt_key('q')

    # Disable Gatekeeper
    vnc.wait(10)
    vnc.type('sudo spctl --global-disable')
    vnc.key('Return')
    vnc.wait(10)
    vnc.type('admin')
    vnc.key('Return')


def setup_sequoia(vnc):
    # hello, hola, bonjour
    vnc.wait(60)
    vnc.key('space')

    # Language
    vnc.wait(30)
    vnc.type('italiano')
    vnc.key('Escape')
    vnc.type('english')
    vnc.key('Return')

    # Select Your Country or Region
    vnc.wait(30)
    vnc.type('united states')
    vnc.shift_tab()
    vnc.key('space')

    # Transfer Your Data to This Mac — skip
    vnc.wait(10)
    vnc.tabs(3)
    vnc.key('space')
    vnc.tabs(2)
    vnc.key('space')

    # Written and Spoken Languages — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Accessibility — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Data & Privacy — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Create a Mac Account
    vnc.wait(10)
    vnc.type('Managed via Orka')
    vnc.key('Tab')
    vnc.type('admin')
    vnc.key('Tab')
    vnc.type('admin')
    vnc.key('Tab')
    vnc.type('admin')
    vnc.tabs(2)
    vnc.key('space')
    vnc.tabs(2)
    vnc.key('space')

    # Enable VoiceOver
    vnc.wait(120)
    vnc.alt_key('f5')

    # Sign In with Your Apple ID — skip
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Are you sure?
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Terms and Conditions
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # I have read and agree
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Enable Location Services — skip
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Are you sure?
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Select Your Time Zone
    vnc.wait(10)
    vnc.tabs(2)
    vnc.type('Atlanta')
    vnc.key('Return')
    vnc.shift_tab()
    vnc.tabs(2)
    vnc.key('space')

    # Analytics — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Screen Time — skip
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Siri — disable, then continue
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')
    vnc.shift_tab()
    vnc.key('space')

    # Choose Your Look — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Set Up FileVault — don't encrypt
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('Tab')
    vnc.key('space')

    # Mac Data Will Not Be Securely Encrypted — confirm
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Update Mac Automatically — skip
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Welcome to Mac
    vnc.wait(10)
    vnc.key('space')

    # Disable VoiceOver
    vnc.alt_key('f5')

    # Enable keyboard navigation
    vnc.wait(10)
    vnc.alt_key('space')
    vnc.type('Terminal')
    vnc.key('Return')
    vnc.wait(10)
    vnc.type('defaults write NSGlobalDomain AppleKeyboardUIMode -int 3')
    vnc.key('Return')
    vnc.wait(10)
    vnc.alt_key('q')

    # Open System Settings
    vnc.wait(10)
    vnc.alt_key('space')
    vnc.type('System Settings')
    vnc.key('Return')

    # Navigate to Sharing
    vnc.wait(10)
    vnc.ctrl_key('f2')
    vnc.key('Right')
    vnc.key('Right')
    vnc.key('Right')
    vnc.key('Down')
    vnc.type('Sharing')
    vnc.key('Return')

    # Enable Screen Sharing
    vnc.wait(10)
    vnc.tabs(7)
    vnc.key('space')

    # Enable Remote Login
    vnc.wait(10)
    vnc.tabs(12)
    vnc.key('space')

    # Quit System Settings
    vnc.wait(10)
    vnc.alt_key('q')

    # Disable Gatekeeper
    vnc.wait(10)
    vnc.alt_key('space')
    vnc.type('Terminal')
    vnc.key('Return')
    vnc.wait(10)
    vnc.type('sudo spctl --global-disable')
    vnc.key('Return')
    vnc.wait(10)
    vnc.type('admin')
    vnc.key('Return')
    vnc.wait(10)
    vnc.alt_key('q')


def setup_sonoma(vnc):
    # hello, hola, bonjour
    vnc.wait(60)
    vnc.key('space')

    # Language
    vnc.wait(30)
    vnc.type('italiano')
    vnc.key('Escape')
    vnc.type('english')
    vnc.key('Return')

    # Select Your Country and Region
    vnc.wait(30)
    vnc.type('united states')
    vnc.shift_tab()
    vnc.key('space')

    # Written and Spoken Languages — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Accessibility — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Data & Privacy — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Migration Assistant — skip
    vnc.wait(10)
    vnc.tabs(3)
    vnc.key('space')

    # Sign In with Your Apple ID — skip
    vnc.wait(10)
    vnc.shift_tab()
    vnc.shift_tab()
    vnc.key('space')

    # Are you sure?
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Terms and Conditions
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # I have read and agree
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Create a Computer Account
    vnc.wait(10)
    vnc.type('admin')
    vnc.tabs(2)
    vnc.type('admin')
    vnc.key('Tab')
    vnc.type('admin')
    vnc.tabs(3)
    vnc.key('space')

    # Enable Location Services — skip
    vnc.wait(30)
    vnc.shift_tab()
    vnc.key('space')

    # Are you sure?
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Select Your Time Zone
    vnc.wait(10)
    vnc.key('Tab')
    vnc.type('Atlanta')
    vnc.key('Return')
    vnc.shift_tab()
    vnc.key('space')

    # Analytics — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Screen Time — skip
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Siri — disable, then continue
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')
    vnc.shift_tab()
    vnc.key('space')

    # Choose Your Look — continue
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('space')

    # Set Up FileVault — don't encrypt
    vnc.wait(10)
    vnc.shift_tab()
    vnc.key('Tab')
    vnc.key('space')

    # Mac Data Will Not Be Securely Encrypted — confirm
    vnc.wait(10)
    vnc.key('Tab')
    vnc.key('space')

    # Enable VoiceOver
    vnc.wait(10)
    vnc.alt_key('f5')
    vnc.wait(5)
    vnc.key('v')

    # Open System Settings
    vnc.wait(10)
    vnc.alt_key('space')
    vnc.type('System Settings')
    vnc.key('Return')

    # Navigate to Sharing via search
    vnc.wait(10)
    vnc.alt_key('f')
    vnc.type('sharing')
    vnc.key('Return')

    # Enable Screen Sharing
    vnc.wait(10)
    vnc.tabs(4)
    vnc.key('space')

    # Enable Remote Login
    vnc.wait(10)
    vnc.tabs(12)
    vnc.key('space')

    # Disable VoiceOver
    vnc.alt_key('f5')


SEQUENCES = {
    'tahoe': setup_tahoe,
    'sequoia': setup_sequoia,
    'sonoma': setup_sonoma,
}


def main():
    parser = argparse.ArgumentParser(description='Automate macOS Setup Assistant via VNC')
    parser.add_argument('--host', required=True, help='VNC server IP address')
    parser.add_argument('--port', type=int, default=5900, help='VNC port (default: 5900)')
    parser.add_argument('--password', default=None, help='VNC password (if set)')
    parser.add_argument('--macos', required=True, choices=SEQUENCES.keys(),
                        help='macOS version to configure')
    args = parser.parse_args()

    print(f'Connecting to VNC at {args.host}:{args.port}...')
    vnc = VNCSession(args.host, args.port, args.password)

    try:
        print(f'Running Setup Assistant sequence for {args.macos}...')
        SEQUENCES[args.macos](vnc)
        print('Setup Assistant sequence complete. Wait for SSH to come up before continuing.')
    finally:
        vnc.close()


if __name__ == '__main__':
    main()
