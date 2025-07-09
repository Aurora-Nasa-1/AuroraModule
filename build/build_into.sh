#!/bin/sh
# Aurora Module Build Into Script - Complete Magisk Module Builder
set -e
# Build configuration
BUILD_DIR="$PROJECT_ROOT/build_output"
MODULE_DIR="$BUILD_DIR/module"
TEMP_DIR="$BUILD_DIR/temp"
NDK_DIR="$PROJECT_ROOT/android-ndk"
NDK_VERSION="r27c"

# Initialize build environment
init_build() {
    info "Initializing build environment..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$MODULE_DIR" "$TEMP_DIR"
    success "Build environment ready"
}

# Install Android NDK if needed
install_ndk() {
    local use_tools_form="$(read_json '.build.use_tools_form' '')"

    if [ "$use_tools_form" = "build" ] && [ ! -d "$NDK_DIR" ]; then
        info "Installing Android NDK $NDK_VERSION..."

        case "$OS" in
        "linux")
            local ndk_url="https://dl.google.com/android/repository/android-ndk-$NDK_VERSION-linux.zip"
            ;;
        "macos")
            local ndk_url="https://dl.google.com/android/repository/android-ndk-$NDK_VERSION-darwin.zip"
            ;;
        "windows")
            local ndk_url="https://dl.google.com/android/repository/android-ndk-$NDK_VERSION-windows.zip"
            ;;
        *)
            error "Unsupported OS for NDK installation: $OS"
            exit 1
            ;;
        esac

        info "Downloading NDK from $ndk_url..."
        if command -v curl >/dev/null 2>&1; then
            curl -L -o "$TEMP_DIR/ndk.zip" "$ndk_url"
        elif command -v wget >/dev/null 2>&1; then
            wget -O "$TEMP_DIR/ndk.zip" "$ndk_url"
        else
            error "Neither curl nor wget found. Please install one of them."
            exit 1
        fi

        info "Extracting NDK..."
        cd "$PROJECT_ROOT"
        unzip -q "$TEMP_DIR/ndk.zip"
        mv "android-ndk-$NDK_VERSION" "$NDK_DIR"

        success "Android NDK installed successfully"
    fi
}

# Build C++ components using NDK
build_cpp() {
    local use_tools_form="$(read_json '.build.use_tools_form' '')"
    local build_type="$(read_json '.build.build_type' 'Release')"

    if [ "$use_tools_form" = "build" ] && [ -d "$PROJECT_ROOT/Core" ]; then
        info "Building C++ components..."

        if [ ! -d "$NDK_DIR" ]; then
            error "Android NDK not found. Please install NDK first."
            exit 1
        fi

        cd "$PROJECT_ROOT/Core"
        mkdir -p build && cd build

        # Configure CMake with Android NDK
        cmake .. \
            -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
            -DANDROID_ABI=arm64-v8a \
            -DANDROID_PLATFORM=android-21 \
            -DCMAKE_BUILD_TYPE="$build_type" \
            -DBUILD_TESTING=OFF

        # Build with parallel jobs
        make -j"$(get_cores)"

        # Copy binaries to module directory
        mkdir -p "$MODULE_DIR/system/bin" "$MODULE_DIR/system/lib64"
        find . -name "*.so" -exec cp {} "$MODULE_DIR/system/lib64/" \; 2>/dev/null || true
        find . -type f -executable -exec cp {} "$MODULE_DIR/system/bin/" \; 2>/dev/null || true

        success "C++ components built successfully"
    fi
}

# Create META-INF structure
create_meta_inf() {
    local meta_inf_default="$(read_bool '.module.META_INF_default')"

    if [ "$meta_inf_default" = "false" ]; then
        info "Creating META-INF structure..."
        mkdir -p "$MODULE_DIR/META-INF/com/google/android"

        # Create update-binary
        cat >"$MODULE_DIR/META-INF/com/google/android/update-binary" <<'EOF'
#!/sbin/sh

#################
# Initialization
#################

umask 022

# echo before loading util_functions
ui_print() { echo "$1"; }

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk v20.4+! "
  ui_print "*******************************"
  exit 1
}

