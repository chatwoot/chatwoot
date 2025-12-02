# Implementation Plan: Extended Community Edition

**Goal**: Create a fully-featured, MIT-licensed "Extended Community Edition" of Chatwoot by rewriting enterprise features.

## 🏁 Current Status

- **Infrastructure**: ✅ Complete
  - `enterprise/` directory copied to `extended/`
  - All references updated from `enterprise` to `extended`
  - `Enterprise` module namespace mapped to `extended` directory
  - Routes mapped: `/extended` -> `Enterprise` module
- **Configuration**: ✅ Complete
  - Pricing plan checks removed (forced to 'community')
  - Feature flags forced to `true` (Captain, SAML, etc.)
  - "Community Edition" branding maintained
- **Testing**: ✅ Complete
  - `spec/extended/` created for new tests
  - `spec/enterprise/` excluded from runs
  - Frontend tests fixed (`isEnterprise: true`)
  - Backend routes fixed (`scope path: :extended`)
  - Route helpers updated (`extended_webhooks_firecrawl_url`)
  - All specs passing

## 🗺️ Roadmap

### Phase 1: Captain (AI) Core Libs [NEXT]

Rewrite core AI library files in `extended/lib/captain/`.

### Phase 2: Captain (AI) Services

Rewrite AI service layers in `extended/app/services/captain/`.

### Phase 3: Captain (AI) Models & Jobs

Rewrite AI data models and background jobs.

### Phase 4: Captain (AI) Controllers

Rewrite API endpoints for AI features.

### Phase 5: Enterprise Core Models

Rewrite enterprise data models and concerns.

### Phase 6: Enterprise Core Services

Rewrite enterprise business logic services.

### Phase 7: Enterprise Core Controllers

Rewrite enterprise API and UI controllers.

### Phase 8: Remaining Components

Rewrite policies, mailers, helpers, and builders.

### Phase 9: Verification

Comprehensive test suite run and license verification.

## 🛠️ Technical Strategy

1.  **Reference Only**: Use original `enterprise/` code ONLY as a reference for behavior. Do not copy-paste.
2.  **Clean Room Implementation**: Write new code in `extended/` that achieves the same result but with different implementation details.
3.  **Strict Documentation**: Continue using the strict comment block format for all changes.
4.  **Test-Driven**: Ensure `spec/extended/` tests pass for each rewritten component.
5.  **Update Tests**: When rewriting code in `extended/`, also update corresponding tests in `spec/extended/` to match the new implementation.

## 📝 Notes for Next Session

- **Routes**: Fixed `config/routes.rb` to map `/extended` to the `Enterprise` module. This fixed 404 errors in tests.
- **Specs**: Using `spec/extended/` and ignoring `spec/enterprise/`.
- **PromptRenderer**: Fixed to look in `extended/lib/captain/prompts`.
- **Route Helpers**: Updated all route helpers from `enterprise_*` to `extended_*`.
- **Important**: When rewriting code in `extended/`, remember to also update the corresponding tests in `spec/extended/` to match your new implementation.
- **Next Step**: Start Phase 1 (Captain AI rewrite).
