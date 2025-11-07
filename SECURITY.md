# Security Policy

## Supported Versions

We actively support the following versions of Build Tools Collection:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **security@ontheshoulders.cc**

You should receive an acknowledgment within **48 hours**, and we'll send a more detailed response within **7 days** indicating the next steps in handling your report.

### What to Include in Your Report

- Type of vulnerability (e.g., secret exposure, command injection, XSS)
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit/direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if available)
- Impact of the vulnerability (what an attacker could achieve)

### What to Expect

1. **Acknowledgment:** Within 48 hours
2. **Initial Assessment:** Within 7 days
3. **Fix Timeline:** Critical issues within 30 days, others within 90 days
4. **Public Disclosure:** Coordinated with reporter after fix is released

## Security Best Practices for Users

### 1. Credential Management

**Never commit real credentials:**
```bash
# Use environment variables
export TELEGRAM_BOT_TOKEN="your_real_token"
export CLOUDFLARE_API_TOKEN="your_real_token"

# Or use .env files (gitignored)
echo "TELEGRAM_BOT_TOKEN=xxx" > .env
```

**Files to keep private:**
- `.env` files
- `*.key`, `*.pem`, `*.p12` (certificates)
- `*.token`, `*_token`, `*-token` (API tokens)
- `config.local.*` (local configurations)

### 2. MCP Server Security

**Verify TLS for remote connections:**
```bash
# Local proxy detected (127.0.0.1:22708)
# Ensure TLS is enabled for production deployments
```

**Restrict MCP server permissions:**
```json
{
  "mcpServers": {
    "messaging-bridge": {
      "command": "python3",
      "args": ["./mcp-servers/messaging-bridge/server.py"],
      "permissions": ["read", "write"]
    }
  }
}
```

### 3. GitHub Actions Security

**Keep actions updated:**
- Dependabot monitors GitHub Actions automatically
- Review and merge security updates promptly

**Use pinned actions:**
```yaml
# Good: Pinned by SHA256
uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1

# Avoid: Unpinned versions
uses: actions/checkout@v4
```

### 4. Dependency Management

**Python dependencies:**
```bash
# Audit installed packages
pip-audit -r automation/ocr-watcher/requirements.txt

# Keep dependencies updated
pip install --upgrade watchdog
```

**Submodule security:**
```bash
# DeepSeek-OCR is maintained externally
# Review updates before pulling
cd automation/ocr-watcher/deepseek-ocr
git log --oneline -10
```

### 5. Code Review Checklist

Before merging PRs, verify:
- [ ] No hardcoded secrets or credentials
- [ ] Input validation for user-supplied data
- [ ] No command injection vulnerabilities (shell scripts)
- [ ] Secure file permissions (`chmod 600` for sensitive files)
- [ ] Error messages don't leak sensitive info
- [ ] Dependencies are up-to-date

## Known Limitations

### Submodule Dependencies
- `automation/ocr-watcher/deepseek-ocr` is maintained externally
- Security updates depend on upstream project
- Review submodule updates before merging

### Local Proxy Usage
- Default remote uses local proxy (127.0.0.1:22708)
- Intended for development environments
- **Production deployments must use direct HTTPS connections**

### Third-Party Integrations
- WhatsApp, Telegram, Discord, Slack integrations rely on external APIs
- Review platform-specific security guidelines
- Rotate API tokens regularly

## Security Hardening Recommendations

### For Production Deployments

1. **Enable GPG commit signing:**
   ```bash
   git config --global commit.gpgsign true
   git config --global user.signingkey <YOUR_GPG_KEY_ID>
   ```

2. **Configure branch protection (main branch):**
   - Require signed commits
   - Require pull request reviews (1+ approver)
   - Require status checks to pass
   - Restrict force pushes

3. **Enable GitHub security features:**
   - Secret scanning (push protection)
   - Dependabot alerts
   - Code scanning (CodeQL)

4. **Regular security audits:**
   - Quarterly dependency reviews
   - Annual penetration testing (if handling sensitive data)
   - Monitor GitHub Security Advisories

### For Open-Source Public Releases

1. **Security policy visible in README.md**
2. **Triage security reports within 48 hours**
3. **CVE assignment for verified vulnerabilities**
4. **Security advisories published via GitHub**

## Disclosure Policy

We follow **coordinated disclosure**:

1. Reporter notifies us privately
2. We confirm and develop a fix
3. Fix is tested and released
4. Public disclosure after fix is available
5. Reporter receives credit (if desired)

**Typical timeline:** 30-90 days from report to public disclosure

## Past Security Advisories

No security advisories have been published for this project yet.

When available, they will be listed here with:
- CVE ID
- Severity (Critical/High/Medium/Low)
- Affected versions
- Fixed version
- Credit to reporter

## Contact

**Security Team:** security@ontheshoulders.cc
**General Contact:** tech@ontheshoulders.cc
**GitHub Issues:** https://github.com/raspoutineOTS/build-tools/issues (for non-security bugs only)

---

**Last Updated:** 2025-11-07
**Policy Version:** 1.0
