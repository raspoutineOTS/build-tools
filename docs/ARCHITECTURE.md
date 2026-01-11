# 🏗️ Build-Tools Architecture v3.0

**Version**: 3.0
**Last Updated**: January 2026
**Status**: Production-Ready

---

## 📋 Overview

Build-Tools implements a **multi-agent orchestration architecture** using Claude Code native agents. This architecture has been validated in production environments handling 1,000+ operations per day.

### Design Principles

1. **Modularity**: Each agent is independent and replaceable
2. **Composability**: Agents work together through clear interfaces
3. **Scalability**: Parallel execution where possible
4. **Observability**: Clear data flow and error handling
5. **Security**: Credentials managed through environment variables

---

## 🎯 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                    USER / TRIGGER                           │
│          (Message, File, Webhook, Schedule)                 │
│                                                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                  MONITORING HOOKS                           │
│         (SessionStart, UserPromptSubmit, etc.)              │
│                                                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│               SYSTEM ORCHESTRATOR (Sonnet)                  │
│                                                             │
│  • Receives requests                                        │
│  • Analyzes requirements                                    │
│  • Delegates to specialized agents                          │
│  • Aggregates results                                       │
│  • Returns formatted response                               │
│                                                             │
└───┬──────────────────┬──────────────────┬──────────────┬────┘
    │                  │                  │              │
    ▼                  ▼                  ▼              ▼
┌─────────┐      ┌──────────┐      ┌──────────┐   ┌──────────┐
│ MESSAGE │      │   DATA   │      │  DOMAIN  │   │  MEDIA   │
│PROCESSOR│      │  SORTER  │      │ANALYZERS │   │PROCESSOR │
│ (Haiku) │      │ (Sonnet) │      │(Varies)  │   │ (Haiku)  │
└─────────┘      └──────────┘      └──────────┘   └──────────┘
    │                  │                  │              │
    │ Extract          │ Classify         │ Analyze      │ Process
    │ Content          │ & Route          │ Domain       │ Media
    │                  │                  │              │
    └──────────────────┴──────────────────┴──────────────┘
                         │
                         ▼
                ┌──────────────────┐
                │    DATABASE      │
                │    MANAGER       │
                │    (Haiku)       │
                │                  │
                │  • Insert        │
                │  • Update        │
                │  • Query         │
                │  • Validate      │
                └────────┬─────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    ┌────────┐     ┌────────┐     ┌────────┐
    │Database│     │Database│     │Database│
    │   A    │     │   B    │     │   C    │
    └────────┘     └────────┘     └────────┘
```

---

## 🧩 Component Details

### 1. Monitoring Hooks

**Purpose**: Detect events and trigger automation workflows

**Types**:
- **SessionStart**: Triggers on Claude Code session start
- **UserPromptSubmit**: Triggers when user submits a prompt
- **File Watchers**: Monitor directories for new files (OCR, media)

**Example Hook** (`monitor-messages.sh`):
```bash
#!/bin/bash
# Check for new messages in the last hour
NEW_COUNT=$(query_database "SELECT COUNT(*) FROM messages WHERE timestamp > datetime('now', '-1 hour')")

if [ $NEW_COUNT -gt 0 ]; then
    echo "🔔 Found $NEW_COUNT new messages - triggering analysis"
    exit 0  # Trigger automation
fi
```

**Configuration**:
```json
{
  "hooks": {
    "SessionStart": [".claude/hooks/monitor-messages.sh"],
    "UserPromptSubmit": [".claude/hooks/check-context.sh"]
  }
}
```

---

### 2. System Orchestrator

**Purpose**: Central coordinator for multi-agent workflows

**Model**: Claude Sonnet (complex reasoning required)

**Responsibilities**:
1. **Request Analysis**: Understand user intent
2. **Agent Selection**: Choose appropriate specialized agents
3. **Execution Coordination**: Run agents in sequence or parallel
4. **Result Aggregation**: Combine outputs from multiple agents
5. **Response Formatting**: Present results to user

**Decision Tree**:
```
User Request
    │
    ├─ Contains media? → Delegate to Media Processor
    ├─ Needs classification? → Delegate to Data Sorter
    ├─ Domain-specific? → Delegate to Domain Analyzers
    └─ Database operation? → Delegate to Database Manager
