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

get_macos_version() {
    sw_vers -productVersion
}

log "Starting MacOS Orka VM setup..."
log "Detected macOS version: $(get_macos_version)"

if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root. Please run as a regular user with sudo privileges."
fi

if ! command -v sudo &> /dev/null; then
    error "sudo is required but not available"
fi

ensure_autologin() {
    log "Configuring auto-login for GUI session..."

    sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "$CURRENT_USER"
    sudo defaults write /Library/Preferences/com.apple.loginwindow DisableReauthForLogin -bool true
    sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool false
    sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    
    log "Auto-login configured for user: $CURRENT_USER"
}

install_orka_vm_tools() {
    log "Installing Orka VM Tools version ${ORKA_VM_TOOLS_VERSION}..."
    
    local pkg_url="https://orka-tools.s3.amazonaws.com/orka-vm-tools/official/${ORKA_VM_TOOLS_VERSION}/orka-vm-tools.pkg"
    local pkg_path="/tmp/orka-vm-tools.pkg"
    
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

setup_sys_daemon() {
    log "Setting up system daemon..."
    
    local script_url="https://raw.githubusercontent.com/macstadium/packer-plugin-macstadium-orka/main/guest-scripts/setup-sys-daemon.sh"
    
    curl -fsSL "$script_url" | sudo bash || error "Failed to run setup-sys-daemon.sh"
    
    log "System daemon setup completed"
}

cleanup_system() {
    log "Performing minimal system cleanup..."
    
    rm -rf /tmp/* 2>/dev/null || true
    history -c 2>/dev/null || true
    
    log "System cleanup completed"
}

verify_configuration() {
    log "Verifying automated configuration..."

    local autologin_user
    autologin_user=$(sudo defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || echo "not set")
    if [[ "$autologin_user" == "$CURRENT_USER" ]]; then
        log "✓ Auto-login configured for $CURRENT_USER"
    else
        warn "✗ Auto-login not properly configured (currently: $autologin_user)"
    fi
    
    local filevault_status
    filevault_status=$(sudo fdesetup status)
    if echo "$filevault_status" | grep -q "FileVault is Off"; then
        log "✓ FileVault is disabled (auto-login will work)"
    else
        warn "✗ FileVault is enabled (auto-login will NOT work)"
    fi
}

display_manual_steps() {
    log "=== REQUIRED MANUAL CONFIGURATION ==="
    echo ""
    warn "The following must be configured manually via System Settings before committing this VM:"
    echo ""
    
    echo "1. DISABLE FILEVAULT (Required for auto-login):"
    echo "   - Open System Settings > Privacy & Security > FileVault"
    echo "   - Click 'Turn Off...' and follow prompts"
    echo "   - OR run: sudo fdesetup disable"
    echo ""
    
    echo "2. CONFIGURE SHARING SERVICES:"
    echo "   - Open System Settings > General > Sharing"
    echo ""
    echo "   a) Enable Screen Sharing (Required for VNC access):"
    echo "      - Toggle 'Screen Sharing' ON"
    echo "      - Click the 'i' button next to Screen Sharing"
    echo "      - Ensure 'VNC viewers may control screen with password' is checked"
    echo "      - Set a VNC password if desired"
    echo ""
    echo "   b) Enable Remote Login (Required for SSH access):"
    echo "      - Toggle 'Remote Login' ON"
    echo ""
    
    echo "3. GRANT FULL DISK ACCESS TO SSH:"
    echo "   - Open System Settings > Privacy & Security > Full Disk Access"
    echo "   - Click the '+' button"
    echo "   - Press Cmd+Shift+G and enter: /usr/libexec/sshd-keygen-wrapper"
    echo "   - Click 'Open' to add it to the list"
    echo "   - Ensure the checkbox next to 'sshd-keygen-wrapper' is checked"
    echo ""
    
    echo "4. REMOVE USER PASSWORD (Optional, for passwordless auto-login):"
    echo "   - Run: sudo dscl . -passwd /Users/$CURRENT_USER ''"
    echo "   - WARNING: This removes password protection from the account"
    echo ""
}

display_verification_steps() {
    log "=== VERIFICATION STEPS ==="
    echo ""
    log "After completing manual configuration above:"
    echo ""
    echo "1. Reboot the VM"
    echo ""
    echo "2. Verify auto-login works:"
    echo "   who"
    echo "   # Should show: $CURRENT_USER  console  <date>"
    echo ""
    echo "3. Verify Screen Sharing is active:"
    echo "   sudo lsof -i :5900"
    echo "   # Should show a process listening on port 5900"
    echo ""
    echo "4. Verify SSH is working:"
    echo "   # From your laptop: ssh $CURRENT_USER@<vm-ip>"
    echo ""
    echo "5. Test VNC connection:"
    echo "   # From your laptop: open vnc://<vm-ip>"
    echo ""
    echo "6. Once everything works, commit this VM to an Orka image"
    echo ""
}

display_troubleshooting() {
    log "=== TROUBLESHOOTING ==="
    echo ""
    echo "If Screen Sharing doesn't work:"
    echo "  - Check: sudo launchctl print system/com.apple.screensharing | grep state"
    echo "  - May show 'not running' until first connection (this is normal)"
    echo "  - Verify Screen Sharing is enabled in System Settings > Sharing"
    echo ""
    echo "If auto-login doesn't work:"
    echo "  - Check FileVault status: sudo fdesetup status"
    echo "  - Must show 'FileVault is Off'"
    echo "  - Check if user has password set"
    echo ""
    echo "If SSH doesn't work:"
    echo "  - Verify Remote Login is enabled in System Settings > Sharing"
    echo "  - Check: sudo launchctl list | grep sshd"
    echo ""
}

main() {
    log "=== MacOS Orka VM Setup Started ==="
    echo ""
    
    ensure_autologin
    install_orka_vm_tools
    setup_sys_daemon
    cleanup_system
    
    echo ""
    verify_configuration
    
    echo ""
    log "=== Automated Setup Completed ==="
    echo ""
    
    display_manual_steps
    display_verification_steps
    display_troubleshooting
    
    echo ""
    warn "DO NOT REBOOT until you have completed the manual configuration steps above!"
    echo ""
}

trap 'error "Script interrupted by user"' INT TERM

main