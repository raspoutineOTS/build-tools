#!/bin/bash

# Universal Service/Daemon Manager
# Manage long-running services, MCP servers, and background processes

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/services-config.json}"
LOG_FILE="${LOG_FILE:-$SCRIPT_DIR/services.log}"
PID_DIR="${PID_DIR:-$SCRIPT_DIR/pids}"

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

# Initialize configuration
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "Creating default services configuration"
        mkdir -p "$(dirname "$CONFIG_FILE")"
        mkdir -p "$PID_DIR"
        
        cat > "$CONFIG_FILE" << 'EOF'
{
  "services": {
    "messaging-bridge": {
      "enabled": true,
      "command": "python3",
      "args": ["./mcp-servers/messaging-bridge/server.py"],
      "working_directory": "./",
      "environment": {
        "PYTHONPATH": "."
      },
      "restart_policy": "always",
      "restart_delay": 5,
      "health_check": {
        "enabled": true,
        "command": "ps aux | grep -v grep | grep messaging-bridge",
        "interval": 60
      }
    },
    "database-connector": {
      "enabled": true,
      "command": "python3",
      "args": ["./mcp-servers/database-connector/connector.py"],
      "working_directory": "./",
      "environment": {},
      "restart_policy": "on-failure",
      "restart_delay": 10
    },
    "context-wrapper": {
      "enabled": false,
      "command": "./mcp-servers/context-wrapper/wrapper.sh",
      "args": [],
      "working_directory": "./",
      "environment": {},
      "restart_policy": "manual"
    }
  },
  "global_settings": {
    "max_restart_attempts": 5,
    "health_check_interval": 300,
    "log_rotation": true,
    "log_max_size": "10M"
  }
}
EOF
    fi
}

# Load configuration
load_config() {
    if command -v jq >/dev/null 2>&1; then
        CONFIG=$(cat "$CONFIG_FILE")
    else
        error "jq is required for JSON configuration parsing"
        exit 1
    fi
}

# Get PID file path
get_pid_file() {
    local service_name="$1"
    echo "$PID_DIR/$service_name.pid"
}

# Check if service is running
is_service_running() {
    local service_name="$1"
    local pid_file
    pid_file=$(get_pid_file "$service_name")
    
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        if ps -p "$pid" >/dev/null 2>&1; then
            return 0
        else
            # Stale PID file
            rm -f "$pid_file"
            return 1
        fi
    fi
    return 1
}

# Start service
start_service() {
    local service_name="$1"
    local service_config
    
    service_config=$(echo "$CONFIG" | jq -r --arg name "$service_name" '.services[$name]')
    
    if [[ "$service_config" == "null" ]]; then
        error "Service not found: $service_name"
        return 1
    fi
    
    local enabled
    enabled=$(echo "$service_config" | jq -r '.enabled')
    if [[ "$enabled" != "true" ]]; then
        log "Service disabled: $service_name"
        return 1
    fi
    
    if is_service_running "$service_name"; then
        log "Service already running: $service_name"
        return 0
    fi
    
    log "Starting service: $service_name"
    
    # Extract service configuration
    local command
    command=$(echo "$service_config" | jq -r '.command')
    
    local args
    mapfile -t args < <(echo "$service_config" | jq -r '.args[]?')
    
    local working_dir
    working_dir=$(echo "$service_config" | jq -r '.working_directory // "."')
    working_dir=$(realpath "$working_dir")
    
    # Set up environment
    local env_vars
    env_vars=$(echo "$service_config" | jq -r '.environment // {} | to_entries[] | "\(.key)=\(.value)"')
    
    # Create log file for service
    local service_log="$SCRIPT_DIR/$service_name.log"
    
    # Start service in background
    (
        cd "$working_dir"
        
        # Set environment variables
        while IFS= read -r env_var; do
            if [[ -n "$env_var" ]]; then
                export "$env_var"
            fi
        done <<< "$env_vars"
        
        # Start the service
        exec "$command" "${args[@]}" >>"$service_log" 2>&1
    ) &
    
    local pid=$!
    local pid_file
    pid_file=$(get_pid_file "$service_name")
    echo "$pid" > "$pid_file"
    
    # Wait a moment to see if it started successfully
    sleep 2
    
    if is_service_running "$service_name"; then
        log "Service started successfully: $service_name (PID: $pid)"
        return 0
    else
        error "Failed to start service: $service_name"
        return 1
    fi
}

