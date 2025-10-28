#!/bin/bash
# OCR Watcher Control Script
# Part of the build-tools automation suite

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/ocr_watcher.py"
PID_FILE="$SCRIPT_DIR/.ocr_watcher.pid"
WATCH_DIR="$HOME/Documents/OCR_Input"
LOG_FILE="$WATCH_DIR/ocr.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

start() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}OCR Watcher is already running${NC} (PID: $PID)"
            return 1
        else
            echo "Removing stale PID file..."
            rm "$PID_FILE"
        fi
    fi

    echo -e "${GREEN}Starting OCR Watcher...${NC}"
    nohup python3 "$PYTHON_SCRIPT" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo -e "${GREEN}✓ OCR Watcher started${NC} (PID: $(cat "$PID_FILE"))"
    echo ""
    echo "Watching: $WATCH_DIR"
    echo "Logs: $LOG_FILE"
    echo ""
    echo "To view logs in real-time:"
    echo "  ocr-watch logs"
}

stop() {
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}OCR Watcher is not running${NC}"
        return 1
    fi

    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${GREEN}Stopping OCR Watcher...${NC} (PID: $PID)"
        kill "$PID"
        sleep 1

        # Force kill if still running
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "Force stopping..."
            kill -9 "$PID"
        fi

        rm "$PID_FILE"
        echo -e "${GREEN}✓ OCR Watcher stopped${NC}"
    else
        echo -e "${YELLOW}OCR Watcher is not running${NC} (removing stale PID file)"
        rm "$PID_FILE"
    fi
}

status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${GREEN}● OCR Watcher is running${NC}"
            echo "PID: $PID"
            echo "Watching: $WATCH_DIR"
            echo "Logs: $LOG_FILE"
            echo ""
            echo "Recent activity:"
            tail -5 "$LOG_FILE" 2>/dev/null || echo "No logs yet"
            return 0
        else
            echo -e "${RED}● OCR Watcher is not running${NC} (stale PID file exists)"
            return 1
        fi
    else
        echo -e "${RED}● OCR Watcher is not running${NC}"
        return 1
    fi
}

logs() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "${GREEN}Following logs${NC} (Press Ctrl+C to stop)..."
        echo ""
        tail -f "$LOG_FILE"
    else
        echo -e "${YELLOW}No log file found${NC} at $LOG_FILE"
        echo "Start the watcher first: ocr-watch start"
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    *)
        echo "OCR Watcher - Control Script"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start OCR watcher in background"
        echo "  stop    - Stop OCR watcher"
        echo "  restart - Restart OCR watcher"
        echo "  status  - Check if OCR watcher is running"
        echo "  logs    - View logs in real-time (Ctrl+C to exit)"
        echo ""
        echo "Watch directory: $WATCH_DIR"
        echo ""
        exit 1
        ;;
esac
