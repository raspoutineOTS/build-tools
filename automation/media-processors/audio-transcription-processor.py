#!/usr/bin/env python3
"""
Audio Transcription Processor for WhatsApp messages
Downloads audio files and transcribes them via ElevenLabs API
"""

import sys
import json
import os
import requests
from pathlib import Path
from datetime import datetime

# Configuration from environment variables
ELEVENLABS_API_KEY = os.getenv('ELEVENLABS_API_KEY')
ELEVENLABS_API_URL = "https://api.elevenlabs.io/v1/speech-to-text"
ELEVENLABS_STT_MODEL_ID = os.getenv("ELEVENLABS_STT_MODEL_ID", "scribe_v1")
ELEVENLABS_ENABLE_LOGGING = os.getenv("ELEVENLABS_ENABLE_LOGGING", "true").lower() in ("1", "true", "yes")
ELEVENLABS_DIARIZE = os.getenv("ELEVENLABS_DIARIZE", "").lower() in ("1", "true", "yes")
ELEVENLABS_TAG_AUDIO_EVENTS = os.getenv("ELEVENLABS_TAG_AUDIO_EVENTS", "").lower() in ("1", "true", "yes")
STORE_PATH = Path(os.getenv('WHATSAPP_STORE_PATH', Path.home() / "whatsapp-store"))
TRANSCRIPTIONS_PATH = Path(os.getenv('TRANSCRIPTIONS_PATH', Path.home() / "audio-transcriptions"))

# Create transcriptions directory if needed
TRANSCRIPTIONS_PATH.mkdir(parents=True, exist_ok=True)

def download_audio_via_whatsapp_bridge(message_id, chat_jid):
    """
    Attempt to download audio file via WhatsApp bridge
    Returns the path to the downloaded file or None
    """
    # WhatsApp bridge stores files in store/<chat_jid>/
    chat_dir = chat_jid.replace('@', '_at_').replace('.', '_')
    chat_path = STORE_PATH / chat_dir

    # Search for audio files in the directory
    if chat_path.exists():
        audio_extensions = ['.ogg', '.opus', '.mp3', '.m4a', '.wav']
        for audio_file in chat_path.iterdir():
            if audio_file.suffix.lower() in audio_extensions:
                print(f"✓ Audio file found: {audio_file}")
                return str(audio_file)

    print(f"⚠ No audio file found in {chat_path}")
    return None

def transcribe_audio_elevenlabs(audio_file_path, language_code=None):
    """
    Transcribe an audio file via ElevenLabs API
    """
    if not ELEVENLABS_API_KEY:
        return {
            'success': False,
            'error': 'ELEVENLABS_API_KEY environment variable not set'
        }

    print(f"🎙️  Transcribing with ElevenLabs: {audio_file_path}")

    headers = {
        "xi-api-key": ELEVENLABS_API_KEY
    }

    # Prepare request data
    data = {
        "model_id": ELEVENLABS_STT_MODEL_ID,
        "enable_logging": str(ELEVENLABS_ENABLE_LOGGING).lower()
    }
    if language_code:
        data["language_code"] = language_code
    if ELEVENLABS_DIARIZE:
        data["diarize"] = "true"
    if ELEVENLABS_TAG_AUDIO_EVENTS:
        data["tag_audio_events"] = "true"

    try:
        with open(audio_file_path, "rb") as audio_file:
            response = requests.post(
                ELEVENLABS_API_URL,
                headers=headers,
                files={"audio": audio_file},
                data=data,
                timeout=60
            )

        if response.status_code == 200:
            result = response.json()
            transcription = result.get("text") or result.get("transcription") or ""
            transcription_id = result.get("transcription_id")
            detected_language = result.get('detected_language', language_code or 'unknown')

            print(f"✓ Transcription successful ({detected_language})")
            if transcription_id and not transcription:
                print(f"ℹ Transcription queued, id: {transcription_id}")

            return {
                'success': True,
                'transcription': transcription,
                'transcription_id': transcription_id,
                'detected_language': detected_language,
                'confidence': result.get('confidence', 0.0),
                'audio_duration': result.get('duration', 0)
            }
        else:
            print(f"✗ ElevenLabs API error: {response.status_code}")
            print(f"  Response: {response.text}")
            return {
                'success': False,
                'error': f"API error: {response.status_code}",
                'details': response.text
            }

    except Exception as e:
        print(f"✗ Exception during transcription: {e}")
        return {
            'success': False,
            'error': str(e)
        }

