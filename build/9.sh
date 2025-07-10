#!/system/bin/sh
# 高性能日志系统 - 与C++日志组件集成
# 版本: 3.0.0 - 重构版本

# ============================
# Global Variables
# ============================
LOGGER_INITIALIZED=0
LOG_FILE_NAME="main"
LOGGER_DAEMON_PID=""
LOGGER_DAEMON_BIN="${MODPATH}/bin/logger_daemon"
LOGGER_CLIENT_BIN="${MODPATH}/bin/logger_client"
LOGGER_BATCH_CLIENT_BIN="${MODPATH}/bin/logger_batch_client"
SOCKET_PATH="${MODPATH}/tmp/logger_daemon"
LOG_DIR="${MODPATH}/logs"
LOG_LEVEL="info"  # debug, info, warning, error, critical
LOW_POWER_MODE=0  # Default: Low power mode off
FLUSH_INTERVAL=10000  # 10 seconds in milliseconds for power saving
BUFFER_SIZE=131072    # 128KB buffer size for better buffering
MAX_FILE_SIZE=10485760  # 10MB max file size
MAX_FILES=5          # Maximum number of log files

# Shell-side buffering for batch operations
SHELL_BUFFER_ENABLED=1  # Enable shell-side buffering
SHELL_BUFFER_SIZE=20    # Max messages in shell buffer
SHELL_BUFFER_TIMEOUT=5  # Seconds before auto-flush
SHELL_BUFFER_FILE="${MODPATH}/tmp/shell_buffer.tmp"
SHELL_BUFFER_COUNT=0
SHELL_BUFFER_LAST_FLUSH=0

# ============================
# Buffer Management Functions
# ============================

# Add message to shell buffer
add_to_buffer() {
    [ "$SHELL_BUFFER_ENABLED" != "1" ] && return 1
    [ -z "$1" ] || [ -z "$2" ] && return 1
    
    # Create buffer file if it doesn't exist
    [ ! -f "$SHELL_BUFFER_FILE" ] && touch "$SHELL_BUFFER_FILE"
    
    # Add message to buffer file
    echo "$1|$2" >> "$SHELL_BUFFER_FILE"
    SHELL_BUFFER_COUNT=$((SHELL_BUFFER_COUNT + 1))
    
    # Check if buffer should be flushed
    check_buffer_flush
}

# Flush shell buffer to daemon
flush_buffer() {
    [ ! -f "$SHELL_BUFFER_FILE" ] && return 0
    [ "$SHELL_BUFFER_COUNT" -eq 0 ] && return 0
    
    # Initialize logger if not already done
    [ "$LOGGER_INITIALIZED" != "1" ] && init_logger
    
    # Use batch client for efficient sending
    if [ -f "$LOGGER_BATCH_CLIENT_BIN" ] && [ "$SHELL_BUFFER_COUNT" -gt 1 ]; then
        # Send as batch using the batch client
        "$LOGGER_BATCH_CLIENT_BIN" -p "$SOCKET_PATH" -f "$SHELL_BUFFER_FILE" 2>/dev/null &
    else
        # Fallback to individual sends
        while IFS='|' read -r level message; do
            [ -n "$level" ] && [ -n "$message" ] && {
                "$LOGGER_CLIENT_BIN" -p "$SOCKET_PATH" -l "$level" -m "$message" 2>/dev/null &
            }
        done < "$SHELL_BUFFER_FILE"
    fi
    
    # Clean up
    rm -f "$SHELL_BUFFER_FILE" 2>/dev/null
    SHELL_BUFFER_COUNT=0
    SHELL_BUFFER_LAST_FLUSH=$(date +%s)
}

# Check if buffer should be flushed
check_buffer_flush() {
    # Flush if buffer size exceeded
    if [ "$SHELL_BUFFER_COUNT" -ge "$SHELL_BUFFER_SIZE" ]; then
        flush_buffer
        return
    fi
    
    # Flush if timeout exceeded
    local current_time=$(date +%s)
    local time_diff=$((current_time - SHELL_BUFFER_LAST_FLUSH))
    if [ "$time_diff" -ge "$SHELL_BUFFER_TIMEOUT" ] && [ "$SHELL_BUFFER_COUNT" -gt 0 ]; then
        flush_buffer
    fi
}

# ============================
# Core Functions
# ============================

