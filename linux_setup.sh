#!/bin/bash
#
# Dink Smallwood HD - Linux Build & Setup Script
#
# This script will:
#   1. Clone RTDink (if not already in the repo)
#   2. Install required dependencies (auto-detects package manager)
#   3. Clone the Proton SDK
#   4. Build RTDink (binary goes to bin/ where game assets already live)
#
# Supported distros: Debian/Ubuntu, Fedora/RHEL, Arch/Manjaro, openSUSE, Alpine
#
# One-liner install:
#   curl -sL https://raw.githubusercontent.com/SethRobinson/RTDink/master/linux_setup.sh | bash
#
# Or from within the repo:
#   ./linux_setup.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------------------------------------------------------------------------
# Detect package manager
# ---------------------------------------------------------------------------
detect_pkg_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MANAGER="zypper"
    elif command -v apk >/dev/null 2>&1; then
        PKG_MANAGER="apk"
    else
        PKG_MANAGER=""
    fi
}

# Install packages using the detected package manager
pkg_install() {
    case "$PKG_MANAGER" in
        apt)
            sudo apt-get update
            sudo apt-get install -y "$@"
            ;;
        dnf)
            sudo dnf install -y "$@"
            ;;
        yum)
            sudo yum install -y "$@"
            ;;
        pacman)
            sudo pacman -S --needed --noconfirm "$@"
            ;;
        zypper)
            sudo zypper install -y "$@"
            ;;
        apk)
            sudo apk add "$@"
            ;;
        *)
            error "No supported package manager found (tried apt, dnf, yum, pacman, zypper, apk)."
            error "Please install the following packages manually:"
            error "  C/C++ compiler, cmake, OpenGL dev libs, X11 dev libs, libpng, zlib, bzip2,"
            error "  libcurl, SDL2, SDL2_mixer"
            exit 1
            ;;
    esac
}

get_build_packages() {
    case "$PKG_MANAGER" in
        apt)
            echo "build-essential cmake libgl1-mesa-dev libx11-dev libpng-dev zlib1g-dev libbz2-dev libcurl4-openssl-dev libsdl2-dev libsdl2-mixer-dev"
            ;;
        dnf|yum)
            echo "gcc gcc-c++ make cmake mesa-libGL-devel libX11-devel libpng-devel zlib-devel bzip2-devel libcurl-devel SDL2-devel SDL2_mixer-devel"
            ;;
        pacman)
            echo "base-devel cmake mesa libx11 libpng zlib bzip2 curl sdl2 sdl2_mixer"
            ;;
        zypper)
            echo "gcc gcc-c++ make cmake Mesa-libGL-devel libX11-devel libpng16-devel zlib-devel libbz2-devel libcurl-devel libSDL2-devel libSDL2_mixer-devel"
            ;;
        apk)
            echo "build-base cmake mesa-dev libx11-dev libpng-dev zlib-dev bzip2-dev curl-dev sdl2-dev sdl2_mixer-dev"
            ;;
    esac
}

get_git_package() {
    echo "git"
}

detect_pkg_manager

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
INSTALL_DIR="$HOME/RTDink"
for arg in "$@"; do
    case $arg in
        --dir=*) INSTALL_DIR="${arg#*=}" ;;
        --help|-h)
            echo "Usage: $0 [--dir=PATH]"
            echo "  --dir=PATH   Install directory (default: ~/RTDink)"
            echo ""
            echo "One-liner install:"
            echo "  curl -sL https://raw.githubusercontent.com/SethRobinson/RTDink/master/linux_setup.sh | bash"
            exit 0
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Bootstrap: if we're not inside the RTDink repo, clone it and re-run
# ---------------------------------------------------------------------------
BOOTSTRAPPED=false
if [ ! -f "CMakeLists.txt" ] || [ ! -d "source" ]; then
    BOOTSTRAPPED=true
    info "RTDink repo not detected in current directory."

    # Make sure git is available
    if ! command -v git >/dev/null 2>&1; then
        info "Installing git..."
        pkg_install $(get_git_package)
    fi

    if [ -d "$INSTALL_DIR/.git" ]; then
        info "RTDink already cloned at $INSTALL_DIR, pulling latest..."
        cd "$INSTALL_DIR"
        git pull || warn "git pull failed (local changes or network issue?), continuing with existing files..."
    elif [ -d "$INSTALL_DIR" ] && [ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]; then
        if [ -f "$INSTALL_DIR/CMakeLists.txt" ] && [ -d "$INSTALL_DIR/source" ]; then
            warn "Directory $INSTALL_DIR contains RTDink files but no .git directory."
            warn "Proceeding with existing files (no git pull possible)..."
            cd "$INSTALL_DIR"
        else
            error "Directory $INSTALL_DIR already exists and is not empty,"
            error "but does not appear to be an RTDink checkout."
            error "Please remove it or choose a different directory with --dir=PATH"
            exit 1
        fi
    else
        info "Cloning RTDink into $INSTALL_DIR ..."
        git clone https://github.com/SethRobinson/RTDink.git "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi
