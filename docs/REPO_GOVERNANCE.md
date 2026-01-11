# 🏛️ REPOSITORY GOVERNANCE

**Version**: 1.0
**Last Updated**: January 2026
**Status**: Active

---

## 📋 Overview

This document defines the governance model for the **Build-Tools** ecosystem, which consists of two repositories:

- **Public Repository**: `raspoutineOTS/build-tools` - Generic, open-source toolkit
- **Private Repositories**: Implementation-specific projects (e.g., NGO analysis systems)

### Purpose

Establish clear guidelines for:
1. What content belongs in public vs private repositories
2. Process for promoting generic components to open-source
3. Security and privacy standards
4. Contribution workflows

---

## 🔀 Repository Separation Model

### Public Repository (`build-tools`)

**Purpose**: Generic, reusable components for Claude Code automation

**Content Policy**:

✅ **ALLOWED**:
- Generic agent templates (system-orchestrator, message-processor, data-sorter)
- Platform-agnostic automation scripts
- Generic MCP integration guides
- Helper utilities (database wrappers, media processors)
- Documentation with placeholder examples
- Architecture patterns and best practices
- Sanitized use cases (no client/project details)

❌ **PROHIBITED**:
- Client names, project names, or organization identifiers
- Real API tokens, credentials, or account IDs
- Proprietary business logic
- Client-specific data schemas
- Private project details or roadmaps
- Personally identifiable information (PII)
- Geographic specifics (e.g., "Gaza hospital", "Lylia client")

### Private Repositories

**Purpose**: Implementation-specific projects with client data

**Content Policy**:

✅ **ALLOWED**:
- Client-specific agent implementations
- Real credentials (stored in `.env`, gitignored)
- Business-specific domain analyzers
- Client data schemas and examples
- Implementation details and customizations
- Project-specific documentation

❌ **PROHIBITED**:
- Committing credentials to Git (use `.env` files)
- Copying generic components without attribution
- Sharing client data without permission

---

## 🔄 Promotion Workflow: Private → Public

When you identify a generic component in a private repo that could benefit the community:

### Step 1: Identification

**Candidates for Promotion**:
- Reusable utility functions (e.g., Excel extractors, PDF processors)
- Generic workflow patterns (e.g., monitoring hooks)
- Platform-agnostic integrations (e.g., database helpers)
- Documentation patterns (e.g., security guides)

**NOT Candidates**:
- Business-specific logic (e.g., NGO domain analyzers)
- Client-customized agents
- Project-specific configurations

### Step 2: Sanitization Checklist

Before promoting, ensure:

- [ ] All client names removed (replace with "Client A", "Organization")
- [ ] All credentials removed (replace with `YOUR_API_KEY_HERE`)
- [ ] All geographic specifics removed (replace with "Location X", "Region")
- [ ] All proprietary data schemas generalized
- [ ] All business logic made generic (parameterize specific values)
- [ ] Documentation rewritten for general audience
- [ ] Examples use fictitious data only

### Step 3: Documentation

Add to the promoted component:

```markdown
## Origin

This component was extracted from a production system and generalized
for community use. It has been validated on:
- [Generic description of use case, e.g., "multi-domain data analysis"]
- [Generic scale metrics, e.g., "1000+ messages/day"]

Original context: [Vague description without client details]
```

### Step 4: Attribution

In the private repo, reference the public component:

```markdown
## Based On

This implementation uses the generic [Component Name] from
[Build-Tools](https://github.com/raspoutineOTS/build-tools),
customized for [project name] requirements.
```

### Step 5: Pull Request

1. Fork `build-tools` repository
2. Create feature branch: `feature/add-[component-name]`
3. Add sanitized component
4. Submit pull request with:
   - Description of component
   - Use case explanation
   - Testing evidence
   - Documentation

### Step 6: Review

Maintainers will verify:
- No client-specific information
- No credentials or sensitive data
- Quality documentation
- Tests included (if applicable)
- Follows project conventions

---

## 🔒 Security & Privacy Standards

### Credential Management

**Public Repository**:
- ✅ Use placeholders: `YOUR_API_KEY`, `your_token_here`
- ✅ Reference `.env.example` templates
- ✅ Include security documentation
- ❌ NEVER include real credentials, even in examples
- ❌ NEVER include real account IDs or database UUIDs

**Private Repository**:
- ✅ Use `.env` files (gitignored)
- ✅ Follow `SETUP_SECURE.md` guidelines
- ✅ Rotate tokens regularly
- ❌ NEVER commit `.env` to Git
- ❌ NEVER hardcode credentials in code

### Data Privacy

**PII (Personally Identifiable Information)**:
- ❌ Names, email addresses, phone numbers
- ❌ Addresses, locations (specific)
- ❌ Medical records, financial data
- ❌ Authentication tokens, passwords

**Acceptable in Public**:
- ✅ Fictitious examples: "John Doe", "example@example.com"
- ✅ Generic locations: "City A", "Region B"
- ✅ Sanitized metrics: "200+ messages/day" (no specific counts)
- ✅ Placeholder UUIDs: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

### Client Confidentiality

**Never Disclose**:
- Client names or organization names
- Project details or timelines
- Financial arrangements
- Proprietary methodologies
- Strategic plans or roadmaps

**Acceptable Generic References**:
- "A humanitarian organization"
- "An international NGO"
- "A production system"
- "A multi-domain analysis project"

---

## 📝 Contribution Guidelines

### For Build-Tools (Public)

**Who Can Contribute**:
- Anyone (open-source, MIT license)

**What to Contribute**:
1. **Agent Templates**: New generic agent types
2. **MCP Integrations**: New platform connectors
3. **Automation Scripts**: Hooks, watchers, processors
4. **Documentation**: Guides, tutorials, examples
5. **Bug Fixes**: Issue resolution
6. **Feature Enhancements**: Improvements to existing components

