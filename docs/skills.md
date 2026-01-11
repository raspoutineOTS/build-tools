# Skills Registry

This registry maps common tasks to agents and workflows. It is a planning aid for
selecting the right agent set and validating inputs/outputs. It does not change
runtime behavior by itself.

## Core Skills

### orchestration
- **Primary agent**: system-orchestrator (or system-orchestrator-enhanced)
- **Inputs**: user request, workflow context
- **Outputs**: task plan, delegated agent calls, aggregated result
- **Notes**: Use Sonnet for multi-step reasoning and routing.

### message-ingestion
- **Primary agent**: message-processor (or message-processor-enhanced)
- **Inputs**: platform targets, time ranges, message filters, media
- **Outputs**: normalized messages, transcripts, extracted content
- **Notes**: Enhanced agent adds audio transcription and translation.

### domain-routing
- **Primary agent**: data-sorter (or data-sorter-enhanced)
- **Inputs**: processed messages/documents
- **Outputs**: domain tags, routed payloads, missing-field detection
- **Notes**: Coordinates with domain analyzers when present.

### domain-analysis
- **Primary agent**: domain-analyzer-* (custom agents created from template)
- **Inputs**: domain-specific payloads
- **Outputs**: structured extraction, alerts, missing-data list
- **Notes**: Use Haiku for cost-efficient extraction tasks.

### data-storage
- **Primary agent**: database-manager (or database-manager-enhanced)
- **Inputs**: structured data, schema targets
- **Outputs**: database writes, queries, integrity checks
- **Notes**: Enhanced agent adds completeness tracking.

### data-quality
- **Primary agent**: data-sorter-enhanced + database-manager-enhanced
- **Inputs**: partial records, required field lists
- **Outputs**: completeness scores, follow-up requests, flags

### follow-up-collection
- **Primary agent**: data-sorter-enhanced + message-processor-enhanced
- **Inputs**: missing fields, original language context
- **Outputs**: follow-up questions, status tracking

## Workflow Mapping

### data_processing
- **Skills**: message-ingestion -> domain-routing -> data-storage
- **Agents**: message-processor -> data-sorter -> database-manager

### data_processing_enhanced
- **Skills**: message-ingestion -> domain-routing -> data-quality -> data-storage
- **Agents**: message-processor-enhanced -> data-sorter-enhanced -> database-manager-enhanced

### multi_domain_analysis
- **Skills**: message-ingestion -> domain-routing -> domain-analysis -> data-storage
- **Agents**: message-processor -> data-sorter -> domain-analyzer-* -> database-manager

## Inputs and Outputs (Checklist)

- **Inputs**: source platform, time window, language hints, schema targets
- **Outputs**: structured JSON, alerts, missing-field list, database actions
