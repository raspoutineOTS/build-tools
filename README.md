# Build Tools Collection

A comprehensive collection of modular tools for Claude Code automation and MCP (Model Context Protocol) integrations. This toolkit provides intelligent agents, universal servers, automation scripts, and configuration templates for building sophisticated AI-powered workflows.

## 🚀 Quick Start

### Prerequisites

- **Python 3.8+** with pip or uv
- **Node.js 18+** with npm or yarn
- **Git** for version control
- **jq** for JSON processing (recommended)

### Installation

1. **Clone the repository:**
```bash
git clone <repository-url>
cd build-tools
```

2. **Install Python dependencies:**
```bash
# Using pip
pip install mcp sqlite3 asyncio pydantic aiohttp

# Using uv (recommended)
uv pip install mcp sqlite3 asyncio pydantic aiohttp
```

3. **Configure environment variables:**
```bash
cp configs/mcp-templates/database-connector-config.json ~/.database-connector/config.json
# Edit configuration files with your credentials
```

4. **Set up Claude Code integration:**
```bash
# Copy agent definitions
cp -r agents ~/.claude/agents/

# Configure MCP servers in Claude Code
claude mcp add messaging-bridge ./mcp-servers/messaging-bridge/server.py
claude mcp add database-connector ./mcp-servers/database-connector/connector.py
```

## 📁 Project Structure

```
build-tools/
├── agents/                       # 🤖 Claude Code Agents
│   ├── system-orchestrator/      # Multi-agent coordination
│   ├── message-processor/        # Multi-platform messaging
│   ├── data-sorter/              # Intelligent categorization
│   └── database-manager/         # Universal database ops
├── mcp-servers/                  # 🔌 MCP Protocol Servers
│   ├── messaging-bridge/         # Universal messaging bridge
│   ├── context-wrapper/          # Context7 integration wrapper
│   └── database-connector/       # Multi-database connector
├── automation/                   # ⚙️ Automation Scripts
│   ├── monitor-hooks/            # Smart monitoring system
│   ├── document-processor/       # Document analysis tools
│   └── service-manager/          # Service/daemon management
├── configs/                      # 🔧 Configuration Templates
│   ├── claude-settings/          # Claude Code settings
│   └── mcp-templates/            # MCP server configs
└── docs/                         # 📚 Documentation
    ├── setup-guide.md
    ├── architecture.md
    └── examples/
```

## 🤖 Intelligent Agents

### System Orchestrator
**Purpose**: Coordinates multi-agent workflows and delegates tasks intelligently.

```bash
# Activate in Claude Code
@system-orchestrator Process new messaging data and store in cloud databases
```

**Capabilities:**
- Multi-agent task delegation
- Workflow orchestration
- Resource management
- Error handling and fallback

### Message Processor  
**Purpose**: Universal message handling across multiple platforms.

```bash
@message-processor Get recent WhatsApp messages and transcribe voice notes
```

**Supported Platforms:**
- WhatsApp, Telegram, Discord, Slack
- Audio transcription
- Media download and analysis
- Real-time monitoring

### Data Sorter
**Purpose**: Intelligent data categorization and pattern recognition.

```bash
@data-sorter Analyze extracted messages for urgent healthcare items
```

**Features:**
- Content classification
- Priority scoring
- Pattern recognition
- Anomaly detection

### Database Manager
**Purpose**: Universal database operations and schema management.

```bash
@database-manager Query healthcare database for recent patient data
```

**Supported Databases:**
- Cloudflare D1, PostgreSQL, MySQL, SQLite
- Connection pooling
- Query optimization
- Schema management

## 🔌 MCP Servers

### Messaging Bridge
Universal messaging platform connector with real-time capabilities.

**Setup:**
```bash
cd mcp-servers/messaging-bridge
python server.py
```

**Configuration:**
```json
{
  "platforms": {
    "whatsapp": {"enabled": true, "bridge_port": 8080},
    "telegram": {"enabled": true, "bot_token": "${TELEGRAM_BOT_TOKEN}"},
    "discord": {"enabled": true, "bot_token": "${DISCORD_BOT_TOKEN}"}
  }
}
```

### Database Connector
Multi-database connector with intelligent query optimization.

**Setup:**
```bash
cd mcp-servers/database-connector  
python connector.py
```

**Supported Operations:**
- CRUD operations across multiple database types
- Schema introspection and management
- Connection pooling and caching
- Query performance optimization

### Context Wrapper
Enhanced wrapper for Context7 MCP server with advanced configuration.

**Setup:**
```bash
cd mcp-servers/context-wrapper
./wrapper.sh
```

**Features:**
- Automatic Node.js environment setup
- Credential management
- Health monitoring
- Error recovery

## ⚙️ Automation Scripts

### Smart Monitor
Configurable monitoring system with intelligent triggers.

**Usage:**
```bash
./automation/monitor-hooks/smart-monitor.sh --config custom-config.json
```

**Monitors:**
- Database activity and new records
- File system changes and new documents
- System health and performance metrics
- Custom triggers and actions

### Document Processor
Intelligent document analysis for multiple file formats.

**Usage:**
```bash
./automation/document-processor/process-document.sh document.pdf
```

