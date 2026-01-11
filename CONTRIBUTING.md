# 🤝 Contributing to Build-Tools

Thank you for your interest in contributing to Build-Tools! We welcome contributions from the community and are grateful for your support.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Community](#community)

---

## 📜 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive Behavior**:
- ✅ Using welcoming and inclusive language
- ✅ Respecting differing viewpoints and experiences
- ✅ Gracefully accepting constructive criticism
- ✅ Focusing on what is best for the community
- ✅ Showing empathy towards other community members

**Unacceptable Behavior**:
- ❌ Harassment, trolling, or insulting comments
- ❌ Public or private attacks
- ❌ Publishing others' private information
- ❌ Other conduct which could reasonably be considered inappropriate

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported to the project maintainers. All complaints will be reviewed and investigated promptly and fairly.

---

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Claude Code** installed and configured
- **Git** for version control
- **Basic understanding** of Claude Code agents and MCP
- **GitHub account** for pull requests

### Setting Up Development Environment

1. **Fork the Repository**
```bash
# Click "Fork" on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/build-tools.git
cd build-tools
```

2. **Add Upstream Remote**
```bash
git remote add upstream https://github.com/raspoutineOTS/build-tools.git
```

3. **Install Development Dependencies** (if any)
```bash
# Currently, Build-Tools doesn't require package installation
# But copy agents to your Claude environment for testing
cp -r agents/.claude/agents/ ~/.claude/agents/
```

4. **Verify Setup**
```bash
# Test an agent
@system-orchestrator "Verify that agents are working"
```

---

## 💡 How to Contribute

### Types of Contributions

We welcome various types of contributions:

#### 1. Agent Templates

**What**: New specialized agents for different domains

**Good Candidates**:
- Customer support automation agents
- Research workflow agents
- Business intelligence agents
- Compliance monitoring agents

**How to Contribute**:
1. Copy `agents/domain-analyzer-template/`
2. Customize for your domain
3. Test thoroughly
4. Submit with documentation

#### 2. MCP Integrations

**What**: Connectors for new MCP servers

**Examples**:
- Slack MCP integration
- Notion MCP integration
- Airtable MCP integration
- Google Drive MCP integration

**How to Contribute**:
1. Create MCP wrapper agent
2. Add configuration guide
3. Provide usage examples
4. Test with real MCP server

#### 3. Automation Scripts

**What**: Hooks, watchers, and helper utilities

**Examples**:
- Additional OCR watchers
- Database migration scripts
- Monitoring dashboards
- Performance profiling tools

**How to Contribute**:
1. Place in `automation/` directory
2. Add README with usage
3. Ensure cross-platform compatibility (or document limitations)
4. Include example configurations

#### 4. Documentation

**What**: Guides, tutorials, and examples

**Examples**:
- Getting started tutorials
- Video walkthroughs
- Architecture deep-dives
- Troubleshooting guides
- Multilingual translations

**How to Contribute**:
1. Place in `docs/` or `examples/`
2. Follow markdown standards
3. Include code examples
4. Test all instructions

#### 5. Bug Fixes

**What**: Fixes for reported issues

**How to Contribute**:
1. Find an issue labeled `bug`
2. Comment that you're working on it
3. Create fix with tests
4. Reference issue in PR

#### 6. Feature Enhancements

**What**: Improvements to existing components

**How to Contribute**:
1. Open discussion first (GitHub Discussions)
2. Get consensus from maintainers
3. Implement enhancement
4. Submit PR with documentation

---

## 🔄 Development Workflow

### Step 1: Create an Issue (Optional but Recommended)

For significant contributions, create an issue first:

1. Go to **Issues** tab
2. Click **New Issue**
3. Describe your proposal
4. Wait for maintainer feedback

### Step 2: Create a Branch

```bash
# Update your fork
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

**Branch Naming Conventions**:
- `feature/` - New features or agents
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions

### Step 3: Make Changes

- Write clear, concise code
- Follow coding standards (see below)
- Add comments for complex logic
- Update documentation as needed

### Step 4: Test Your Changes

```bash
# Test the specific component you changed
@your-new-agent "Test prompt"

# Test integration with orchestrator
@system-orchestrator "Test full workflow"

# Verify no regressions
# (Run through common use cases)
```

### Step 5: Commit Your Changes

**Commit Message Format**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting, no code change
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples**:
```bash
# Good commits
git commit -m "feat(agents): Add customer-support-analyzer agent"
git commit -m "fix(database-manager): Prevent SQL injection in query builder"
git commit -m "docs(guides): Add MCP integration tutorial"

# Bad commits
git commit -m "Update"
git commit -m "Fix stuff"
git commit -m "WIP"
```

### Step 6: Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### Step 7: Create Pull Request

1. Go to your fork on GitHub
2. Click **"Pull Request"**
3. Select your feature branch
4. Fill out PR template:
   - **Title**: Clear, descriptive
   - **Description**: What, why, how
   - **Testing**: How you tested
   - **Screenshots**: If UI changes
   - **Related Issues**: Link issues

**PR Template**:
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
How was this tested?

## Checklist
- [ ] Code follows project standards
- [ ] Documentation updated
- [ ] Tests added (if applicable)
- [ ] No breaking changes (or documented)

## Related Issues
Closes #123
```

### Step 8: Respond to Review Feedback

- Maintainers will review your PR
- Address any requested changes
- Push additional commits to same branch
- PR will auto-update

### Step 9: Merge

Once approved:
- Maintainer will merge your PR
- Your changes will be in main branch
- Branch will be deleted automatically

---

## 📐 Coding Standards

### Agent Prompts

**Structure**:
```markdown
# Agent Name

Clear description of what this agent does.

## Input
Describe expected input format

## Output
Describe output format

## Responsibilities
- Responsibility 1
- Responsibility 2

## Examples
Provide clear examples

## Error Handling
How errors are handled
```

**Best Practices**:
- ✅ Clear, specific instructions
- ✅ Examples included
- ✅ Error handling defined
- ✅ Output format specified
- ❌ Avoid ambiguous language
- ❌ Don't assume context

### Python/Bash Scripts

**Style**:
- Follow PEP 8 (Python)
- Use ShellCheck (Bash)
- Add docstrings/comments
- Handle errors gracefully

**Example**:
```python
def process_message(message: dict) -> dict:
    """
    Process a message and extract metadata.

    Args:
        message: Dict containing message data

    Returns:
        Dict with extracted metadata

    Raises:
        ValueError: If message format is invalid
    """
    if not isinstance(message, dict):
        raise ValueError("Message must be a dictionary")

    # Processing logic here
    return metadata
```

### Documentation

**Markdown Standards**:
- Use ATX headers (`#`, `##`, `###`)
- Code blocks with language hints
- Lists use `-` for unordered
- Tables for structured data

**Example**:
```markdown
## Installation

Follow these steps to install:

1. Clone repository
2. Copy agents
3. Configure

```bash
cp -r agents/ ~/.claude/agents/
```

See [Configuration Guide](./CONFIG.md) for details.
```

---

## 🧪 Testing Guidelines

### Manual Testing

**For New Agents**:
1. Test in isolation (directly invoke agent)
2. Test via orchestrator (full workflow)
3. Test error cases (invalid input)
4. Test edge cases (empty data, large data)

**Testing Checklist**:
- [ ] Agent responds to basic prompt
- [ ] Output format is correct
- [ ] Error handling works
- [ ] Integrates with orchestrator
- [ ] Documentation accurate

### Integration Testing

**Test Workflows**:
```bash
# Test 1: Simple message processing
@system-orchestrator "Process this message: Hello world"

# Test 2: Multi-agent workflow
@system-orchestrator "Analyze this document and store in database: [PDF]"

# Test 3: Error handling
@system-orchestrator "Process invalid data: @#$%^"
```

### Regression Testing

Before submitting PR:
- [ ] Test existing use cases still work
- [ ] No breaking changes to agent interfaces
- [ ] Documentation still accurate

---

## 📖 Documentation Standards

### Required Documentation

For every contribution, update:

1. **README.md** (if adding major component)
2. **Agent-specific README** (for new agents)
3. **CHANGELOG.md** (summarize changes)
4. **Examples/** (usage examples)

### Documentation Template

```markdown
# Component Name

## Overview
Brief description (1-2 sentences)

## Installation
How to install/configure

## Usage
Basic usage examples

## Configuration
Available options

## Examples
Real-world examples

## Troubleshooting
Common issues and solutions

## API Reference
(If applicable)

## Related
Links to related docs
```

### Writing Style

- **Clear and concise**: Short sentences
- **Active voice**: "Use the agent" not "The agent can be used"
- **Examples first**: Show before explaining
- **Audience-aware**: Assume basic Claude Code knowledge

---

## 👥 Community

### Communication Channels

- **GitHub Discussions**: Questions, ideas, general discussion
- **GitHub Issues**: Bug reports, feature requests
- **Pull Requests**: Code contributions
- **Email**: contact@buildtools.dev (for private matters)

### Getting Help

**Before Asking**:
1. Check existing documentation
2. Search GitHub Issues
3. Search GitHub Discussions

**When Asking**:
- Provide context
- Share error messages
- Describe what you've tried
- Include system info (OS, Claude Code version)

### Recognition

Contributors are recognized in:
- **CONTRIBUTORS.md**: List of all contributors
- **Release Notes**: Credit for specific contributions
- **README.md**: Major contributors highlighted

---

## 🏆 Contribution Ladder

### Contributor Levels

**1. Contributor**:
- Anyone who submits a merged PR
- Listed in CONTRIBUTORS.md

**2. Regular Contributor**:
- 5+ merged PRs
- Helps triage issues
- Mentors new contributors

**3. Maintainer**:
- Trusted community member
- Can merge PRs
- Guides project direction
- Invited by existing maintainers

---

## 📝 Legal

### Contributor License Agreement

By contributing, you agree that:
- Your contributions are your own work
- You have the right to contribute
- Your contributions are licensed under MIT License
- You grant Build-Tools project rights to use your contributions

### Copyright

- Build-Tools is MIT Licensed
- Copyright remains with original authors
- Contributions become part of the project

---

## ❓ FAQ

**Q: Do I need permission to contribute?**
A: No! Fork, create a branch, and submit a PR.

**Q: How long does PR review take?**
A: Minor PRs: 1-3 days. Major PRs: 1 week.

**Q: Can I contribute if I'm a beginner?**
A: Absolutely! Look for issues labeled `good first issue`.

**Q: What if my PR is rejected?**
A: Don't worry! We'll explain why and suggest improvements.

**Q: Can I contribute documentation only?**
A: Yes! Documentation is highly valued.

**Q: How do I become a maintainer?**
A: Consistent contributions over time. Maintainers will invite you.

---

## 📞 Questions?

- **Open a Discussion**: https://github.com/raspoutineOTS/build-tools/discussions
- **Join the Community**: See README for links
- **Email Us**: contact@buildtools.dev

---

**Thank you for contributing to Build-Tools! 🚀**

Together, we're making Claude Code automation accessible to everyone.

---

*Last Updated: January 2026*
*License: MIT*