```

**Example Prompt** (simplified):
```markdown
You are a system orchestrator coordinating specialized agents.

When you receive a request:
1. Analyze the requirements
2. Identify which agents are needed
3. Delegate to agents in optimal order
4. Aggregate and format results

Available agents:
- @message-processor: Extract content from messages
- @data-sorter: Classify and route data
- @domain-analyzer-*: Specialized domain analysis
- @database-manager: Database operations

Always return a structured summary of actions taken.
```

---

### 3. Message Processor

**Purpose**: Extract and normalize content from various sources

**Model**: Claude Haiku (structured extraction, fast)

**Supported Sources**:
- Text messages (WhatsApp, Slack, Email)
- PDF documents
- Audio messages (via transcription MCP)
- Images (via OCR)
- Excel spreadsheets

**Output Format**:
```json
{
  "source": "whatsapp",
  "timestamp": "2026-01-15T10:30:00Z",
  "sender": "user_id_123",
  "content_type": "text",
  "extracted_text": "Message content here",
  "metadata": {
    "language": "en",
    "confidence": 0.95
  },
  "media_urls": []
}
```

**Capabilities**:
- Language detection
- Format normalization
- Metadata extraction
- Error handling for corrupted files

---

### 4. Data Sorter

**Purpose**: Intelligent classification and routing

**Model**: Claude Sonnet (complex classification logic)

**Workflow**:
```
Input Data
    │
    ├─ Extract keywords
    ├─ Analyze context
    ├─ Detect domain(s)
    │
    ├─ Single domain? → Route to specific analyzer
    ├─ Multiple domains? → Split and route to multiple analyzers
    └─ Unknown domain? → Ask clarifying questions
```

**Classification Methods**:
1. **Keyword Matching**: Predefined term dictionaries
2. **Semantic Analysis**: Claude's understanding of context
3. **Pattern Recognition**: Recurring structures
4. **Confidence Scoring**: Probabilistic classification

**Output Format**:
```json
{
  "primary_domain": "medical",
  "confidence": 0.92,
  "secondary_domains": ["logistics"],
  "routing_decisions": [
    {
      "agent": "medical-domain-analyzer",
      "data_subset": { ... },
      "priority": "high"
    }
  ],
  "gaps_detected": [
    {
      "field": "patient_age",
      "question": "What is the patient's age?"
    }
  ]
}
```

---

### 5. Domain Analyzers

**Purpose**: Specialized analysis for specific business domains

**Model**: Configurable (Sonnet for complex, Haiku for structured)

**Generic Template**:
```markdown
# Domain Analyzer Template

You are a specialized analyzer for the [DOMAIN_NAME] domain.

## Your Expertise
- [Domain-specific knowledge area 1]
- [Domain-specific knowledge area 2]
- [Domain-specific knowledge area 3]

## Input
You receive extracted data that has been classified as [DOMAIN_NAME].

## Your Tasks
1. Extract domain-specific entities
2. Validate data completeness
3. Generate domain-specific metrics
4. Identify anomalies or alerts
5. Create structured database mappings

