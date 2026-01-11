#!/bin/bash

# Context7 MCP Wrapper
# Universal wrapper script for Context7 MCP server with flexible configuration

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-${SCRIPT_DIR}/config.json}"
LOG_FILE="${LOG_FILE:-${SCRIPT_DIR}/context7.log}"

# Default configuration
DEFAULT_NODE_VERSION="18"
DEFAULT_PACKAGE="@upstash/context7-mcp"
DEFAULT_REGISTRY="https://registry.npmjs.org"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
    exit 1
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "Loading configuration from $CONFIG_FILE"
        
        # Parse JSON config (requires jq, fallback to default if not available)
        if command -v jq >/dev/null 2>&1; then
            NODE_VERSION=$(jq -r '.node_version // "18"' "$CONFIG_FILE")
            PACKAGE=$(jq -r '.package // "@upstash/context7-mcp"' "$CONFIG_FILE")
            REGISTRY=$(jq -r '.registry // "https://registry.npmjs.org"' "$CONFIG_FILE")
            INSTALL_GLOBALLY=$(jq -r '.install_globally // false' "$CONFIG_FILE")
        else
            log "jq not found, using default configuration"
            NODE_VERSION="$DEFAULT_NODE_VERSION"
            PACKAGE="$DEFAULT_PACKAGE"
            REGISTRY="$DEFAULT_REGISTRY"
            INSTALL_GLOBALLY=false
        fi
    else
        log "No config file found, using defaults"
        NODE_VERSION="$DEFAULT_NODE_VERSION"
        PACKAGE="$DEFAULT_PACKAGE" 
        REGISTRY="$DEFAULT_REGISTRY"
        INSTALL_GLOBALLY=false
        
        # Create default config
        cat > "$CONFIG_FILE" << EOF
{
  "node_version": "18",
  "package": "@upstash/context7-mcp",
  "registry": "https://registry.npmjs.org",
  "install_globally": false,
  "environment": {
    "NODE_ENV": "production"
  },
  "upstash": {
    "redis_url": "\${UPSTASH_REDIS_REST_URL}",
    "redis_token": "\${UPSTASH_REDIS_REST_TOKEN}",
    "vector_url": "\${UPSTASH_VECTOR_REST_URL}",
    "vector_token": "\${UPSTASH_VECTOR_REST_TOKEN}"
  }
}
EOF
        log "Created default configuration at $CONFIG_FILE"
    fi
}

