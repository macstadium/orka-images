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

disable_remote_management() {
    log "Disabling Remote Management (if enabled)..."
    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
        -deactivate -stop || warn "Remote Management was not active"
}

enable_screen_sharing() {
    log "Enabling Screen Sharing..."

    sudo dseditgroup -o create com.apple.access_screensharing 2>/dev/null || true
    sudo dseditgroup -o edit -a "$CURRENT_USER" -t user com.apple.access_screensharing

    sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false 2>/dev/null || true
    
    sudo defaults write /Library/Preferences/com.apple.screensharing AllowAccessFor -int 0
    
    sudo launchctl unload /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist

    log "Screen Sharing enabled and configured"
}

ensure_autologin() {
    log "Configuring auto-login for GUI session..."

    sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "$CURRENT_USER"
    
    sudo defaults write /Library/Preferences/com.apple.loginwindow DisableReauthForLogin -bool true
    
    sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool false
    
    sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    
    warn "Note: Auto-login requires one of the following:"
    warn "  - User account has no password, OR"
    warn "  - FileVault is disabled, OR"
    warn "  - kcpassword is configured with the user's password"
    
    log "Auto-login configured for user: $CURRENT_USER"
}

configure_vnc_password() {
    log "Checking VNC password configuration..."
    
    if sudo defaults read /Library/Preferences/com.apple.VNCSettings Password 2>/dev/null; then
        log "VNC password already configured"
    else
        warn "No VNC password set. Screen Sharing will require user authentication."
        warn "To set a VNC password, use: System Preferences > Sharing > Screen Sharing > Computer Settings"
    fi
}

enable_remote_login() {
    log "Enabling Remote Login (SSH)..."
    sudo systemsetup -setremotelogin on 2>/dev/null || {
        sudo launchctl enable system/com.openssh.sshd 2>/dev/null || true
        sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
    }
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

cleanup_system() {
    log "Performing minimal system cleanup..."
    
    rm -rf /tmp/* 2>/dev/null || true
    
    history -c 2>/dev/null || true
    
    log "System cleanup completed"
}

verify_configuration() {
    log "Verifying configuration..."
    
    if sudo launchctl list | grep -q com.apple.screensharing; then
        log "✓ Screen Sharing service is loaded"
    else
        warn "✗ Screen Sharing service is not loaded"
    fi
    
    if sudo launchctl list | grep -q com.openssh.sshd; then
        log "✓ SSH service is loaded"
    else
        warn "✗ SSH service is not loaded"
    fi

    local autologin_user
    autologin_user=$(sudo defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || echo "not set")
    if [[ "$autologin_user" == "$CURRENT_USER" ]]; then
        log "✓ Auto-login configured for $CURRENT_USER"
    else
        warn "✗ Auto-login not properly configured (currently: $autologin_user)"
    fi
}

display_post_setup_info() {
    log "=== Post-Setup Information ==="
    echo ""
    log "Screen Sharing will be available after the system reboots and auto-login completes."
    echo ""
    warn "IMPORTANT: Screen Sharing requires an active GUI session to start."
    echo ""
    log "Troubleshooting steps if Screen Sharing doesn't work after reboot:"
    echo ""
    echo "  1. Check if GUI session is active:"
    echo "     who"
    echo "     ps aux | grep loginwindow"
    echo ""
    echo "  2. Check Screen Sharing service status:"
    echo "     sudo launchctl print system/com.apple.screensharing"
    echo ""
    echo "  3. Try manually loading Screen Sharing after GUI login:"
    echo "     sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist"
    echo ""
    echo "  4. If auto-login fails:"
    echo "     - Verify FileVault is disabled: sudo fdesetup status"
    echo "     - Check if user has a password set"
    echo "     - Manually log in once via console, then test again"
    echo ""
}

schedule_reboot() {
    log "System will reboot in 30 seconds to apply all changes..."
    log "Press Ctrl+C to cancel the reboot if needed"
    
    sleep 30
    
    sudo shutdown -r now "Rebooting to apply VM changes" 2>/dev/null || sudo reboot
}

main() {
    log "=== MacOS Orka VM Setup Started ==="
    echo ""
    
    disable_remote_management
    
    ensure_autologin
    
    enable_screen_sharing
    enable_remote_login
    
    configure_vnc_password
    
    install_orka_vm_tools
    setup_sys_daemon

    cleanup_system
    
    echo ""
    verify_configuration
    
    echo ""
    log "=== Setup completed successfully ==="
    
    display_post_setup_info
    
    schedule_reboot
}

trap 'error "Script interrupted by user"' INT TERM

main