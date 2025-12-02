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

- [x] **Phase 1: Captain (AI) Core Libs**

  - [x] `extended/lib/captain/llm_service.rb`
  - [x] `extended/lib/captain/agent.rb`
  - [x] `extended/lib/captain/prompt_renderer.rb`
  - [x] `extended/lib/captain/tool.rb`
  - [x] `extended/lib/captain/response_schema.rb`
  - [x] `extended/lib/captain/tools/*.rb` (10 files)

- [ ] **Phase 2: Captain (AI) Services**

  - [ ] `extended/app/services/captain/llm/*.rb`
  - [ ] `extended/app/services/captain/tools/*.rb`
  - [ ] `extended/app/services/captain/*.rb`

- [ ] **Phase 3: Captain (AI) Models & Jobs**

  - [ ] `extended/app/models/captain/*.rb`
  - [ ] `extended/app/jobs/captain/*.rb`

- [ ] **Phase 4: Captain (AI) Controllers**

  - [ ] `extended/app/controllers/api/v1/accounts/captain/*.rb`

- [ ] **Phase 5: Enterprise Core Models**

  - [ ] `extended/app/models/enterprise/*.rb`
  - [ ] `extended/app/models/enterprise/concerns/*.rb`

- [ ] **Phase 6: Enterprise Core Services**

  - [ ] `extended/app/services/enterprise/*.rb`

- [ ] **Phase 7: Enterprise Core Controllers**

  - [ ] `extended/app/controllers/enterprise/*.rb`

- [ ] **Phase 8: Remaining Components**
  - [ ] Policies
  - [ ] Mailers
  - [ ] Helpers
  - [ ] Views/Builders
