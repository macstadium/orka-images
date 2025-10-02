# Orka VM Setup Script Usage

## This script automates the configuration and setup of macOS Orka VMs for optimal performance. It configures system settings, installs required tools, and prepares the VM for use with Orka

### System requirements

- macOS IPSW file (Tahoe, Sequoia, or Sonoma)
- Admin/sudo privileges on the VM
- Internet connection for downloading packages
- Terminal access (via SSH, Screen Sharing, or direct console)

### Before running

- Ensure you have administrator access to the VM
- Close any important applications (they will be terminated during cleanup)
- Save any work in progress (the VM will reboot automatically)

### Installation

#### Download via GitHub

- `bash /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/macstadium/orka-images/setup/setup.sh)"`

### Installation steps when running the script

#### On MacOS Sequoia

- When prompted for Terminal permissions access, click 'Accept'
- Terminal will need full disk access to run the script. Configure this by going to your System Settings -> Privacy and Security -> Full Disk Access and adding 'Terminal' by clicking the + button and searching for the app in the search bar.
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
"net.inet.tcp.tso=0";
);
```

#### On MacOS Tahoe

Same as above, though users may experience a delay during the system cleanup and restart step. If the system does not reboot within 60 seconds, reboot manually.

#### On MacOS Sonoma

Approve Terminal 'System Events' access and 'Finder' access request when prompted during the system cleanup and restart step.

### What the script does

#### System Configuration

- Enables Screen Sharing with VNC password
- Enables Remote Login (SSH) with full disk access
- Sets macOS updates to Download Only (prevents automatic updates)

#### Tool installation

- Downloads and installs the current version of Orka VM Tools, default is v3.5.0
- Downloads and runs Orka `sys-daemon.sh` setup script (this is used to optimize the Screen Share and VNC performance of the VM)
- Automatically cleans up installation files

#### System cleanup

- Closes all non-essential applications
- Empties trash and cleans temporary files
- Removes Downloads folder contents
- Clears cache files
- Erases terminal history

#### Final steps

- Automatically reboots the VM to flush all changes

### Important notes

- Change default passwords in production environments
- Restrict network access as needed for your security policy
- Ensure enabled services match your requirements
