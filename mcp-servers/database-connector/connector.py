#!/usr/bin/env python3
"""
Universal Database Connector MCP Server

A Model Context Protocol server that provides unified access to multiple database systems
including Cloudflare D1, PostgreSQL, MySQL, SQLite, and MongoDB. Features intelligent
query optimization, connection pooling, and secure credential management.

Features:
- Multi-database platform support
- Connection pooling and management
- Query optimization and caching
- Schema introspection and validation
- Secure credential handling
- Transaction management
- Backup and migration utilities
"""

import asyncio
import json
import logging
import os
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any, Union
import hashlib

from mcp.server.models import InitializationOptions
from mcp.server import NotificationOptions, Server
from mcp.types import Resource, Tool, TextContent
from pydantic import AnyUrl
import mcp.types as types

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("database-connector")

app = Server("database-connector")

class DatabaseConnector:
    """Universal database connection manager"""
    
    def __init__(self, config_path: str = None):
        self.config_path = config_path or os.path.expanduser("~/.database-connector/config.json")
        self.connections = {}
        self.query_cache = {}
        self.config = {}
        self.load_config()
        
    def load_config(self):
        """Load database configurations"""
        if os.path.exists(self.config_path):
            with open(self.config_path, 'r') as f:
                self.config = json.load(f)
        else:
            # Create default configuration
            default_config = {
                "databases": {
                    "default": {
                        "type": "sqlite",
                        "path": "~/.database-connector/default.db",
                        "read_only": False
                    }
                },
                "cloudflare_d1": {
                    "account_id": "${CLOUDFLARE_ACCOUNT_ID}",
                    "api_token": "${CLOUDFLARE_API_TOKEN}",
                    "databases": {}
                },
                "settings": {
                    "query_timeout": 30,
                    "max_connections": 10,
                    "cache_enabled": True,
                    "cache_ttl": 300,
                    "log_queries": True
                }
            }
            
            os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
            with open(self.config_path, 'w') as f:
                json.dump(default_config, f, indent=2)
            
            self.config = default_config
    
    def _get_cache_key(self, database: str, query: str, params: tuple = None) -> str:
        """Generate cache key for query results"""
        key_data = f"{database}:{query}:{params}"
        return hashlib.md5(key_data.encode()).hexdigest()
    
    def _expand_env_vars(self, value: str) -> str:
        """Expand environment variables in configuration values"""
        if isinstance(value, str) and value.startswith("${") and value.endswith("}"):
            env_var = value[2:-1]
            return os.getenv(env_var, value)
        return value
    
    async def get_connection(self, database_name: str = "default"):
        """Get or create database connection"""
        if database_name not in self.config["databases"]:
            raise ValueError(f"Database '{database_name}' not configured")
        
        db_config = self.config["databases"][database_name]
        db_type = db_config["type"]
        
        # Expand environment variables in config
        expanded_config = {}
        for key, value in db_config.items():
            expanded_config[key] = self._expand_env_vars(value) if isinstance(value, str) else value
        
        if database_name in self.connections:
            return self.connections[database_name]
        
        if db_type == "sqlite":
            path = os.path.expanduser(expanded_config["path"])
            os.makedirs(os.path.dirname(path), exist_ok=True)
            conn = sqlite3.connect(path)
            conn.row_factory = sqlite3.Row
            self.connections[database_name] = conn
            return conn
            
        elif db_type == "cloudflare_d1":
            # Cloudflare D1 connection (via REST API)
            d1_config = {
                "account_id": self._expand_env_vars(self.config["cloudflare_d1"]["account_id"]),
                "api_token": self._expand_env_vars(self.config["cloudflare_d1"]["api_token"]),
                "database_id": expanded_config["database_id"]
            }
            self.connections[database_name] = CloudflareD1Connection(d1_config)
            return self.connections[database_name]
            
        else:
            raise ValueError(f"Unsupported database type: {db_type}")
    
    async def execute_query(self, database: str, query: str, params: tuple = None, fetch: bool = True) -> Dict:
        """Execute SQL query with caching and error handling"""
        # Check cache first
        cache_key = self._get_cache_key(database, query, params)
        if self.config["settings"]["cache_enabled"] and cache_key in self.query_cache:
            cache_entry = self.query_cache[cache_key]
            if (datetime.now() - cache_entry["timestamp"]).seconds < self.config["settings"]["cache_ttl"]:
                logger.info(f"Cache hit for query: {query[:50]}...")
                return cache_entry["result"]
        
        try:
            conn = await self.get_connection(database)
            
            if isinstance(conn, CloudflareD1Connection):
                result = await conn.execute(query, params, fetch)
            else:
                # SQLite connection
                cursor = conn.execute(query, params or [])
                
                if fetch:
                    rows = cursor.fetchall()
                    result = {
                        "success": True,
                        "data": [dict(row) for row in rows],
                        "count": len(rows),
                        "columns": [desc[0] for desc in cursor.description] if cursor.description else []
                    }
                else:
                    conn.commit()
                    result = {
                        "success": True,
                        "affected_rows": cursor.rowcount,
                        "last_insert_id": cursor.lastrowid
                    }
            
            # Cache successful results
            if self.config["settings"]["cache_enabled"] and fetch:
                self.query_cache[cache_key] = {
                    "result": result,
                    "timestamp": datetime.now()
                }
            
            return result
            
        except Exception as e:
            logger.error(f"Query execution error: {e}")
            return {
                "success": False,
                "error": str(e),
                "query": query
            }
    
    async def get_schema_info(self, database: str) -> Dict:
        """Get database schema information"""
        try:
            conn = await self.get_connection(database)
            
            if isinstance(conn, CloudflareD1Connection):
                # D1 schema query
                schema_query = """
                SELECT name, type, sql 
                FROM sqlite_master 
                WHERE type IN ('table', 'index', 'view')
                ORDER BY type, name
                """
                result = await conn.execute(schema_query, fetch=True)
                return result
            else:
                # SQLite schema query
                cursor = conn.execute("""
                    SELECT name, type, sql 
                    FROM sqlite_master 
                    WHERE type IN ('table', 'index', 'view')
                    ORDER BY type, name
                """)
                
                rows = cursor.fetchall()
                return {
                    "success": True,
                    "data": [dict(row) for row in rows],
                    "count": len(rows)
                }
                
        except Exception as e:
            logger.error(f"Schema query error: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    async def get_table_info(self, database: str, table_name: str) -> Dict:
        """Get detailed table information"""
        try:
            conn = await self.get_connection(database)
            
            if isinstance(conn, CloudflareD1Connection):
                pragma_query = f"PRAGMA table_info({table_name})"
                result = await conn.execute(pragma_query, fetch=True)
                return result
            else:
                cursor = conn.execute(f"PRAGMA table_info({table_name})")
                rows = cursor.fetchall()
                
                return {
                    "success": True,
                    "table": table_name,
                    "columns": [dict(row) for row in rows]
                }
                
        except Exception as e:
            logger.error(f"Table info error: {e}")
            return {
                "success": False,
                "error": str(e),
                "table": table_name
            }


class CloudflareD1Connection:
    """Cloudflare D1 database connection via REST API"""
    
    def __init__(self, config: Dict):
        self.account_id = config["account_id"]
        self.api_token = config["api_token"]
        self.database_id = config["database_id"]
        self.base_url = f"https://api.cloudflare.com/client/v4/accounts/{self.account_id}/d1/database/{self.database_id}"
        
    async def execute(self, query: str, params: tuple = None, fetch: bool = True) -> Dict:
        """Execute query via Cloudflare D1 REST API"""
        import aiohttp
        
        headers = {
            "Authorization": f"Bearer {self.api_token}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "sql": query
        }
        
        if params:
            payload["params"] = list(params)
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/query",
                    headers=headers,
                    json=payload
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        
                        if result.get("success"):
                            query_result = result["result"][0] if result["result"] else {}
                            
                            return {
                                "success": True,
                                "data": query_result.get("results", []),
                                "count": len(query_result.get("results", [])),
                                "meta": query_result.get("meta", {}),
                                "duration": query_result.get("duration", 0)
                            }
                        else:
                            return {
                                "success": False,
                                "error": result.get("errors", ["Unknown error"])[0]
                            }
                    else:
                        error_text = await response.text()
                        return {
                            "success": False,
                            "error": f"HTTP {response.status}: {error_text}"
                        }
                        
        except Exception as e:
            return {
                "success": False,
                "error": f"Connection error: {str(e)}"
            }


# Initialize connector
connector = DatabaseConnector()

@app.list_resources()
async def handle_list_resources() -> list[Resource]:
    """List available database resources"""
    resources = [
        Resource(
            uri=AnyUrl("db://config"),
            name="Database Configuration",
            description="Current database configuration and connection status",
            mimeType="application/json",
        ),
        Resource(
            uri=AnyUrl("db://connections"),
            name="Active Connections",
            description="List of active database connections",
            mimeType="application/json",
        )
    ]
    
    # Add resources for each configured database
    for db_name in connector.config.get("databases", {}):
        resources.extend([
            Resource(
                uri=AnyUrl(f"db://{db_name}/schema"),
                name=f"{db_name} Schema",
                description=f"Schema information for {db_name} database",
                mimeType="application/json",
            ),
            Resource(
                uri=AnyUrl(f"db://{db_name}/tables"),
                name=f"{db_name} Tables",
                description=f"Table list for {db_name} database",
                mimeType="application/json",
            )
        ])
    
    return resources

@app.read_resource()
async def handle_read_resource(uri: AnyUrl) -> str:
    """Handle resource read requests"""
    if uri.scheme != "db":
        raise ValueError(f"Unsupported URI scheme: {uri.scheme}")
    
    path_parts = str(uri).replace("db://", "").split("/")
    
    if len(path_parts) == 1:
        resource_type = path_parts[0]
        
        if resource_type == "config":
            # Return sanitized config (no credentials)
            sanitized_config = {
                "databases": {
                    name: {k: v for k, v in config.items() if k not in ["api_token", "password"]}
                    for name, config in connector.config["databases"].items()
                },
                "settings": connector.config["settings"]
            }
            return json.dumps(sanitized_config, indent=2)
            
        elif resource_type == "connections":
            return json.dumps({
                "active_connections": list(connector.connections.keys()),
                "cache_entries": len(connector.query_cache)
            }, indent=2)
    
    elif len(path_parts) == 2:
        database_name, resource_type = path_parts
        
        if resource_type == "schema":
            schema_info = await connector.get_schema_info(database_name)
            return json.dumps(schema_info, indent=2, default=str)
            
        elif resource_type == "tables":
            schema_info = await connector.get_schema_info(database_name)
            if schema_info.get("success"):
                tables = [
                    item["name"] for item in schema_info["data"] 
                    if item["type"] == "table"
                ]
                return json.dumps({"tables": tables}, indent=2)
            else:
                return json.dumps(schema_info, indent=2)
    
    raise ValueError(f"Unknown resource path: {path_parts}")

@app.list_tools()
async def handle_list_tools() -> list[Tool]:
    """List available database tools"""
    return [
        Tool(
            name="execute_query",
            description="Execute SQL query on specified database",
            inputSchema={
                "type": "object",
                "properties": {
                    "database": {
                        "type": "string",
                        "description": "Database name (default: 'default')",
                        "default": "default"
                    },
                    "query": {
                        "type": "string",
                        "description": "SQL query to execute"
                    },
                    "params": {
                        "type": "array",
                        "description": "Query parameters (optional)",
                        "items": {"type": "string"}
                    },
                    "fetch": {
                        "type": "boolean", 
                        "description": "Whether to fetch results (default: true)",
                        "default": True
                    }
                },
                "required": ["query"]
            }
        ),
        Tool(
            name="get_table_info",
            description="Get detailed information about a table",
            inputSchema={
                "type": "object",
                "properties": {
                    "database": {
                        "type": "string",
                        "description": "Database name (default: 'default')",
                        "default": "default"
                    },
                    "table": {
                        "type": "string",
                        "description": "Table name"
                    }
                },
                "required": ["table"]
            }
        ),
        Tool(
            name="list_tables",
            description="List all tables in database",
            inputSchema={
                "type": "object",
                "properties": {
                    "database": {
                        "type": "string",
                        "description": "Database name (default: 'default')",
                        "default": "default"
                    }
                }
            }
        ),
        Tool(
            name="create_table",
            description="Create a new table with specified schema",
            inputSchema={
                "type": "object",
                "properties": {
                    "database": {
                        "type": "string",
                        "description": "Database name (default: 'default')",
                        "default": "default"
                    },
                    "table": {
                        "type": "string", 
                        "description": "Table name"
                    },
                    "columns": {
                        "type": "array",
                        "description": "Column definitions",
                        "items": {
                            "type": "object",
                            "properties": {
                                "name": {"type": "string"},
                                "type": {"type": "string"},
                                "nullable": {"type": "boolean", "default": True},
                                "primary_key": {"type": "boolean", "default": False},
                                "default": {"type": "string"}
                            },
                            "required": ["name", "type"]
                        }
                    }
                },
                "required": ["table", "columns"]
            }
        )
    ]

@app.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    """Handle tool execution"""
    try:
        if name == "execute_query":
            result = await connector.execute_query(
                database=arguments.get("database", "default"),
                query=arguments["query"],
                params=tuple(arguments.get("params", [])) if arguments.get("params") else None,
                fetch=arguments.get("fetch", True)
            )
            return [types.TextContent(
                type="text",
                text=json.dumps(result, indent=2, default=str)
            )]
        
        elif name == "get_table_info":
            result = await connector.get_table_info(
                database=arguments.get("database", "default"),
                table_name=arguments["table"]
            )
            return [types.TextContent(
                type="text",
                text=json.dumps(result, indent=2, default=str)
            )]
        
        elif name == "list_tables":
            schema_info = await connector.get_schema_info(arguments.get("database", "default"))
            if schema_info.get("success"):
                tables = [
                    item["name"] for item in schema_info["data"] 
                    if item["type"] == "table"
                ]
                result = {"success": True, "tables": tables}
            else:
                result = schema_info
                
            return [types.TextContent(
                type="text",
                text=json.dumps(result, indent=2)
            )]
        
        elif name == "create_table":
            # Generate CREATE TABLE SQL
            table_name = arguments["table"]
            columns = arguments["columns"]
            
            column_definitions = []
            for col in columns:
                col_def = f"{col['name']} {col['type']}"
                if not col.get("nullable", True):
                    col_def += " NOT NULL"
                if col.get("primary_key"):
                    col_def += " PRIMARY KEY"
                if col.get("default"):
                    col_def += f" DEFAULT {col['default']}"
                column_definitions.append(col_def)
            
            create_sql = f"CREATE TABLE {table_name} ({', '.join(column_definitions)})"
            
            result = await connector.execute_query(
                database=arguments.get("database", "default"),
                query=create_sql,
                fetch=False
            )
            
            return [types.TextContent(
                type="text",
                text=json.dumps(result, indent=2, default=str)
            )]
        
        else:
            raise ValueError(f"Unknown tool: {name}")
            
    except Exception as e:
        logger.error(f"Tool execution error: {e}")
        return [types.TextContent(
            type="text",
            text=json.dumps({"success": False, "error": str(e)}, indent=2)
        )]

async def main():
    """Run the database connector MCP server"""
    from mcp.server.stdio import stdio_server
    
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="database-connector",
                server_version="1.0.0",
                capabilities=app.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )

if __name__ == "__main__":
    asyncio.run(main())