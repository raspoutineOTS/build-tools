# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Git repository audit framework for comprehensive health analysis
- SECURITY.md with vulnerability disclosure policy
- .github/CODEOWNERS for code ownership management
- Dependabot configuration for automated dependency updates
- This CHANGELOG.md file

### Security
- Dependabot monitoring for Python dependencies (watchdog)
- Dependabot monitoring for GitHub Actions
- Dependabot monitoring for git submodules
- Security policy with coordinated disclosure process

## [1.0.0] - 2025-11-07

### Added

#### Claude Code Agents
- **system-orchestrator**: Multi-agent coordination and workflow orchestration
- **message-processor**: Universal message handling across multiple platforms (WhatsApp, Telegram, Discord, Slack)
- **data-sorter**: Intelligent data categorization and pattern recognition
- **database-manager**: Universal database operations (Cloudflare D1, PostgreSQL, MySQL, SQLite)
- **domain-analyzer-template**: Generic template for creating custom domain-specific analyzers

#### MCP Servers
- **messaging-bridge**: Universal messaging platform connector with real-time capabilities
- **database-connector**: Multi-database connector with intelligent query optimization
- **context-wrapper**: Enhanced wrapper for Context7 MCP server

#### Automation Scripts
- **ocr-watcher**: Automatic OCR processing with DeepSeek-OCR and folder watching
  - Zero-configuration setup
  - Auto-detect images
  - Extract text, tables, LaTeX equations to Markdown
  - Apple Silicon optimized with Metal acceleration
  - Background processing with daemon support
- **smart-monitor**: Configurable monitoring system with intelligent triggers
- **document-processor**: Intelligent document analysis for PDF, DOCX, TXT, CSV
- **media-processors**: Audio transcription (ElevenLabs API) and Excel/CSV extraction
- **database-tools**: Cloudflare D1 access via Wrangler CLI (Bash and Python helpers)
- **service-manager**: Universal daemon and service management system

#### Documentation
- Comprehensive README.md with quick start guide
- CONTRIBUTING.md with development guidelines
- ARCHITECTURE.md documenting system design
- ARCHITECTURE_V3.md detailing Python to Claude agents migration
- REPO_GOVERNANCE.md with project governance policies
- setup-guide.md for installation instructions
- cloudflare-d1-access-guide.md for D1 database integration

#### CI/CD
- GitHub Actions workflow for OCR Watcher testing (macOS Apple Silicon)
- Automated linting and formatting checks (flake8, black, isort, shellcheck)
- Rust compilation verification for DeepSeek-OCR
- Caching for Cargo and pip dependencies

#### Configuration
- MCP server templates for messaging bridge and database connector
- Claude Code settings templates
- Default OCR Watcher configuration
- Comprehensive .gitignore for sensitive files

### Changed
- Migrated from Python-based data analyzers to Claude Code agents (Architecture v3.0)
  - 95%+ semantic accuracy vs 70-80% regex-based
  - 90% simpler maintenance (prompts vs ~1,800 LOC)
  - Native multilingual support
  - Contextual understanding vs pattern matching

### Security
- Git submodule for DeepSeek-OCR (tracked dependency)
- Placeholder-based configuration (no hardcoded secrets)
- Comprehensive .gitignore (excludes .env, *.key, *.token, *.pem)
- Environment variable-based credential management

### Infrastructure
- MIT License
- GitHub repository structure
- Local proxy support for development (127.0.0.1:22708)

## [0.1.0] - 2025-09-03 (Internal)

### Added
- Initial project structure
- Basic agent framework
- MCP server prototypes

---

## Version History Notes

### Versioning Strategy

We use [Semantic Versioning](https://semver.org/):
- **MAJOR** version (1.x.x): Breaking changes, incompatible API changes
- **MINOR** version (x.1.x): New features, backward-compatible
- **PATCH** version (x.x.1): Bug fixes, backward-compatible

### Release Process

1. Update CHANGELOG.md with changes since last release
2. Bump version in relevant files
3. Create git tag: `git tag -a v1.x.x -m "Release 1.x.x"`
4. Push tag: `git push origin v1.x.x`
5. Create GitHub release with notes from CHANGELOG
6. Announce release (if applicable)

### Migration Guides

#### From Python Analyzers to v3.0 Agents
See `docs/ARCHITECTURE_V3.md` for detailed migration guide.

Key changes:
- Replace Python scripts with Claude agent prompts
- Update database schemas for quality tracking
- Configure parallel agent execution
- Adjust cost/performance expectations

---

## Links

- [Repository](https://github.com/raspoutineOTS/build-tools)
- [Issue Tracker](https://github.com/raspoutineOTS/build-tools/issues)
- [Security Policy](SECURITY.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [License](LICENSE)

---

**Maintained by:** raspoutineOTS (tech@ontheshoulders.cc)
**Last Updated:** 2025-11-07
