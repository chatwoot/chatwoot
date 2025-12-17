# Git Commit Rules for AINative Projects

## CRITICAL RULES - NEVER VIOLATE

### 1. NO ANTHROPIC OR CLAUDE ATTRIBUTION
**NEVER** include any of the following in git commits, pull requests, or GitHub activity:

❌ **FORBIDDEN TEXT:**
- "Claude"
- "Anthropic"
- "claude.com"
- "Claude Code"
- "Generated with Claude"
- "Co-Authored-By: Claude"
- Any reference to Claude or Anthropic whatsoever

### 2. COMMIT MESSAGE FORMAT

✅ **CORRECT FORMAT:**
```
Short descriptive title

- Bullet point describing changes
- Another bullet point
- Final bullet point
```

❌ **INCORRECT FORMAT:**
```
Short descriptive title

- Changes made
- More changes

🤖 Generated with Claude Code
https://claude.com/claude-code

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 3. PULL REQUEST DESCRIPTIONS

✅ **CORRECT FORMAT:**
```markdown
## Summary
- Clear description of changes
- What was fixed or added
- Why these changes were made

## Test Plan
- How to test the changes
- Expected results
```

❌ **INCORRECT FORMAT:**
```markdown
## Summary
Changes made...

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 4. ENFORCEMENT

**These rules apply to:**
- All commit messages
- All pull request descriptions
- All issue comments
- All GitHub discussions
- Any public-facing git activity

**Violating these rules will:**
- Create public attribution that must be avoided
- Associate our work with third-party tools
- Compromise the professional appearance of our repositories

### 5. EXAMPLES

#### ✅ GOOD COMMIT:
```
Add multi-dimension vector support

- Support for 384, 768, 1024, and 1536 dimensions
- Update validation logic for new dimensions
- Add comprehensive test coverage
```

#### ❌ BAD COMMIT:
```
Add multi-dimension vector support

- Support for 384, 768, 1024, and 1536 dimensions
- Update validation logic for new dimensions
- Add comprehensive test coverage

🤖 Generated with Claude Code
https://claude.com/claude-code

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## REMINDER

This is a **ZERO TOLERANCE** rule. Every commit must be checked before pushing to ensure no Claude/Anthropic attribution exists.
