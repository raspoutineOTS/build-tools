#!/bin/bash

# Universal Document Processor
# Intelligent document analysis and processing tool for various file formats

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/processor-config.json}"
LOG_FILE="${LOG_FILE:-$SCRIPT_DIR/processor.log}"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/processed}"

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "$LOG_FILE" >&2
}

# Initialize configuration
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "Creating default processor configuration"
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << 'EOF'
{
  "processors": {
    "pdf": {
      "enabled": true,
      "extract_text": true,
      "extract_metadata": true,
      "ocr_enabled": false,
      "tools": ["pdftotext", "pdfinfo"]
    },
    "docx": {
      "enabled": true,
      "extract_text": true,
      "extract_metadata": true,
      "preserve_formatting": false
    },
    "txt": {
      "enabled": true,
      "encoding": "auto",
      "analyze_content": true
    },
    "csv": {
      "enabled": true,
      "delimiter": "auto",
      "header_detection": true,
      "max_preview_rows": 10
    }
  },
  "analysis": {
    "keywords": {
      "healthcare": ["medical", "hospital", "patient", "health", "clinical"],
      "business": ["report", "analysis", "revenue", "profit", "meeting"],
      "urgent": ["urgent", "asap", "emergency", "critical", "immediate"]
    },
    "metrics_extraction": true,
    "summary_generation": true,
    "category_classification": true
  },
  "output": {
    "format": "json",
    "include_raw_text": false,
    "include_metadata": true,
    "generate_summary": true
  },
  "storage": {
    "keep_originals": true,
    "output_directory": "./processed",
    "database_integration": false
  }
}
EOF
    fi
}

