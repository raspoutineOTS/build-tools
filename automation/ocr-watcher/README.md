# OCR Watcher 🔍

> Automatic OCR processing with DeepSeek-OCR and folder watching

**One-command installation** • **Zero-configuration** • **Apple Silicon optimized**

Part of [build-tools](https://github.com/raspoutineOTS/build-tools) automation suite.

## ✨ Features

- 🚀 **One-command installation** - Installs everything automatically
- 🔍 **Auto-detect images** - Watches folder for new files
- 📝 **Extract everything** - Text, tables, LaTeX equations to Markdown
- ⚡ **Apple Silicon optimized** - Metal acceleration (M1/M2/M3/M4)
- 🔄 **Background processing** - Non-blocking operation
- 📊 **Real-time logging** - Monitor processing status
- 📦 **Bundled DeepSeek-OCR** - No separate installation needed

## 🚀 Quick Start

### Installation (macOS Apple Silicon)

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/raspoutineOTS/build-tools.git
cd build-tools/automation/ocr-watcher

# Run installation script
./install.sh
```

That's it! The script will:
- ✅ Install Rust (if needed)
- ✅ Install Python watchdog
- ✅ Compile DeepSeek-OCR CLI with Metal
- ✅ Configure shell aliases
- ✅ Create watch directory

### Usage

```bash
# Reload shell configuration
source ~/.zshrc

# Start watching
ocr-watch start

# Drop images into ~/Documents/OCR_Input
# Results appear as *_ocr.md files automatically

# View logs in real-time
ocr-watch logs

# Check status
ocr-watch status

# Stop watching
ocr-watch stop
```

## 📖 How It Works

```
┌─────────────┐
│   Drop Image │
│  in Folder  │
└──────┬──────┘
       │
       v
┌─────────────┐
│   Watcher   │◄─── Detects new files
│   Python    │
└──────┬──────┘
       │
       v
┌─────────────┐
│ DeepSeek OCR│◄─── Extracts content
│    (Rust)   │
└──────┬──────┘
       │
       v
┌─────────────┐
│  Markdown   │◄─── Saves result
│    Output   │
└─────────────┘
```

## 📋 Requirements

- **OS**: macOS 13+ (Ventura or later)
- **CPU**: Apple Silicon (M1/M2/M3/M4)
- **RAM**: 16GB minimum, 24GB+ recommended
- **Disk**: 10GB free space (6.3GB for models)
- **Network**: For downloading models on first use

## 🎯 Supported Formats

- **Images**: PNG, JPG, JPEG
- **Documents**: PDF
- **Output**: Markdown with LaTeX equations

## ⚙️ Configuration

Edit `config/default_config.json` to customize:

```json
{
  "watch_dir": "~/Documents/OCR_Input",
  "ocr_bin": "./deepseek-ocr/target/release/deepseek-ocr-cli",
  "supported_formats": [".png", ".jpg", ".jpeg", ".pdf"],
  "default_prompt": "<image>\\n<|grounding|>...",
  "max_tokens": 2048,
  "device": "cpu",
  "timeout_seconds": 300
}
```

## 💡 Examples

### Invoice Processing

```bash
cp ~/Downloads/invoice.pdf ~/Documents/OCR_Input/
# Wait ~30s
cat ~/Documents/OCR_Input/invoice_ocr.md
```

### Screenshot Analysis

```bash
# Take screenshot and save to OCR_Input
# Automatic processing begins immediately
```

### Batch Processing

```bash
# Copy multiple images
cp ~/Desktop/*.png ~/Documents/OCR_Input/
# Watch logs in real-time
ocr-watch logs
```

## 🔧 Advanced Usage

### Custom OCR Prompts

Edit the `default_prompt` in `config/default_config.json`:

```json
{
  "default_prompt": "<image>\\n<|grounding|>Extract tables in CSV format"
}
```

### Change Watch Directory

```json
{
  "watch_dir": "~/Dropbox/OCR_Queue"
}
```

### Adjust Timeout

For large documents:

```json
{
  "timeout_seconds": 600
}
```

## 🐛 Troubleshooting

### OCR binary not found

```bash
cd ~/path/to/build-tools/automation/ocr-watcher
./install.sh
```

### Watchdog not installed

```bash
python3 -m pip install --user watchdog
```

### Models not downloading

On first OCR run, models (~6.3GB) download automatically from Hugging Face. Ensure stable internet connection.

### Permission issues

```bash
chmod +x install.sh ocr-watcher.sh ocr_watcher.py
```

## 📊 Performance

| Hardware | First Run | Subsequent Runs |
|----------|-----------|-----------------|
| M1/M2 | ~2 minutes | ~30-60 seconds |
| M3/M4 Pro | ~90 seconds | ~20-30 seconds |

*Times include model loading and processing a typical document page*

## 🏗️ Architecture

```
ocr-watcher/
├── deepseek-ocr/          # Git submodule
│   ├── crates/            # Rust source
│   └── target/release/    # Compiled binary
├── ocr_watcher.py         # Python watcher
├── ocr-watcher.sh         # Control script
├── install.sh             # Installation
├── config/
│   └── default_config.json
└── requirements.txt
```

## 🤝 Contributing

Contributions welcome! Please follow the standard workflow:

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📜 License

This project inherits the Apache 2.0 license from DeepSeek-OCR.

## 🙏 Credits

Built on top of:
- [DeepSeek-OCR](https://github.com/TimmyOVO/deepseek-ocr.rs) by TimmyOVO
- [watchdog](https://github.com/gorakhargosh/watchdog) Python library

Part of [build-tools](https://github.com/raspoutineOTS/build-tools) by raspoutineOTS

## 📚 Documentation

- [Installation Guide](docs/installation.md)
- [Configuration Guide](docs/configuration.md)
- [Troubleshooting](docs/troubleshooting.md)
- [API Reference](docs/api.md)

## 🔗 Links

- [GitHub Repository](https://github.com/raspoutineOTS/build-tools)
- [Issue Tracker](https://github.com/raspoutineOTS/build-tools/issues)
- [DeepSeek-OCR Original](https://github.com/TimmyOVO/deepseek-ocr.rs)

---

Made with ❤️ for the automation community
