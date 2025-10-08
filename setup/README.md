# Orka VM Setup Script Usage

## This script automates the configuration and setup of macOS Orka VMs for optimal performance. It configures system settings, installs required tools, and prepares the VM for use with Orka

### System requirements

- macOS IPSW file (Tahoe, Sequoia, or Sonoma)
- Admin/sudo privileges on the VM
- Internet connection for downloading packages
- Terminal access (via SSH, Screen Sharing, or direct console)

### Before running the script

- Ensure you have administrator access to the VM
- Close any important applications (they will be terminated during cleanup)
- Toggle 'Screen Sharing' off, then back on via the GUI **System Preferences -> General -> Sharing -> Screen Sharing** so that system settings persist when connecting to a VM via SSH.
- Toggle 'Remote Login' off, then back on via the GUI  **System Preferences -> General -> Sharing -> Remote Login**
- Enable 'Full Disk Access' to SSH via **System Settings > Privacy & Security > Full Disk Access** -> Click the "+" button
Press `Cmd+Shift+G` and enter: `/usr/libexec/sshd-keygen-wrapper` Click "Open" -> Ensure the checkbox is checked
- Save any work in progress
- Close all open applications manually
- Empty the Trash if desired

The script will handle system-level cleanup only

### Installation

#### Download via GitHub

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/macstadium/orka-images/HEAD/setup/setup.sh)"
```

### Installation steps when running the script

#### On MacOS Sequoia

- When prompted for Terminal permissions access, click 'Accept'
- Enter your password when prompted during the script installation process
- When the script shell displays `sh-3.2#` type `exit` and press `Enter` to continue script installation
- Upon system reboot, re-open the Terminal application and enter `sudo launchctl list sysctl` to confirm the Orka sys-daemon script has installed. You should see an output similar to:

```markdown
"LimitLoadToSessionType" = "System";
"Label" = "sysctl";
"OnDemand" = true;
"LastExitStatus" = 0;
"Program" = "/usr/sbin/sysctl";
"ProgramArguments" = (
"/usr/sbin/sysctl";
"-w";
"net.link.generic.system.hwcksum_tx=0";
"net.link.generic.system.hwcksum_rx=0";
"net.inet.tcp.tso=0"; );
```

#### On MacOS Tahoe

Same as above, though users may experience a delay during the system cleanup and restart step. If the system does not reboot within 60 seconds, reboot manually. It is recommended to disable automatic system updates and to disable Filevault to ensure that VM data isn't deleted when automatic updates are applied.

### What the script does

Automatically configures the following:

- Auto-login: Enables automatic GUI login on boot (required for Screen Sharing)
- Orka VM Tools: Downloads and installs the specified version of Orka VM Tools
- System Daemon: Sets up the Orka system daemon
- System Cleanup: Removes temporary files and clears bash history

The following cannot be automated due to macOS security requirements (TCC permissions) and must be configured manually via System Settings:

- FileVault: Must be disabled for auto-login to work
- Screen Sharing: Must be enabled via GUI to initialize TCC database permissions
- Remote Login (SSH): Should be enabled via GUI alongside Screen Sharing
- Full Disk Access: Must be granted for SSH connection via remote login

#### Tool installation

- Downloads and installs the current version of Orka VM Tools, default is v3.5.0
- Downloads and runs Orka `sys-daemon.sh` setup script (this is used to optimize the Screen Share and VNC performance of the VM)
- Automatically cleans up installation files

#### System cleanup

- Cleans temporary files

### Important notes

- Change default passwords in production environments
- Restrict network access as needed for your security policy
- Ensure enabled services match your requirements
- If you need access to certain directories that are protected by Full Disk Access, you will need enable this through System Preferences. Navigate to to **System Preferences -> General -> Sharing -> Remote Login** and toggle "Allow full disk access for remote users" to On.
