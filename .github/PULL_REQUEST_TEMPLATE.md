## Pull Request

### Description
Brief description of changes made.

### Definition of Done Checklist

Ensure all items are completed before merging:

#### Code Quality
- [ ] **Code + tests green**: All tests pass locally and in CI
- [ ] **Linting passes**: `pnpm eslint` and `bundle exec rubocop` pass
- [ ] **Performance budgets respected**: Size-limit checks pass for widget ≤100KB, dashboard ≤200KB
- [ ] **No hardcoded secrets**: All sensitive config uses environment variables

#### Testing
- [ ] **Unit tests added/updated**: For new business logic
- [ ] **Integration tests added**: For API endpoints (if applicable) 
- [ ] **Frontend tests added**: For new Vue components (if applicable)
- [ ] **Manual testing completed**: Feature works as expected in development

#### Documentation
- [ ] **README updated**: Documentation reflects new changes (UK English)
- [ ] **API documentation updated**: OpenAPI spec updated for new endpoints
- [ ] **Environment variables documented**: New vars added to .env.example

#### Release Process
- [ ] **Conventional commit**: Commit message follows `feat:`, `fix:`, `chore:` format
- [ ] **UK English compliance**: All UI text, comments, and docs use British spellings
- [ ] **Feature flags configured**: New features are properly gated (if applicable)
- [ ] **Database migrations safe**: Follow expand/contract pattern for zero-downtime

### Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)  
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

### Testing Instructions
1. Checkout this branch
2. Run setup: `bundle install && pnpm install`
3. Start services: `pnpm dev`
4. Test the feature: [specific steps]

### Performance Impact
- [ ] No performance regression detected
- [ ] Bundle size impact measured and acceptable
- [ ] API response times within SLA (p95 ≤300ms read, ≤600ms write)

### Screenshots (if applicable)
Add screenshots or GIFs demonstrating the changes.

### Related Issues
Closes #[issue-number]