#########################
# Load util_functions.sh
#########################

OUTFD=$2
ZIPFILE=$3

mount /data 2>/dev/null

[ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
. /data/adb/magisk/util_functions.sh
[ $MAGISK_VER_CODE -lt 20400 ] && require_new_magisk

install_module
exit 0
EOF

        # Create updater-script
        echo "#MAGISK" >"$MODULE_DIR/META-INF/com/google/android/updater-script"

        chmod +x "$MODULE_DIR/META-INF/com/google/android/update-binary"
        success "META-INF structure created"
    fi
}

# Create module.prop
create_module_prop() {
    info "Creating module.prop..."

    local module_name="$(read_json '.build.module_properties.module_name' 'AuroraModule')"
    local module_version="$(read_json '.build.module_properties.module_version' '1.0.0')"
    local module_versioncode="$(read_json '.build.module_properties.module_versioncode' '1')"
    local module_author="$(read_json '.build.module_properties.module_author' 'Aurora')"
    local module_description="$(read_json '.build.module_properties.module_description' 'Aurora Module')"
    local update_json="$(read_json '.build.module_properties.updateJson' '')"

    # Remove 'module_' prefix from property names
    local name="${module_name#module_}"
    local version="${module_version#module_}"
    local versioncode="${module_versioncode#module_}"
    local author="${module_author#module_}"
    local description="${module_description#module_}"

    cat >"$MODULE_DIR/module.prop" <<EOF
id=$name
name=$name
version=$version
versionCode=$versioncode
author=$author
description=$description
EOF

    if [ -n "$update_json" ]; then
        echo "updateJson=$update_json" >>"$MODULE_DIR/module.prop"
    fi

    success "module.prop created"
}