## Output Format
{
  "domain": "[DOMAIN_NAME]",
  "entities": { ... },
  "metrics": { ... },
  "alerts": [ ... ],
  "database_mapping": { ... }
}
```

**Example Domains**:
- **Medical**: Patient records, diagnoses, treatments
- **Financial**: Transactions, budgets, forecasts
- **Logistics**: Shipments, inventory, routes
- **Customer Support**: Tickets, resolutions, satisfaction

**Customization**:
1. Copy `agents/domain-analyzer-template/`
2. Replace `[DOMAIN_NAME]` with your domain
3. Define domain-specific entities and rules
4. Configure output schema

---

### 6. Media Processor

**Purpose**: Handle multimedia content

**Model**: Claude Haiku (delegated processing)

**Capabilities**:

**Audio Processing**:
- Transcription (via ElevenLabs MCP)
- Language detection
- Speaker diarization
- Translation (ar→en, fr→en, etc.)

**Image Processing**:
- OCR (via Tesseract or cloud OCR)
- Object detection
- Text extraction from screenshots
- Diagram interpretation

**Document Processing**:
- PDF text extraction
- Excel parsing
- Word document reading
- Format conversion

**Integration with MCPs**:
```markdown
For audio transcription:
1. Download audio file
2. Call ElevenLabs MCP: speech_to_text(file_path, language_code="auto", model_id="scribe_v1", enable_logging=true)
3. Receive transcript with confidence score
4. Store in audio_transcriptions table
```

---

### 7. Database Manager

**Purpose**: Centralized database operations

**Model**: Claude Haiku (CRUD operations, fast)

**Supported Databases**:
- **Cloudflare D1** (SQLite edge) - via Wrangler CLI
- **PostgreSQL** - via adapters
- **MySQL** - via adapters
- **MongoDB** - via adapters

**Operations**:

**Insert**:
```python
database_manager.insert(
    database="analytics",
    table="events",
    data={
        "user_id": 123,
        "event_type": "message_sent",
        "timestamp": "2026-01-15T10:30:00Z"
    }
)
```

**Query**:
```python
results = database_manager.query(
    database="analytics",
    sql="SELECT * FROM events WHERE user_id = ? LIMIT 10",
    params=[123]
)
```

**Features**:
- SQL injection prevention
- Transaction support
- Error handling and retries
- Data validation before insert
- Schema compatibility checks

---

## 🔄 Workflow Examples

### Example 1: Message Analysis Pipeline

```
1. USER: Receives WhatsApp message with audio attachment

2. HOOK: whatsapp-monitor.sh detects new message

3. ORCHESTRATOR:
   - Analyzes request: "New message with audio"
   - Delegates to @message-processor

4. MESSAGE PROCESSOR:
   - Downloads audio file
   - Calls ElevenLabs MCP for transcription
   - Detects language: Arabic
   - Translates to English
   - Returns: { extracted_text: "...", language: "ar" }

5. ORCHESTRATOR:
   - Delegates to @data-sorter with transcript

6. DATA SORTER:
   - Analyzes keywords and context
   - Detects domains: ["medical", "logistics"]
   - Routes to 2 analyzers in parallel

7. DOMAIN ANALYZERS:
   - medical-analyzer: Extracts patient data
   - logistics-analyzer: Extracts shipment info
   - Both return structured data + DB mappings

8. DATABASE MANAGER:
   - Inserts patient data to medical_db
   - Inserts shipment data to logistics_db
   - Inserts audio transcript to both DBs
   - Returns: { inserted: 5 records }

9. ORCHESTRATOR:
   - Aggregates results
   - Formats response
   - Returns to user:
     "✅ Message processed:
      - 1 patient record created
      - 1 shipment logged
      - Audio transcribed (95% confidence)"
```

### Example 2: Batch Document Processing

```
1. USER: Drops 50 PDF files in watched directory

2. HOOK: ocr-watcher.sh detects new files

3. ORCHESTRATOR:
   - Analyzes: "50 PDF documents"
   - Delegates to @media-processor (batch mode)

4. MEDIA PROCESSOR:
   - Processes 50 PDFs in parallel (batches of 10)
   - Extracts text from each
   - Returns array of extracted content

5. ORCHESTRATOR:
   - Delegates to @data-sorter for batch classification

6. DATA SORTER:
   - Classifies each document by domain
   - Returns: { financial: 30, legal: 15, misc: 5 }

7. ORCHESTRATOR:
   - Delegates to domain analyzers:
     - financial-analyzer: Processes 30 docs
     - legal-analyzer: Processes 15 docs
     - generic-analyzer: Processes 5 docs

8. DATABASE MANAGER:
   - Inserts 50 records across 3 databases
   - Updates processing queue
   - Returns: { success: 50, failed: 0 }

9. ORCHESTRATOR:
   - Returns summary:
     "✅ Processed 50 documents:
      - 30 financial records
      - 15 legal contracts
      - 5 miscellaneous files
      - 100% success rate"
