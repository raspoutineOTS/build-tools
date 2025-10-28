#!/usr/bin/env python3
"""
OCR Watcher - Automatic OCR processing for files dropped in a watched folder

Part of the build-tools automation suite
GitHub: https://github.com/raspoutineOTS/build-tools
"""

import os
import sys
import time
import subprocess
import json
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Get script directory for relative paths
SCRIPT_DIR = Path(__file__).parent.resolve()

# Default configuration
DEFAULT_CONFIG = {
    "watch_dir": str(Path.home() / "Documents" / "OCR_Input"),
    "ocr_bin": str(SCRIPT_DIR / "deepseek-ocr" / "target" / "release" / "deepseek-ocr-cli"),
    "supported_formats": [".png", ".jpg", ".jpeg", ".pdf"],
    "default_prompt": "<image>\\n<|grounding|>Extrait tout le texte, tableaux et équations en markdown",
    "max_tokens": 2048,
    "device": "cpu",
    "timeout_seconds": 300,
    "log_level": "INFO"
}

# Load configuration
CONFIG_FILE = SCRIPT_DIR / "config" / "default_config.json"
if CONFIG_FILE.exists():
    with open(CONFIG_FILE) as f:
        config = json.load(f)
else:
    config = DEFAULT_CONFIG

# Configuration values
WATCH_DIR = Path(config["watch_dir"]).expanduser()
PROCESSED_DIR = WATCH_DIR / ".processed"
LOG_FILE = WATCH_DIR / "ocr.log"
OCR_BIN = Path(config["ocr_bin"]).expanduser()

# Resolve relative paths
if not OCR_BIN.is_absolute():
    OCR_BIN = (SCRIPT_DIR / config["ocr_bin"]).resolve()

SUPPORTED_FORMATS = set(config["supported_formats"])
DEFAULT_PROMPT = config["default_prompt"]
MAX_TOKENS = config["max_tokens"]
DEVICE = config["device"]
TIMEOUT = config["timeout_seconds"]


def log(message):
    """Write log message to both console and log file"""
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    log_message = f"[{timestamp}] {message}"
    print(log_message)

    WATCH_DIR.mkdir(parents=True, exist_ok=True)
    with open(LOG_FILE, 'a') as f:
        f.write(log_message + "\\n")


def is_processed(file_path):
    """Check if file has already been processed"""
    processed_marker = PROCESSED_DIR / f"{file_path.name}.done"
    return processed_marker.exists()


def mark_processed(file_path):
    """Mark file as processed"""
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    processed_marker = PROCESSED_DIR / f"{file_path.name}.done"
    processed_marker.touch()


def process_ocr(image_path):
    """Run OCR on the image file"""
    log(f"Processing: {image_path.name}")

    # Check if OCR binary exists
    if not OCR_BIN.exists():
        log(f"✗ Error: OCR binary not found at {OCR_BIN}")
        log(f"  Please run install.sh first")
        return False

    # Generate output filename
    output_name = image_path.stem + "_ocr.md"
    output_path = image_path.parent / output_name

    try:
        # Run OCR command
        result = subprocess.run(
            [
                str(OCR_BIN),
                "--prompt", DEFAULT_PROMPT,
                "--image", str(image_path),
                "--device", DEVICE,
                "--max-new-tokens", str(MAX_TOKENS)
            ],
            capture_output=True,
            text=True,
            timeout=TIMEOUT
        )

        if result.returncode == 0:
            # Save output to markdown file
            with open(output_path, 'w') as f:
                f.write(f"# OCR Results for {image_path.name}\\n\\n")
                f.write(f"**Processed:** {time.strftime('%Y-%m-%d %H:%M:%S')}\\n\\n")
                f.write("---\\n\\n")
                f.write(result.stdout)

            log(f"✓ Success: {output_name} created")
            mark_processed(image_path)
            return True
        else:
            log(f"✗ Error processing {image_path.name}:")
            if result.stderr:
                for line in result.stderr.split('\\n')[:5]:  # First 5 lines of error
                    log(f"  {line}")
            return False

    except subprocess.TimeoutExpired:
        log(f"✗ Timeout processing {image_path.name} (> {TIMEOUT}s)")
        return False
    except Exception as e:
        log(f"✗ Exception processing {image_path.name}: {str(e)}")
        return False


class OCREventHandler(FileSystemEventHandler):
    """Handle file system events"""

    def __init__(self):
        super().__init__()
        self.processing = set()

    def on_created(self, event):
        """Handle file creation events"""
        if event.is_directory:
            return

        file_path = Path(event.src_path)

        # Skip hidden files and processed markers
        if file_path.name.startswith('.'):
            return

        # Skip OCR output files
        if file_path.name.endswith('_ocr.md'):
            return

        # Skip log file
        if file_path.name == 'ocr.log':
            return

        # Check if supported format
        if file_path.suffix.lower() not in SUPPORTED_FORMATS:
            log(f"Skipping unsupported format: {file_path.name}")
            return

        # Check if already processed
        if is_processed(file_path):
            log(f"Already processed: {file_path.name}")
            return

        # Avoid duplicate processing
        if file_path in self.processing:
            return

        # Wait a bit to ensure file is fully written
        time.sleep(1)

        # Process the file
        self.processing.add(file_path)
        try:
            process_ocr(file_path)
        finally:
            self.processing.discard(file_path)

    def on_modified(self, event):
        """Handle file modification - treat as new file if recently created"""
        if not event.is_directory:
            file_path = Path(event.src_path)
            if file_path.exists():
                age = time.time() - file_path.stat().st_mtime
                if age < 2:  # File modified within last 2 seconds
                    self.on_created(event)


def main():
    """Main function"""
    # Ensure directories exist
    WATCH_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    # Check if OCR binary exists
    if not OCR_BIN.exists():
        log(f"ERROR: OCR binary not found at {OCR_BIN}")
        log(f"Please run install.sh first:")
        log(f"  cd {SCRIPT_DIR}")
        log(f"  ./install.sh")
        sys.exit(1)

    log("=" * 60)
    log("OCR Watcher started")
    log(f"Watching: {WATCH_DIR}")
    log(f"OCR Binary: {OCR_BIN}")
    log(f"Supported formats: {', '.join(SUPPORTED_FORMATS)}")
    log(f"Max tokens: {MAX_TOKENS}")
    log(f"Device: {DEVICE}")
    log(f"Timeout: {TIMEOUT}s")
    log("=" * 60)
    log("Waiting for files... (Press Ctrl+C to stop)")

    # Set up file system observer
    event_handler = OCREventHandler()
    observer = Observer()
    observer.schedule(event_handler, str(WATCH_DIR), recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        log("Stopping OCR Watcher...")
        observer.stop()

    observer.join()
    log("OCR Watcher stopped")


if __name__ == "__main__":
    main()
