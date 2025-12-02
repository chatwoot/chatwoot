# Task: Extended Community Edition Setup

## Current Status: Infrastructure Complete ✅

- [x] **Setup Infrastructure**
  - [x] Copy `enterprise/` to `extended/`
  - [x] Update all path references
  - [x] Configure module namespace mapping
  - [x] Update routes to use `/extended`
- [x] **Configuration Changes**
  - [x] Force pricing plan to 'community'
  - [x] Enable all feature flags
  - [x] Maintain Community Edition branding
- [x] **Testing Setup**
  - [x] Create `spec/extended/` directory
  - [x] Exclude `spec/enterprise/` from runs
  - [x] Fix frontend tests
  - [x] Fix backend route tests
  - [x] Update route helpers
- [x] **Documentation**
  - [x] Create `MODIFICATIONS.md`
  - [x] Apply strict comment formatting
  - [x] Document all changes

## Next Phase: Code Rewriting

**Important**: When rewriting code in `extended/`, also update corresponding tests in `spec/extended/`.

- [ ] **Phase 1: Captain (AI) Features**
  - [ ] Rewrite `extended/lib/captain/llm_service.rb` + update tests
  - [ ] Rewrite `extended/app/services/captain/llm/contact_notes_service.rb` + update tests
  - [ ] Rewrite `extended/app/services/captain/llm/faq_generator_service.rb` + update tests
  - [ ] Rewrite `extended/app/services/captain/llm/paginated_faq_generator_service.rb` + update tests
  - [ ] Rewrite `extended/app/services/internal/account_analysis/content_evaluator_service.rb` + update tests
  - [ ] Rewrite `extended/app/services/captain/onboarding/website_analyzer_service.rb` + update tests
- [ ] **Phase 2: Agent Capacity**
- [ ] **Phase 3: Audit Logs**
- [ ] **Phase 4: SAML SSO**
- [ ] **Phase 5: Custom Branding**
- [ ] **Phase 6: Cleanup & Verification**