**Supported Formats:**
- PDF (with OCR support)
- DOCX (Microsoft Word)
- TXT (plain text)
- CSV (structured data)

**Output:**
- Extracted text and metadata
- Content analysis and categorization
- Keywords and summary generation
- Structured JSON output

### Service Manager
Universal daemon and service management system.

**Usage:**
```bash
./automation/service-manager/daemon-manager.sh start messaging-bridge
./automation/service-manager/daemon-manager.sh status
./automation/service-manager/daemon-manager.sh logs messaging-bridge
```

**Features:**
- Service lifecycle management
- Health monitoring and auto-restart
- Log management and rotation
- Configuration-driven setup

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root:

```bash
# Messaging Platforms
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
DISCORD_BOT_TOKEN=your_discord_bot_token
SLACK_BOT_TOKEN=your_slack_bot_token

# Database Connections
DB_USERNAME=your_db_username
DB_PASSWORD=your_db_password

# Cloudflare D1
CLOUDFLARE_ACCOUNT_ID=your_account_id
CLOUDFLARE_API_TOKEN=your_api_token
CLOUDFLARE_D1_DATABASE_ID=your_database_id

# Context7/Upstash
UPSTASH_REDIS_URL=your_redis_url
UPSTASH_REDIS_TOKEN=your_redis_token
UPSTASH_VECTOR_URL=your_vector_url
UPSTASH_VECTOR_TOKEN=your_vector_token
```

### Claude Code Integration

Add to your `.claude.json`:

```json
{
  "mcpServers": {
    "messaging-bridge": {
      "command": "python3",
      "args": ["./mcp-servers/messaging-bridge/server.py"]
    },
    "database-connector": {
      "command": "python3", 
      "args": ["./mcp-servers/database-connector/connector.py"]
    }
  }
}
```

## 📚 Usage Examples

### Complete Workflow Example

```bash
# 1. Start monitoring for new messages
./automation/monitor-hooks/smart-monitor.sh

# 2. Process incoming documents automatically
@system-orchestrator Monitor for new documents and process through complete pipeline

# 3. Query processed data
@database-manager Query recent processed documents from database

# 4. Generate analytics report
@data-sorter Analyze recent data trends and generate priority report
```

### Custom Messaging Integration

```python
# Use messaging bridge programmatically
import asyncio
from mcp import Client

async def get_recent_messages():
    async with Client() as client:
        messages = await client.call_tool(
            "get_recent_messages", 
            {"platform": "whatsapp", "hours": 24}
        )
        return messages
```

### Database Operations

```bash
# Query across multiple databases  
@database-manager Execute SELECT * FROM users WHERE active=true on analytics database

# Create new table
@database-manager Create table user_sessions with columns: id, user_id, start_time, end_time

# Backup and migrate data
./automation/service-manager/daemon-manager.sh start backup-service
```

## 🔒 Security Considerations

### Credential Management
- Store sensitive credentials in environment variables
- Use `.gitignore` to exclude configuration files with secrets
- Implement credential rotation where supported
- Enable encryption for database connections

### Access Control
- Configure service-specific permissions
- Implement API rate limiting
- Use secure session management
- Regular security audits and updates

### Data Privacy
- Implement data retention policies
- Support data anonymization
- Comply with GDPR and privacy regulations
- Secure data transmission with TLS/SSL

## 🚨 Troubleshooting

### Common Issues

**MCP Server Connection Issues:**
```bash
# Check server status
claude mcp list

# View server logs
./automation/service-manager/daemon-manager.sh logs messaging-bridge

# Restart problematic server
./automation/service-manager/daemon-manager.sh restart messaging-bridge
```

**Database Connection Problems:**
```bash
# Test database connectivity
@database-manager Test connection to default database

# Check configuration
cat ~/.database-connector/config.json
```

**Messaging Platform Authentication:**
```bash
# WhatsApp: Re-scan QR code
# Telegram: Verify bot token
# Discord: Check bot permissions
```

### Debug Mode

Enable detailed logging:

```bash
export DEBUG=true
export LOG_LEVEL=DEBUG
./automation/monitor-hooks/smart-monitor.sh --debug
```

## 🤝 Contributing

### Development Setup

1. **Fork the repository**
2. **Create feature branch:** `git checkout -b feature/amazing-feature`
3. **Make changes and test thoroughly**
4. **Follow coding standards and add tests**
5. **Submit pull request with detailed description**

### Coding Standards

- **Python:** Follow PEP 8, use type hints
- **Shell Scripts:** Use shellcheck, follow best practices
- **Documentation:** Update README and inline documentation
- **Testing:** Add unit tests for new functionality

### Architecture Guidelines

- **Modularity:** Keep components loosely coupled
- **Configurability:** Make behavior configurable
- **Error Handling:** Implement graceful error recovery
- **Logging:** Comprehensive logging for debugging
- **Security:** Follow security best practices

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Claude Code Team** for the excellent AI-powered development environment
- **MCP Community** for protocol specifications and examples
- **Open Source Contributors** for the tools and libraries that make this possible

## 📞 Support

- **Issues:** Report bugs and request features via GitHub Issues
- **Documentation:** Check the `docs/` directory for detailed guides
- **Community:** Join discussions in GitHub Discussions

---

**Built with ❤️ for the Claude Code and MCP community**
