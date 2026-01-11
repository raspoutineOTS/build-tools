# 🗄️ CLOUDFLARE D1 ACCESS GUIDE

**Two Approaches for D1 Database Access**

---

## 🎯 OVERVIEW

This guide covers **two methods** for accessing Cloudflare D1 databases:
1. **MCP Cloudflare Server** - Protocol-based integration
2. **Wrangler CLI** - Direct command-line access

Both approaches are included in this toolkit for flexibility.

---

## 📌 APPROACH 1: MCP CLOUDFLARE SERVER

### When to Use
- ✅ Real-time integration with Claude Code agents
- ✅ Protocol-based communication
- ✅ Multiple concurrent database operations
- ✅ Automatic result formatting

### Setup
```json
{
  "mcpServers": {
    "cloudflare": {
      "type": "sse",
      "url": "https://bindings.mcp.cloudflare.com/sse",
      "headers": {
        "Authorization": "Bearer YOUR_CLOUDFLARE_API_TOKEN"
      },
      "env": {
        "CLOUDFLARE_ACCOUNT_ID": "YOUR_ACCOUNT_ID",
        "CLOUDFLARE_D1_DATABASES": "{\"db_name\":{\"uuid\":\"DB_UUID\",\"name\":\"db_name\"}}"
      }
    }
  }
}
```

### Usage with Agents
```bash
@database-manager Query users from production database
```

---

## 📌 APPROACH 2: WRANGLER CLI

### When to Use
- ✅ Direct CLI access without MCP overhead
- ✅ Scripting and automation
- ✅ Troubleshooting and debugging
- ✅ One-time operations

### Installation
```bash
npm install -g wrangler
# Version: 4.45.3+ recommended
```

### Configuration
```bash
# Set environment variables
export CLOUDFLARE_API_TOKEN="your_api_token_here"
export CLOUDFLARE_ACCOUNT_ID="your_account_id_here"
```

Note: For HTTP API writes, Cloudflare now requires API tokens with explicit
`D1:Edit` permission. Invalid SQL returns HTTP 400 and overloaded databases
can return HTTP 429.

### Helper Scripts Included

#### 🔧 `wrangler-d1.sh`
Bash wrapper for common Wrangler operations.

**Location**: `automation/database-tools/wrangler-d1.sh`

**Commands**:
```bash
# List all D1 databases
./wrangler-d1.sh list

# List tables in a database
./wrangler-d1.sh tables core

# Execute SQL query
./wrangler-d1.sh query medical "SELECT * FROM patients LIMIT 10"

# Count entries in main tables
./wrangler-d1.sh count core

# Show detailed database info
./wrangler-d1.sh info logistics
```

**Database Shortcuts**:
| Shortcut | Database | Purpose |
|----------|----------|---------|
| `core` | app_core | Admin, budgets, projects |
| `medical` | app_medical | Patients, healthcare data |
| `distribution` | app_distribution | Beneficiaries, aid distribution |
| `logistics` | app_logistics | Inventory, transport |

#### 🐍 `wrangler_helper.py`
Python module for programmatic D1 access.

**Location**: `automation/database-tools/wrangler_helper.py`

**Usage**:
```python
from wrangler_helper import WranglerD1Client

# Initialize client (uses env vars)
client = WranglerD1Client()

# List tables
tables = client.list_tables("medical")

# Count records
count = client.count("medical", "patients")

# Select data
result = client.select("medical", "patients", limit=10)

# Insert data
result = client.insert("medical", "patients", {
    "name": "John Doe",
    "age": 35,
    "gender": "M"
})

# Update data
result = client.update("medical", "patients",
    {"status": "active"},
    "id=123"
)

# Custom query
result = client.execute("medical", "SELECT COUNT(*) FROM encounters")
```

---

## 🔄 WHEN TO USE WHICH APPROACH

### Use MCP Server When:
- Working within Claude Code agents
- Need real-time multi-database operations
- Want automatic result parsing
- Building interactive workflows

### Use Wrangler CLI When:
- Writing automation scripts
- Debugging database issues
- Running one-time migrations
- Need direct SQL access
- Building custom pipelines

---

## 📊 EXAMPLE: MULTI-DATABASE SYSTEM

### 4-Database Architecture

```
app_core (17 tables)
├── users, projects, budgets
├── organizations, partnerships
└── admin_documents, audit_log

app_medical (9 tables)
├── patients, encounters
├── prescriptions, facilities
└── medical_reports

app_distribution (8 tables)
├── beneficiaries
├── distribution_events
└── deliveries, assessments

app_logistics (7 tables)
├── warehouses, stock_movements
├── items_catalog
└── suppliers, transport
```

### Database Name Mapping

```bash
# Helper scripts use short names
./wrangler-d1.sh tables core  # → app_core

# Python module supports both
client.select("core", "users")       # Short name
client.select("app_core", "users")   # Full name
```

---

## 🔑 SECURITY BEST PRACTICES

### Never Hardcode Credentials
```bash
# ❌ WRONG
export CLOUDFLARE_API_TOKEN="your_token_here"

# ✅ CORRECT - Load from secure file
source ~/.cloudflare/credentials.env
```

### Use Environment Variables
```python
import os

# Read from environment
api_token = os.getenv("CLOUDFLARE_API_TOKEN")
if not api_token:
    raise ValueError("CLOUDFLARE_API_TOKEN not set")
```

### Protect Configuration Files
```bash
# Add to .gitignore
.env
credentials.env
*.token
.cloudflare/
```

---

## 🧪 TESTING YOUR SETUP

### Test Wrangler CLI
```bash
# 1. Verify installation
wrangler --version

# 2. Test authentication
wrangler whoami

# 3. List databases
wrangler d1 list

# 4. Test query
wrangler d1 execute app_core --remote --command "SELECT 1 as test"
```

### Test Python Module
```python
from wrangler_helper import WranglerD1Client

client = WranglerD1Client()
tables = client.list_tables("core")
print(f"Found {len(tables)} tables: {tables}")
```

### Test Helper Script
```bash
# Run with --help to see all options
./wrangler-d1.sh help

# Test listing
./wrangler-d1.sh list
```

---

## 🚨 TROUBLESHOOTING

### Wrangler Auth Errors
```bash
# Issue: "Authentication failed"
# Fix: Verify token and account ID
echo $CLOUDFLARE_API_TOKEN
echo $CLOUDFLARE_ACCOUNT_ID

# Re-export if needed
export CLOUDFLARE_API_TOKEN="your_token"
export CLOUDFLARE_ACCOUNT_ID="your_id"
```

### Python Module Not Found
```bash
# Make sure wrangler_helper.py is in your Python path
export PYTHONPATH="/path/to/build-tools/automation/database-tools:$PYTHONPATH"

# Or copy to site-packages
cp wrangler_helper.py ~/.local/lib/python3.*/site-packages/
```

### MCP Connection Issues
```bash
# Check MCP server status
claude mcp list

# View MCP server logs
cat ~/.claude/logs/cloudflare.log

# Restart MCP server
claude mcp restart cloudflare
```

---

## 📚 ADDITIONAL RESOURCES

- **Cloudflare D1 Docs**: https://developers.cloudflare.com/d1/
- **Wrangler CLI Docs**: https://developers.cloudflare.com/workers/wrangler/
- **MCP Protocol**: https://github.com/anthropics/mcp

---

## 🎓 NEXT STEPS

1. Choose your preferred approach (MCP vs Wrangler)
2. Set up environment variables securely
3. Test connection with a simple query
4. Integrate with your agents or scripts
5. Build your multi-database workflows

**Both approaches work together** - use MCP for agent integration and Wrangler for direct access!
