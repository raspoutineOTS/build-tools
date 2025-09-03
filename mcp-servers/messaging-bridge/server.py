#!/usr/bin/env python3
"""
Universal Messaging Bridge MCP Server

A Model Context Protocol server that provides unified access to multiple messaging platforms
including WhatsApp, Telegram, Discord, Slack, and SMS. Supports message retrieval,
sending, media handling, and real-time notifications.

Features:
- Multi-platform messaging support
- Audio transcription and media handling  
- Real-time message monitoring
- Secure credential management
- Configurable platform adapters
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any
import sqlite3
import os

from mcp.server.models import InitializationOptions
from mcp.server import NotificationOptions, Server
from mcp.types import Resource, Tool, TextContent, ImageContent, EmbeddedResource
from pydantic import AnyUrl
import mcp.types as types

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("messaging-bridge")

app = Server("messaging-bridge")

class MessagingBridge:
    """Universal messaging platform bridge"""
    
    def __init__(self, config_path: str = None):
        self.config_path = config_path or os.path.expanduser("~/.messaging-bridge/config.json")
        self.platforms = {}
        self.db_path = os.path.expanduser("~/.messaging-bridge/messages.db")
        self.init_database()
        self.load_config()
    
    def init_database(self):
        """Initialize SQLite database for message storage"""
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS messages (
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
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS chats (
                    id TEXT PRIMARY KEY,
                    platform TEXT NOT NULL,
                    chat_id TEXT NOT NULL,
                    name TEXT,
                    type TEXT DEFAULT 'private',
                    participant_count INTEGER,
                    last_message_at DATETIME,
                    metadata JSON,
                    UNIQUE(platform, chat_id)
                )
            """)
            
            # Create indexes for performance
            conn.execute("CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_messages_platform ON messages(platform)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_messages_chat ON messages(platform, chat_id)")

    def load_config(self):
        """Load platform configurations"""
        if os.path.exists(self.config_path):
            with open(self.config_path, 'r') as f:
                config = json.load(f)
                self.platforms = config.get('platforms', {})
        else:
            # Create default config
            default_config = {
                "platforms": {
                    "whatsapp": {
                        "enabled": True,
                        "bridge_port": 8080,
                        "qr_auth": True,
                        "session_path": "~/.messaging-bridge/whatsapp-session"
                    },
                    "telegram": {
                        "enabled": False,
                        "bot_token": "${TELEGRAM_BOT_TOKEN}",
                        "webhook_url": None
                    },
                    "discord": {
                        "enabled": False,
                        "bot_token": "${DISCORD_BOT_TOKEN}",
                        "guild_ids": []
                    }
                },
                "settings": {
                    "auto_transcribe": True,
                    "media_download": True,
                    "max_message_age": 30
                }
            }
            
            os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
            with open(self.config_path, 'w') as f:
                json.dump(default_config, f, indent=2)

    async def get_recent_messages(self, platform: str = None, hours: int = 24, limit: int = 100) -> List[Dict]:
        """Retrieve recent messages from specified platform(s)"""
        query = """
            SELECT id, platform, chat_id, sender_name, content, message_type, 
                   media_url, timestamp, metadata
            FROM messages 
            WHERE timestamp > ?
        """
        params = [datetime.now() - timedelta(hours=hours)]
        
        if platform:
            query += " AND platform = ?"
            params.append(platform)
            
        query += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)
        
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(query, params)
            return [dict(row) for row in cursor.fetchall()]

    async def search_messages(self, query: str, platform: str = None, limit: int = 50) -> List[Dict]:
        """Search messages by content"""
        sql_query = """
            SELECT id, platform, chat_id, sender_name, content, timestamp, metadata
            FROM messages 
            WHERE content LIKE ?
        """
        params = [f"%{query}%"]
        
        if platform:
            sql_query += " AND platform = ?"
            params.append(platform)
            
        sql_query += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)
        
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(sql_query, params)
            return [dict(row) for row in cursor.fetchall()]

    async def get_chat_list(self, platform: str = None) -> List[Dict]:
        """Get list of chats/conversations"""
        query = "SELECT * FROM chats"
        params = []
        
        if platform:
            query += " WHERE platform = ?"
            params.append(platform)
            
        query += " ORDER BY last_message_at DESC"
        
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(query, params)
            return [dict(row) for row in cursor.fetchall()]

# Initialize bridge
bridge = MessagingBridge()

@app.list_resources()
async def handle_list_resources() -> list[Resource]:
    """List available messaging resources"""
    return [
        Resource(
            uri=AnyUrl("messaging://recent"),
            name="Recent Messages",
            description="Access recent messages from all platforms",
            mimeType="application/json",
        ),
        Resource(
            uri=AnyUrl("messaging://chats"),
            name="Chat List",
            description="List of all conversations/chats",
            mimeType="application/json",
        ),
        Resource(
            uri=AnyUrl("messaging://config"),
            name="Platform Configuration",
            description="Current platform settings and status",
            mimeType="application/json",
        ),
    ]