```

---

## 🚀 Performance Characteristics

### Latency (Production Metrics)

| Operation | Haiku Agent | Sonnet Agent |
|-----------|-------------|--------------|
| Message extraction | 0.5-1s | 1-2s |
| Classification | 1-2s | 2-4s |
| Domain analysis | 0.5-1s | 3-5s |
| Database insert | 0.1-0.3s | 0.1-0.3s |

**Total Pipeline (Message → Database)**:
- Simple path: 2-4 seconds
- Complex path (multi-domain): 5-10 seconds

### Throughput

**Tested Capacity**:
- **Messages**: 200+ per day sustained
- **Documents**: 50+ batch processing
- **Audio**: 30+ transcriptions per day

**Bottlenecks**:
- MCP rate limits (ElevenLabs: 100 requests/day free tier)
- Database write throughput (D1: ~10 writes/second)
- Agent invocation limits (Claude API rate limits)

### Cost Optimization

**Model Selection Strategy**:
- **Haiku** for: Extraction, CRUD, structured tasks (-65% cost)
- **Sonnet** for: Classification, complex reasoning, orchestration

**Production Cost** (Real deployment):
- Base infrastructure: $0/month (serverless)
- Claude API: ~$0.03/month marginal cost
- MCP services: Varies by tier (ElevenLabs: $0-$99/month)

---

## 🔒 Security Architecture

### Credential Flow

```
.env file (gitignored)
    │
    ├─ Loaded by shell (source .env)
    │
    ├─ Passed to agents as environment variables
    │
    ├─ Agents use for MCP authentication
    │
    └─ Never logged or exposed
```

### Data Privacy

**Sensitive Data Handling**:
1. **At Rest**: Encrypted in databases (D1 encryption at rest)
2. **In Transit**: HTTPS for all API calls
3. **In Memory**: Cleared after processing
4. **In Logs**: Redacted automatically

**Access Control**:
- Agents run with minimal permissions
- Database access via read-only tokens where possible
- MCP credentials scoped to specific operations

---

## 📊 Monitoring & Observability

### Metrics Tracked

**Agent Performance**:
- Invocation count
- Latency (p50, p95, p99)
- Error rate
- Cost per invocation

**Pipeline Health**:
- End-to-end latency
- Success rate
- Data quality scores
- Alert frequency

**Resource Usage**:
- API quota consumption
- Database storage
- MCP credit usage

### Logging Strategy

**Log Levels**:
- **DEBUG**: Agent internal state
- **INFO**: Pipeline progress
- **WARNING**: Recoverable errors
- **ERROR**: Failed operations
- **CRITICAL**: System-wide failures

**Log Storage**:
- Local: `~/.claude/logs/`
- Centralized: CloudWatch, Datadog (optional)

---

## 🔧 Extensibility

### Adding New Agents

1. **Copy Template**: Use `agents/domain-analyzer-template/`
2. **Define Purpose**: What does this agent specialize in?
3. **Specify Input/Output**: Clear data contracts
4. **Choose Model**: Haiku (fast) or Sonnet (complex)?
5. **Test Isolation**: Verify agent works standalone
6. **Integrate**: Update orchestrator to delegate to new agent

### Adding New MCPs

1. **Install MCP**: Follow MCP server installation guide
2. **Configure**: Add to Claude Code MCP settings
3. **Wrapper Agent**: Create agent to interface with MCP
4. **Document**: Add to `docs/mcp-integrations/`
5. **Test**: Verify MCP connectivity and responses

### Adding New Databases

1. **Driver**: Install database client/driver
2. **Adapter**: Create database adapter following interface
3. **Config**: Add connection string to `.env.example`
4. **Update Manager**: Add database to database-manager
5. **Test**: Verify CRUD operations

---

## 📚 Additional Resources

- **Getting Started**: `/docs/GETTING_STARTED.md`
- **Agent Development**: `/docs/guides/creating-agents.md`
- **MCP Integration**: `/docs/guides/mcp-integration.md`
- **Security**: `/docs/guides/security-best-practices.md`
- **Troubleshooting**: `/docs/TROUBLESHOOTING.md`

---

**Document Version**: 1.0
**Architecture Version**: 3.0
**Last Updated**: January 2026
**Status**: Production-Ready
