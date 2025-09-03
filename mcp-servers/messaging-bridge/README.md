# Messaging Bridge MCP Server

A universal Model Context Protocol server that provides unified access to multiple messaging platforms including WhatsApp, Telegram, Discord, Slack, and SMS.

## Features

- **Multi-Platform Support**: Connect to WhatsApp, Telegram, Discord, Slack, and SMS
- **Message Retrieval**: Get recent messages, search conversation history
- **Media Handling**: Download and process images, documents, audio files
- **Real-time Monitoring**: Track new messages across platforms
- **Audio Transcription**: Convert voice messages to text
- **Secure Storage**: Local SQLite database for message caching
- **Configurable**: Easy platform configuration and management

## Installation

### Prerequisites

- Python 3.8+
- pip or uv package manager

### Install Dependencies

```bash
# Using pip
pip install mcp sqlite3 asyncio pydantic

# Using uv (recommended)
uv pip install mcp sqlite3 asyncio pydantic
```

### Setup

1. **Create configuration directory:**
```bash
mkdir -p ~/.messaging-bridge
```

2. **Configure platforms:**
Edit `~/.messaging-bridge/config.json`:
```json
{
  "platforms": {
    "whatsapp": {
      "enabled": true,
      "bridge_port": 8080,
      "qr_auth": true,
      "session_path": "~/.messaging-bridge/whatsapp-session"
    },
    "telegram": {
      "enabled": true,
      "bot_token": "${TELEGRAM_BOT_TOKEN}",
      "webhook_url": null
    },
    "discord": {
      "enabled": true,
      "bot_token": "${DISCORD_BOT_TOKEN}",
      "guild_ids": ["your-server-id"]
    }
  },
  "settings": {
    "auto_transcribe": true,
    "media_download": true,
    "max_message_age": 30
  }
}
```

3. **Set environment variables:**
```bash
export TELEGRAM_BOT_TOKEN="your_telegram_bot_token"
export DISCORD_BOT_TOKEN="your_discord_bot_token"
```

## Usage with Claude Code

### Add to MCP Configuration

Add this server to your Claude Code MCP configuration:

```bash
claude mcp add messaging-bridge ./mcp-servers/messaging-bridge/server.py
```

Or configure manually in `.claude.json`:
```json
{
  "mcpServers": {
    "messaging-bridge": {
      "command": "python",
      "args": ["./mcp-servers/messaging-bridge/server.py"]
    }
  }
}
```

### Available Tools

1. **get_recent_messages**: Retrieve recent messages from platforms
2. **search_messages**: Search messages by content
3. **get_chat_list**: List all conversations/chats  
4. **send_message**: Send messages (platform-dependent)

### Example Usage

```python
# Get recent messages from all platforms
await mcp.call_tool("get_recent_messages", {
    "hours": 12,
    "limit": 50
})

# Search for specific content
await mcp.call_tool("search_messages", {
    "query": "meeting tomorrow",
    "platform": "whatsapp"
})

# List WhatsApp chats
await mcp.call_tool("get_chat_list", {
    "platform": "whatsapp"
})
```

## Platform Setup

### WhatsApp

1. **Install WhatsApp Bridge** (separate Go service):
```bash
# See whatsapp-bridge documentation
go run whatsapp-bridge/main.go
```

2. **Scan QR code** when prompted for authentication

3. **Configure port** in messaging bridge config (default: 8080)

### Telegram

1. **Create bot** with @BotFather on Telegram
2. **Get bot token** and add to environment variables
3. **Optional**: Set up webhook URL for real-time messages

### Discord

1. **Create Discord application** at https://discord.com/developers/applications
2. **Create bot** and get bot token
3. **Add bot to servers** with appropriate permissions
4. **Configure guild IDs** in config file

## Database Schema

The server uses SQLite to store messages and chat metadata:

### Messages Table
```sql
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    platform TEXT NOT NULL,
    chat_id TEXT NOT NULL,
    sender_id TEXT,
    sender_name TEXT,
    content TEXT,
    message_type TEXT DEFAULT 'text',
    media_url TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    metadata JSON
);
```

### Chats Table
```sql
CREATE TABLE chats (
    id TEXT PRIMARY KEY,
    platform TEXT NOT NULL,
    chat_id TEXT NOT NULL,
    name TEXT,
    type TEXT DEFAULT 'private',
    participant_count INTEGER,
    last_message_at DATETIME,
    metadata JSON
);
```

## Configuration Options

### Platform Settings

```json
{
  "platforms": {
    "whatsapp": {
      "enabled": true,
      "bridge_port": 8080,
      "qr_auth": true,
      "session_path": "~/.messaging-bridge/whatsapp-session",
      "webhook_url": null
    },
    "telegram": {
      "enabled": true,
      "bot_token": "${TELEGRAM_BOT_TOKEN}",
      "webhook_url": "https://your-domain.com/telegram/webhook",
      "allowed_chats": ["chat_id_1", "chat_id_2"]
    },
    "discord": {
      "enabled": true,
      "bot_token": "${DISCORD_BOT_TOKEN}",
      "guild_ids": ["123456789"],
      "channel_ids": ["987654321"]
    },
    "slack": {
      "enabled": false,
      "bot_token": "${SLACK_BOT_TOKEN}",
      "workspace_id": "your-workspace"
    }
  }
}
```

### Processing Settings

```json
{
  "settings": {
    "auto_transcribe": true,
    "media_download": true,
    "max_message_age": 30,
    "batch_size": 100,
    "sync_interval": 300,
    "enable_notifications": true
  }
}
```

## Security Considerations

- **Credentials**: Store API tokens in environment variables, not config files
- **Session Data**: WhatsApp session files contain encryption keys
- **Database**: SQLite database contains message history
- **Network**: Use HTTPS for webhooks and API calls
- **Access Control**: Limit bot permissions and allowed chats/channels

## Troubleshooting

### Common Issues

1. **WhatsApp QR Code expired**:
   - Restart the WhatsApp bridge service
   - Scan new QR code within 30 seconds

2. **Telegram bot not receiving messages**:
   - Check bot permissions in group chats
   - Verify webhook URL is accessible

3. **Database locked errors**:
   - Ensure only one instance is running
   - Check file permissions on database

### Debug Mode

Enable debug logging:
```bash
export LOG_LEVEL=DEBUG
python server.py
```

## Extension Points

The messaging bridge is designed to be extensible:

1. **New Platforms**: Add platform adapters in `platforms/` directory
2. **Message Processors**: Custom message analysis and transformation
3. **Storage Backends**: Replace SQLite with PostgreSQL, MySQL, etc.
4. **Notification Systems**: Custom alert and notification handlers

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Submit pull request with description

## Support

- Create issues on GitHub for bugs and feature requests
- Check existing issues for solutions
- Provide logs and configuration when reporting problems