# Orka VM Setup Script Usage
## This script automates the configuration and setup of macOS Orka VMs for optimal performance. It configures system settings, installs required tools, and prepares the VM for use with Orka.

### System Requirements:

- macOS IPSW file (Tahoe, Sequoia, or Sonoma)
- Admin/sudo privileges on the VM
- Internet connection for downloading packages
- Terminal access (via SSH, Screen Sharing, or direct console)

### Before Running:

- Ensure you have administrator access to the VM
- Close any important applications (they will be terminated during cleanup)
- Save any work in progress (the VM will reboot automatically)

### Installation:

#### Method 1: Direct Copy & Paste (Recommended)

Connect to your VM via SSH, Screen Sharing, or console
Open the Terminal application

Create the script file:

```bash   nano orka-ipsw-setup-tahoe.sh```

Copy the [entire script] and paste into nano
Save and exit: ```Ctrl+X → Y → Enter```
Make executable:

```bash   chmod +x orka-ipsw-setup-tahoe.sh```

Run the script:

```bash   ./orka-ipsw-setup-tahoe.sh```

#### Method 2: Download via GitHub

- ```bashcurl -fsSL https://github.com/macstadium/orka-images/orka-ipsw-setup-tahoe.sh -o orka-ipsw-setup-tahoe.sh```
- ```chmod +x orka-ipsw-setup-tahoe.sh```
- ```./orka-ipsw-setup-tahoe.sh```

#### Method 3: Transfer via SCP

From your local machine:

- ```bash scp orka-ipsw-setup-tahoe.sh user@vm-ip:/Users/user/```
- ```ssh user@vm-ip```
- ```chmod +x orka-ipsw-setup-tahoe.sh```
- ```./orka-ipsw-setup-tahoe.sh```

### What the Script Does:

#### System Configuration

- Enables Screen Sharing with VNC password "admin"
- Enables Remote Login (SSH) with full disk access
- Creates/configures admin user (username: admin, password: admin)
- Disables FileVault (checks status and warns if enabled)
- Sets macOS updates to Download Only (prevents automatic updates)

#### Tool Installation

- Downloads and installs Orka VM Tools v3.5.0
- Downloads and runs Orka sys-daemon setup script (this is used to optimize the Screen Share and VNC performance of the VM)
- Automatically cleans up installation files

#### System Cleanup

- Closes all non-essential applications
- Empties trash and cleans temporary files
- Removes Downloads folder contents
- Clears cache files
- Erases terminal history

#### Final Steps

- Automatically reboots the VM to flush all changes

### Important notes:

- Change default passwords in production environments
- Restrict network access as needed for your security policy
- Ensure enabled services match your requirements

[entire script]: https://github.com/macstadium/orka-images/orka-ipsw-setup-tahoe.sh
