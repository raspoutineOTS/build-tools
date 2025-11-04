# Domain Analyzer Agent Template

This template provides a starting point for creating specialized domain analyzer agents in the v3.0 architecture.

## Purpose

Domain analyzer agents perform semantic extraction and analysis of domain-specific data, replacing traditional Python regex-based analyzers with Claude's contextual reasoning capabilities.

## When to Create a Domain Analyzer

Create a new domain analyzer agent when you need to:
- Extract structured data from unstructured text/documents
- Apply domain-specific business logic and thresholds
- Generate alerts based on domain knowledge
- Map extracted data to database schemas
- Identify missing critical information

## Template Structure

See `agent-template.md` for a complete template with:
- Agent metadata (name, description, model, color)
- Core capabilities definition
- Semantic understanding advantages
- Database mapping strategy
- Intelligent gap detection
- Output format specification

## Customization Steps

### 1. Define Your Domain

**Domain**: [Your domain name, e.g., "financial", "legal", "technical"]

**Data Sources**: [Where data comes from, e.g., "financial reports", "legal documents", "support tickets"]

**Key Metrics**: [What you're extracting, e.g., "revenue", "contract terms", "response times"]

### 2. Design Database Schema

Define tables for your domain in your database system (D1, PostgreSQL, etc.):

```sql
-- Example: Main data table
CREATE TABLE [domain]_records (
    id INTEGER PRIMARY KEY,
    [key_field_1] TEXT,
    [key_field_2] REAL,
    data_completeness_score REAL,
    missing_fields TEXT,
    created_at TIMESTAMP
);

-- Example: Related data table
CREATE TABLE [domain]_metrics (
    id INTEGER PRIMARY KEY,
    record_id INTEGER,
    metric_name TEXT,
    metric_value REAL,
    FOREIGN KEY (record_id) REFERENCES [domain]_records(id)
);
```

### 3. Configure Extraction Logic

In your agent prompt, define:

**What to Extract**:
- Primary entities (e.g., customers, transactions, cases)
- Metrics and KPIs
- Relationships between entities
- Temporal data (dates, durations)
- Categorical data (statuses, types)

**How to Extract**:
- Use semantic understanding, not regex patterns
- Infer implicit information from context
- Handle variations in terminology
- Process multiple languages if needed

### 4. Set Alert Thresholds

Define business rules and thresholds:

```markdown
## Alert Thresholds

**Critical Alerts** (immediate action required):
- [Metric] > [threshold]: [description and action]
- [Condition]: [description and action]

**Warning Alerts** (monitoring required):
- [Metric] between [low] and [high]: [description]
- [Condition]: [description]
```

### 5. Configure Gap Detection

Specify required vs optional fields:

```markdown
## Data Requirements

**Essential Fields** (cannot proceed without):
- [field_name]: [why it's essential]
- [field_name]: [why it's essential]

**Important Fields** (should ask for):
- [field_name]: [why it's important]
- [field_name]: [why it's important]

**Optional Fields** (nice to have):
- [field_name]: [optional context]
```

### 6. Design Output Format

Standardize your agent's output:

```json
{
  "domain": "[your_domain]",
  "confidence_score": 0.85,
  "extracted_data": {
    "[category_1]": {...},
    "[category_2]": {...}
  },
  "alerts": [...],
  "d1_mappings": {
    "[table_name]": {...}
  },
  "missing_data": [...]
}
```

## Model Selection

### Use Haiku When:
- Data extraction is straightforward and structured
- High volume of analyses needed
- Cost optimization is important
- Speed is critical

### Use Sonnet When:
- Complex reasoning required
- Ambiguous or nuanced input
- Cross-domain synthesis needed
- Quality is paramount over cost

**Default Recommendation**: Start with Haiku, upgrade to Sonnet only if quality issues arise.

## Example Domains

### Financial Domain
- **Extract**: Revenue, expenses, profit margins, cash flow
- **Alerts**: Budget overruns, negative cash flow, unusual transactions
- **Tables**: financial_records, transactions, budgets

### Customer Support Domain
- **Extract**: Ticket metrics, response times, satisfaction scores, issue categories
- **Alerts**: SLA breaches, high-priority tickets, negative sentiment
- **Tables**: support_tickets, customer_interactions, satisfaction_scores

### Content Moderation Domain
- **Extract**: Content type, risk level, policy violations, sentiment
- **Alerts**: High-risk content, policy breaches, escalation triggers
- **Tables**: moderated_content, violations, moderator_actions

### Legal/Compliance Domain
- **Extract**: Contract terms, obligations, deadlines, parties
- **Alerts**: Expiring contracts, missing clauses, compliance risks
- **Tables**: contracts, obligations, compliance_checks

## Integration with Data Sorter

Update your `data-sorter` agent to route data to your new domain analyzer:

```markdown
### Domain Detection Keywords

**[Your Domain] Keywords**:
- [keyword1, keyword2, keyword3...]

**When [Domain] Detected**:
- Delegate to @[domain]-analyzer agent
- Expect d1_mappings for [table1], [table2]
- Handle missing_data follow-ups
```

## Testing Your Agent

### Test Data Preparation
1. Collect 10-20 representative samples
2. Include edge cases and variations
3. Mix complete and incomplete data
4. Test multilingual if applicable

### Quality Metrics
- **Extraction Accuracy**: >95% for key fields
- **False Positives**: <5%
- **Missing Data Detection**: >90%
- **Confidence Score Accuracy**: Within 10% of manual evaluation

### Performance Benchmarks
- **Target Latency**: <1 second per analysis
- **Cost Target**: <$0.002 per analysis
- **Throughput**: 100+ analyses per minute (Haiku)

## Maintenance

### Updating Agent Prompts
- Test changes with diverse samples
- Monitor confidence scores after updates
- Version control your agent definitions
- Document rationale for changes

### Monitoring Production
- Track extraction quality over time
- Monitor confidence score distributions
- Review missing data patterns
- Analyze alert effectiveness

## Common Patterns

### Pattern 1: Metric Extraction with Thresholds
```markdown
Extract [metric] from content
Apply threshold logic:
- Normal: [range]
- Warning: [range]
- Critical: [range]
Generate alerts based on threshold
```

### Pattern 2: Entity Relationship Mapping
```markdown
Identify primary entity (e.g., customer, project)
Extract related entities (e.g., contacts, milestones)
Map relationships for database foreign keys
```

### Pattern 3: Temporal Analysis
```markdown
Extract dates and durations
Calculate derived metrics (e.g., days overdue)
Detect temporal patterns (e.g., recurring events)
Alert on timeline issues
```

### Pattern 4: Multilingual Processing
```markdown
Detect input language
Extract data regardless of language
Normalize to standard format (e.g., dates, currencies)
Generate follow-up questions in original language
```

## Troubleshooting

### Low Confidence Scores
- Review extracted data for patterns
- Add more context to agent prompt
- Provide examples of good extractions
- Consider upgrading from Haiku to Sonnet

### Missing Data Not Detected
- Review essential fields definition
- Check D1 schema requirements
- Verify gap detection logic
- Test with intentionally incomplete samples

### Slow Performance
- Check agent model (Haiku faster than Sonnet)
- Optimize prompt length
- Batch similar analyses
- Use parallel execution

### High False Positive Rate
- Add negative examples to prompt
- Refine threshold definitions
- Implement confidence score filtering
- Review semantic understanding section

## License

MIT License - Customize freely for your use case
