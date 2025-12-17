# GitHub Issue Tracking Enforcement Rules

## 🚨 CRITICAL: MANDATORY ISSUE TRACKING FOR ALL AGENT ACTIONS 🚨

**EVERY action taken by an AI agent on ANY AINative codebase MUST be tracked in GitHub Issues.**

---

## 1) Scope: What Requires an Issue

### ✅ **MANDATORY - Must Create Issue:**

#### **Bug Fixes**
- Any code fix, no matter how small
- Error handling improvements
- Performance bug fixes
- Security vulnerability fixes
- UI/UX bugs
- API bugs or incorrect behavior
- Test failures requiring code changes

#### **New Features**
- New API endpoints
- New UI components
- New database tables/schemas
- New integrations or services
- New authentication/authorization features
- New CLI commands or tools
- New configuration options

#### **Testing & QA**
- Writing new test suites
- Adding test coverage for untested code
- Implementing e2e tests
- Adding integration tests
- Performance testing implementation
- Security testing additions

#### **Refactoring**
- Code restructuring for maintainability
- Design pattern implementations
- Performance optimizations
- Dependency updates
- Architecture changes

#### **Documentation**
- API documentation updates
- README updates
- Architecture documentation
- Deployment guides
- Developer onboarding docs

#### **DevOps & Infrastructure**
- CI/CD pipeline changes
- Deployment configuration updates
- Environment setup changes
- Docker/container configuration
- Database migrations
- Monitoring/logging setup

### ❌ **EXCEPTIONS - No Issue Required:**
- Typo fixes in comments (non-code)
- Whitespace/formatting fixes (no logic changes)
- Local development environment setup (not committed)

---

## 2) Issue Creation Requirements

### **Before Starting ANY Work:**

1. **Search for existing issue**
   - Check if issue already exists for this work
   - If exists, assign yourself and reference it
   - If doesn't exist, CREATE IT FIRST

2. **Issue Title Format:**
   ```
   [TYPE] Brief descriptive title (max 60 chars)
   ```

   **Types:**
   - `[BUG]` - Something broken that needs fixing
   - `[FEATURE]` - New functionality or enhancement
   - `[TEST]` - Testing-related work
   - `[REFACTOR]` - Code improvement without behavior change
   - `[DOCS]` - Documentation updates
   - `[DEVOPS]` - Infrastructure/deployment work
   - `[SECURITY]` - Security-related changes
   - `[PERFORMANCE]` - Performance optimization

3. **Issue Description Template:**

```markdown
## Problem/Context
[Clear description of what needs to be done and why]

## Current Behavior
[What currently happens - for bugs]

## Expected Behavior
[What should happen - for bugs/features]

## Proposed Solution
[How you plan to solve this]

## Technical Details
- **Files affected:** [List key files]
- **Dependencies:** [Any new dependencies needed]
- **Breaking changes:** [Yes/No - if yes, explain]

## Testing Plan
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing steps: [list steps]

## Acceptance Criteria
- [ ] [Specific measurable outcome 1]
- [ ] [Specific measurable outcome 2]
- [ ] [Specific measurable outcome 3]

## Estimate
**Story Points:** [0/1/2/3/5/8]
**Rationale:** [Why this estimate]

## References
- Related Issues: #[issue-number]
- Documentation: [links]
- External References: [links]
```

4. **Labels (REQUIRED):**
   - **Type:** `bug`, `feature`, `testing`, `refactor`, `documentation`, `devops`
   - **Priority:** `critical`, `high`, `medium`, `low`
   - **Status:** `ready`, `in-progress`, `blocked`, `review`, `done`
   - **Component:** `backend`, `frontend`, `database`, `api`, `ui`, `infrastructure`
   - **Effort:** `xs`, `s`, `m`, `l`, `xl`

5. **Assignee:**
   - Assign yourself IMMEDIATELY when starting work
   - Never work on unassigned issues without assigning first

---

