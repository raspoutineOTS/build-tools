#!/bin/bash
# OCR Watcher - One-Command Installation Script
# Installs everything needed for automatic OCR processing with DeepSeek-OCR

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEEPSEEK_DIR="$SCRIPT_DIR/deepseek-ocr"
OCR_BIN="$DEEPSEEK_DIR/target/release/deepseek-ocr-cli"
WATCH_DIR="$HOME/Documents/OCR_Input"
ZSHRC="$HOME/.zshrc"

# Functions
print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}OCR Watcher - Automatic Installation${NC}          ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_macos() {
    print_step "Checking macOS..."
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This script is only for macOS"
        exit 1
    fi
    print_success "Running on macOS"
}

check_apple_silicon() {
    print_step "Checking Apple Silicon..."
    ARCH=$(uname -m)
    if [[ "$ARCH" != "arm64" ]]; then
        print_warning "Not Apple Silicon (detected: $ARCH)"
        print_warning "Installation will continue but Metal acceleration won't be available"
        return 1
    fi
    print_success "Apple Silicon detected ($ARCH)"
    return 0
}

check_rust() {
    print_step "Checking Rust installation..."
    if command -v rustc &> /dev/null; then
        RUST_VERSION=$(rustc --version | awk '{print $2}')
        print_success "Rust is installed (version $RUST_VERSION)"
        return 0
    else
        print_warning "Rust is not installed"
        return 1
    fi
}

install_rust() {
    print_step "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    print_success "Rust installed successfully"
}

check_python() {
    print_step "Checking Python installation..."
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        print_success "Python is installed (version $PYTHON_VERSION)"
        return 0
    else
        print_error "Python 3 is required but not found"
        print_error "Please install Python 3 and try again"
        exit 1
    fi
}

install_watchdog() {
    print_step "Installing Python watchdog library..."
    if python3 -c "import watchdog" 2>/dev/null; then
        print_success "Watchdog already installed"
    else
        python3 -m pip install --user --break-system-packages watchdog 2>/dev/null || \
        python3 -m pip install --user watchdog
        print_success "Watchdog installed"
    fi
}

compile_deepseek_ocr() {
    print_step "Compiling DeepSeek-OCR CLI..."

    if [[ ! -d "$DEEPSEEK_DIR" ]]; then
        print_error "DeepSeek-OCR submodule not found at $DEEPSEEK_DIR"
        print_error "Please run: git submodule update --init --recursive"
        exit 1
    fi

    cd "$DEEPSEEK_DIR"

    # Check if already compiled
    if [[ -f "$OCR_BIN" ]]; then
        print_warning "DeepSeek-OCR CLI already compiled"
        read -p "Recompile? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_success "Using existing binary"
            cd "$SCRIPT_DIR"
            return 0
        fi
    fi

    # Compile with Metal support if on Apple Silicon
    if check_apple_silicon; then
        print_step "Compiling with Metal acceleration..."
        cargo build -p deepseek-ocr-cli --release --features metal
    else
        print_step "Compiling for CPU only..."
        cargo build -p deepseek-ocr-cli --release
    fi

    cd "$SCRIPT_DIR"

    if [[ -f "$OCR_BIN" ]]; then
        print_success "DeepSeek-OCR CLI compiled successfully"
        print_success "Binary: $OCR_BIN"
    else
        print_error "Compilation failed"
        exit 1
    fi
}

create_watch_directory() {
    print_step "Creating watch directory..."
    mkdir -p "$WATCH_DIR/.processed"
    print_success "Created: $WATCH_DIR"
}

setup_aliases() {
    print_step "Setting up shell aliases..."

    ALIAS_MARKER="# OCR Watcher aliases"
    ALIAS_OCR="alias ocr=\"$OCR_BIN\""
    ALIAS_WATCH="alias ocr-watch=\"$SCRIPT_DIR/ocr-watcher.sh\""

    # Check if aliases already exist
    if grep -q "$ALIAS_MARKER" "$ZSHRC" 2>/dev/null; then
        print_warning "Aliases already configured in $ZSHRC"
    else
        echo "" >> "$ZSHRC"
        echo "$ALIAS_MARKER" >> "$ZSHRC"
        echo "$ALIAS_OCR" >> "$ZSHRC"
        echo "$ALIAS_WATCH" >> "$ZSHRC"
        print_success "Aliases added to $ZSHRC"
    fi
}

test_installation() {
    print_step "Testing installation..."

    # Test OCR binary
    if "$OCR_BIN" --version &> /dev/null; then
        print_success "OCR binary works"
    else
        print_error "OCR binary test failed"
        return 1
    fi

    # Test Python script
    if python3 -c "import sys; sys.path.insert(0, '$SCRIPT_DIR'); import ocr_watcher" 2>/dev/null; then
        print_success "Python watcher script OK"
    else
        print_warning "Python watcher script check failed (non-critical)"
    fi

    print_success "Installation test passed"
}

print_final_instructions() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BLUE}Installation Complete! 🎉${NC}                       ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo ""
    echo "1. Reload your shell configuration:"
    echo -e "   ${YELLOW}source ~/.zshrc${NC}"
    echo ""
    echo "2. Start the OCR watcher:"
    echo -e "   ${YELLOW}ocr-watch start${NC}"
    echo ""
    echo "3. Drop images into the watched folder:"
    echo -e "   ${YELLOW}$WATCH_DIR${NC}"
    echo ""
    echo "4. View logs in real-time:"
    echo -e "   ${YELLOW}ocr-watch logs${NC}"
    echo ""
    echo "5. Stop the watcher:"
    echo -e "   ${YELLOW}ocr-watch stop${NC}"
    echo ""
    echo -e "${BLUE}Documentation:${NC}"
    echo "   $SCRIPT_DIR/README.md"
    echo ""
    echo -e "${BLUE}Supported formats:${NC} PNG, JPG, JPEG, PDF"
    echo -e "${BLUE}Watch directory:${NC} $WATCH_DIR"
    echo -e "${BLUE}OCR Binary:${NC} $OCR_BIN"
    echo ""
    echo -e "${GREEN}Happy OCR processing! 📝${NC}"
    echo ""
}

# Main installation flow
main() {
    print_header

    check_macos
    check_apple_silicon || true  # Don't exit if not Apple Silicon
    check_python

    if ! check_rust; then
        install_rust
    fi

    install_watchdog
    compile_deepseek_ocr
    create_watch_directory
    setup_aliases
    test_installation

    print_final_instructions
}

# Run installation
main "$@"