# Setup Node.js environment
setup_node() {
    log "Setting up Node.js environment"
    
    # Try different Node.js version managers
    if [[ -d "$HOME/.nvm" ]]; then
        log "Using NVM for Node.js management"
        export NVM_DIR="$HOME/.nvm"
        
        # Load NVM
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            # shellcheck source=/dev/null
            source "$NVM_DIR/nvm.sh"
        else
            error "NVM not properly installed"
        fi
        
        # Load NVM bash completion (optional)
        if [[ -s "$NVM_DIR/bash_completion" ]]; then
            # shellcheck source=/dev/null
            source "$NVM_DIR/bash_completion"
        fi
        
        # Use specified Node version
        if ! nvm use "$NODE_VERSION" >/dev/null 2>&1; then
            log "Installing Node.js $NODE_VERSION"
            nvm install "$NODE_VERSION"
            nvm use "$NODE_VERSION"
        fi
        
    elif command -v fnm >/dev/null 2>&1; then
        log "Using fnm for Node.js management"
        eval "$(fnm env)"
        
        if ! fnm use "$NODE_VERSION" >/dev/null 2>&1; then
            log "Installing Node.js $NODE_VERSION with fnm"
            fnm install "$NODE_VERSION"
            fnm use "$NODE_VERSION"
        fi
        
    elif command -v n >/dev/null 2>&1; then
        log "Using n for Node.js management"
        n "$NODE_VERSION"
        
    elif command -v node >/dev/null 2>&1; then
        log "Using system Node.js $(node --version)"
        
        # Check if version meets minimum requirements
        CURRENT_VERSION=$(node --version | sed 's/v//')
        if [[ "$(printf '%s\n' "$NODE_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" != "$NODE_VERSION" ]]; then
            log "Warning: Node.js $CURRENT_VERSION may not be compatible. Recommended: $NODE_VERSION+"
        fi
        
    else
        error "Node.js not found. Please install Node.js $NODE_VERSION+ or a Node version manager (nvm, fnm, n)"
    fi
    
    # Verify Node.js installation
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js not available after setup"
    fi
    
    log "Using Node.js $(node --version) at $(which node)"
}

# Install or update Context7 MCP
install_context7() {
    log "Installing/updating Context7 MCP package"
    
    # Set registry if specified
    if [[ "$REGISTRY" != "$DEFAULT_REGISTRY" ]]; then
        npm config set registry "$REGISTRY"
    fi
    
    # Install package
    if [[ "$INSTALL_GLOBALLY" == "true" ]]; then
        log "Installing globally: npm install -g $PACKAGE"
        npm install -g "$PACKAGE"
    else
        log "Using npx for execution: $PACKAGE"
        # npx will handle installation automatically
    fi
}

# Validate environment
validate_environment() {
    log "Validating environment"

    # Map REST env vars to legacy names and vice versa for compatibility
    if [[ -z "${UPSTASH_REDIS_URL:-}" && -n "${UPSTASH_REDIS_REST_URL:-}" ]]; then
        export UPSTASH_REDIS_URL="$UPSTASH_REDIS_REST_URL"
    fi
    if [[ -z "${UPSTASH_REDIS_REST_URL:-}" && -n "${UPSTASH_REDIS_URL:-}" ]]; then
        export UPSTASH_REDIS_REST_URL="$UPSTASH_REDIS_URL"
    fi
    if [[ -z "${UPSTASH_REDIS_TOKEN:-}" && -n "${UPSTASH_REDIS_REST_TOKEN:-}" ]]; then
        export UPSTASH_REDIS_TOKEN="$UPSTASH_REDIS_REST_TOKEN"
    fi
    if [[ -z "${UPSTASH_REDIS_REST_TOKEN:-}" && -n "${UPSTASH_REDIS_TOKEN:-}" ]]; then
        export UPSTASH_REDIS_REST_TOKEN="$UPSTASH_REDIS_TOKEN"
    fi
    if [[ -z "${UPSTASH_VECTOR_URL:-}" && -n "${UPSTASH_VECTOR_REST_URL:-}" ]]; then
        export UPSTASH_VECTOR_URL="$UPSTASH_VECTOR_REST_URL"
    fi
    if [[ -z "${UPSTASH_VECTOR_REST_URL:-}" && -n "${UPSTASH_VECTOR_URL:-}" ]]; then
        export UPSTASH_VECTOR_REST_URL="$UPSTASH_VECTOR_URL"
    fi
    if [[ -z "${UPSTASH_VECTOR_TOKEN:-}" && -n "${UPSTASH_VECTOR_REST_TOKEN:-}" ]]; then
        export UPSTASH_VECTOR_TOKEN="$UPSTASH_VECTOR_REST_TOKEN"
    fi
    if [[ -z "${UPSTASH_VECTOR_REST_TOKEN:-}" && -n "${UPSTASH_VECTOR_TOKEN:-}" ]]; then
        export UPSTASH_VECTOR_REST_TOKEN="$UPSTASH_VECTOR_TOKEN"
    fi

    # Check required environment variables for Upstash
    local required_vars=()
    
    # Check if config specifies required environment variables
    if [[ -f "$CONFIG_FILE" ]] && command -v jq >/dev/null 2>&1; then
        # Extract environment variables from config
        while IFS= read -r var; do
            if [[ "$var" =~ ^\$\{(.+)\}$ ]]; then
                var_name="${BASH_REMATCH[1]}"
                if [[ -z "${!var_name:-}" ]]; then
                    required_vars+=("$var_name")
                fi
            fi
        done < <(jq -r '.upstash | to_entries | .[].value' "$CONFIG_FILE" 2>/dev/null | grep '${' || true)
    fi
    
    if [[ ${#required_vars[@]} -gt 0 ]]; then
        log "Warning: Missing environment variables: ${required_vars[*]}"
        log "Context7 may not function properly without Upstash credentials"
        log "Set the following environment variables:"
        for var in "${required_vars[@]}"; do
            log "  export $var=\"your_${var,,}_here\""
        done
    fi
    
    # Check network connectivity (optional)
    if command -v curl >/dev/null 2>&1; then
        if ! curl -s --connect-timeout 5 "https://registry.npmjs.org" >/dev/null 2>&1; then
            log "Warning: Cannot reach npm registry. Check internet connection"
        fi
    fi
}

# Health check
health_check() {
    log "Performing health check"
    
    # Check if Context7 package is accessible
    if [[ "$INSTALL_GLOBALLY" == "true" ]]; then
        if ! command -v context7-mcp >/dev/null 2>&1; then
            log "Warning: context7-mcp not found in PATH"
            return 1
        fi
    else
        if ! npx --yes "$PACKAGE" --help >/dev/null 2>&1; then
            log "Warning: Cannot execute $PACKAGE via npx"
            return 1
        fi
    fi
    
    return 0
}

# Execute Context7 MCP
execute_context7() {
    log "Starting Context7 MCP server with args: $*"
    
    # Set environment from config
    if [[ -f "$CONFIG_FILE" ]] && command -v jq >/dev/null 2>&1; then
        while IFS="=" read -r key value; do
            if [[ -n "$key" && -n "$value" ]]; then
                export "$key"="$value"
                log "Set environment: $key"
            fi
        done < <(jq -r '.environment // {} | to_entries | .[] | "\(.key)=\(.value)"' "$CONFIG_FILE" 2>/dev/null || true)
    fi
    
    # Execute the MCP server
    if [[ "$INSTALL_GLOBALLY" == "true" ]]; then
        exec context7-mcp "$@"
    else
        exec npx --yes "$PACKAGE" "$@"
    fi
}

# Cleanup function
cleanup() {
    log "Shutting down Context7 MCP wrapper"
}

# Signal handlers
trap cleanup EXIT INT TERM

# Main execution
main() {
    log "Starting Context7 MCP Wrapper"
    log "Script directory: $SCRIPT_DIR"
    log "Config file: $CONFIG_FILE"
    log "Log file: $LOG_FILE"
    
    # Load configuration
    load_config
    
    # Setup Node.js
    setup_node
    
    # Install Context7 if needed
    install_context7
    
    # Validate environment
    validate_environment
    
    # Health check
    if ! health_check; then
        log "Health check failed, but continuing anyway"
    fi
    
    # Execute Context7 MCP server
    execute_context7 "$@"
}

# Help function
show_help() {
    cat << EOF
Context7 MCP Wrapper

Usage: $0 [OPTIONS] [MCP_ARGS...]

OPTIONS:
  -h, --help           Show this help message
  -c, --config FILE    Use specific config file
  -l, --log FILE       Use specific log file
  --install-global     Install Context7 globally
  --health-check       Run health check only
  --version           Show version information

ENVIRONMENT VARIABLES:
  CONFIG_FILE         Path to configuration file
  LOG_FILE           Path to log file
  UPSTASH_REDIS_REST_URL   Upstash Redis REST URL
  UPSTASH_REDIS_REST_TOKEN Upstash Redis REST token
  UPSTASH_VECTOR_REST_URL  Upstash Vector REST URL
  UPSTASH_VECTOR_REST_TOKEN Upstash Vector REST token
  UPSTASH_REDIS_URL        Legacy alias for Redis REST URL
  UPSTASH_REDIS_TOKEN      Legacy alias for Redis REST token
  UPSTASH_VECTOR_URL       Legacy alias for Vector REST URL
  UPSTASH_VECTOR_TOKEN     Legacy alias for Vector REST token

EXAMPLES:
  $0                          # Start with default configuration
  $0 -c /path/to/config.json  # Use specific config file
  $0 --health-check           # Run health check only
  $0 --install-global         # Install globally and start

CONFIGURATION:
  Edit $CONFIG_FILE to customize:
  - Node.js version
  - Package version/source
  - Registry URL
  - Environment variables
  - Upstash credentials

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
        --install-global)
            INSTALL_GLOBALLY=true
            shift
            ;;
        --health-check)
            load_config
            setup_node
            install_context7
            health_check
            exit $?
            ;;
        --version)
            echo "Context7 MCP Wrapper v1.0.0"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            log "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Run main function with remaining arguments
main "$@"
