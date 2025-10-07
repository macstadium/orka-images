#!/bin/bash

ORKA_VM_TOOLS_VERSION="${ORKA_VM_TOOLS_VERSION:-3.5.0}"
CURRENT_USER="${USER}"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

set -euo pipefail

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root. Please run as a regular user with sudo privileges."
fi

if ! command -v sudo &> /dev/null; then
    error "sudo is required but not available"
fi

log "Starting MacOS Orka VM setup..."

enable_screen_sharing() {
    log "Enabling Screen Sharing..."
    
    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
        -activate -configure -access -on -restart -agent -privs -all
    
    log "Screen Sharing enabled"
}

configure_screen_sharing_access() {
    log "Configuring Screen Sharing access for $CURRENT_USER..."
    
    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
        -configure -users "$CURRENT_USER" -access -on -privs -all
    
    log "Screen Sharing configured"
}


enable_remote_login() {
    log "Enabling Remote Login (SSH)..."
   
    sudo launchctl enable system/com.openssh.sshd
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
    
    log "Remote Login (SSH) enabled"
}

# Download and install Orka VM Tools
install_orka_vm_tools() {
    log "Installing Orka VM Tools version ${ORKA_VM_TOOLS_VERSION}..."
    
    local pkg_url="https://orka-tools.s3.amazonaws.com/orka-vm-tools/official/${ORKA_VM_TOOLS_VERSION}/orka-vm-tools.pkg"
    local pkg_path="/tmp/orka-vm-tools.pkg"
    local pkg_name="orka-vm-tools.pkg"
    
    log "Downloading Orka VM Tools from $pkg_url..."
    curl -fsSL "$pkg_url" -o "$pkg_path" || error "Failed to download Orka VM Tools package"
    
    if [[ ! -f "$pkg_path" ]]; then
        error "Orka VM Tools package not found after download"
    fi
    
    log "Installing Orka VM Tools package..."
    sudo installer -pkg "$pkg_path" -target / || error "Failed to install Orka VM Tools package"
    
    rm -f "$pkg_path"
    
    log "Orka VM Tools ${ORKA_VM_TOOLS_VERSION} installed successfully"
}

# Download and run the setup-sys-daemon.sh script
setup_sys_daemon() {
    log "Setting up system daemon..."
    
    local script_url="https://raw.githubusercontent.com/macstadium/packer-plugin-macstadium-orka/main/guest-scripts/setup-sys-daemon.sh"
    
    curl -fsSL "$script_url" | sudo bash || error "Failed to run setup-sys-daemon.sh"
    
    log "System daemon setup completed"
}

# Post-install system cleanup

cleanup_system() {
    log "Performing minimal system cleanup..."
    
    rm -rf /tmp/* 2>/dev/null || true
    
    log "System cleanup completed"
}

schedule_reboot() {
    log "System will reboot in 30 seconds to flush all changes..."
    log "Press Ctrl+C to cancel the reboot if needed"
    
    sleep 5
    
    sudo shutdown -r +0.5 "Rebooting to flush VM changes" 2>/dev/null || \
    sudo reboot
}

main() {
    log "=== MacOS Orka VM Setup Started ==="
    
    enable_screen_sharing
    enable_remote_login
    
    install_orka_vm_tools
    
    setup_sys_daemon
    
    cleanup_system
    
    log "=== Setup completed successfully ==="
    log "The system will now reboot to ensure all changes are applied"
    
    schedule_reboot
}

trap 'error "Script interrupted by user"' INT TERM

main
