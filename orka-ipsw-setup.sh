#!/bin/bash

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root. Please run as a regular user with sudo privileges."
fi

# Check if sudo is available
if ! command -v sudo &> /dev/null; then
    error "sudo is required but not available"
fi

log "Starting MacOS Orka VM setup..."

# Enable Screen Sharing
enable_screen_sharing() {
    log "Enabling Screen Sharing..."
    
    # Enable Screen Sharing via System Preferences
    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
        -activate -configure -access -on -clientopts -setvnclegacy -vnclegacy yes \
        -clientopts -setvncpw -vncpw admin -restart -agent -privs -all
    
    # Alternative method using launchctl
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
    
    log "Screen Sharing enabled"
}

# Enable Remote Login (SSH)
enable_remote_login() {
    log "Enabling Remote Login (SSH)..."
    
    # Create admin user if one doesn't already exist
    if ! dscl . -read /Users/admin &>/dev/null; then
        log "Creating admin user..."
        sudo dscl . -create /Users/admin
        sudo dscl . -create /Users/admin UserShell /bin/bash
        sudo dscl . -create /Users/admin RealName "Administrator"
        sudo dscl . -create /Users/admin UniqueID 501
        sudo dscl . -create /Users/admin PrimaryGroupID 80
        sudo dscl . -create /Users/admin NFSHomeDirectory /Users/admin
        
        # Set password to "admin"
        sudo dscl . -passwd /Users/admin admin
        
        # Add to admin group
        sudo dscl . -append /Groups/admin GroupMembership admin
        sudo dscl . -append /Groups/wheel GroupMembership admin
        
        # Create home directory
        sudo createhomedir -c -u admin
        
        log "Admin user created with password 'admin'"
    else
        log "Admin user already exists, updating password..."
        sudo dscl . -passwd /Users/admin admin
        log "Admin user password set to 'admin'"
    fi
    
    # Enable SSH
    sudo systemsetup -setremotelogin on
    
    # Enable full disk access for remote users
    sudo dseditgroup -o edit -a everyone -t group com.apple.access_ssh
    
    # Ensure admin user can SSH
    sudo dseditgroup -o edit -a admin -t user com.apple.access_ssh
    
    # Start SSH service
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
    
    log "Remote Login enabled with full disk access for admin user"
}

# Configure macOS updates (Set to download-only for Tahoe)
configure_macos_updates() {
    log "Configuring macOS updates for Download Only..."
    
    # Set automatic update check to true, but disable automatic installation
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled -bool true
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload -bool true
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticallyInstallMacOSUpdates -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist ConfigDataInstall -bool false
    
    # Disable automatic installation of app updates from App Store
    sudo defaults write /Library/Preferences/com.apple.commerce.plist AutoUpdate -bool false
    sudo defaults write /Library/Preferences/com.apple.commerce.plist AutoUpdateRestartRequired -bool false
    
    log "macOS updates configured for Download Only mode"
}

# Disable FileVault (When running on Tahoe)
disable_filevault() {
    log "Ensuring FileVault is disabled..."
    
    # Check if FileVault is enabled
    local filevault_status=$(sudo fdesetup status | head -1)
    
    if [[ "$filevault_status" == "FileVault is On." ]]; then
        warn "FileVault is currently enabled. For Tahoe, it should be disabled."
        warn "Please disable FileVault manually through System Preferences > Security & Privacy > FileVault"
        warn "This requires a reboot and cannot be automated safely."
    else
        log "FileVault is already disabled"
    fi
}

# Download and install Orka VM Tools
install_orka_vm_tools() {
    log "Installing Orka VM Tools..."
    
    local pkg_url="https://orka-tools.s3.amazonaws.com/orka-vm-tools/official/3.5.0/orka-vm-tools.pkg"
    local pkg_path="/tmp/orka-vm-tools.pkg"
    local pkg_name="orka-vm-tools.pkg"
    
    # Download the Orka VM Tools package
    log "Downloading Orka VM Tools from $pkg_url..."
    curl -fsSL "$pkg_url" -o "$pkg_path" || error "Failed to download Orka VM Tools package"
    
    # Verify the download was successful
    if [[ ! -f "$pkg_path" ]]; then
        error "Orka VM Tools package not found after download"
    fi
    
    # Install the package
    log "Installing Orka VM Tools package..."
    sudo installer -pkg "$pkg_path" -target / || error "Failed to install Orka VM Tools package"
    
    # Clean up installer
    rm -f "$pkg_path"
    
    log "Orka VM Tools v3.5.0 installed successfully"
}

# Download and run the setup-sys-daemon.sh script
setup_sys_daemon() {
    log "Setting up system daemon..."
    
    local script_url="https://raw.githubusercontent.com/macstadium/packer-plugin-macstadium-orka/main/guest-scripts/setup-sys-daemon.sh"
    local script_path="/tmp/setup-sys-daemon.sh"
    
    # Download the script
    curl -fsSL "$script_url" -o "$script_path" || error "Failed to download setup-sys-daemon.sh"
    
    # Make it executable
    chmod +x "$script_path"
    
    # Run the script
    sudo "$script_path" || error "Failed to run setup-sys-daemon.sh"
    
    # Delete the script
    rm -f "$script_path"
    
    log "System daemon setup completed and script deleted"
}

# Post-install system cleanup
cleanup_system() {
    log "Cleaning up system..."
    
    # Close all applications (except essential system apps)
    osascript -e 'tell application "System Events" to set quitapps to name of every application process whose background only is false'
    osascript -e 'repeat with apps in quitapps
        if apps is not in {"Finder", "loginwindow"} then
            tell application apps to quit
        end if
    end repeat' 2>/dev/null || true
    
    # Empty trash
    osascript -e 'tell application "Finder" to empty trash' 2>/dev/null || true
    
    # Clean home directory
    local home_dir="$HOME"
    
    # Remove files from Downloads folder
    rm -rf "$home_dir/Downloads/"* 2>/dev/null || true
    
    # Clean temporary files
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf "$home_dir/Library/Caches/"* 2>/dev/null || true
    
    log "System cleanup completed"
}

erase_terminal_history() {
    log "Erasing terminal history..."
    
    function erase_history() { 
        local HISTSIZE=0
        unset HISTFILE
        history -c
        history -w
    }
    
    erase_history
    
    rm -f "$HOME/.bash_history" 2>/dev/null || true
    rm -f "$HOME/.zsh_history" 2>/dev/null || true
    
    log "Terminal history erased"
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
    
    # Enable required services
    enable_screen_sharing
    enable_remote_login
    
    # Configure Tahoe-specific settings
    disable_filevault
    configure_macos_updates
    
    # Install Orka VM Tools
    install_orka_vm_tools
    
    # Setup system daemon
    setup_sys_daemon
    
    # Clean up system
    cleanup_system
    
    # Erase terminal history
    erase_terminal_history
    
    log "=== Setup completed successfully ==="
    log "The system will now reboot to ensure all changes are applied"
    
    # Schedule reboot
    schedule_reboot
}

# Handle script interruption
trap 'error "Script interrupted by user"' INT TERM

# Run main function
main "$@"