# Initialize logger system
init_logger() {
    [ "$LOGGER_INITIALIZED" = "1" ] && return 0
    
    # Create necessary directories
    mkdir -p "$LOG_DIR" "$(dirname "$SOCKET_PATH")" "$(dirname "$SHELL_BUFFER_FILE")" 2>/dev/null
    
    # Initialize shell buffer timestamp
    SHELL_BUFFER_LAST_FLUSH=$(date +%s)
    
    # Check if daemon is already running
    LOGGER_DAEMON_PID=$(pgrep -f "$LOGGER_DAEMON_BIN" 2>/dev/null)
    if [ -z "$LOGGER_DAEMON_PID" ]; then
        # Start logger daemon with power-optimized configuration
        local log_file="$LOG_DIR/$LOG_FILE_NAME.log"
        local flush_time=$FLUSH_INTERVAL
        [ "$LOW_POWER_MODE" = "1" ] && flush_time=$((FLUSH_INTERVAL * 3))
        
        "$LOGGER_DAEMON_BIN" -f "$log_file" -p "$SOCKET_PATH" \
            -s "$MAX_FILE_SIZE" -n "$MAX_FILES" -b "$BUFFER_SIZE" \
            -t "$flush_time" >/dev/null 2>&1 &
        
        LOGGER_DAEMON_PID=$!
        sleep 0.1  # Minimal wait for daemon to initialize
    fi
    
    LOGGER_INITIALIZED=1
    return 0
}

# Log a message with specified level
log() {
    [ -z "$1" ] || [ -z "$2" ] && return 1
    
    # Check for immediate flush requirement (critical/error logs)
    case "$1" in
        critical|error)
            # Force immediate flush of buffer first
            [ "$SHELL_BUFFER_COUNT" -gt 0 ] && flush_buffer
            
            # Initialize logger if not already done
            [ "$LOGGER_INITIALIZED" != "1" ] && init_logger
            
            # Send critical/error messages immediately
            "$LOGGER_CLIENT_BIN" -p "$SOCKET_PATH" -l "$1" -m "$2" 2>/dev/null &
            ;;
        *)
            # Use buffering for other log levels
            if [ "$SHELL_BUFFER_ENABLED" = "1" ]; then
                add_to_buffer "$1" "$2"
            else
                # Initialize logger if not already done
                [ "$LOGGER_INITIALIZED" != "1" ] && init_logger
                
                # Send message immediately if buffering disabled
                "$LOGGER_CLIENT_BIN" -p "$SOCKET_PATH" -l "$1" -m "$2" 2>/dev/null &
            fi
            ;;
    esac
}

# Log a message immediately (bypass buffer)
log_immediate() {
    [ -z "$1" ] || [ -z "$2" ] && return 1
    
    # Initialize logger if not already done
    [ "$LOGGER_INITIALIZED" != "1" ] && init_logger
    
    # Send log message using client (fire and forget for performance)
    "$LOGGER_CLIENT_BIN" -p "$SOCKET_PATH" -l "$1" -m "$2" 2>/dev/null &
}

# Convenience functions for different log levels
log_debug() { log "debug" "$1"; }
log_info() { log "info" "$1"; }
log_warn() { log "warning" "$1"; }
log_warning() { log "warning" "$1"; }
log_error() { log "error" "$1"; }
log_critical() { log "critical" "$1"; }

# Batch log from file
batch_log() {
    [ -z "$1" ] || [ ! -f "$1" ] && return 1
    
    # Initialize logger if not already done
    [ "$LOGGER_INITIALIZED" != "1" ] && init_logger
    
    # Read file line by line and send each line as a log message
    while IFS= read -r line || [ -n "$line" ]; do
        [ -n "$line" ] && log "${2:-info}" "$line"
    done < "$1"
}

# Set log file name
set_log_file() {
    [ -n "$1" ] && LOG_FILE_NAME="$1"
}

# Set log level (for filtering, though daemon handles all levels)
set_log_level() {
    case "$1" in
        debug|info|warning|error|critical) LOG_LEVEL="$1" ;;
    esac
}

# Enable/disable low power mode
set_low_power_mode() {
    case "$1" in
        1|true|on) LOW_POWER_MODE=1 ;;
        *) LOW_POWER_MODE=0 ;;
    esac
}

# Flush logs (force daemon to flush buffers)
flush_logs() {
    # Flush shell buffer first
    [ "$SHELL_BUFFER_COUNT" -gt 0 ] && flush_buffer
    
    # Then flush daemon buffers
    [ "$LOGGER_INITIALIZED" = "1" ] && [ -n "$LOGGER_DAEMON_PID" ] && \
        kill -USR1 "$LOGGER_DAEMON_PID" 2>/dev/null
}