## 3) Issue Workflow

### **Step 1: Create Issue**
```bash
# Before writing ANY code:
1. Create GitHub issue with proper template
2. Add all required labels
3. Assign to yourself
4. Add to project board (if applicable)
```

### **Step 2: Create Branch**
```bash
# Branch naming convention:
git checkout -b [type]/[issue-number]-[short-description]

# Examples:
git checkout -b feature/123-add-user-authentication
git checkout -b bug/456-fix-login-redirect
git checkout -b test/789-add-api-integration-tests
git checkout -b refactor/321-optimize-database-queries
```

### **Step 3: Work & Commit**
```bash
# Reference issue in EVERY commit:
git commit -m "Add user authentication endpoint

- Implement JWT token generation
- Add password hashing with bcrypt
- Create login/logout routes

Refs #123"

# For closing commits:
git commit -m "Complete user authentication implementation

- All tests passing
- Documentation updated
- Security review completed

Closes #123"
```

### **Step 4: Create Pull Request**
```markdown
## PR Title Format:
[TYPE] Brief description - Fixes #[issue-number]

## PR Description Must Include:
- **Closes #[issue-number]** (at the top)
- Link to issue: "Fixes #123" or "Resolves #456"
- Summary of changes
- Testing performed
- Screenshots (for UI changes)
- Breaking changes (if any)
```

### **Step 5: Update Issue During Work**
- Comment on progress/blockers
- Update labels as status changes
- Link related PRs
- Add test results/screenshots

### **Step 6: Close Issue**
- Issues auto-close when PR with "Closes #123" merges
- OR manually close with final comment summarizing completion

---

## 4) Enforcement for AI Agents

### **PRE-WORK CHECKLIST (REQUIRED):**

Before an AI agent writes ANY code, it MUST:

```
[ ] 1. Search for existing issue related to this work
[ ] 2. If no issue exists, CREATE issue with full template
[ ] 3. Add all required labels (type, priority, status, component, effort)
[ ] 4. Assign issue to self/user
[ ] 5. Create branch following naming convention
[ ] 6. Reference issue number in branch name
```

### **DURING-WORK REQUIREMENTS:**

```
[ ] 1. Every commit references issue number (Refs #123)
[ ] 2. Update issue with progress comments
[ ] 3. Update labels as status changes (in-progress → review → done)
[ ] 4. Document any blockers or challenges in issue comments
```

### **POST-WORK REQUIREMENTS:**

```
[ ] 1. Create PR with "Closes #123" in description
[ ] 2. Link PR to issue
[ ] 3. Update issue with test results
[ ] 4. Ensure issue closes automatically when PR merges
[ ] 5. Add final summary comment if manual close needed
```

---

## 5) Integration with Semantic Seed Standards

All issues MUST also comply with `/Users/aideveloper/core/.claude/RULES.MD`:

### **From RULES.MD - Applied to Issues:**

1. **TDD/BDD Requirements:**
   - Issue must include test plan
   - Acceptance criteria must be testable
   - Test coverage requirements stated

2. **Story Point Estimation:**
   - Use Fibonacci: 0, 1, 2, 3, 5, 8
   - Provide rationale for estimate
   - Stories >3 points should be split

3. **Security & Compliance:**
   - Security considerations documented
   - PII handling documented
   - Compliance requirements noted

4. **Documentation:**
   - Files affected must be listed
   - Documentation updates required
   - API changes documented

5. **Accessibility (for UI):**
   - A11y requirements stated
   - Responsive breakpoints listed
   - Keyboard nav requirements

6. **NO AI ATTRIBUTION:**
   - ❌ NEVER mention Claude, Anthropic, or AI tools in issues
   - ✅ Use professional, clear language
   - ❌ No "Generated by AI" or similar phrases

---

## 6) Violation Consequences

### **If Agent Proceeds Without Issue:**

1. **Immediate Stop:**
   - Work must halt immediately
   - No PR can be created without issue
   - No merge without proper tracking

