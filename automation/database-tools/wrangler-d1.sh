#!/bin/bash

# Wrangler D1 Helper Script
# Simplified management tool for Cloudflare D1 databases via Wrangler CLI
# Usage: ./wrangler-d1.sh <command> <database> [sql_query]

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration - Use environment variables for security
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo -e "${RED}❌ CLOUDFLARE_API_TOKEN not set${NC}"
    echo "Please export your Cloudflare API token:"
    echo "  export CLOUDFLARE_API_TOKEN=\"your_token_here\""
    exit 1
fi

if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ CLOUDFLARE_ACCOUNT_ID not set${NC}"
    echo "Please export your Cloudflare account ID:"
    echo "  export CLOUDFLARE_ACCOUNT_ID=\"your_account_id_here\""
    exit 1
fi

# Available databases (customize for your use case)
declare -A DATABASES
DATABASES[core]="app_core"
DATABASES[medical]="app_medical"
DATABASES[distribution]="app_distribution"
DATABASES[logistics]="app_logistics"

show_help() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          🗄️  WRANGLER D1 HELPER SCRIPT                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC} $0 <command> [options]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  list                - List all D1 databases"
    echo "  tables <db>         - List tables in a database"
    echo "  query <db> \"<SQL>\"  - Execute a SQL query"
    echo "  count <db>          - Count main table entries"
    echo "  info <db>           - Show detailed database info"
    echo ""
    echo -e "${YELLOW}Available databases:${NC}"
    echo "  core         → app_core"
    echo "  medical      → app_medical"
    echo "  distribution → app_distribution"
    echo "  logistics    → app_logistics"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 list"
    echo "  $0 tables core"
    echo "  $0 query medical \"SELECT * FROM patients LIMIT 10\""
}

cmd_list() {
    echo -e "${CYAN}📋 D1 Databases:${NC}"
    wrangler d1 list
}

cmd_tables() {
    local db_key=$1
    local db_name=${DATABASES[$db_key]}
    [ -z "$db_name" ] && echo -e "${RED}❌ Invalid database${NC}" && exit 1
    echo -e "${CYAN}📊 Tables in ${db_name}:${NC}"
    wrangler d1 execute "$db_name" --remote --command "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
}

cmd_query() {
    local db_key=$1
    local sql=$2
    local db_name=${DATABASES[$db_key]}
    [ -z "$db_name" ] && echo -e "${RED}❌ Invalid database${NC}" && exit 1
    [ -z "$sql" ] && echo -e "${RED}❌ SQL query required${NC}" && exit 1
    echo -e "${CYAN}🔍 Executing on ${db_name}:${NC}"
    wrangler d1 execute "$db_name" --remote --command "$sql"
}

cmd_count() {
    local db_key=$1
    local db_name=${DATABASES[$db_key]}
    [ -z "$db_name" ] && echo -e "${RED}❌ Invalid database${NC}" && exit 1
    echo -e "${CYAN}📈 Entry counts for ${db_name}:${NC}"
    case $db_key in
        core)
            wrangler d1 execute "$db_name" --remote --command "SELECT 'users' as table_name, COUNT(*) as count FROM users UNION ALL SELECT 'projects', COUNT(*) FROM projects"
            ;;
        medical)
            wrangler d1 execute "$db_name" --remote --command "SELECT 'patients' as table_name, COUNT(*) as count FROM patients UNION ALL SELECT 'encounters', COUNT(*) FROM encounters"
            ;;
        *)
            wrangler d1 execute "$db_name" --remote --command "SELECT name, COUNT(*) FROM sqlite_master WHERE type='table' GROUP BY name"
            ;;
    esac
}

cmd_info() {
    local db_key=$1
    local db_name=${DATABASES[$db_key]}
    [ -z "$db_name" ] && echo -e "${RED}❌ Invalid database${NC}" && exit 1
    echo -e "${CYAN}ℹ️  Info for ${db_name}:${NC}"
    wrangler d1 info "$db_name"
}

COMMAND=$1
shift

case $COMMAND in
    list) cmd_list ;;
    tables) cmd_tables "$@" ;;
    query) cmd_query "$@" ;;
    count) cmd_count "$@" ;;
    info) cmd_info "$@" ;;
    *) show_help && exit 1 ;;
esac
