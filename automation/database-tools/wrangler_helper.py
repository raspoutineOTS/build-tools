#!/usr/bin/env python3
"""
Wrangler D1 Helper Module
Helper functions for interacting with Cloudflare D1 databases via Wrangler CLI

This module provides a Python interface to Wrangler CLI for D1 database operations.
It's an alternative to using the MCP Cloudflare server for direct CLI access.
"""

import subprocess
import json
import os
from typing import Dict, List, Optional, Any
from dataclasses import dataclass


# Database configuration - Customize for your use case
DATABASES = {
    "core": "app_core",
    "medical": "app_medical",
    "distribution": "app_distribution",
    "logistics": "app_logistics"
}

# Environment variables - Should be set externally for security
# Use os.getenv() to read from environment instead of hardcoding
CLOUDFLARE_API_TOKEN = os.getenv("CLOUDFLARE_API_TOKEN")
CLOUDFLARE_ACCOUNT_ID = os.getenv("CLOUDFLARE_ACCOUNT_ID")


@dataclass
class QueryResult:
    """Result from a D1 query"""
    success: bool
    results: List[Dict[str, Any]]
    meta: Dict[str, Any]
    error: Optional[str] = None


class WranglerD1Client:
    """Client for interacting with Cloudflare D1 via Wrangler CLI"""

    def __init__(self, api_token: str = None, account_id: str = None):
        """
        Initialize Wrangler D1 Client

        Args:
            api_token: Cloudflare API token (defaults to env var)
            account_id: Cloudflare account ID (defaults to env var)
        """
        self.api_token = api_token or CLOUDFLARE_API_TOKEN
        self.account_id = account_id or CLOUDFLARE_ACCOUNT_ID

        if not self.api_token or not self.account_id:
            raise ValueError(
                "CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID must be set "
                "either as environment variables or passed to constructor"
            )

        self.env = {
            **os.environ,
            "CLOUDFLARE_API_TOKEN": self.api_token,
            "CLOUDFLARE_ACCOUNT_ID": self.account_id
        }

    def _get_database_name(self, db_key: str) -> str:
        """
        Convert database key to full database name

        Args:
            db_key: Short database key (core, medical, distribution, logistics)

        Returns:
            Full database name (app_core, app_medical, etc.)
        """
        if db_key in DATABASES:
            return DATABASES[db_key]
        # If already full name, return as is
        if db_key.startswith("app_"):
            return db_key
        raise ValueError(f"Unknown database key: {db_key}. Use: {', '.join(DATABASES.keys())}")

    def execute(self, database: str, sql: str, remote: bool = True) -> QueryResult:
        """
        Execute SQL query on D1 database

        Args:
            database: Database key or full name (e.g., 'medical' or 'app_medical')
            sql: SQL query to execute
            remote: Whether to execute on remote database (default: True)

        Returns:
            QueryResult object with results and metadata
        """
        db_name = self._get_database_name(database)

        # Build wrangler command
        cmd = ["wrangler", "d1", "execute", db_name]
        if remote:
            cmd.append("--remote")
        cmd.extend(["--command", sql])

        try:
            # Execute command
            result = subprocess.run(
                cmd,
                env=self.env,
                capture_output=True,
                text=True,
                check=False
            )

            if result.returncode != 0:
                return QueryResult(
                    success=False,
                    results=[],
                    meta={},
                    error=result.stderr
                )

            # Parse JSON output (wrangler outputs JSON array)
            output_lines = result.stdout.strip().split('\n')
            # Find the JSON array (starts with '[')
            json_output = None
            for line in output_lines:
                if line.strip().startswith('['):
                    json_output = '\n'.join(output_lines[output_lines.index(line):])
                    break

            if not json_output:
                return QueryResult(
                    success=False,
                    results=[],
                    meta={},
                    error="Could not parse wrangler output"
                )

            data = json.loads(json_output)

            if data and len(data) > 0:
                first_result = data[0]
                return QueryResult(
                    success=first_result.get("success", False),
                    results=first_result.get("results", []),
                    meta=first_result.get("meta", {})
                )
            else:
                return QueryResult(
                    success=False,
                    results=[],
                    meta={},
                    error="Empty response from wrangler"
                )

        except Exception as e:
            return QueryResult(
                success=False,
                results=[],
                meta={},
                error=str(e)
            )

    def select(self, database: str, table: str, where: Optional[str] = None,
               limit: Optional[int] = None) -> QueryResult:
        """
        Execute SELECT query

        Args:
            database: Database key
            table: Table name
            where: Optional WHERE clause (without 'WHERE' keyword)
            limit: Optional LIMIT

        Returns:
            QueryResult
        """
        sql = f"SELECT * FROM {table}"
        if where:
            sql += f" WHERE {where}"
        if limit:
            sql += f" LIMIT {limit}"

        return self.execute(database, sql)

    def insert(self, database: str, table: str, data: Dict[str, Any]) -> QueryResult:
        """
        Insert data into table

        Args:
            database: Database key
            table: Table name
            data: Dictionary of column: value pairs

        Returns:
            QueryResult
        """
        columns = ", ".join(data.keys())
        # Properly escape values
        values = []
        for v in data.values():
            if v is None:
                values.append("NULL")
            elif isinstance(v, (int, float)):
                values.append(str(v))
            else:
                # Escape single quotes in strings
                escaped = str(v).replace("'", "''")
                values.append(f"'{escaped}'")

        values_str = ", ".join(values)
        sql = f"INSERT INTO {table} ({columns}) VALUES ({values_str})"

        return self.execute(database, sql)

    def update(self, database: str, table: str, data: Dict[str, Any],
               where: str) -> QueryResult:
        """
        Update data in table

        Args:
            database: Database key
            table: Table name
            data: Dictionary of column: value pairs to update
            where: WHERE clause (without 'WHERE' keyword)

        Returns:
            QueryResult
        """
        set_clauses = []
        for col, val in data.items():
            if val is None:
                set_clauses.append(f"{col} = NULL")
            elif isinstance(val, (int, float)):
                set_clauses.append(f"{col} = {val}")
            else:
                escaped = str(val).replace("'", "''")
                set_clauses.append(f"{col} = '{escaped}'")

        set_str = ", ".join(set_clauses)
        sql = f"UPDATE {table} SET {set_str} WHERE {where}"

        return self.execute(database, sql)

    def delete(self, database: str, table: str, where: str) -> QueryResult:
        """
        Delete data from table

        Args:
            database: Database key
            table: Table name
            where: WHERE clause (without 'WHERE' keyword)

        Returns:
            QueryResult
        """
        sql = f"DELETE FROM {table} WHERE {where}"
        return self.execute(database, sql)

    def count(self, database: str, table: str, where: Optional[str] = None) -> int:
        """
        Count rows in table

        Args:
            database: Database key
            table: Table name
            where: Optional WHERE clause

        Returns:
            Number of rows, or -1 on error
        """
        sql = f"SELECT COUNT(*) as count FROM {table}"
        if where:
            sql += f" WHERE {where}"

        result = self.execute(database, sql)
        if result.success and result.results:
            return result.results[0].get("count", -1)
        return -1

    def list_tables(self, database: str) -> List[str]:
        """
        List all tables in database

        Args:
            database: Database key

        Returns:
            List of table names
        """
        sql = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
        result = self.execute(database, sql)

        if result.success:
            return [row["name"] for row in result.results]
        return []