# Stop service
stop_service() {
    local service_name="$1"
    local pid_file
    pid_file=$(get_pid_file "$service_name")
    
    if [[ ! -f "$pid_file" ]]; then
        log "Service not running: $service_name"
        return 0
    fi
    
    local pid
    pid=$(cat "$pid_file")
    
    if ! ps -p "$pid" >/dev/null 2>&1; then
        log "Service not running (stale PID): $service_name"
        rm -f "$pid_file"
        return 0
    fi
    
    log "Stopping service: $service_name (PID: $pid)"
    
    # Try graceful shutdown first
    kill -TERM "$pid" 2>/dev/null || true
    
    # Wait up to 10 seconds for graceful shutdown
    local count=0
    while ps -p "$pid" >/dev/null 2>&1 && [[ $count -lt 10 ]]; do
        sleep 1
        ((count++))
    done
    
    # Force kill if still running
    if ps -p "$pid" >/dev/null 2>&1; then
        log "Force killing service: $service_name"
        kill -KILL "$pid" 2>/dev/null || true
        sleep 1
    fi
    
    rm -f "$pid_file"
    log "Service stopped: $service_name"
}

# Restart service
restart_service() {
    local service_name="$1"
    
    log "Restarting service: $service_name"
    stop_service "$service_name"
    sleep 2
    start_service "$service_name"
}

# Get service status
get_service_status() {
    local service_name="$1"
    local service_config
    
    service_config=$(echo "$CONFIG" | jq -r --arg name "$service_name" '.services[$name]')
    
    if [[ "$service_config" == "null" ]]; then
        echo "not_configured"
        return
    fi
    
    local enabled
    enabled=$(echo "$service_config" | jq -r '.enabled')
    
    if [[ "$enabled" != "true" ]]; then
        echo "disabled"
        return
    fi
    
    if is_service_running "$service_name"; then
        echo "running"
    else
        echo "stopped"
    fi
}

# List all services
list_services() {
    local services
    services=$(echo "$CONFIG" | jq -r '.services | keys[]')
    
    printf "%-20s %-10s %-10s %s\n" "SERVICE" "STATUS" "ENABLED" "PID"
    printf "%-20s %-10s %-10s %s\n" "-------" "------" "-------" "---"
    
    while IFS= read -r service_name; do
        local service_config
        service_config=$(echo "$CONFIG" | jq -r --arg name "$service_name" '.services[$name]')
        
        local enabled
        enabled=$(echo "$service_config" | jq -r '.enabled')
        
        local status
        status=$(get_service_status "$service_name")
        
        local pid="N/A"
        if [[ "$status" == "running" ]]; then
            local pid_file
            pid_file=$(get_pid_file "$service_name")
            if [[ -f "$pid_file" ]]; then
                pid=$(cat "$pid_file")
            fi
        fi
        
        printf "%-20s %-10s %-10s %s\n" "$service_name" "$status" "$enabled" "$pid"
    done <<< "$services"
}