**How to Contribute**:
1. Read `CONTRIBUTING.md` (contribution guidelines)
2. Check existing issues and discussions
3. Fork repository
4. Create feature branch
5. Implement changes with tests
6. Submit pull request
7. Respond to review feedback

### For Private Repositories

**Who Can Contribute**:
- Project team members only

**Contribution Process**:
- Follow internal development workflows
- Use feature branches
- Code review before merge
- Document customizations

---

## 🏷️ Versioning & Releases

### Public Repository (build-tools)

**Semantic Versioning** (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes to agent interfaces
- **MINOR**: New agents, features, backwards-compatible
- **PATCH**: Bug fixes, documentation updates

**Release Process**:
1. Update version in documentation
2. Create `CHANGELOG.md` entry
3. Tag release: `git tag v3.1.0`
4. Push tags: `git push --tags`
5. Create GitHub Release with notes

**Current Version**: v3.0 (Architecture v3.0 - Native Agents)

### Private Repositories

**Versioning**:
- Follow project-specific versioning
- Tag major milestones
- Document dependencies on build-tools version

---

## 🎯 Decision-Making Process

### Public Repository Decisions

**Minor Changes** (documentation, bug fixes):
- Maintainer approval required
- 1 business day review SLA

**Major Changes** (new agents, breaking changes):
- Community discussion (GitHub Discussions)
- Maintainer consensus
- 1 week review period minimum

**Maintainers**:
- Listed in `README.md`
- Responsible for code quality, security, documentation

### Private Repository Decisions

**Development Decisions**:
- Project lead or tech lead approval
- Follow internal processes

**Promotion to Public**:
- Requires review by:
  - Technical lead (quality)
  - Security lead (sanitization)
  - Client manager (confidentiality)

---

## 🔍 Quality Standards

### Code Quality (Public)

**Required**:
- ✅ Clear, descriptive agent prompts
- ✅ Inline documentation
- ✅ Examples in README
- ✅ No hardcoded values (use parameters)
- ✅ Error handling
- ✅ Security best practices (OWASP)

**Recommended**:
- Tests for complex logic
- Performance benchmarks
- Multiple use case examples

### Documentation Quality (Public)

**Required**:
- ✅ README.md for each component
- ✅ Usage examples
- ✅ Prerequisites listed
- ✅ Troubleshooting section
- ✅ English language (primary)

**Recommended**:
- Architecture diagrams
- Video tutorials
- Multiple language support

---

## 📊 Metrics & Monitoring

### Public Repository Health

**Track**:
- Stars, forks, watchers (GitHub)
- Open issues response time
- Pull request merge time
- Community engagement (Discussions)
- Download/clone metrics

**Goals**:
- Issue response: < 48 hours
- PR review: < 1 week
- Monthly release cadence

### Private Repository Health

**Track**:
- System uptime
- Error rates
- Performance metrics
- Cost metrics (API usage)

---

## 🚨 Security Incident Response

### Public Repository

**If Credential Exposed**:
1. Immediately revoke exposed credential
2. Remove from repository (BFG Repo-Cleaner if in history)
3. Issue security advisory (GitHub Security)
4. Notify affected users
5. Document incident in `SECURITY.md`

**Reporting Vulnerabilities**:
- Email: security@buildtools.dev
- GitHub Security Advisories (preferred)
- Do NOT open public issue for vulnerabilities

### Private Repository

**If Credential Exposed**:
1. Follow `SETUP_SECURE.md` rotation procedures
2. Rotate immediately (< 1 hour)
3. Audit access logs
4. Notify team and client
5. Document incident internally

---

## 📚 Resources

### Templates

- `.env.example` - Environment variables template
- `SETUP_SECURE.md` - Security configuration guide
- `agent-template/` - Generic agent structure
- `hook-template/` - Automation hook structure

### References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

---

## 🔄 Governance Review

This governance document is reviewed:
- **Quarterly**: Regular updates
- **Ad-hoc**: After significant incidents
- **Community-driven**: Via GitHub Discussions

**Propose Changes**:
1. Open Discussion in GitHub Discussions
2. Tag with `governance` label
3. Community feedback period (2 weeks)
4. Maintainer decision
5. Update document with version increment

---

## 📞 Contact

### Public Repository Questions
- **GitHub Discussions**: General questions, feature requests
- **GitHub Issues**: Bug reports, specific problems
- **Email**: contact@buildtools.dev

### Private Repository Questions
- Follow internal communication channels
- Project lead for escalations

---

## ✅ Checklist: Before Promoting to Public

Use this checklist when moving code from private to public:

### Sanitization
- [ ] All client names removed
- [ ] All credentials removed (replaced with placeholders)
- [ ] All real account IDs removed
- [ ] All geographic specifics generalized
- [ ] All PII removed
- [ ] Proprietary business logic generalized

### Documentation
- [ ] README.md created
- [ ] Usage examples provided
- [ ] Prerequisites documented
- [ ] English language used
- [ ] Security notes included (if applicable)

### Quality
- [ ] Code follows project conventions
- [ ] No hardcoded values
- [ ] Error handling present
- [ ] Examples use fictitious data

### Legal
- [ ] No copyright violations
- [ ] MIT license compatible
- [ ] Client approval (if derived from client work)
- [ ] Attribution added (if based on external work)

### Testing
- [ ] Component tested in isolation
- [ ] Examples verified to work
- [ ] No dependencies on private components

---

**Version History**:
- v1.0 (January 2026): Initial governance document

**Maintainers**: See `README.md` in build-tools repository

**License**: This governance document is licensed under CC BY 4.0
