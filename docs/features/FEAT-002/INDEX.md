# FEAT-002: API Campaign Documentation Index

## Quick Navigation

This directory contains comprehensive documentation for the API Campaign feature implemented in commit 923ae29a8.

---

## Documents

### 📋 [README.md](README.md)
**Main Feature Specification** (1,140 lines)

Complete technical specification covering:
- Feature overview and business value
- User stories with acceptance criteria
- Technical architecture (frontend & backend)
- Implementation details and data flows
- UI/UX specifications with form layouts
- Testing strategy and coverage
- Internationalization support
- Data models and security
- Future enhancement roadmap

**Read this for:** Understanding the complete feature design and technical implementation.

---

### ✅ [PROGRESS.md](PROGRESS.md)
**Implementation Status** (420 lines)

Detailed progress tracking:
- Implementation summary and timeline
- Completed components checklist
- Quality metrics and test coverage
- File additions/modifications
- Integration points verification
- Known limitations and constraints
- Post-launch monitoring plan
- Production readiness sign-off

**Read this for:** Understanding what was delivered, test coverage, and production readiness.

---

### ✅ [EXT-001-MESSAGE-DELAY.md](EXT-001-MESSAGE-DELAY.md)
**Extension: Campaign Message Delay** (Completed)

Feature extension specification and implementation record:
- Configurable delays between campaign messages (none/fixed/random)
- Prevents rate limiting and improves deliverability
- Uses existing `trigger_rules` jsonb column (no migration required)
- Fully implemented with 107 passing tests
- Backend: Campaign model validation, service integration
- Frontend: Form UI with Vuelidate validation, Tailwind styling
- Complete internationalization (English and Portuguese)
- Production ready with full documentation

**Read this for:** Understanding the message delay feature implementation, technical design, and completed tasks.

**Status:** ✅ Completed on October 4, 2025 (17 hours implementation time)

---

## Quick Reference

### Key Statistics

- **Total Code:** 1,223 insertions, 5 deletions
- **Frontend:** 771 lines (Vue 3 components)
- **Backend:** 105 lines (Rails services)
- **Tests:** 607 lines (100% passing)
- **Files Changed:** 20 files
- **Implementation Date:** September 20, 2025
- **Status:** ✅ Production Ready

### Feature Capabilities

✅ Create API campaigns with validation
✅ Schedule campaigns for future execution
✅ Target audiences using labels
✅ Support API and WhatsApp channels
✅ Background job processing
✅ Webhook integration
✅ Multi-language support (en, pt_BR)

### Technical Stack

- **Frontend:** Vue 3 Composition API, Tailwind CSS, Vuelidate
- **Backend:** Rails 7.1, PostgreSQL, Sidekiq
- **Testing:** Vitest (frontend), RSpec (backend)
- **I18n:** English, Portuguese

---

## File Locations

### Frontend Components
```
/app/javascript/dashboard/
├── components-next/Campaigns/
│   ├── Pages/CampaignPage/APICampaign/
│   │   ├── APICampaignForm.vue          (189 lines)
│   │   ├── APICampaignDialog.vue        (49 lines)
│   │   └── APICampaignForm.spec.js      (195 lines)
│   └── EmptyState/
│       └── APICampaignEmptyState.vue    (37 lines)
└── routes/dashboard/campaigns/pages/
    ├── APICampaignsPage.vue             (85 lines)
    └── APICampaignsPage.spec.js         (152 lines)
```

### Backend Services
```
/app/services/
├── api/
│   └── oneoff_api_campaign_service.rb   (52 lines)
└── whatsapp/
    └── oneoff_whatsapp_campaign_service.rb (46 lines)

/spec/services/
├── api/
│   └── oneoff_api_campaign_service_spec.rb   (146 lines)
└── whatsapp/
    └── oneoff_whatsapp_campaign_service_spec.rb (114 lines)
```

### Model
```
/app/models/
└── campaign.rb                          (7 lines modified)
```

---

## Related Resources

### Chatwoot Documentation
- Campaign Model: `/app/models/campaign.rb`
- Campaigns Routes: `/app/javascript/dashboard/routes/dashboard/campaigns/campaigns.routes.js`
- Campaign Store: `/app/javascript/dashboard/store/modules/campaigns.js`
- Inboxes Store: `/app/javascript/dashboard/store/modules/inboxes.js`

### External References
- Vue 3 Composition API: https://vuejs.org/guide/introduction.html
- Vuelidate: https://vuelidate-next.netlify.app/
- Rails Service Objects: https://www.toptal.com/ruby-on-rails/rails-service-objects-tutorial
- Tailwind CSS: https://tailwindcss.com/docs

---

## For Developers

### Getting Started
1. Read [README.md](README.md) sections 1-3 for feature overview and architecture
2. Review [PROGRESS.md](PROGRESS.md) to see what's implemented
3. Check test files for usage examples
4. Reference README.md sections 4-6 for implementation patterns

### Extending the Feature
See README.md section "Future Enhancements" for planned extensions and architecture guidance.

### Running Tests
```bash
# Frontend tests
pnpm test APICampaign

# Backend tests
bundle exec rspec spec/services/api/oneoff_api_campaign_service_spec.rb
bundle exec rspec spec/services/whatsapp/oneoff_whatsapp_campaign_service_spec.rb
```

### Common Tasks

**Add new channel support:**
1. Create service in `/app/services/{channel}/`
2. Add case in `campaign.rb#execute_campaign`
3. Add tests in `/spec/services/{channel}/`
4. Update frontend to filter by channel type

**Add new targeting criteria:**
1. Extend `audience` JSON structure
2. Update campaign form with new fields
3. Modify service `process_audience` method
4. Add validation in Campaign model

**Add internationalization:**
1. Update `/app/javascript/dashboard/i18n/locale/en/campaign.json`
2. Crowdin will sync to other languages

---

## Support

**Questions or Issues?**
- Developer: @milesibastos (antonio@milesibastos.com)
- Codebase: https://github.com/chatwoot/chatwoot
- Documentation: This directory

---

**Last Updated:** October 4, 2025
**Feature Version:** 1.0
**Status:** Production Ready