# Process PDF files
process_pdf() {
    local file_path="$1"
    local output_file="$2"
    
    log "Processing PDF: $(basename "$file_path")"
    
    local extracted_text=""
    local metadata="{}"
    
    # Extract text using pdftotext if available
    if command -v pdftotext >/dev/null 2>&1; then
        local temp_text
        temp_text=$(mktemp)
        if pdftotext "$file_path" "$temp_text" 2>/dev/null; then
            extracted_text=$(cat "$temp_text")
            rm -f "$temp_text"
        fi
    else
        log "Warning: pdftotext not available, skipping text extraction"
    fi
    
    # Extract metadata using pdfinfo if available
    if command -v pdfinfo >/dev/null 2>&1; then
        local temp_info
        temp_info=$(mktemp)
        if pdfinfo "$file_path" > "$temp_info" 2>/dev/null; then
            # Convert pdfinfo output to JSON format
            metadata=$(python3 -c "
import json
import sys

metadata = {}
with open('$temp_info', 'r') as f:
    for line in f:
        if ':' in line:
            key, value = line.split(':', 1)
            metadata[key.strip().lower().replace(' ', '_')] = value.strip()

print(json.dumps(metadata, indent=2))
" 2>/dev/null || echo "{}")
            rm -f "$temp_info"
        fi
    fi
    
    # Generate analysis
    local analysis
    analysis=$(analyze_content "$extracted_text")
    
    # Create output JSON
    python3 -c "
import json
import os
from datetime import datetime

data = {
    'file_info': {
        'name': '$(basename "$file_path")',
        'path': '$file_path',
        'size': $(stat -c%s "$file_path" 2>/dev/null || echo 0),
        'processed_at': datetime.now().isoformat(),
        'type': 'pdf'
    },
    'content': {
        'text': '''$extracted_text''',
        'length': len('''$extracted_text''')
    },
    'metadata': $metadata,
    'analysis': $analysis
}

with open('$output_file', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
"
}

# Process DOCX files
process_docx() {
    local file_path="$1"
    local output_file="$2"
    
    log "Processing DOCX: $(basename "$file_path")"
    
    local extracted_text=""
    
    # Extract text using python-docx if available
    if python3 -c "import docx" >/dev/null 2>&1; then
        extracted_text=$(python3 -c "
import docx
import sys

try:
    doc = docx.Document('$file_path')
    text = []
    for paragraph in doc.paragraphs:
        text.append(paragraph.text)
    print('\n'.join(text))
except Exception as e:
    sys.stderr.write(f'Error processing DOCX: {e}\n')
" 2>/dev/null || echo "")
    else
        # Fallback: try unzip and extract from XML
        local temp_dir
        temp_dir=$(mktemp -d)
        if unzip -q "$file_path" -d "$temp_dir" 2>/dev/null; then
            if [[ -f "$temp_dir/word/document.xml" ]]; then
                # Simple text extraction from XML (basic)
                extracted_text=$(sed -n 's/.*<w:t[^>]*>\([^<]*\)<\/w:t>.*/\1/p' "$temp_dir/word/document.xml" | tr '\n' ' ')
            fi
        fi
        rm -rf "$temp_dir"
    fi
    
    # Generate analysis
    local analysis
    analysis=$(analyze_content "$extracted_text")
    
    # Create output JSON
    python3 -c "
import json
import os
from datetime import datetime

data = {
    'file_info': {
        'name': '$(basename "$file_path")',
        'path': '$file_path',
        'size': $(stat -c%s "$file_path" 2>/dev/null || echo 0),
        'processed_at': datetime.now().isoformat(),
        'type': 'docx'
    },
    'content': {
        'text': '''$extracted_text''',
        'length': len('''$extracted_text''')
    },
    'analysis': $analysis
}

with open('$output_file', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
"
}

# Process text files
process_txt() {
    local file_path="$1"
    local output_file="$2"
    
    log "Processing TXT: $(basename "$file_path")"
    
    local content
    content=$(cat "$file_path")
    
    # Generate analysis
    local analysis
    analysis=$(analyze_content "$content")
    
    # Create output JSON
    python3 -c "
import json
import os
from datetime import datetime

data = {
    'file_info': {
        'name': '$(basename "$file_path")',
        'path': '$file_path',
        'size': $(stat -c%s "$file_path" 2>/dev/null || echo 0),
        'processed_at': datetime.now().isoformat(),
        'type': 'txt'
    },
    'content': {
        'text': '''$content''',
        'length': len('''$content''')
    },
    'analysis': $analysis
}

with open('$output_file', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
"
}

# Content analysis function
analyze_content() {
    local content="$1"
    
    if [[ -z "$content" ]]; then
        echo '{"categories": [], "keywords": [], "summary": "No content to analyze"}'
        return
    fi
    
    # Simple analysis using Python
    python3 -c "
import json
import re
from collections import Counter

content = '''$content'''

# Define keyword categories
categories = {
    'healthcare': ['medical', 'hospital', 'patient', 'health', 'clinical', 'doctor', 'treatment'],
    'business': ['report', 'analysis', 'revenue', 'profit', 'meeting', 'sales', 'market'],
    'urgent': ['urgent', 'asap', 'emergency', 'critical', 'immediate', 'priority'],
    'technical': ['system', 'server', 'database', 'api', 'code', 'bug', 'fix'],
    'financial': ['budget', 'cost', 'price', 'payment', 'invoice', 'expense']
}

# Find categories
found_categories = []
content_lower = content.lower()

for category, keywords in categories.items():
    matches = sum(1 for keyword in keywords if keyword in content_lower)
    if matches > 0:
        found_categories.append({
            'category': category,
            'matches': matches,
            'confidence': min(matches / len(keywords), 1.0)
        })

# Extract key phrases (simple word frequency)
words = re.findall(r'\b[a-zA-Z]{4,}\b', content.lower())
word_freq = Counter(words)
keywords = [{'word': word, 'frequency': freq} for word, freq in word_freq.most_common(10)]

# Generate simple summary (first 200 characters)
summary = content.strip()[:200]
if len(content) > 200:
    summary += '...'

analysis = {
    'categories': found_categories,
    'keywords': keywords,
    'summary': summary,
    'word_count': len(content.split()),
    'character_count': len(content)
}

print(json.dumps(analysis, indent=2, ensure_ascii=False))
"
}

# Main processing function
process_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        error "File not found: $file_path"
        return 1
    fi
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Determine file type
    local extension
    extension=$(echo "${file_path##*.}" | tr '[:upper:]' '[:lower:]')
    
    # Generate output filename
    local base_name
    base_name=$(basename "$file_path" ".$extension")
    local output_file="$OUTPUT_DIR/${base_name}_processed.json"
    
    log "Processing file: $file_path -> $output_file"
    
    case "$extension" in
        pdf)
            process_pdf "$file_path" "$output_file"
            ;;
        docx)
            process_docx "$file_path" "$output_file"
            ;;
        txt)
            process_txt "$file_path" "$output_file"
            ;;
        *)
            error "Unsupported file type: $extension"
            return 1
            ;;
    esac
    
    if [[ -f "$output_file" ]]; then
        log "Successfully processed: $(basename "$file_path")"
        echo "$output_file"
    else
        error "Failed to process: $(basename "$file_path")"
        return 1
    fi
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <file_path> [file_path2] ..."
        echo "       $0 --help"
        exit 1
    fi
    
    # Initialize configuration
    init_config
    
    # Process each file
    for file_path in "$@"; do
        if [[ "$file_path" == "--help" ]]; then
            cat << EOF
Universal Document Processor

Process documents and extract text, metadata, and insights.

Usage: $0 [OPTIONS] <file_path> [file_path2] ...

OPTIONS:
  --help              Show this help message

SUPPORTED FORMATS:
  - PDF files (.pdf)
  - Word documents (.docx)  
  - Text files (.txt)

ENVIRONMENT VARIABLES:
  CONFIG_FILE         Path to configuration file
  LOG_FILE           Path to log file
  OUTPUT_DIR         Directory for processed files

EXAMPLES:
  $0 document.pdf                    # Process single PDF
  $0 *.docx                         # Process all DOCX files
  $0 /path/to/report.pdf            # Process with full path

OUTPUT:
  Each processed file generates a JSON file with:
  - Extracted text content
  - File metadata
  - Content analysis and categories
  - Keywords and summary

EOF
            exit 0
        fi
        
        process_file "$file_path"
    done
}

# Run main function
main "$@"