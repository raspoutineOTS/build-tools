#!/bin/bash

# Smart Monitor Hook
# Universal monitoring system for Claude Code with configurable triggers and actions

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/monitor-config.json}"
LOG_FILE="${LOG_FILE:-$SCRIPT_DIR/monitor.log}"
STATE_FILE="${STATE_FILE:-$SCRIPT_DIR/monitor-state.json}"

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

debug() {
    if [[ "${DEBUG:-}" == "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $*" | tee -a "$LOG_FILE"
    fi
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

# Initialize configuration
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "Creating default monitor configuration"
        cat > "$CONFIG_FILE" << 'EOF'
{
  "monitors": {
    "database_activity": {
      "enabled": true,
      "database_path": "${HOME}/.messaging-bridge/messages.db",
      "table": "messages",
      "check_interval": 300,
      "threshold": {
        "new_records": 1,
        "time_window": 3600
      },
      "actions": ["trigger_processor"]
    },
    "file_watcher": {
      "enabled": true,
      "watch_paths": [
        "${HOME}/Documents/incoming",
        "${HOME}/Downloads"
      ],
      "file_patterns": ["*.pdf", "*.docx", "*.txt", "*.csv"],
      "actions": ["process_document"]
    },
    "system_health": {
      "enabled": true,
      "checks": ["disk_space", "memory_usage", "process_health"],
      "thresholds": {
        "disk_usage_percent": 85,
        "memory_usage_percent": 90,
        "max_processes": 50
      },
      "actions": ["send_alert", "cleanup_temp"]
    }
  },
  "actions": {
    "trigger_processor": {
      "type": "agent_call",
      "agent": "message-processor",
      "message": "New activity detected - analyze recent data and process accordingly"
    },
    "process_document": {
      "type": "script",
      "command": "./automation/document-processor/process-file.sh",
      "args": ["${FILE_PATH}"]
    },
    "send_alert": {
      "type": "notification",
      "method": "system_message",
      "template": "🚨 System Alert: ${ALERT_TYPE} - ${DETAILS}"
    },
    "cleanup_temp": {
      "type": "script",
      "command": "find ${HOME}/.cache -name '*.tmp' -mtime +1 -delete"
    }
  },
  "settings": {
    "global_enabled": true,
    "log_level": "info",
    "max_log_size": "10M",
    "state_retention_days": 7
  }
}
EOF
    fi

    # Initialize state file
    if [[ ! -f "$STATE_FILE" ]]; then
        echo '{"last_checks": {}, "counters": {}, "alerts": []}' > "$STATE_FILE"
    fi
}

# Load and parse configuration
load_config() {
    if command -v jq >/dev/null 2>&1; then
        CONFIG=$(cat "$CONFIG_FILE")
    else
        error "jq is required for JSON configuration parsing"
        exit 1
    fi
}

# Expand environment variables in configuration values
expand_env_vars() {
    local value="$1"
    # Simple environment variable expansion
    while [[ "$value" =~ \$\{([^}]+)\} ]]; do
        local var="${BASH_REMATCH[1]}"
        local replacement="${!var:-}"
        value="${value/\$\{$var\}/$replacement}"
    done
    echo "$value"
}

# Update state file
update_state() {
    local key="$1"
    local value="$2"
    
    if command -v jq >/dev/null 2>&1; then
        local temp_state
        temp_state=$(mktemp)
        jq --arg key "$key" --arg value "$value" '.last_checks[$key] = $value' "$STATE_FILE" > "$temp_state"
        mv "$temp_state" "$STATE_FILE"
    fi
}

# Get last check time
get_last_check() {
    local monitor="$1"
    
    if command -v jq >/dev/null 2>&1 && [[ -f "$STATE_FILE" ]]; then
        jq -r --arg monitor "$monitor" '.last_checks[$monitor] // "0"' "$STATE_FILE"
    else
        echo "0"
    fi
}

# Database activity monitor
monitor_database_activity() {
    local config="$1"
    local monitor_name="database_activity"
    
    debug "Checking database activity monitor"
    
    # Extract configuration
    local db_path
    db_path=$(echo "$config" | jq -r '.database_path' | xargs -I {} bash -c 'echo {}')
    db_path=$(expand_env_vars "$db_path")
    
    local table
    table=$(echo "$config" | jq -r '.table')
    
    local threshold
    threshold=$(echo "$config" | jq -r '.threshold.new_records')
    
    local time_window
    time_window=$(echo "$config" | jq -r '.threshold.time_window')
    
    if [[ ! -f "$db_path" ]]; then
        debug "Database file not found: $db_path"
        return 0
    fi
    
    # Query for new records
    local current_time
    current_time=$(date +%s)
    local cutoff_time
    cutoff_time=$((current_time - time_window))
    local cutoff_datetime
    cutoff_datetime=$(date -d "@$cutoff_time" '+%Y-%m-%d %H:%M:%S')
    
    local new_count
    new_count=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM $table WHERE timestamp > '$cutoff_datetime'" 2>/dev/null || echo "0")
    
    debug "Found $new_count new records in $table table"
    
    if [[ "$new_count" -ge "$threshold" ]]; then
        log "Database activity trigger: $new_count new records (threshold: $threshold)"
        
        # Execute configured actions
        local actions
        actions=$(echo "$config" | jq -r '.actions[]')
        
        while IFS= read -r action; do
            execute_action "$action" "database_activity" "$new_count new records detected"
        done <<< "$actions"
    fi
    
    update_state "$monitor_name" "$current_time"
}

# File watcher monitor
monitor_file_watcher() {
    local config="$1"
    local monitor_name="file_watcher"
    
    debug "Checking file watcher monitor"
    
    local watch_paths
    watch_paths=$(echo "$config" | jq -r '.watch_paths[]')
    
    local file_patterns
    file_patterns=$(echo "$config" | jq -r '.file_patterns[]')
    
    local last_check
    last_check=$(get_last_check "$monitor_name")
    
    # Check for new files
    local new_files=()
    
    while IFS= read -r path; do
        local expanded_path
        expanded_path=$(expand_env_vars "$path")
        
        if [[ -d "$expanded_path" ]]; then
            while IFS= read -r pattern; do
                while IFS= read -r -d '' file; do
                    local file_mtime
                    file_mtime=$(stat -c %Y "$file" 2>/dev/null || echo "0")
                    
                    if [[ "$file_mtime" -gt "$last_check" ]]; then
                        new_files+=("$file")
                        debug "Found new file: $file"
                    fi
                done < <(find "$expanded_path" -name "$pattern" -type f -print0 2>/dev/null || true)
            done <<< "$file_patterns"
        fi
    done <<< "$watch_paths"
    
    if [[ ${#new_files[@]} -gt 0 ]]; then
        log "File watcher trigger: ${#new_files[@]} new files detected"
        
        # Execute actions for each new file
        local actions
        actions=$(echo "$config" | jq -r '.actions[]')
        
        for file in "${new_files[@]}"; do
            while IFS= read -r action; do
                execute_action "$action" "file_watcher" "$file"
            done <<< "$actions"
        done
    fi
    
    update_state "$monitor_name" "$(date +%s)"
}

# System health monitor
monitor_system_health() {
    local config="$1"
    local monitor_name="system_health"
    
    debug "Checking system health monitor"
    
    local checks
    checks=$(echo "$config" | jq -r '.checks[]')
    
    local alerts=()
    
    while IFS= read -r check; do
        case "$check" in
            "disk_space")
                local disk_threshold
                disk_threshold=$(echo "$config" | jq -r '.thresholds.disk_usage_percent')
                
                local disk_usage
                disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
                
                if [[ "$disk_usage" -gt "$disk_threshold" ]]; then
                    alerts+=("Disk usage: ${disk_usage}% (threshold: ${disk_threshold}%)")
                fi
                ;;
                
            "memory_usage")
                local memory_threshold
                memory_threshold=$(echo "$config" | jq -r '.thresholds.memory_usage_percent')
                
                local memory_usage
                memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
                
                if [[ "$memory_usage" -gt "$memory_threshold" ]]; then
                    alerts+=("Memory usage: ${memory_usage}% (threshold: ${memory_threshold}%)")
                fi
                ;;
                
            "process_health")
                local max_processes
                max_processes=$(echo "$config" | jq -r '.thresholds.max_processes')
                
                local process_count
                process_count=$(pgrep -f "claude|mcp" | wc -l)
                
                if [[ "$process_count" -gt "$max_processes" ]]; then
                    alerts+=("Too many processes: $process_count (max: $max_processes)")
                fi
                ;;
        esac
    done <<< "$checks"
    
    if [[ ${#alerts[@]} -gt 0 ]]; then
        log "System health alerts: ${#alerts[@]} issues detected"
        
        local actions
        actions=$(echo "$config" | jq -r '.actions[]')
        
        for alert in "${alerts[@]}"; do
            while IFS= read -r action; do
                execute_action "$action" "system_health" "$alert"
            done <<< "$actions"
        done
    fi
    
    update_state "$monitor_name" "$(date +%s)"
}

# Execute configured action
execute_action() {
    local action_name="$1"
    local trigger_type="$2"
    local context="$3"
    
    debug "Executing action: $action_name (trigger: $trigger_type)"
    
    # Get action configuration
    local action_config
    action_config=$(echo "$CONFIG" | jq -r --arg name "$action_name" '.actions[$name]')
    
    if [[ "$action_config" == "null" ]]; then
        error "Action not found: $action_name"
        return 1
    fi
    
    local action_type
    action_type=$(echo "$action_config" | jq -r '.type')
    
    case "$action_type" in
        "agent_call")
            local agent
            agent=$(echo "$action_config" | jq -r '.agent')
            local message
            message=$(echo "$action_config" | jq -r '.message')
            
            # Replace variables in message
            message="${message//\$\{TRIGGER_TYPE\}/$trigger_type}"
            message="${message//\$\{CONTEXT\}/$context}"
            
            log "Triggering agent: @$agent $message"
            echo "@$agent $message"
            ;;
            
        "script")
            local command
            command=$(echo "$action_config" | jq -r '.command')
            local args
            args=$(echo "$action_config" | jq -r '.args[]? // empty')
            
            # Expand variables
            command=$(expand_env_vars "$command")
            
            # Replace context variable in args
            local expanded_args=()
            while IFS= read -r arg; do
                arg="${arg//\$\{FILE_PATH\}/$context}"
                arg="${arg//\$\{CONTEXT\}/$context}"
                expanded_args+=("$(expand_env_vars "$arg")")
            done <<< "$args"
            
            log "Executing script: $command ${expanded_args[*]}"
            
            if [[ -x "$command" ]]; then
                "$command" "${expanded_args[@]}" || error "Script execution failed: $command"
            else
                error "Script not executable: $command"
            fi
            ;;
            
        "notification")
            local method
            method=$(echo "$action_config" | jq -r '.method')
            local template
            template=$(echo "$action_config" | jq -r '.template')
            
            # Replace variables in template
            local message
            message="${template//\$\{ALERT_TYPE\}/$trigger_type}"
            message="${message//\$\{DETAILS\}/$context}"
            
            case "$method" in
                "system_message")
                    echo "{\"systemMessage\": \"$message\"}"
                    ;;
                "log")
                    log "NOTIFICATION: $message"
                    ;;
            esac
            ;;
            
        *)
            error "Unknown action type: $action_type"
            ;;
    esac
}

