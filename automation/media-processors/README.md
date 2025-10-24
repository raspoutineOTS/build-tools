# Media Processors

Collection of media processing tools for WhatsApp messages and attachments.

## Features

- **Audio Transcription**: Transcribe WhatsApp voice messages using ElevenLabs API
- **Excel Extractor**: Extract and analyze Excel/CSV files with domain detection

## Setup

### Environment Variables

```bash
# Audio Transcription
export ELEVENLABS_API_KEY="your_elevenlabs_api_key"
export WHATSAPP_STORE_PATH="/path/to/whatsapp/store"
export TRANSCRIPTIONS_PATH="/path/to/output/transcriptions"

# Excel Extractor
export EXCEL_OUTPUT_PATH="/path/to/output/excel"
```

### Dependencies

```bash
# Audio transcription
pip install requests

# Excel extractor
pip install openpyxl pandas xlrd
```

## Usage

### Audio Transcription Processor

Process WhatsApp audio messages:

```bash
python3 audio-transcription-processor.py '[
  {
    "id": "MESSAGE_ID",
    "chat_jid": "123456789@s.whatsapp.net",
    "language_hint": "en"
  }
]'
```

**Parameters:**
- `id`: Message ID
- `chat_jid`: WhatsApp JID of the chat
- `language_hint` (optional): Language code for better accuracy (e.g., "en", "ar", "fr")

**Output:**
```json
{
  "success": true,
  "message_id": "MESSAGE_ID",
  "transcription": "Transcribed text...",
  "detected_language": "en",
  "saved_file": "/path/to/transcription.json"
}
```

### Excel Extractor

Extract data from Excel/CSV files:

```bash
python3 excel-extractor.py "/path/to/file.xlsx" "ContactName" "MSG123"
```

**Parameters:**
1. File path (Excel/CSV file)
2. Contact name
3. Message ID

**Output:**
```json
{
  "success": true,
  "message_id": "MSG123",
  "contact_name": "ContactName",
  "domains": ["financial", "hr"],
  "summary": {
    "total_sheets": 2,
    "total_rows": 150,
    "total_columns": 12
  },
  "saved_file": "/path/to/output.json"
}
```

## Domain Detection

The Excel extractor automatically detects data domains based on keywords:

- **Medical**: patient, hospital, medical, surgery, etc.
- **Financial**: budget, funding, finance, invoice, etc.
- **Logistics**: transport, delivery, warehouse, etc.
- **HR**: employee, staff, personnel, salary, etc.

You can customize domain detection by modifying the keywords configuration in the code.

## Integration with Claude Code

These processors can be integrated as hooks or called from agents:

```python
import subprocess
import json

# Transcribe audio
result = subprocess.run([
    'python3', 'audio-transcription-processor.py',
    json.dumps(audio_messages)
], capture_output=True, text=True)

transcriptions = json.loads(result.stdout)
```

## Error Handling

All processors return structured JSON with success/error information:

```json
{
  "success": false,
  "error": "Error message",
  "details": "Additional error details"
}
```

## License

MIT License - See LICENSE file for details
