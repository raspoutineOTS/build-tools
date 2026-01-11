# Setup Guide

Complete setup instructions for the Build Tools collection.

## Prerequisites

### Required Software

1. **Python 3.8 or higher**
   ```bash
   python3 --version
   pip install --upgrade pip
   ```

2. **Node.js 18 or higher**
   ```bash
   node --version
   npm --version
   ```

3. **Git**
   ```bash
   git --version
   ```

4. **jq (JSON processor)**
   ```bash
   # Ubuntu/Debian
   sudo apt install jq
   
   # macOS
   brew install jq
   
   # Check installation
   jq --version
   ```

### Optional Tools

1. **UV (Fast Python package manager)**
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. **Docker (for containerized services)**
   ```bash
   docker --version
   ```

## Installation Steps

### 1. Clone and Setup

```bash
# Clone repository
git clone <your-repository-url>
cd build-tools

# Create directories
mkdir -p ~/.messaging-bridge
mkdir -p ~/.database-connector
mkdir -p ~/.claude/agents
```

### 2. Python Dependencies

```bash
# Using pip
pip install mcp sqlite3 asyncio pydantic aiohttp python-docx

# Using uv (recommended)
uv pip install mcp sqlite3 asyncio pydantic aiohttp python-docx
```

### 3. Node.js Dependencies

```bash
# For Context7 wrapper
npm install -g @upstash/context7-mcp

# Or install locally
npm install @upstash/context7-mcp
```

### 4. Environment Configuration

Create `.env` file in project root:

```bash
cat > .env << 'EOF'
# Messaging Platforms
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
DISCORD_BOT_TOKEN=your_discord_bot_token_here  
SLACK_BOT_TOKEN=your_slack_bot_token_here

# Database Connections
DB_USERNAME=your_database_username
DB_PASSWORD=your_database_password

# Cloudflare D1
CLOUDFLARE_ACCOUNT_ID=your_cloudflare_account_id
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token
D1_CORE_DATABASE_ID=your_core_database_id
D1_ANALYTICS_DATABASE_ID=your_analytics_database_id
D1_MESSAGING_DATABASE_ID=your_messaging_database_id

# Context7/Upstash
UPSTASH_REDIS_REST_URL=your_upstash_redis_rest_url
UPSTASH_REDIS_REST_TOKEN=your_upstash_redis_rest_token
UPSTASH_VECTOR_REST_URL=your_upstash_vector_rest_url
UPSTASH_VECTOR_REST_TOKEN=your_upstash_vector_rest_token
EOF

# Secure the file
chmod 600 .env
```

Note: The Context7 wrapper accepts the legacy variable names
`UPSTASH_REDIS_URL`, `UPSTASH_REDIS_TOKEN`, `UPSTASH_VECTOR_URL`, and
`UPSTASH_VECTOR_TOKEN` as aliases for backward compatibility.

### 5. Configuration Files

```bash
# Copy configuration templates
cp configs/mcp-templates/messaging-bridge-config.json ~/.messaging-bridge/config.json
cp configs/mcp-templates/database-connector-config.json ~/.database-connector/config.json

# Copy agents to Claude directory
cp -r agents/* ~/.claude/agents/
```

#### Optional: Choose a Claude settings template

Pick one of the provided settings templates and load it into your Claude Code
configuration workflow:

- Standard agents: `configs/claude-settings/settings-template.json`
- Enhanced agents (audio + multilingual + follow-ups): `configs/claude-settings/settings-template-enhanced.json`
- Domain analyzers (Haiku-optimized): `configs/claude-settings/settings-template-domain-analyzers.json`

See `docs/enhanced-agent-system.md` for enhanced agent usage patterns.

### 6. Claude Code Integration

Add MCP servers to your Claude configuration:

```bash
# Method 1: Using Claude CLI
claude mcp add messaging-bridge ./mcp-servers/messaging-bridge/server.py
claude mcp add database-connector ./mcp-servers/database-connector/connector.py
claude mcp add context-wrapper ./mcp-servers/context-wrapper/wrapper.sh

# Method 2: Manual configuration
# Edit ~/.claude.json and add:
```

```json
{
  "mcpServers": {
    "messaging-bridge": {
      "command": "python3",
      "args": ["./mcp-servers/messaging-bridge/server.py"],
      "env": {
        "PYTHONPATH": "."
      }
    },
    "database-connector": {
      "command": "python3",
      "args": ["./mcp-servers/database-connector/connector.py"],
      "env": {
        "PYTHONPATH": "."
      }
    },
    "context-wrapper": {
      "command": "./mcp-servers/context-wrapper/wrapper.sh",
      "env": {
        "UPSTASH_REDIS_REST_URL": "${UPSTASH_REDIS_REST_URL}",
        "UPSTASH_REDIS_REST_TOKEN": "${UPSTASH_REDIS_REST_TOKEN}",
        "UPSTASH_VECTOR_REST_URL": "${UPSTASH_VECTOR_REST_URL}",
        "UPSTASH_VECTOR_REST_TOKEN": "${UPSTASH_VECTOR_REST_TOKEN}",
        "UPSTASH_REDIS_URL": "${UPSTASH_REDIS_URL}",
        "UPSTASH_REDIS_TOKEN": "${UPSTASH_REDIS_TOKEN}",
        "UPSTASH_VECTOR_URL": "${UPSTASH_VECTOR_URL}",
        "UPSTASH_VECTOR_TOKEN": "${UPSTASH_VECTOR_TOKEN}"
      }
    }
  }
}
```