def save_transcription(message_id, chat_jid, transcription_data, audio_file_path):
    """
    Save transcription to a JSON file
    """
    timestamp = datetime.now().isoformat()
    output_file = TRANSCRIPTIONS_PATH / f"{message_id}_{timestamp.replace(':', '-')}.json"

    full_data = {
        'message_id': message_id,
        'chat_jid': chat_jid,
        'audio_file': audio_file_path,
        'timestamp': timestamp,
        'transcription_result': transcription_data
    }

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(full_data, f, indent=2, ensure_ascii=False)

    print(f"💾 Transcription saved: {output_file}")
    return str(output_file)

def process_audio_message(message_data):
    """
    Process a complete audio message
    """
    message_id = message_data.get('id')
    chat_jid = message_data.get('chat_jid')

    print(f"\n{'='*60}")
    print(f"🎧 Processing audio message: {message_id}")
    print(f"   Contact: {chat_jid}")
    print(f"{'='*60}\n")

    # 1. Download the audio file
    audio_file = download_audio_via_whatsapp_bridge(message_id, chat_jid)

    if not audio_file:
        print(f"✗ Cannot find audio file for {message_id}")
        return {
            'success': False,
            'message_id': message_id,
            'error': 'Audio file not found'
        }

    # 2. Transcribe with ElevenLabs
    # Try without specifying language first (auto-detect)
    transcription_result = transcribe_audio_elevenlabs(audio_file)

    # If failed or low confidence, try with explicit language if provided
    language_hint = message_data.get('language_hint')
    if (not transcription_result.get('success') or
        transcription_result.get('confidence', 0) < 0.5) and language_hint:
        print(f"⚠ Low confidence, retrying with language: {language_hint}...")
        transcription_result = transcribe_audio_elevenlabs(audio_file, language_code=language_hint)

    if not transcription_result.get('success'):
        print(f"✗ Transcription failed: {transcription_result.get('error')}")
        return {
            'success': False,
            'message_id': message_id,
            'error': transcription_result.get('error')
        }

    # 3. Save the transcription
    saved_file = save_transcription(message_id, chat_jid, transcription_result, audio_file)

    # 4. Display result
    print(f"\n{'='*60}")
    print(f"✅ TRANSCRIPTION COMPLETED")
    print(f"   Message ID: {message_id}")
    print(f"   Detected language: {transcription_result.get('detected_language')}")
    print(f"   Confidence: {transcription_result.get('confidence', 0):.2%}")
    print(f"   Transcription: {transcription_result.get('transcription')[:200]}...")
    print(f"   File: {saved_file}")
    print(f"{'='*60}\n")

    return {
        'success': True,
        'message_id': message_id,
        'transcription': transcription_result.get('transcription'),
        'detected_language': transcription_result.get('detected_language'),
        'saved_file': saved_file
    }

def main():
    """
    Main entry point
    Expects JSON with audio message data to process
    """
    if len(sys.argv) < 2:
        print("Usage: audio-transcription-processor.py '<json_data>'")
        sys.exit(1)

    try:
        audio_messages = json.loads(sys.argv[1])
    except json.JSONDecodeError as e:
        print(f"✗ JSON error: {e}")
        sys.exit(1)

    if not isinstance(audio_messages, list):
        audio_messages = [audio_messages]

    results = []
    for message in audio_messages:
        result = process_audio_message(message)
        results.append(result)

    # Display summary
    print(f"\n{'='*60}")
    print(f"📊 SUMMARY: {len(results)} audio messages processed")
    success_count = sum(1 for r in results if r.get('success'))
    print(f"   ✅ Success: {success_count}")
    print(f"   ✗ Failed: {len(results) - success_count}")
    print(f"{'='*60}\n")

    # Return JSON results
    print(json.dumps(results, ensure_ascii=False))

if __name__ == "__main__":
    main()