# Convenience functions for quick use
def query(database: str, sql: str) -> QueryResult:
    """Execute a SQL query"""
    client = WranglerD1Client()
    return client.execute(database, sql)


def insert_record(database: str, table: str, data: Dict[str, Any]) -> QueryResult:
    """Insert a record"""
    client = WranglerD1Client()
    return client.insert(database, table, data)


def get_records(database: str, table: str, where: Optional[str] = None,
                limit: Optional[int] = None) -> List[Dict[str, Any]]:
    """Get records from a table"""
    client = WranglerD1Client()
    result = client.select(database, table, where, limit)
    return result.results if result.success else []


# Example usage
if __name__ == "__main__":
    # Initialize client
    client = WranglerD1Client()

    # List tables in medical database
    print("📋 Tables in app_medical:")
    tables = client.list_tables("medical")
    for table in tables:
        print(f"  - {table}")

    # Count patients
    patient_count = client.count("medical", "patients")
    print(f"\n📊 Total patients: {patient_count}")

    # Example insert (commented out to avoid accidents)
    # result = client.insert("medical", "patients", {
    #     "name": "John Doe",
    #     "age": 35,
    #     "gender": "M"
    #     })
    # print(f"\n✅ Insert result: {result.success}")

    # Example select
    print("\n🔍 Recent patients:")
    result = client.select("medical", "patients", limit=5)
    if result.success:
        for patient in result.results:
            print(f"  - {patient}")
    else:
        print(f"  Error: {result.error}")
