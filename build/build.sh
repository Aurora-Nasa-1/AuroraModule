#!/bin/bash
# Aurora Module Build Script - Simplified Version
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SETTINGS_FILE="$PROJECT_ROOT/module/settings.json"
BUILD_DIR="$PROJECT_ROOT/build_output"
MODULE_DIR="$BUILD_DIR/module"
NDK_DIR="$PROJECT_ROOT/android-ndk"

# Colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

# Logging functions
log() { echo -e "${2}[${1}]${NC} ${3}"; }
info() { log "INFO" "$BLUE" "$1"; }
success() { log "OK" "$GREEN" "$1"; }
warn() { log "WARN" "$YELLOW" "$1"; }
error() { log "ERROR" "$RED" "$1"; }

# Error handling and cleanup
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        error "Build failed with exit code $exit_code"
        [ -d "$BUILD_DIR" ] && rm -rf "$BUILD_DIR"
    fi
    exit $exit_code
}
trap cleanup EXIT

# Check dependencies
check_deps() {
    local missing=()
    for cmd in jq cmake make zip; do
        command -v "$cmd" >/dev/null || missing+=("$cmd")
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing dependencies: ${missing[*]}"
        error "Please install: sudo apt-get install ${missing[*]}"
        exit 1
    fi
}

# Read JSON configuration
read_json() {
    jq -r "$1 // \"$2\"" "$SETTINGS_FILE" 2>/dev/null
}

read_bool() {
    local value=$(read_json "$1" "false")
    [ "$value" = "true" ] && echo "true" || echo "false"
}

# Validate configuration
validate_config() {
    [ ! -f "$SETTINGS_FILE" ] && { error "Settings file not found: $SETTINGS_FILE"; exit 1; }
    jq empty "$SETTINGS_FILE" 2>/dev/null || { error "Invalid JSON in settings file"; exit 1; }
}

# Initialize build environment
init_build() {
    info "Initializing build environment..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$MODULE_DIR" "$BUILD_DIR/temp"
    success "Build environment ready"
}

# Build C++ components
build_cpp() {
    local use_tools=$(read_json '.build.use_tools_form' '')
    local build_type=$(read_json '.build.build_type' 'Release')
    
    if [ "$use_tools" = "build" ] && [ -d "$PROJECT_ROOT/Core" ]; then
        info "Building C++ components..."
        
        [ ! -d "$NDK_DIR" ] && { error "Android NDK not found at $NDK_DIR"; exit 1; }
        
        cd "$PROJECT_ROOT/Core"
        rm -rf build && mkdir build && cd build
        
        cmake .. \
            -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
            -DANDROID_ABI=arm64-v8a \
            -DANDROID_PLATFORM=android-21 \
            -DCMAKE_BUILD_TYPE="$build_type" \
            -DBUILD_TESTING=OFF
        
        make -j$(nproc)
        
        # Copy binaries
        mkdir -p "$MODULE_DIR/system/bin" "$MODULE_DIR/system/lib64"
        find . -name "*.so" -exec cp {} "$MODULE_DIR/system/lib64/" \; 2>/dev/null || true
        find . -type f -executable -exec cp {} "$MODULE_DIR/system/bin/" \; 2>/dev/null || true
        
        success "C++ components built"
    fi
}

# Create META-INF structure
create_meta_inf() {
    if [ "$(read_bool '.module.META_INF_default')" = "false" ]; then
        info "Creating META-INF structure..."
        mkdir -p "$MODULE_DIR/META-INF/com/google/android"
        
        cat > "$MODULE_DIR/META-INF/com/google/android/update-binary" << 'EOF'
#!/sbin/sh
umask 022
ui_print() { echo "$1"; }
require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk v20.4+! "
  ui_print "*******************************"
  exit 1
}
OUTFD=$2
ZIPFILE=$3
mount /data 2>/dev/null
[ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
. /data/adb/magisk/util_functions.sh
[ $MAGISK_VER_CODE -lt 20400 ] && require_new_magisk
install_module
exit 0
EOF
        
        echo "#MAGISK" > "$MODULE_DIR/META-INF/com/google/android/updater-script"
        chmod +x "$MODULE_DIR/META-INF/com/google/android/update-binary"
        success "META-INF structure created"
    fi
}

# Create module.prop
create_module_prop() {
    info "Creating module.prop..."
    
    local name=$(read_json '.build.module_properties.module_name' 'AuroraModule')
    local version=$(read_json '.build.module_properties.module_version' '1.0.0')
    local versioncode=$(read_json '.build.module_properties.module_versioncode' '1')
    local author=$(read_json '.build.module_properties.module_author' 'Aurora')
    local description=$(read_json '.build.module_properties.module_description' 'Aurora Module')
    local update_json=$(read_json '.build.module_properties.updateJson' '')
    
    cat > "$MODULE_DIR/module.prop" << EOF
id=$name
name=$name
version=$version
versionCode=$versioncode
author=$author
description=$description
EOF
    
    [ -n "$update_json" ] && echo "updateJson=$update_json" >> "$MODULE_DIR/module.prop"
    success "module.prop created"
}