2. **Remediation:**
   - Create issue retroactively
   - Update all commits to reference issue
   - Amend PR to link issue

3. **Impact:**
   - Lost tracking and metrics
   - Difficulty in code archaeology
   - Breaking team workflow
   - Cannot measure velocity
   - Audit trail gaps

---

## 7) Issue Templates (Quick Reference)

### **Bug Template:**
```markdown
## Bug Description
[Clear description of the bug]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Environment
- OS: [e.g., macOS 14.1]
- Browser: [if applicable]
- Node version: [if applicable]
- Deployment: [local/staging/production]

## Error Messages
```
[Paste error messages/stack traces]
```

## Screenshots
[If applicable]

## Proposed Fix
[If you have ideas]
```

### **Feature Template:**
```markdown
## Feature Description
[Clear description of the feature]

## User Story
As a [type of user]
I want [goal/desire]
So that [benefit/value]

## Acceptance Criteria
- [ ] [Specific outcome 1]
- [ ] [Specific outcome 2]
- [ ] [Specific outcome 3]

## Technical Approach
[Proposed implementation]

## UI/UX Mockups
[Links or attachments]

## Dependencies
[Any prerequisites or blockers]
```

### **Test Template:**
```markdown
## Testing Scope
[What needs testing]

## Test Types
- [ ] Unit tests
- [ ] Integration tests
- [ ] E2E tests
- [ ] Performance tests
- [ ] Security tests

## Coverage Goal
Current: [X%]
Target: [Y%]

## Test Cases
1. [Test case 1]
2. [Test case 2]
3. [Test case 3]

## Success Criteria
- [ ] All tests passing
- [ ] Coverage >= target
- [ ] No flaky tests
```

---

## 8) Metrics & Reporting

### **Required Metrics Tracked via Issues:**

- Velocity (story points per sprint)
- Cycle time (issue open → close)
- Bug resolution time
- Test coverage per feature
- Code review time
- Deployment frequency

### **Issue Hygiene:**

- **Weekly Review:** Close stale issues, update priorities
- **Monthly Audit:** Ensure all merged PRs have linked issues
- **Quarterly Cleanup:** Archive old issues, update labels

---

## 9) Quick Command Reference

### **Create Issue (GitHub CLI):**
```bash
gh issue create \
  --title "[BUG] Login redirect fails on Safari" \
  --body-file issue-template.md \
  --label "bug,high,backend" \
  --assignee "@me"
```

### **List My Issues:**
```bash
gh issue list --assignee "@me" --state open
```

### **Link Issue to PR:**
```bash
gh pr create \
  --title "Fix login redirect - Fixes #123" \
  --body "Closes #123" \
  --base main
```

### **Update Issue:**
```bash
gh issue edit 123 --add-label "in-progress"
gh issue comment 123 --body "Progress update: 50% complete"
```

---

## 10) Exceptions & Special Cases

### **Emergency Hotfixes:**
- Issue can be created IMMEDIATELY after fix starts
- Mark with `critical` and `hotfix` labels
- Abbreviated template acceptable
- Full details added within 1 hour

### **Dependency Updates:**
- Single issue can track multiple dependency updates
- Use checklist format for each dependency
- Batch similar updates together

### **Documentation-Only Changes:**
- Still requires issue for tracking
- Can use simplified template
- Mark with `documentation` label

---

## SUMMARY: The Golden Rule

> **"No Code Without An Issue. No PR Without A Link. No Merge Without Tracking."**

Every line of code committed to any AINative repository MUST be traceable to a GitHub issue. This is non-negotiable for:
- Code quality
- Team collaboration
- Velocity measurement
- Audit compliance
- Knowledge management
- Professional development practices

---

## Enforcement Date
**Effective:** Immediately upon adoption
**Review:** Quarterly
**Updates:** As team workflow evolves

**This is a ZERO TOLERANCE policy. All agents and team members must comply.**