# Health check for all services
health_check() {
    log "Running health checks"
    
    local services
    services=$(echo "$CONFIG" | jq -r '.services | to_entries[] | select(.value.enabled == true) | .key')
    
    while IFS= read -r service_name; do
        local service_config
        service_config=$(echo "$CONFIG" | jq -r --arg name "$service_name" '.services[$name]')
        
        local health_check_enabled
        health_check_enabled=$(echo "$service_config" | jq -r '.health_check.enabled // false')
        
        if [[ "$health_check_enabled" == "true" ]]; then
            local health_command
            health_command=$(echo "$service_config" | jq -r '.health_check.command // ""')
            
            if [[ -n "$health_command" ]]; then
                if eval "$health_command" >/dev/null 2>&1; then
                    log "Health check passed: $service_name"
                else
                    log "Health check failed: $service_name"
                    
                    local restart_policy
                    restart_policy=$(echo "$service_config" | jq -r '.restart_policy // "manual"')
                    
                    if [[ "$restart_policy" == "always" ]] || [[ "$restart_policy" == "on-failure" ]]; then
                        log "Attempting restart: $service_name"
                        restart_service "$service_name"
                    fi
                fi
            fi
        else
            # Simple running check
            if ! is_service_running "$service_name"; then
                log "Service not running: $service_name"
                
                local restart_policy
                restart_policy=$(echo "$service_config" | jq -r '.restart_policy // "manual"')
                
                if [[ "$restart_policy" == "always" ]]; then
                    log "Attempting restart: $service_name"
                    start_service "$service_name"
                fi
            fi
        fi
    done <<< "$services"
}

# Show service logs
show_logs() {
    local service_name="$1"
    local lines="${2:-50}"
    
    local service_log="$SCRIPT_DIR/$service_name.log"
    
    if [[ -f "$service_log" ]]; then
        tail -n "$lines" "$service_log"
    else
        error "Log file not found: $service_log"
    fi
}

# Main function
main() {
    local command="${1:-help}"
    
    # Initialize configuration
    init_config
    load_config
    
    case "$command" in
        start)
            if [[ $# -eq 2 ]]; then
                start_service "$2"
            else
                # Start all enabled services
                local services
                services=$(echo "$CONFIG" | jq -r '.services | to_entries[] | select(.value.enabled == true) | .key')
                while IFS= read -r service_name; do
                    start_service "$service_name"
                done <<< "$services"
            fi
            ;;
        stop)
            if [[ $# -eq 2 ]]; then
                stop_service "$2"
            else
                # Stop all services
                local services
                services=$(echo "$CONFIG" | jq -r '.services | keys[]')
                while IFS= read -r service_name; do
                    if is_service_running "$service_name"; then
                        stop_service "$service_name"
                    fi
                done <<< "$services"
            fi
            ;;
        restart)
            if [[ $# -eq 2 ]]; then
                restart_service "$2"
            else
                error "Please specify service name: $0 restart <service_name>"
                exit 1
            fi
            ;;
        status)
            if [[ $# -eq 2 ]]; then
                local status
                status=$(get_service_status "$2")
                echo "$2: $status"
            else
                list_services
            fi
            ;;
        logs)
            if [[ $# -eq 2 ]]; then
                show_logs "$2"
            elif [[ $# -eq 3 ]]; then
                show_logs "$2" "$3"
            else
                error "Usage: $0 logs <service_name> [lines]"
                exit 1
            fi
            ;;
        health)
            health_check
            ;;
        list|ls)
            list_services
            ;;
        help|--help|-h)
            cat << EOF
Universal Service/Daemon Manager

Manage long-running services, MCP servers, and background processes.

Usage: $0 <command> [arguments]

COMMANDS:
  start [service]       Start service(s)
  stop [service]        Stop service(s)
  restart <service>     Restart specific service
  status [service]      Show service status
  logs <service> [n]    Show service logs (last n lines)
  health               Run health checks
  list                 List all services
  help                 Show this help

EXAMPLES:
  $0 start                    # Start all enabled services
  $0 start messaging-bridge   # Start specific service
  $0 stop                     # Stop all services
  $0 status                   # Show all service statuses
  $0 logs messaging-bridge 100 # Show last 100 log lines
  $0 health                   # Run health checks

CONFIGURATION:
  Edit $CONFIG_FILE to configure services, restart policies, and health checks.

EOF
            ;;
        *)
            error "Unknown command: $command"
            main help
            exit 1
            ;;
    esac
}

# Signal handlers for graceful shutdown
cleanup() {
    log "Received shutdown signal, stopping all services..."
    main stop
}

trap cleanup EXIT INT TERM

# Run main function
main "$@"