---
name: Feature Request
about: Request a new feature for WeaveSmart Chat
title: 'feat: '
labels: 'enhancement'
assignees: ''
---

## Feature Request

### Description
Brief description of the feature and why it's needed.

### Definition of Ready Checklist

Before this issue can be worked on, ensure all items are completed:

- [ ] **Block scope is clear**: Feature requirements are well-defined with clear boundaries
- [ ] **Acceptance criteria testable**: Specific, measurable outcomes defined below
- [ ] **Feature flags identified**: Any new features require appropriate toggles (per tenant/plan)
- [ ] **Environment variables defined**: Any new config vars documented with defaults
- [ ] **Migrations planned**: Database changes follow expand/contract pattern for zero-downtime

### Acceptance Criteria

Define specific, testable criteria:

- [ ] Given [context], when [action], then [expected outcome]
- [ ] Error cases and edge cases considered
- [ ] UI/UX specifications clear (if applicable)
- [ ] Performance requirements defined (if applicable)

### Feature Flags Required

- [ ] Per-tenant flag: `feature.new_feature_name`
- [ ] Per-plan availability: Basic/Pro/Premium/App/Custom
- [ ] Default state: disabled

### Environment Variables

List any new environment variables needed:

```bash
# Example:
NEW_FEATURE_API_KEY=your_api_key_here
NEW_FEATURE_ENABLED=false
```

### Database Migrations

- [ ] Expand phase: Add new columns/tables without breaking existing code
- [ ] Contract phase: Remove old columns after code deployment (if applicable)
- [ ] Backward compatibility maintained during migration

### Technical Notes

Any additional technical considerations or constraints.