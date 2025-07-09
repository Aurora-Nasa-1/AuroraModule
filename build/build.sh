#!/bin/sh
# Aurora Module Build Script - Optimized Version
set -e

# Global variables
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SETTINGS_FILE="$PROJECT_ROOT/module/settings.json"

# Detect environment
detect_env() {
    case "$(uname -s)" in
    Linux*) OS="linux" ;;
    Darwin*) OS="macos" ;;
    MINGW* | MSYS* | CYGWIN*) OS="windows" ;;
    *) OS="unknown" ;;
    esac

    # Check if PowerShell is available in Windows environments
    [ "$OS" = "windows" ] && command -v powershell.exe >/dev/null 2>&1 && HAS_PS=1 || HAS_PS=0
}

# Logging with colors (if supported)
setup_colors() {
    if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
        R='\033[31m' G='\033[32m' Y='\033[33m' B='\033[34m' N='\033[0m'
    else
        R='' G='' Y='' B='' N=''
    fi
}

log() { echo -e "${2:-$B}[$1]$N ${3:-$4}"; }
info() { log "INFO" "$B" "$1"; }
success() { log "OK" "$G" "$1"; }
warn() { log "WARN" "$Y" "$1"; }
error() { log "ERROR" "$R" "$1"; }

# Detect package manager
detect_pkg_mgr() {
    for mgr in apt-get yum dnf pacman zypper brew choco scoop winget; do
        command -v "$mgr" >/dev/null 2>&1 && echo "$mgr" && return
    done

    # Check PowerShell package managers
    if [ "$HAS_PS" = "1" ]; then
        for ps_mgr in choco scoop winget; do
            powershell.exe -Command "Get-Command $ps_mgr -ErrorAction SilentlyContinue" >/dev/null 2>&1 && echo "ps_$ps_mgr" && return
        done
        echo "powershell"
    else
        echo "none"
    fi
}

# Install jq automatically
install_jq() {
    local mgr="$(detect_pkg_mgr)"
    info "Attempting to install jq via $mgr..."

    case "$mgr" in
    apt-get) sudo apt-get update && sudo apt-get install -y jq ;;
    yum) sudo yum install -y jq ;;
    dnf) sudo dnf install -y jq ;;
    pacman) sudo pacman -S --noconfirm jq ;;
    zypper) sudo zypper install -y jq ;;
    brew) brew install jq ;;
    choco) choco install jq -y ;;
    scoop) scoop install jq ;;
    winget) winget install jqlang.jq ;;
    ps_choco) powershell.exe -Command "choco install jq -y" ;;
    ps_scoop) powershell.exe -Command "scoop install jq" ;;
    ps_winget) powershell.exe -Command "winget install jqlang.jq" ;;
    powershell) powershell.exe -Command "winget install jqlang.jq" ;;
    *) error "No package manager found. Please install jq manually from https://github.com/stedolan/jq/releases" && exit 1 ;;
    esac

    command -v jq >/dev/null 2>&1 && success "jq installed successfully" || (error "jq installation failed" && exit 1)
}

# Check and install jq if needed
check_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        error "jq not found"
        printf "Install jq automatically? (y/N): "
        read -r response
        case "$response" in [yY]*) install_jq ;; *) exit 1 ;; esac
    fi
}

# Read JSON values with fallback
read_json() {
    local value
    value="$(jq -r "$1" "$SETTINGS_FILE" 2>/dev/null || echo "null")"
    [ "$value" = "null" ] && echo "${2:-}" || echo "$value"
}

# Read boolean values
read_bool() {
    local value
    value="$(read_json "$1")"
    [ "$value" = "true" ] && echo "true" || echo "${2:-false}"
}

# Display configuration
show_config() {
    info "Aurora Module Configuration:"
    echo "Module Build: $(read_bool '.module.AuroraModuleBuild')"
    echo "WebUI Build: $(read_bool '.build.Aurora_webui_build')"
    echo "Build Type: $(read_json '.build.build_type' 'Release')"
    echo "Module Name: $(read_json '.build.module_properties.module_name' 'AuroraModule')"
    echo "Version: $(read_json '.build.module_properties.module_version' '1.0.0')"
    echo
}

# Get CPU cores count
get_cores() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
    elif [ -r /proc/cpuinfo ]; then
        grep -c ^processor /proc/cpuinfo
    elif command -v sysctl >/dev/null 2>&1; then
        sysctl -n hw.ncpu 2>/dev/null || echo 4
    else
        echo 4
    fi
}

run_custom_script() {
    if [ "$(read_bool '.build.custom_build_script')" = "true" ]; then
        local script="$(read_json '.build.build_script.script_path' 'custom_build_script.sh')"
        if [ -f "$PROJECT_ROOT/$script" ]; then
            info "Running custom script: $script"
            cd "$PROJECT_ROOT" && . "$script"
            success "Custom script completed"
        else
            warn "Custom script not found: $script"
        fi
    fi
}

# Main build process
build() {
    if [ "$(read_bool '.build_module')" = "true" ]; then
        info "Starting build process..."
        . "$SCRIPT_DIR/build_into.sh"
        main_build
        run_custom_script
        success "Build process completed!"
        exit 0
    else
        info "Build disabled in configuration"
        exit 0
    fi
}

# Main function
main() {
    detect_env
    setup_colors

    case "${1:-}" in
    -h | --help)
        echo "Usage: $0 [OPTIONS]"
        echo "  -a, --auto    Auto mode (no confirmation)"
        echo "  -c, --config  Show config only"
        echo "  -h, --help    Show help"
        exit 0
        ;;
    -c | --config)
        check_jq
        [ ! -f "$SETTINGS_FILE" ] && error "Settings file not found: $SETTINGS_FILE" && exit 1
        jq empty "$SETTINGS_FILE" >/dev/null 2>&1 || (error "Invalid JSON in settings file" && exit 1)
        show_config
        exit 0
        ;;
    esac

    info "Aurora Module Build Script"
    check_jq

    # Validate settings
    [ ! -f "$SETTINGS_FILE" ] && error "Settings file not found: $SETTINGS_FILE" && exit 1
    jq empty "$SETTINGS_FILE" >/dev/null 2>&1 || (error "Invalid JSON in settings file" && exit 1)

    show_config

    # Build confirmation
    if [ "$1" = "-a" ] || [ "$1" = "--auto" ]; then
        build
    else
        printf "Proceed with build? (y/N): "
        read -r response
        case "$response" in 
            [yY]*) 
                build
                ;;
            *) 
                info "Build cancelled"
                exit 0
                ;;
        esac
    fi
}

# Execute main function
main "$@"