# Main monitoring loop
run_monitors() {
    local global_enabled
    global_enabled=$(echo "$CONFIG" | jq -r '.settings.global_enabled')
    
    if [[ "$global_enabled" != "true" ]]; then
        debug "Global monitoring disabled"
        return 0
    fi
    
    # Get list of enabled monitors
    local monitors
    monitors=$(echo "$CONFIG" | jq -r '.monitors | to_entries[] | select(.value.enabled == true) | .key')
    
    while IFS= read -r monitor_name; do
        debug "Running monitor: $monitor_name"
        
        local monitor_config
        monitor_config=$(echo "$CONFIG" | jq -r --arg name "$monitor_name" '.monitors[$name]')
        
        case "$monitor_name" in
            "database_activity")
                monitor_database_activity "$monitor_config"
                ;;
            "file_watcher")
                monitor_file_watcher "$monitor_config"
                ;;
            "system_health")
                monitor_system_health "$monitor_config"
                ;;
            *)
                error "Unknown monitor: $monitor_name"
                ;;
        esac
    done <<< "$monitors"
}

# Cleanup old state data
cleanup_state() {
    local retention_days
    retention_days=$(echo "$CONFIG" | jq -r '.settings.state_retention_days // 7')
    
    local cutoff_time
    cutoff_time=$(($(date +%s) - (retention_days * 24 * 60 * 60)))
    
    if command -v jq >/dev/null 2>&1; then
        local temp_state
        temp_state=$(mktemp)
        jq --arg cutoff "$cutoff_time" '
            .alerts = (.alerts // [] | map(select(.timestamp > ($cutoff | tonumber))))
        ' "$STATE_FILE" > "$temp_state"
        mv "$temp_state" "$STATE_FILE"
    fi
}

# Main execution
main() {
    debug "Smart Monitor Hook started"
    debug "Hook event: ${HOOK_EVENT:-none}"
    debug "Config file: $CONFIG_FILE"
    debug "Log file: $LOG_FILE"
    debug "State file: $STATE_FILE"
    
    # Initialize configuration
    init_config
    
    # Load configuration
    load_config
    
    # Run monitors based on hook event
    case "${HOOK_EVENT:-}" in
        "SessionStart"|"UserPromptSubmit"|"")
            run_monitors
            cleanup_state
            ;;
        *)
            debug "Ignoring hook event: $HOOK_EVENT"
            ;;
    esac
    
    debug "Smart Monitor Hook completed"
}

# Help function
show_help() {
    cat << EOF
Smart Monitor Hook

A universal monitoring system for Claude Code with configurable triggers and actions.

Usage: $0 [OPTIONS]

OPTIONS:
  -h, --help           Show this help message
  -c, --config FILE    Use specific config file
  -l, --log FILE       Use specific log file
  -s, --state FILE     Use specific state file
  --debug             Enable debug logging
  --test              Run all monitors once (test mode)

ENVIRONMENT VARIABLES:
  CONFIG_FILE         Path to configuration file
  LOG_FILE           Path to log file
  STATE_FILE         Path to state file
  HOOK_EVENT         Claude Code hook event type
  DEBUG              Enable debug logging (true/false)

CONFIGURATION:
  Edit $CONFIG_FILE to customize:
  - Monitor types and thresholds
  - Watch paths and patterns
  - Actions and notifications
  - Logging and state settings

EXAMPLES:
  $0                          # Run with default settings
  $0 --debug                  # Run with debug logging
  $0 --test                   # Test all monitors once
  $0 -c custom-config.json    # Use custom config

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -s|--state)
            STATE_FILE="$2"
            shift 2
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --test)
            HOOK_EVENT="test"
            shift
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main