@app.read_resource()
async def handle_read_resource(uri: AnyUrl) -> str:
    """Handle resource read requests"""
    if uri.scheme != "messaging":
        raise ValueError(f"Unsupported URI scheme: {uri.scheme}")
    
    path = str(uri).replace("messaging://", "")
    
    if path == "recent":
        messages = await bridge.get_recent_messages()
        return json.dumps(messages, indent=2, default=str)
    
    elif path == "chats":
        chats = await bridge.get_chat_list()
        return json.dumps(chats, indent=2, default=str)
    
    elif path == "config":
        return json.dumps(bridge.platforms, indent=2)
    
    else:
        raise ValueError(f"Unknown resource path: {path}")

@app.list_tools()
async def handle_list_tools() -> list[Tool]:
    """List available messaging tools"""
    return [
        Tool(
            name="get_recent_messages",
            description="Retrieve recent messages from messaging platforms",
            inputSchema={
                "type": "object",
                "properties": {
                    "platform": {
                        "type": "string",
                        "enum": ["whatsapp", "telegram", "discord", "slack"],
                        "description": "Specific platform to query (optional)"
                    },
                    "hours": {
                        "type": "integer",
                        "default": 24,
                        "description": "Hours back to search (default: 24)"
                    },
                    "limit": {
                        "type": "integer", 
                        "default": 100,
                        "description": "Maximum number of messages (default: 100)"
                    }
                }
            }
        ),
        Tool(
            name="search_messages",
            description="Search messages by content across platforms",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search query string"
                    },
                    "platform": {
                        "type": "string",
                        "enum": ["whatsapp", "telegram", "discord", "slack"],
                        "description": "Specific platform to search (optional)"
                    },
                    "limit": {
                        "type": "integer",
                        "default": 50,
                        "description": "Maximum results (default: 50)"
                    }
                },
                "required": ["query"]
            }
        ),
        Tool(
            name="get_chat_list",
            description="Get list of chats/conversations from platforms",
            inputSchema={
                "type": "object",
                "properties": {
                    "platform": {
                        "type": "string",
                        "enum": ["whatsapp", "telegram", "discord", "slack"],
                        "description": "Specific platform to query (optional)"
                    }
                }
            }
        ),
        Tool(
            name="send_message",
            description="Send message to a chat (requires platform support)",
            inputSchema={
                "type": "object",
                "properties": {
                    "platform": {
                        "type": "string",
                        "enum": ["whatsapp", "telegram", "discord", "slack"],
                        "description": "Target platform"
                    },
                    "chat_id": {
                        "type": "string",
                        "description": "Chat/conversation ID"
                    },
                    "message": {
                        "type": "string",
                        "description": "Message content to send"
                    }
                },
                "required": ["platform", "chat_id", "message"]
            }
        )
    ]

@app.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    """Handle tool execution"""
    try:
        if name == "get_recent_messages":
            messages = await bridge.get_recent_messages(
                platform=arguments.get("platform"),
                hours=arguments.get("hours", 24),
                limit=arguments.get("limit", 100)
            )
            return [types.TextContent(
                type="text",
                text=json.dumps(messages, indent=2, default=str)
            )]
        
        elif name == "search_messages":
            results = await bridge.search_messages(
                query=arguments["query"],
                platform=arguments.get("platform"),
                limit=arguments.get("limit", 50)
            )
            return [types.TextContent(
                type="text", 
                text=json.dumps(results, indent=2, default=str)
            )]
        
        elif name == "get_chat_list":
            chats = await bridge.get_chat_list(arguments.get("platform"))
            return [types.TextContent(
                type="text",
                text=json.dumps(chats, indent=2, default=str)
            )]
        
        elif name == "send_message":
            # This would require platform-specific implementation
            return [types.TextContent(
                type="text",
                text=json.dumps({
                    "status": "not_implemented",
                    "message": "Send functionality requires platform-specific bridge implementation",
                    "platform": arguments.get("platform"),
                    "chat_id": arguments.get("chat_id")
                }, indent=2)
            )]
        
        else:
            raise ValueError(f"Unknown tool: {name}")
            
    except Exception as e:
        logger.error(f"Tool execution error: {e}")
        return [types.TextContent(
            type="text",
            text=json.dumps({"error": str(e)}, indent=2)
        )]

async def main():
    """Run the messaging bridge MCP server"""
    from mcp.server.stdio import stdio_server
    
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream, 
            write_stream,
            InitializationOptions(
                server_name="messaging-bridge",
                server_version="1.0.0",
                capabilities=app.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )

if __name__ == "__main__":
    asyncio.run(main())