fi

# Determine the repo root directory
if [ "$BOOTSTRAPPED" = true ]; then
    SCRIPT_DIR="$(pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
cd "$SCRIPT_DIR"

# Offer to pull latest RTDink changes when running from inside an existing checkout
if [ -d ".git" ]; then
    if [ -t 0 ]; then
        echo -en "${GREEN}[INFO]${NC} Git repo detected. Pull latest RTDink changes before building? [y/N] "
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            git pull || warn "git pull failed (local changes or network issue?), continuing with existing files..."
        else
            info "Skipping git pull, building with existing files."
        fi
    else
        info "Non-interactive mode — skipping git pull for local checkout."
    fi
fi

BIN_DIR="$SCRIPT_DIR/bin"

# ---------------------------------------------------------------------------
# Step 1: Install dependencies
# ---------------------------------------------------------------------------
info "Step 1: Checking dependencies..."
info "Detected package manager: $PKG_MANAGER"

BUILD_PACKAGES=$(get_build_packages)

if [ -z "$BUILD_PACKAGES" ]; then
    error "Could not determine packages for your system."
    error "Please install build dependencies manually (C/C++ toolchain, cmake, SDL2, SDL2_mixer, OpenGL, X11, libpng, zlib, bzip2, libcurl)."
    exit 1
fi

info "Installing build dependencies..."
pkg_install $BUILD_PACKAGES

# ---------------------------------------------------------------------------
# Step 2: Clone Proton SDK
# ---------------------------------------------------------------------------
info "Step 2: Setting up Proton SDK..."

if [ -d "proton/.git" ]; then
    info "Proton SDK already cloned, pulling latest..."
    (cd proton && git pull) || warn "Proton git pull failed (local changes or network issue?), continuing with existing files..."
else
    info "Cloning Proton SDK..."
    git clone https://github.com/SethRobinson/proton.git
fi

# ---------------------------------------------------------------------------
# Step 3: Build (binary goes directly to bin/)
# ---------------------------------------------------------------------------
info "Step 3: Building RTDink..."

mkdir -p build
cd build
cmake ..
make -j$(nproc)
cd ..

info "Build complete!"

# ---------------------------------------------------------------------------
# Verify and report
# ---------------------------------------------------------------------------
echo ""
if [ -f "$BIN_DIR/RTDinkApp" ] && [ -d "$BIN_DIR/dink" ] && [ -f "$BIN_DIR/dink/dink.dat" ]; then
    info "Setup complete! To play, run the game like this:"
    echo ""
    echo "    cd $BIN_DIR && ./RTDinkApp"
    echo ""
else
    if [ ! -f "$BIN_DIR/RTDinkApp" ]; then
        error "Build failed — RTDinkApp binary not found in $BIN_DIR/"
    fi
    if [ ! -d "$BIN_DIR/dink" ] || [ ! -f "$BIN_DIR/dink/dink.dat" ]; then
        error "Game data not found in $BIN_DIR/dink/"
        error "This shouldn't happen — the game data is included in the repo."
    fi
fi