## Platform-Specific Setup

### WhatsApp Integration

1. **Install WhatsApp Web bridge (separate service)**
   ```bash
   # This requires a separate Go service for WhatsApp Web
   # See messaging-bridge documentation for details
   ```

2. **Configure messaging bridge**
   ```json
   {
     "platforms": {
       "whatsapp": {
         "enabled": true,
         "bridge_port": 8080,
         "qr_auth": true,
         "session_path": "~/.messaging-bridge/whatsapp-session"
       }
     }
   }
   ```

### Telegram Bot Setup

1. **Create bot with @BotFather**
   - Message @BotFather on Telegram
   - Use `/newbot` command
   - Follow instructions to create bot
   - Save the bot token

2. **Configure bot permissions**
   - Add bot to groups/channels as needed
   - Grant appropriate permissions
   - Test with `/start` command

### Discord Bot Setup

1. **Create Discord application**
   - Visit https://discord.com/developers/applications
   - Create new application
   - Go to "Bot" section
   - Create bot and copy token

2. **Add bot to servers**
   - Generate invite URL with required permissions
   - Add bot to your Discord servers
   - Note down guild/server IDs

### Cloudflare D1 Setup

1. **Create D1 databases**
   ```bash
   # Using Wrangler CLI
   npx wrangler d1 create core-database
   npx wrangler d1 create analytics-database  
   npx wrangler d1 create messaging-database
   ```

2. **Get database IDs**
   ```bash
   npx wrangler d1 list
   ```

3. **Update configuration**
   ```json
   {
     "cloudflare_d1": {
       "account_id": "your_account_id",
       "api_token": "your_api_token",
       "databases": {
         "core_db": {
           "database_id": "your_core_database_id"
         }
       }
     }
   }
   ```

## Testing Installation

### 1. Test MCP Servers

```bash
# Check MCP server status
claude mcp list

# Test messaging bridge
python3 mcp-servers/messaging-bridge/server.py --test

# Test database connector
python3 mcp-servers/database-connector/connector.py --test
```

### 2. Test Agents

```bash
# In Claude Code, test agents:
@system-orchestrator Test system connectivity and agent communication
@message-processor Test message retrieval capabilities
@database-manager Test database connections
```

### 3. Test Automation Scripts

```bash
# Test smart monitor
./automation/monitor-hooks/smart-monitor.sh --test

# Test document processor
./automation/document-processor/process-document.sh --help

# Test service manager
./automation/service-manager/daemon-manager.sh status
```

## Troubleshooting Installation

### Common Issues

**Python Import Errors:**
```bash
# Check Python path
python3 -c "import sys; print(sys.path)"

# Install missing packages
pip install missing-package-name
```

**Node.js Module Issues:**
```bash
# Clear npm cache
npm cache clean --force

# Reinstall modules
rm -rf node_modules package-lock.json
npm install
```

**Permission Errors:**
```bash
# Fix script permissions
chmod +x mcp-servers/context-wrapper/wrapper.sh
chmod +x automation/monitor-hooks/smart-monitor.sh
chmod +x automation/service-manager/daemon-manager.sh
chmod +x automation/document-processor/process-document.sh
```

**Configuration File Issues:**
```bash
# Validate JSON configuration
jq . ~/.messaging-bridge/config.json
jq . ~/.database-connector/config.json

# Check environment variables
env | grep -E "(TELEGRAM|DISCORD|CLOUDFLARE|UPSTASH)"
```

### Debug Mode

Enable debug logging for troubleshooting:

```bash
export DEBUG=true
export LOG_LEVEL=DEBUG

# Run with debug output
./automation/monitor-hooks/smart-monitor.sh --debug
python3 mcp-servers/messaging-bridge/server.py --debug
```

### Log Files

Check log files for detailed error information:

```bash
# MCP server logs
tail -f mcp-servers/messaging-bridge/messages.log
tail -f mcp-servers/database-connector/database.log

# Automation logs
tail -f automation/monitor-hooks/monitor.log
tail -f automation/service-manager/services.log
```

## Next Steps

After successful installation:

1. **Read the Architecture Guide** (`docs/architecture.md`)
2. **Explore Examples** (`docs/examples/`)
3. **Configure Workflows** (customize agents and automation)
4. **Set up Monitoring** (configure alerts and health checks)
5. **Backup Configuration** (save your customized configs)

## Getting Help

If you encounter issues:

1. **Check logs** for detailed error messages
2. **Review configuration** files for syntax errors
3. **Verify credentials** and API tokens
4. **Test components individually** before integrating
5. **Create GitHub issue** with detailed error information

Remember to never share API tokens or credentials when seeking help!