# Build WebUI
build_webui() {
    local webui_default=$(read_bool '.module.webui_default')
    local aurora_webui_build=$(read_bool '.build.Aurora_webui_build')
    
    if [ "$webui_default" = "false" ] && [ "$aurora_webui_build" = "true" ]; then
        info "Building WebUI..."
        
        [ ! -f "$PROJECT_ROOT/webui/package.json" ] && { warn "WebUI package.json not found, skipping"; return; }
        command -v npm >/dev/null || { error "npm not found"; return; }
        
        cd "$PROJECT_ROOT/webui"
        npm ci && npm run build
        
        mkdir -p "$MODULE_DIR/webroot"
        cp -r dist/* "$MODULE_DIR/webroot/"
        
        success "WebUI built and copied"
    fi
}

# Create customize.sh
create_customize_sh() {
    info "Creating customize.sh..."
    
    local add_aurora=$(read_bool '.build.script.add_Aurora_function_for_script')
    local add_log=$(read_bool '.build.script.add_log_support_for_script')
    local build_type=$(read_json '.build.build_type' 'Release')
    
    cat > "$MODULE_DIR/customize.sh" << EOF
#!/system/bin/sh
# Aurora Module Installation Script

BUILD_TYPE="$build_type"

ui_print "Installing Aurora Module..."
ui_print "Build Type: \$BUILD_TYPE"

set_perm_recursive \$MODPATH 0 0 0755 0644
set_perm_recursive \$MODPATH/system/bin 0 0 0755 0755

ui_print "Aurora Module installed successfully!"
EOF
    
    # Add script imports
    if [ "$add_log" = "true" ]; then
        sed -i '3i\. $MODPATH/Logsystem.sh' "$MODULE_DIR/customize.sh"
        [ -f "$PROJECT_ROOT/build/Logsystem.sh" ] && cp "$PROJECT_ROOT/build/Logsystem.sh" "$MODULE_DIR/"
    fi
    
    if [ "$add_aurora" = "true" ]; then
        sed -i '3i\. $MODPATH/AuroraCore.sh' "$MODULE_DIR/customize.sh"
        [ -f "$PROJECT_ROOT/build/AuroraCore.sh" ] && cp "$PROJECT_ROOT/build/AuroraCore.sh" "$MODULE_DIR/"
    fi
    
    chmod +x "$MODULE_DIR/customize.sh"
    success "customize.sh created"
}

# Run custom script
run_custom_script() {
    if [ "$(read_bool '.build.custom_build_script')" = "true" ]; then
        local script=$(read_json '.build.build_script.script_path' 'custom_build_script.sh')
        if [ -f "$PROJECT_ROOT/$script" ]; then
            info "Running custom script: $script"
            cd "$PROJECT_ROOT" && bash "$script"
            success "Custom script completed"
        else
            warn "Custom script not found: $script"
        fi
    fi
}

# Package module
package_module() {
    info "Packaging Magisk module..."
    
    local name=$(read_json '.build.module_properties.module_name' 'AuroraModule')
    local version=$(read_json '.build.module_properties.module_version' '1.0.0')
    local output="${name}-${version}.zip"
    
    cd "$MODULE_DIR"
    zip -r "$BUILD_DIR/$output" . -x "*.DS_Store" "*Thumbs.db"
    
    success "Module packaged as: $output"
    info "Output location: $BUILD_DIR/$output"
}

# Main build process
main_build() {
    info "Starting Aurora Module build process..."
    
    init_build
    build_cpp
    create_meta_inf
    create_module_prop
    build_webui
    create_customize_sh
    package_module
    run_custom_script
    
    success "Aurora Module build completed successfully!"
}

# Show configuration
show_config() {
    info "Aurora Module Configuration:"
    echo "Module Build: $(read_bool '.build_module')"
    echo "WebUI Build: $(read_bool '.build.Aurora_webui_build')"
    echo "Build Type: $(read_json '.build.build_type' 'Release')"
    echo "Module Name: $(read_json '.build.module_properties.module_name' 'AuroraModule')"
    echo "Version: $(read_json '.build.module_properties.module_version' '1.0.0')"
    echo
}

# Main function
main() {
    case "${1:-}" in
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "  -a, --auto    Auto mode (no confirmation)"
            echo "  -c, --config  Show config only"
            echo "  -h, --help    Show help"
            exit 0
            ;;
        -c|--config)
            validate_config
            show_config
            exit 0
            ;;
    esac
    
    info "Aurora Module Build Script"
    check_deps
    validate_config
    show_config
    
    if [ "$(read_bool '.build_module')" != "true" ]; then
        info "Build disabled in configuration"
        exit 0
    fi
    
    # Build confirmation
    if [ "$1" != "-a" ] && [ "$1" != "--auto" ]; then
        printf "Proceed with build? (y/N): "
        read -r response
        case "$response" in
            [yY]*) ;;
            *) info "Build cancelled"; exit 0 ;;
        esac
    fi
    
    main_build
}

# Execute main function
main "$@"