# Enable/disable shell buffering
set_shell_buffering() {
    case "$1" in
        1|true|on|enable) 
            SHELL_BUFFER_ENABLED=1 
            echo "Shell buffering enabled"
            ;;
        0|false|off|disable) 
            # Flush existing buffer before disabling
            [ "$SHELL_BUFFER_COUNT" -gt 0 ] && flush_buffer
            SHELL_BUFFER_ENABLED=0 
            echo "Shell buffering disabled"
            ;;
        *) 
            echo "Shell buffering status: $SHELL_BUFFER_ENABLED (buffer count: $SHELL_BUFFER_COUNT)"
            ;;
    esac
}

# Set shell buffer size
set_shell_buffer_size() {
    [ -n "$1" ] && [ "$1" -gt 0 ] && {
        SHELL_BUFFER_SIZE="$1"
        echo "Shell buffer size set to $SHELL_BUFFER_SIZE"
    }
}

# Set shell buffer timeout
set_shell_buffer_timeout() {
    [ -n "$1" ] && [ "$1" -gt 0 ] && {
        SHELL_BUFFER_TIMEOUT="$1"
        echo "Shell buffer timeout set to $SHELL_BUFFER_TIMEOUT seconds"
    }
}

# Clean logs (remove log files)
clean_logs() {
    [ -d "$LOG_DIR" ] && rm -f "$LOG_DIR"/*.log* 2>/dev/null
}

# Stop logger system
stop_logger() {
    # Flush shell buffer before stopping
    [ "$SHELL_BUFFER_COUNT" -gt 0 ] && flush_buffer
    
    if [ "$LOGGER_INITIALIZED" = "1" ] && [ -n "$LOGGER_DAEMON_PID" ]; then
        # Send SIGTERM for graceful shutdown
        kill -TERM "$LOGGER_DAEMON_PID" 2>/dev/null
        
        # Wait for daemon to shutdown gracefully
        local count=0
        while [ $count -lt 10 ] && kill -0 "$LOGGER_DAEMON_PID" 2>/dev/null; do
            sleep 0.1
            count=$((count + 1))
        done
        
        # Force kill if still running
        if kill -0 "$LOGGER_DAEMON_PID" 2>/dev/null; then
            kill -KILL "$LOGGER_DAEMON_PID" 2>/dev/null
        fi
        
        # Clean up socket file and buffer files
        rm -f "$SOCKET_PATH" "$SHELL_BUFFER_FILE" 2>/dev/null
        
        LOGGER_DAEMON_PID=""
        LOGGER_INITIALIZED=0
        SHELL_BUFFER_COUNT=0
    fi
    return 0
}
# Additional utility functions

# Get logger status
get_logger_status() {
    if [ "$LOGGER_INITIALIZED" = "1" ] && [ -n "$LOGGER_DAEMON_PID" ] && kill -0 "$LOGGER_DAEMON_PID" 2>/dev/null; then
        echo "Logger daemon running (PID: $LOGGER_DAEMON_PID, Power mode: $LOW_POWER_MODE)"
        echo "Shell buffering: $SHELL_BUFFER_ENABLED (Count: $SHELL_BUFFER_COUNT/$SHELL_BUFFER_SIZE, Timeout: ${SHELL_BUFFER_TIMEOUT}s)"
        echo "Daemon buffer: ${BUFFER_SIZE} bytes, Flush interval: ${FLUSH_INTERVAL}ms"
    else
        echo "Logger daemon not running"
        echo "Shell buffering: $SHELL_BUFFER_ENABLED (Count: $SHELL_BUFFER_COUNT/$SHELL_BUFFER_SIZE)"
    fi
}

# Test logger functionality
test_logger() {
    echo "Testing logger functionality..."
    echo "Current buffer status: $SHELL_BUFFER_COUNT messages buffered"
    
    log_debug "Debug message test"
    log_info "Info message test"
    log_warning "Warning message test"
    echo "Buffer status after normal logs: $SHELL_BUFFER_COUNT messages buffered"
    
    log_error "Error message test (immediate)"
    log_critical "Critical message test (immediate)"
    echo "Buffer status after critical logs: $SHELL_BUFFER_COUNT messages buffered"
    
    echo "Test messages sent. Check log file: $LOG_DIR/$LOG_FILE_NAME.log"
}

# Test batch logging functionality
test_batch_logging() {
    echo "Testing batch logging functionality..."
    
    # Send multiple messages to fill buffer
    for i in $(seq 1 5); do
        log_info "Batch test message $i"
    done
    
    echo "Sent 5 messages, buffer count: $SHELL_BUFFER_COUNT"
    
    # Force flush
    flush_buffer
    echo "After flush, buffer count: $SHELL_BUFFER_COUNT"
    
    echo "Batch test completed. Check log file: $LOG_DIR/$LOG_FILE_NAME.log"
}

# Default configuration - call init_logger manually when needed
set_log_file "main"