# Build WebUI
build_webui() {
    local webui_default="$(read_bool '.module.webui_default')"
    local aurora_webui_build="$(read_bool '.build.Aurora_webui_build')"

    if [ "$webui_default" = "false" ] && [ "$aurora_webui_build" = "true" ]; then
        info "Building WebUI..."

        if [ ! -f "$PROJECT_ROOT/webui/package.json" ]; then
            warn "WebUI package.json not found, skipping WebUI build"
            return
        fi

        cd "$PROJECT_ROOT/webui"

        if ! command -v npm >/dev/null 2>&1; then
            error "npm not found. Please install Node.js first"
            return
        fi

        # Get variables for text replacement
        local github_update_repo="$(read_json '.build.Github_update_repo' '')"
        local mod_id="$(read_json '.build.module_properties.module_name' 'AMMF')"
        local mod_name="$(read_json '.build.module_properties.module_name' 'AMMF')"
        local current_time_versioncode="$(date +%y%m%d)"

        if [ -z "$github_update_repo" ]; then
            warn "Github_update_repo not set, using default values"
            github_update_repo="Aurora-Nasa-1/ModuleWebUI"
        fi

        # Perform text replacements as per CI workflow
        info "Performing text replacements..."

        # Replace version code
        sed -i "s/20240503/${current_time_versioncode}/g" src/pages/status.js 2>/dev/null || true

        # Replace GitHub repo
        find src -name "status.js" -exec sed -i "s|Aurora-Nasa-1/AMMF|${github_update_repo}|g" {} \; 2>/dev/null || true

        # Replace module ID
        find src -name "*.js" -exec sed -i "s/AMMF/${mod_id}/g" {} \; 2>/dev/null || true
        sed -i "s/AMMF/${mod_id}/g" index.html 2>/dev/null || true

        # Replace module name in translations
        find src/assets/translations -name "*.json" -exec sed -i "s/AMMF/${mod_name}/g" {} \; 2>/dev/null || true

        info "Text replacements completed"

        # Install dependencies and build
        npm ci
        npm run build

        # Copy built files to module
        mkdir -p "$MODULE_DIR/webroot"
        cp -r dist/* "$MODULE_DIR/webroot/"

        success "WebUI built and copied to module"
    fi
}

# Create customize.sh
create_customize_sh() {
    local install_script_default="$(read_bool '.module.install_script_default')"
    if [ "$install_script_default" = "true" ]; then
        cp "$MODULE_DIR/build/customize.sh" "$MODULE_DIR/old_install.sh" 2>/dev/null || warn "customize.sh not found"
    fi
        info "Creating customize.sh..."

        local add_aurora_function="$(read_bool '.build.script.add_Aurora_function_for_script')"
        local add_log_support="$(read_bool '.build.script.add_log_support_for_script')"
        local build_type="$(read_json '.build.build_type' 'Release')"

        cat >"$MODULE_DIR/customize.sh" <<'EOF'
#!/system/bin/sh

# Aurora Module Installation Script

EOF
        # Add script imports based on configuration
        if [ "$add_log_support" = "true" ]; then
            echo ". \$MODPATH/Logsystem.sh" >>"$MODULE_DIR/customize.sh"
            cp "$PROJECT_ROOT/build/Logsystem.sh" "$MODULE_DIR/" 2>/dev/null || warn "Logsystem.sh not found"
        fi

        if [ "$add_aurora_function" = "true" ]; then
            echo ". \$MODPATH/AuroraCore.sh" >>"$MODULE_DIR/customize.sh"
            cp "$PROJECT_ROOT/build/AuroraCore.sh" "$MODULE_DIR/" 2>/dev/null || warn "AuroraCore.sh not found"

            if [ "$add_log_support" != "true" ]; then
                cp "$PROJECT_ROOT/build/Log_b.sh" "$MODULE_DIR/" 2>/dev/null || warn "Log_b.sh not found"
            fi
        fi

        # Add build type information
        cat >>"$MODULE_DIR/customize.sh" <<EOF

# Build Configuration
BUILD_TYPE="$build_type"

# Installation logic
ui_print "Installing Aurora Module..."
ui_print "Build Type: \$BUILD_TYPE"

# Set permissions
set_perm_recursive \$MODPATH 0 0 0755 0644
set_perm_recursive \$MODPATH/system/bin 0 0 0755 0755
ui_print "Aurora Module installed successfully!"
EOF
    if [ "$install_script_default" = "true" ]; then
         echo ". \$MODPATH/old_install.sh" >>"$MODULE_DIR/customize.sh"
    fi
old_install.sh

        chmod +x "$MODULE_DIR/customize.sh"
        success "customize.sh created"
}

# Package Magisk module
package_module() {
    info "Packaging Magisk module..."

    local module_name="$(read_json '.build.module_properties.module_name' 'AuroraModule')"
    local module_version="$(read_json '.build.module_properties.module_version' '1.0.0')"
    local output_name="${module_name}-${module_version}.zip"

    cd "$MODULE_DIR"

    # Create the zip file
    if command -v zip >/dev/null 2>&1; then
        zip -r "$BUILD_DIR/$output_name" . -x "*.DS_Store" "*Thumbs.db"
    else
        # Fallback to tar if zip is not available
        tar -czf "$BUILD_DIR/${output_name%.zip}.tar.gz" .
        output_name="${output_name%.zip}.tar.gz"
    fi

    success "Module packaged as: $output_name"
    info "Output location: $BUILD_DIR/$output_name"
}

# Main build process
main_build() {
    local build_module="$(read_bool '.build_module')"

    if [ "$build_module" = "true" ]; then
        info "Starting Aurora Module build process..."

        init_build
        install_ndk
        build_cpp
        create_meta_inf
        create_module_prop
        build_webui
        create_customize_sh
        package_module

        success "Aurora Module build completed successfully!"
    else
        info "Module build is disabled in configuration"
    fi
}
