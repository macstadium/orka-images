#!/usr/bin/env bash
# verify.sh — post-install image verification
# Usage: bash verify.sh <expected_disk_gb> <expected_vm_tools_version>
# Exits non-zero if any check fails.

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1" >&2; }

# When VM_DEFAULT_PASSWORD is set (non-interactive SSH), pipe it to sudo -S.
sudo_run() {
    if [[ -n "${VM_DEFAULT_PASSWORD:-}" ]]; then
        echo "$VM_DEFAULT_PASSWORD" | sudo -S "$@"
    else
        sudo "$@"
    fi
}

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <expected_disk_gb> <expected_vm_tools_version>" >&2
    exit 1
fi

EXPECTED_DISK_GB="$1"
EXPECTED_VERSION="$2"

errors=0

# --- orka-vm-tools version ---
if [[ ! -x /Applications/orka-vm-tools/orka-vm-tools ]]; then
    fail "orka-vm-tools binary not found at /Applications/orka-vm-tools/orka-vm-tools"
    errors=$((errors + 1))
else
    installed_version=$(/Applications/orka-vm-tools/orka-vm-tools version 2>&1 \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
    if [[ "$installed_version" != "$EXPECTED_VERSION" ]]; then
        fail "orka-vm-tools version mismatch: installed ${installed_version}, expected ${EXPECTED_VERSION}"
        errors=$((errors + 1))
    else
        pass "orka-vm-tools ${installed_version}"
    fi
fi

# --- Disk size within ±20% of expected ---
disk_gb=$(df -g / | awk 'NR==2 {print $2}')
lower=$(( EXPECTED_DISK_GB * 80 / 100 ))
upper=$(( EXPECTED_DISK_GB * 120 / 100 ))
if [[ "$disk_gb" -lt "$lower" || "$disk_gb" -gt "$upper" ]]; then
    fail "Disk size ${disk_gb} GB is outside ±20% of expected ${EXPECTED_DISK_GB} GB (${lower}–${upper} GB)"
    errors=$((errors + 1))
else
    pass "Disk size ${disk_gb} GB (expected ~${EXPECTED_DISK_GB} GB)"
fi

# --- No Homebrew ---
# Check both PATH and known install locations (Intel: /usr/local, Apple Silicon: /opt/homebrew)
if which brew &>/dev/null || [[ -x /usr/local/bin/brew ]] || [[ -x /opt/homebrew/bin/brew ]]; then
    fail "Homebrew found — base images must not include Homebrew"
    errors=$((errors + 1))
else
    pass "No Homebrew"
fi

# --- sysctl daemon running ---
if sudo_run launchctl list | grep -q sysctl; then
    pass "sysctl daemon running"
else
    fail "sysctl daemon not running"
    errors=$((errors + 1))
fi

# --- SSH running ---
if sudo_run launchctl list | grep -q com.openssh.sshd; then
    pass "SSH running"
else
    fail "SSH (com.openssh.sshd) not running"
    errors=$((errors + 1))
fi

# --- Screen Sharing running ---
if sudo_run launchctl list | grep -q com.apple.screensharing; then
    pass "Screen Sharing running"
else
    fail "Screen Sharing (com.apple.screensharing) not running"
    errors=$((errors + 1))
fi

# --- Result ---
echo ""
if [[ "$errors" -gt 0 ]]; then
    echo -e "${RED}${errors} check(s) failed${NC}" >&2
    exit 1
fi

echo -e "${GREEN}All checks passed${NC}"
