# CommMate Core Modifications

**Purpose:** Complete list of all Chatwoot files modified by CommMate  
**Goal:** Quick reference for merge conflict resolution during upgrades  
**Last Updated:** January 14, 2026

---

## 📊 Summary

**Total Modified Files:** 51 files  
**Total Lines Changed:** ~1700 lines across all files (including i18n translations)

CommMate maintains minimal modifications to Chatwoot core, focusing on:
- Branding (logo, version display)
- Custom roles functionality
- Campaign permission management
- Version tracking
- WhatsApp Templates CRUD (feat/whatsapp-templates-crud)
- Evolution WhatsApp Inbox Integration (feat/evolution-baileys-inbox)
- Contact Preferences Feature (public subscription management)

---

## 📁 Modified Files by Category

### Controllers (1 file)

#### 1. app/controllers/super_admin/instance_statuses_controller.rb

**Lines Modified:** ~20 lines  
**Reason:** Display CommMate version information alongside Chatwoot version  
**Last Modified:** December 6, 2025

**Changes Made:**
- Modified `show` method to call `commmate_version` and `chatwoot_base_version`
- Enhanced `sha` method to display both CommMate and Chatwoot git SHAs
- Added `commmate_version` method
- Added `chatwoot_base_version` method

**Review on Upgrade:**
- Check if `show` method signature changed
- Check if new metrics were added
- Verify `sha` method still exists
- Ensure CommMate methods don't conflict with new Chatwoot methods

**Merge Conflict Strategy:**
- Keep Chatwoot's new functionality
- Add CommMate version calls at the beginning of `show` method
- Merge both versions in `sha` method

---

### Views (4 files)

#### 2. app/views/super_admin/application/_navigation.html.erb

**Lines Modified:** ~5 lines (lines 26-30)  
**Reason:** CommMate branding in super admin interface  
**Last Modified:** Before December 2025

**Changes Made:**
- Line 26: Changed logo to `/brand-assets/logo_thumbnail.png`
- Line 28: Display CommMate version instead of Chatwoot version
- Line 29: Text changed to "CommMate Admin Console"

**Review on Upgrade:**
- Check if navigation structure changed
- Verify logo path location
- Check if version display logic changed
- Review sidebar layout modifications

**Merge Conflict Strategy:**
- Keep Chatwoot's structural changes
- Reapply CommMate branding (logo, version, text)
- Preserve any new navigation items Chatwoot added

---

#### 3. app/views/super_admin/application/_javascript.html.erb

**Lines Modified:** ~30 lines (lines 23-53)  
**Reason:** Disable Chatwoot support widget for CommMate  
**Last Modified:** Before December 2025

**Changes Made:**
- Commented out entire Chatwoot support widget code
- Added comment explaining widget removal for CommMate

**Review on Upgrade:**
- Check if widget code location changed
- Verify no new widgets were added
- Ensure comment block is still valid

**Merge Conflict Strategy:**
- If new widgets added, evaluate if CommMate needs them
- Keep widget disabled unless specifically needed
- Update comments to reflect any new changes

---

#### 4. app/views/super_admin/application/_icons.html.erb

**Lines Modified:** ~3 lines  
**Reason:** Add shield-check icon for custom roles feature  
**Last Modified:** Before December 2025

**Changes Made:**
- Added `icon-shield-check-line` SVG symbol
- Used for custom roles navigation item

**Review on Upgrade:**
- Check if icon definition format changed
- Verify icon still displays correctly
- Check for icon naming conflicts with new Chatwoot icons

**Merge Conflict Strategy:**
- Keep all Chatwoot's new icons
- Preserve CommMate's shield-check icon
- Resolve any naming conflicts by renaming if needed

---

#### 5. app/views/super_admin/devise/sessions/new.html.erb

**Lines Modified:** ~3 lines (lines 4, 12-13)  
**Reason:** CommMate branding on super admin login page  
**Last Modified:** Before December 2025

**Changes Made:**
- Line 4: Page title changed to "SuperAdmin | CommMate"
- Line 12: Logo changed to `/brand-assets/logo-full.png`
- Line 13: Dark mode logo changed to `/brand-assets/logo-full-dark.png`

**Review on Upgrade:**
- Check if login page structure changed
- Verify logo paths are still valid
- Review any new Tailwind classes or styling
- Check if authentication flow changed

**Merge Conflict Strategy:**
- Keep Chatwoot's layout and functionality changes
- Reapply CommMate branding (title, logos)
- Preserve Chatwoot's security improvements

---

### Dashboards (1 file)

#### 6. app/dashboards/account_user_dashboard.rb

**Lines Modified:** ~3 lines (14, 31, 42)  
**Reason:** Add custom_role field to account user management  
**Last Modified:** Before December 2025

**Changes Made:**
- Line 14: Added `custom_role: Field::BelongsTo` to ATTRIBUTE_TYPES
- Line 31: Added `custom_role` to COLLECTION_ATTRIBUTES
- Line 42: Added `custom_role` to SHOW_PAGE_ATTRIBUTES

**Review on Upgrade:**
- Check if new fields were added to ATTRIBUTE_TYPES
- Verify array positions haven't caused issues
- Review if dashboard field types changed
- Check for new Administrate features

**Merge Conflict Strategy:**
- Keep all Chatwoot's new fields
- Preserve custom_role field in correct position
- Adjust array positions if needed
- Test dashboard displays correctly

---

### Policies (1 file)

#### 7. app/policies/campaign_policy.rb

**Lines Modified:** ~10 lines (entire file)  
**Reason:** Add custom role permission checks for campaigns  
**Last Modified:** Before December 2025

**Changes Made:**
- Modified all permission methods to check custom role permissions
- Added `has_campaign_permission?` private method
- Checks for `campaign_manage` permission in custom role

**Review on Upgrade:**
- Check if new permission methods were added
- Verify permission check logic hasn't changed
- Review if policy base class changed
- Check for new authorization patterns

**Merge Conflict Strategy:**
- Keep Chatwoot's new permission checks
- Preserve custom role check logic
- Use OR logic: `administrator? || has_campaign_permission?`
- Test with custom roles after merge

---

### JavaScript/Frontend (2 files)

#### 8. app/javascript/dashboard/routes/dashboard/campaigns/campaigns.routes.js

**Lines Modified:** 1 line (line 11)  
**Reason:** Add campaign_manage permission to route meta  
**Last Modified:** Before December 2025

**Changes Made:**
- Line 11: Added `'campaign_manage'` to permissions array
- Allows custom role users to access campaigns

**Review on Upgrade:**
- Check if route structure changed
- Verify permissions array format
- Review if new routes were added
- Check for route guard changes

**Merge Conflict Strategy:**
- Keep Chatwoot's route structure
- Preserve campaign_manage in permissions array
- Ensure permission format matches Chatwoot's convention
- Test route access with custom roles

---

#### 9. app/javascript/dashboard/constants/permissions.js

**Lines Modified:** 1 line (line 8)  
**Reason:** Add campaign_manage to available permissions  
**Last Modified:** Before December 2025

**Changes Made:**
- Line 8: Added `'campaign_manage'` to AVAILABLE_CUSTOM_ROLE_PERMISSIONS array
- Enables campaign_manage in custom role UI

**Review on Upgrade:**
- Check if new permissions were added
- Verify permission naming convention
- Review permission constant usage
- Check for permission structure changes

**Merge Conflict Strategy:**
- Keep all Chatwoot's new permissions
- Preserve campaign_manage in the array
- Maintain alphabetical order if Chatwoot does
- Test custom role permission UI

---

### WhatsApp Templates CRUD (4 files)

These modifications support the WhatsApp Templates CRUD feature (feat/whatsapp-templates-crud).

#### 10. config/routes.rb (Additional modification)

**Lines Modified:** ~10 lines  
**Reason:** Add WhatsApp message templates API routes  
**Last Modified:** January 2026

**Changes Made:**
- Added `namespace :whatsapp` nested routes for message_templates
- Routes: `index`, `create`, `destroy`, and `upload_media` collection action
- Path pattern: `/api/v1/accounts/:account_id/whatsapp/inboxes/:inbox_id/message_templates`

**Review on Upgrade:**
- Check if whatsapp namespace structure changed
- Verify route naming conventions
- Check for conflicts with new WhatsApp features

**Merge Conflict Strategy:**
- Keep Chatwoot's routing changes
- Preserve CommMate WhatsApp templates routes in the whatsapp namespace
- Ensure no conflicts with Chatwoot's own template routes

---

#### 11. app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue

**Lines Modified:** ~15 lines  
**Reason:** Add WhatsApp Templates tab to inbox settings  
**Last Modified:** January 2026

**Changes Made:**
- Import `WhatsappTemplates` component
- Add `WhatsappTemplates` to components
- Add tab entry `whatsapp-templates` for WhatsApp Cloud channels
- Add tab content rendering for `<WhatsappTemplates :inbox="inbox" />`

**Review on Upgrade:**
- Check if Settings.vue tabs structure changed
- Verify component import patterns
- Review if new inbox types were added
- Check for isAWhatsAppCloudChannel computed property changes

**Merge Conflict Strategy:**
- Keep Chatwoot's Settings.vue changes
- Preserve WhatsappTemplates import and component registration
- Add tab entry in the correct position (after whatsapp-health)
- Test tab visibility for WhatsApp Cloud channels only

---

#### 12. app/javascript/dashboard/components/Modal.vue

**Lines Modified:** ~3 lines  
**Reason:** Add "large" size class for TemplateBuilder modal  
**Last Modified:** January 2026

**Changes Made:**
- Added `.large` CSS class with `max-w-[90%] w-[75rem]`
- Used for the WhatsApp TemplateBuilder modal

**Review on Upgrade:**
- Check if Modal.vue sizing classes changed
- Verify CSS class naming conventions
- Review Tailwind utilities compatibility

**Merge Conflict Strategy:**
- Keep Chatwoot's Modal.vue changes
- Preserve `.large` class definition
- Adjust Tailwind classes if conventions change

---

#### 13. app/javascript/dashboard/i18n/locale/en/inboxMgmt.json

**Lines Modified:** ~250 lines (WHATSAPP_TEMPLATES section)  
**Reason:** Add WhatsApp Templates CRUD translations to English locale  
**Last Modified:** January 2026

**Changes Made:**
- Added `WHATSAPP_TEMPLATES` key to `INBOX_MGMT.TABS`
- Added complete `WHATSAPP_TEMPLATES` section under `INBOX_MGMT` with all template builder translations
- Added `TEMPLATES` section for account-level templates page translations

**Review on Upgrade:**
- Check if inboxMgmt.json structure changed
- Verify translation key format conventions
- Review if new WhatsApp features were added
- Check for i18n framework updates (vue-i18n)

**Merge Conflict Strategy:**
- Keep Chatwoot's translation changes
- Preserve CommMate's WHATSAPP_TEMPLATES section
- Merge any overlapping keys carefully
- Test all CommMate translations display correctly

---

#### 14. app/javascript/dashboard/i18n/locale/pt_BR/inboxMgmt.json

**Lines Modified:** ~250 lines (WHATSAPP_TEMPLATES section)  
**Reason:** Add WhatsApp Templates CRUD translations to Portuguese locale  
**Last Modified:** January 2026

**Changes Made:**
- Added `WHATSAPP_TEMPLATES` key to `INBOX_MGMT.TABS`
- Added complete `WHATSAPP_TEMPLATES` section under `INBOX_MGMT` with all template builder translations (in Portuguese)
- Added `TEMPLATES` section for account-level templates page translations (in Portuguese)

**Review on Upgrade:**
- Check if inboxMgmt.json structure changed
- Verify translation key format conventions
- Review if new WhatsApp features were added
- Check for i18n framework updates (vue-i18n)

**Merge Conflict Strategy:**
- Keep Chatwoot's translation changes
- Preserve CommMate's WHATSAPP_TEMPLATES section
- Merge any overlapping keys carefully
- Test all CommMate translations display correctly

---

### Evolution WhatsApp Inbox Integration (17 files)

These modifications support the Evolution WhatsApp Inbox integration (feat/evolution-baileys-inbox).  
Enables WhatsApp communication via Evolution API (Baileys provider only).

#### 17. app/controllers/api/v1/accounts/evolution_inboxes_controller.rb

**Lines Modified:** 370 lines (NEW FILE)  
**Reason:** Handle Evolution API-backed WhatsApp inbox operations  
**Last Modified:** January 2026

**Changes Made:**
- New controller for Evolution inbox management
- Actions: create, connection state, QR code, enable integration, restart, logout, refresh
- Phone number extraction from Evolution API (ownerJid)
- Chatwoot integration settings management
- Instance settings configuration

**Review on Upgrade:**
- No conflicts expected (new file)
- Check if BaseController interface changed

**Merge Conflict Strategy:**
- Keep as new file
- Ensure BaseController inheritance works

---

#### 18. app/services/evolution_api/client.rb

**Lines Modified:** 270 lines (NEW FILE)  
**Reason:** Evolution API HTTP client for Baileys integration  
**Last Modified:** January 2026

**Changes Made:**
- HTTP client for Evolution API communication
- Instance management (create, delete, fetch, connection state)
- Chatwoot integration configuration
- WhatsApp settings management
- Message sending (text and media)
- 30-second timeout for API requests

**Review on Upgrade:**
- No conflicts expected (new file)

**Merge Conflict Strategy:**
- Keep as new file

---

#### 19. app/services/evolution_api/inbox_provisioner.rb

**Lines Modified:** 163 lines (NEW FILE)  
**Reason:** Orchestrate Evolution inbox creation  
**Last Modified:** January 2026

**Changes Made:**
- Evolution instance creation
- Chatwoot inbox creation
- Integration user management (uses current user, not system user)
- Inbox name uniqueness validation

**Review on Upgrade:**
- No conflicts expected (new file)

**Merge Conflict Strategy:**
- Keep as new file

---

#### 20. app/services/evolution/send_on_evolution_baileys_service.rb

**Lines Modified:** 139 lines (NEW FILE)  
**Reason:** Handle outbound messages for Evolution Baileys inboxes  
**Last Modified:** January 2026

**Changes Made:**
- Message sending service (text and media)
- Evolution API response parsing
- Message status updates
- Contact identifier handling (WhatsApp JID)

**Review on Upgrade:**
- No conflicts expected (new file)

**Merge Conflict Strategy:**
- Keep as new file

---

#### 21. app/models/concerns/evolution_inbox.rb

**Lines Modified:** 50 lines (NEW FILE)  
**Reason:** Evolution inbox predicates and cleanup  
**Last Modified:** January 2026

**Changes Made:**
- `evolution_inbox?` and `evolution_baileys?` predicates
- `before_destroy` callback to delete Evolution instance
- Instance name extraction helper

**Review on Upgrade:**
- No conflicts expected (new file)
- Ensure included in Inbox model

**Merge Conflict Strategy:**
- Keep as new file

---

#### 22. app/jobs/send_reply_job.rb

**Lines Modified:** ~10 lines  
**Reason:** Prevent duplicate message sending for Evolution inboxes  
**Last Modified:** January 2026

**Changes Made:**
- Skip Evolution inboxes in send job (Evolution's native integration handles it)
- Prevents duplicate outbound messages

**Review on Upgrade:**
- Check if perform method signature changed
- Verify CHANNEL_SERVICES hash structure

**Merge Conflict Strategy:**
- Keep skip logic for Evolution inboxes
- Add comment explaining why

---

#### 23-29. Frontend Components (7 Vue files)

**Files Modified:**
- `app/javascript/dashboard/routes/dashboard/settings/inbox/Index.vue`
- `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue`
- `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/ChannelList.vue`
- `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/ChannelFactory.vue`
- `app/javascript/dashboard/routes/dashboard/settings/inbox/components/ChannelName.vue`
- `app/javascript/dashboard/routes/dashboard/settings/inbox/evolution/EvolutionWhatsapp.vue` (NEW)
- `app/javascript/dashboard/routes/dashboard/settings/inbox/evolution/EvolutionSettings.vue` (NEW)

**Changes Made:**
- Add Evolution channel to inbox creation flow
- Display phone number from additional_attributes for Evolution inboxes
- Show "Evolution WhatsApp" as channel name
- New Evolution inbox creation page with QR code scanning
- New Evolution settings page with connection management
- Phone number display updates after refresh

**Review on Upgrade:**
- Check if inbox creation flow changed
- Verify Settings.vue tabs structure
- Review ChannelList/ChannelFactory patterns

**Merge Conflict Strategy:**
- Keep Evolution channel additions
- Preserve Evolution components as new files

---

#### 30-36. Frontend Helpers & Components (7 files)

**Files Modified:**
- `app/javascript/dashboard/helper/inbox.js` - Evolution inbox detection, WhatsApp icon/name
- `app/javascript/dashboard/components-next/icon/provider.js` - WhatsApp icon for Evolution
- `app/javascript/dashboard/components-next/NewConversation/helpers/composeConversationHelper.js` - Phone number in send message
- `app/javascript/dashboard/components-next/Inbox/InboxCard.vue` - Pass additional_attributes for icon
- `app/javascript/dashboard/components-next/Conversation/ConversationCard.vue` - Pass additional_attributes
- `app/javascript/dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue` - Pass additional_attributes
- `app/javascript/dashboard/components-next/captain/assistant/InboxCard.vue` - Display phone number

**Changes Made:**
- `isEvolutionInbox()` helper function
- `getInboxIconByType()` accepts `additionalAttributes` parameter
- WhatsApp icon display for Evolution inboxes
- Phone number display in all inbox lists

**Review on Upgrade:**
- Check if inbox helper patterns changed
- Verify icon provider structure

**Merge Conflict Strategy:**
- Keep Evolution-specific checks
- Preserve additional_attributes parameter passing

---

#### 37. app/javascript/dashboard/i18n/locale/pt_BR/inboxMgmt.json

**Lines Modified:** ~150 lines  
**Reason:** Portuguese translations for Evolution features  
**Last Modified:** January 2026

**Changes Made:**
- Added `EVOLUTION` section under `INBOX_MGMT.ADD`
- Added `EVOLUTION_SETTINGS` tab and section
- Added `CHANNELS.EVOLUTION` translation
- Complete Evolution UI translations in Portuguese

**Review on Upgrade:**
- Check if inboxMgmt.json structure changed
- Review if Evolution translations conflict with new Chatwoot features

**Merge Conflict Strategy:**
- Keep Chatwoot's structure
- Preserve CommMate's EVOLUTION sections

---

#### 38. app/views/api/v1/models/_inbox_slim.json.jbuilder

**Lines Modified:** 4 lines  
**Reason:** Expose additional_attributes and phone_number for Evolution inboxes  
**Last Modified:** January 2026

**Changes Made:**
- Added `phone_number` field
- Added `additional_attributes` field
- Added `medium` field
- Added `messaging_service_sid` field

**Review on Upgrade:**
- Check if inbox_slim structure changed
- Verify no sensitive data exposure

**Merge Conflict Strategy:**
- Keep additions
- Align with _inbox.json.jbuilder structure

---

### Contact Preferences Feature (14 files)

These modifications implement the public contact preferences system for campaign subscription management.

#### db/migrate/20260124163545_add_available_for_campaigns_to_labels.rb

**Lines Modified:** Entire file (NEW)  
**Reason:** Add `available_for_campaigns` flag to labels for campaign preferences  
**Last Modified:** January 24, 2026

**Changes Made:**
- Adds `available_for_campaigns` boolean column to `labels` table
- Default value: false

---

#### app/models/label.rb

**Lines Modified:** ~5 lines  
**Reason:** Add campaign_labels scope for preference management  
**Last Modified:** January 24, 2026

**Changes Made:**
- Updated schema comment to include `available_for_campaigns`
- Added `scope :campaign_labels` for filtering labels available in campaigns

---

#### app/controllers/api/v1/accounts/labels_controller.rb

**Lines Modified:** ~3 lines  
**Reason:** Allow setting available_for_campaigns attribute  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `:available_for_campaigns` to `permitted_params`

---

#### app/views/api/v1/accounts/labels/*.json.jbuilder (4 files)

**Files:** index, show, create, update  
**Lines Modified:** 1 line each  
**Reason:** Expose available_for_campaigns in API responses  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `json.available_for_campaigns` to each view

---

#### app/services/contact_preference_token_service.rb

**Lines Modified:** Entire file (NEW)  
**Reason:** Generate secure JWT tokens for public preference pages  
**Last Modified:** January 24, 2026

**Changes Made:**
- 30-day token expiry
- Token includes contact_id and account_id
- Decode method with error handling for expired/invalid tokens

---

#### app/drops/contact_drop.rb

**Lines Modified:** ~20 lines  
**Reason:** Add preference_link and unsubscribe_all_link Liquid variables  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `preference_link` method for full preferences URL
- Added `unsubscribe_all_link` method for direct unsubscribe URL
- Added `base_url` private helper

---

#### app/controllers/public/api/v1/preferences_controller.rb

**Lines Modified:** Entire file (NEW)  
**Reason:** Handle public preference page requests  
**Last Modified:** January 24, 2026

**Changes Made:**
- Token validation and contact lookup
- Show full preferences page
- Handle single subscribe/unsubscribe actions via query params
- Handle unsubscribe_all action
- Comprehensive error handling (expired, invalid, not found)

---

#### app/views/layouts/preferences.html.erb

**Lines Modified:** Entire file (NEW)  
**Reason:** Standalone mobile-friendly layout for preference pages  
**Last Modified:** January 24, 2026

**Changes Made:**
- Dark/light mode support
- Mobile-friendly responsive design
- Custom CSS for preference components

---

#### app/views/public/api/v1/preferences/*.html.erb (5 files)

**Files:** show, subscribe, unsubscribe, unsubscribe_all, error  
**Lines Modified:** ~300 lines total (NEW)  
**Reason:** Public preference page views  
**Last Modified:** January 24, 2026

**Changes Made:**
- Full preferences page with label checkboxes
- Subscribe/unsubscribe confirmation pages
- Unsubscribe all confirmation page
- Error page with multiple error types

---

#### config/routes.rb

**Lines Modified:** ~3 lines  
**Reason:** Add public preferences routes  
**Last Modified:** January 24, 2026

**Changes Made:**
- GET `/preferences/:token` for show action
- POST `/preferences/:token` for update action

---

#### app/javascript/dashboard/routes/dashboard/settings/labels/AddLabel.vue

**Lines Modified:** ~10 lines  
**Reason:** Add Available for campaigns checkbox  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `availableForCampaigns` data property
- Added to store dispatch
- Added checkbox in template

---

#### app/javascript/dashboard/routes/dashboard/settings/labels/EditLabel.vue

**Lines Modified:** ~10 lines  
**Reason:** Add Available for campaigns checkbox  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `availableForCampaigns` data property
- Added to setFormValues
- Added to store dispatch
- Added checkbox in template

---

#### app/javascript/dashboard/components-next/whatsapp/chatwootVariables.ts

**Lines Modified:** ~20 lines  
**Reason:** Add preference_link and unsubscribe_all_link to template variables  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `contact.preference_link` variable
- Added `contact.unsubscribe_all_link` variable

---

#### custom/locales/en_custom.yml & pt_BR_custom.yml

**Lines Modified:** ~80 lines total  
**Reason:** Add preference page translations  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `public_preferences` section with all UI strings
- Error messages for all error types
- Both English and Portuguese translations

---

#### app/javascript/dashboard/i18n/locale/en/labelsMgmt.json & pt_BR/labelsMgmt.json

**Lines Modified:** ~6 lines total  
**Reason:** Add label form translation  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `AVAILABLE_FOR_CAMPAIGNS.LABEL` translation

---

#### spec/services/contact_preference_token_service_spec.rb

**Lines Modified:** Entire file (NEW)  
**Reason:** Unit tests for JWT token service  
**Last Modified:** January 24, 2026

**Changes Made:**
- Tests for token generation
- Tests for token decoding (valid, expired, invalid)
- Tests for `generate_for_contact` class method

---

#### spec/controllers/public/api/v1/preferences_controller_spec.rb

**Lines Modified:** Entire file (NEW)  
**Reason:** Unit tests for preferences controller  
**Last Modified:** January 24, 2026

**Changes Made:**
- Tests for `contact_identifier_text` helper
- Tests for `find_campaign_label` method
- Tests for `error_status_for` method
- Tests for locale detection

---

#### spec/drops/contact_drop_spec.rb (modified)

**Lines Modified:** ~20 lines  
**Reason:** Add tests for preference link methods  
**Last Modified:** January 24, 2026

**Changes Made:**
- Tests for `preference_link` method
- Tests for `unsubscribe_all_link` method

---

#### spec/models/label_spec.rb (modified)

**Lines Modified:** ~20 lines  
**Reason:** Add tests for campaign labels  
**Last Modified:** January 24, 2026

**Changes Made:**
- Tests for `campaign_labels` scope
- Tests for `available_for_campaigns` attribute

---

#### app/javascript/dashboard/store/modules/labels.js

**Lines Modified:** ~5 lines  
**Reason:** Add getCampaignLabels getter for campaign audience selection  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `getCampaignLabels` getter to filter labels by `available_for_campaigns: true`

---

#### app/views/api/v1/models/_contact.json.jbuilder

**Lines Modified:** 1 line  
**Reason:** Expose preference_link in contact API responses  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `json.preference_link ContactPreferenceTokenService.generate_preference_url(resource)`

---

#### app/javascript/dashboard/components-next/Contacts/Pages/ContactDetails.vue

**Lines Modified:** ~15 lines  
**Reason:** Add "Manage Preferences" button for agents  
**Last Modified:** January 24, 2026

**Changes Made:**
- Added `openPreferenceLink` method
- Added "Manage Preferences" button next to "Update Contact" (ghost variant, matching Evolution settings style)

---

#### Campaign Forms (3 files)

**Files Modified:**
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignCreateDialog.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignForm.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/SMSCampaign/SMSCampaignForm.vue`

**Lines Modified:** ~6 lines total  
**Reason:** Filter campaign audience to only show campaign-enabled labels  
**Last Modified:** January 24, 2026

**Changes Made:**
- Changed label getter from `labels/getLabels` to `labels/getCampaignLabels`
- Audience dropdown now only shows labels with `available_for_campaigns: true`

---

### Configuration (2 files, now 3 files)

#### 14. config/routes.rb

**Lines Modified:** ~10 lines total (line 597 + WhatsApp templates routes)  
**Reason:** Add custom roles routes to super admin + WhatsApp templates routes  
**Last Modified:** Before December 2025

**Changes Made:**
- Line 597: Added `resources :custom_roles` with all REST actions
- Enables custom roles management in super admin

**Review on Upgrade:**
- Check if super_admin namespace structure changed
- Verify route ordering still makes sense
- Review if new route constraints were added
- Check for routing DSL changes

**Merge Conflict Strategy:**
- Keep Chatwoot's routing changes
- Preserve custom_roles route
- Maintain route position in super_admin namespace
- Test all custom role CRUD operations

---

#### 11. config/initializers/git_sha.rb

**Lines Modified:** ~15 lines (16-30)  
**Reason:** Track both CommMate and Chatwoot git SHAs  
**Last Modified:** Before December 2025

**Changes Made:**
- Added `fetch_commmate_git_sha` method
- Reads `.commmate_git_sha` file if present
- Defines `COMMMATE_GIT_HASH` constant
- Defines `CHATWOOT_GIT_HASH` constant for reference

**Review on Upgrade:**
- Check if SHA fetching logic changed
- Verify constant naming conventions
- Review if new constants were added
- Check for git integration changes

**Merge Conflict Strategy:**
- Keep Chatwoot's SHA fetching improvements
- Preserve CommMate SHA tracking logic
- Ensure both SHAs are captured correctly
- Test version display in super admin

---

### Enterprise Compliance Files (3 files)

#### lib/chatwoot_app.rb

**Lines Modified:** ~15 lines  
**Reason:** Gate enterprise loading when DISABLE_ENTERPRISE=true  
**Last Modified:** January 16, 2026

**Changes Made:**
- `enterprise?` returns false when `DISABLE_ENTERPRISE=true`
- `extensions` no longer includes 'enterprise' when disabled

---

#### config/application.rb

**Lines Modified:** ~20 lines  
**Reason:** Conditionally load enterprise paths only when enterprise is enabled  
**Last Modified:** January 16, 2026

**Changes Made:**
- Enterprise load paths wrapped in conditional
- Enterprise initializers only loaded when enterprise is enabled

---

#### docker/Dockerfile.commmate

**Lines Modified:** ~10 lines added  
**Reason:** Remove enterprise directory from production images  
**Last Modified:** January 16, 2026

**Changes Made:**
- `RUN rm -rf /app/enterprise /app/spec/enterprise` after COPY
- Added `DISABLE_ENTERPRISE=true` to environment variables

---

### Migrations (4 files)

#### db/migrate/20240726220747_add_custom_roles.rb

**Lines Modified:** Entire file (NEW)  
**Reason:** Create custom_roles table and associations (legacy - no longer used)  
**Last Modified:** July 26, 2024  
**Status:** DEPRECATED - custom roles replaced with per-user permissions

---

#### db/migrate/20251202140000_add_campaign_manage_to_manager_roles.rb

**Lines Modified:** Entire file (rewritten to no-op)  
**Reason:** Originally updated custom roles, now a no-op  
**Last Modified:** January 16, 2026  
**Status:** DEPRECATED - converted to no-op for fresh installs

---

#### db/migrate/20260116100000_add_access_permissions_to_account_users.rb

**Lines Modified:** Entire file (NEW)  
**Reason:** Add per-user permissions column for license compliance  
**Last Modified:** January 16, 2026

**Changes Made:**
- Adds `access_permissions` text array column to `account_users`
- Replaces enterprise-dependent Custom Roles feature

---

#### db/migrate/20260116100001_migrate_custom_roles_to_access_permissions.rb

**Lines Modified:** Entire file (NEW)  
**Reason:** Migrate existing custom role data to per-user permissions  
**Last Modified:** January 16, 2026

**Changes Made:**
- Copies permissions from `custom_roles` to `account_users.access_permissions`
- Nulls out `custom_role_id` after migration

---

### Docker (1 file)

#### 14. docker/Dockerfile.commmate

**Lines Modified:** ~20 lines (entire file)  
**Reason:** Custom Docker build for CommMate distribution  
**Last Modified:** Before December 2025

**Changes Made:**
- Custom build steps for CommMate
- Copies CommMate branding assets
- Sets CommMate environment variables
- Configures CommMate-specific paths

**Review on Upgrade:**
- Check if Dockerfile structure changed in main Chatwoot
- Verify all build steps still work
- Review new dependencies or build stages
- Check for security updates in base images

**Merge Conflict Strategy:**
- Base on latest Chatwoot Dockerfile
- Apply CommMate customizations on top
- Test complete build process
- Verify all assets are included

---

### JavaScript Translations (1 file)

#### 15. app/javascript/dashboard/i18n/locale/en/customRole.json

**Lines Modified:** Multiple lines  
**Reason:** Add English translations for custom roles and campaign_manage  
**Last Modified:** Before December 2025

**Changes Made:**
- Added CAMPAIGN_MANAGE translation
- Added custom role related UI strings
- Follows Chatwoot i18n conventions

**Review on Upgrade:**
- Check if i18n structure changed
- Verify translation key format
- Review if new translation features added
- Check for i18n framework updates

**Merge Conflict Strategy:**
- Keep Chatwoot's new translations
- Preserve CommMate translations
- Merge translation objects
- Test UI strings display correctly

---

## 🔄 Upgrade Checklist

When upgrading to a new Chatwoot version, review these files in order:

### Critical (Review First)
1. ✅ config/routes.rb - Routing changes
2. ✅ config/initializers/git_sha.rb - Version tracking
3. ✅ app/controllers/super_admin/instance_statuses_controller.rb - Version display

### Important (Review Second)
4. ✅ app/views/super_admin/application/_navigation.html.erb - Branding
5. ✅ app/views/super_admin/devise/sessions/new.html.erb - Login branding
6. ✅ app/dashboards/account_user_dashboard.rb - Custom role field
7. ✅ app/policies/campaign_policy.rb - Permission logic

### Minor (Review Last)
8. ✅ app/views/super_admin/application/_javascript.html.erb - Widget disable
9. ✅ app/views/super_admin/application/_icons.html.erb - Icon addition
10. ✅ app/javascript/dashboard/routes/dashboard/campaigns/campaigns.routes.js - Route permission
11. ✅ app/javascript/dashboard/constants/permissions.js - Permission constant
12. ✅ app/javascript/dashboard/i18n/locale/en/customRole.json - Translations

### WhatsApp Templates CRUD (Review with WhatsApp updates)
13. ✅ app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue - Templates tab
14. ✅ app/javascript/dashboard/components/Modal.vue - Large size class
15. ✅ app/javascript/dashboard/i18n/locale/en/inboxMgmt.json - WhatsApp Templates translations (EN)
16. ✅ app/javascript/dashboard/i18n/locale/pt_BR/inboxMgmt.json - WhatsApp Templates translations (PT-BR)

### Migrations (Always Run)
13. ✅ db/migrate/20240726220747_add_custom_roles.rb - Run if not yet applied
14. ✅ db/migrate/20251202140000_add_campaign_manage_to_manager_roles.rb - Run if not yet applied

### Docker (Test Build)
15. ✅ docker/Dockerfile.commmate - Test complete build process

---

## 📈 Conflict Resolution Strategy

### General Approach
1. **Always keep Chatwoot's improvements** - They're fixing bugs and adding features
2. **Reapply CommMate changes on top** - Our changes are additive, not replacements
3. **Test thoroughly** - Verify all CommMate features work after merge
4. **Document new conflicts** - Update this file if new modifications are needed

### Common Patterns
- **Branding:** Replace Chatwoot → CommMate in text/logos
- **Versions:** Add CommMate version display alongside Chatwoot version
- **Permissions:** Use OR logic: `administrator? || custom_role_check?`
- **Routes:** Keep CommMate routes in super_admin namespace
- **Constants:** Add CommMate constants to arrays without removing Chatwoot ones

---

## 🧪 Testing After Upgrades

After merging a new Chatwoot version, test:

### Super Admin
- [ ] Login with super admin credentials
- [ ] Verify CommMate logo displays correctly
- [ ] Check version shows CommMate version (not Chatwoot version)
- [ ] Navigate to instance status page
- [ ] Verify both CommMate and Chatwoot versions show

### Custom Roles
- [ ] Access custom roles from super admin navigation
- [ ] Create new custom role
- [ ] Edit existing custom role
- [ ] Assign campaign_manage permission
- [ ] Delete custom role
- [ ] Assign custom role to user

### Campaign Permissions
- [ ] Login as user with custom role (campaign_manage)
- [ ] Verify user can access campaigns
- [ ] Create/edit/delete campaigns
- [ ] Login as user without campaign_manage
- [ ] Verify campaigns are not accessible

### Branding
- [ ] Logo displays on all pages
- [ ] Version numbers are correct
- [ ] Login page shows CommMate branding
- [ ] Support widget is disabled

### Database
- [ ] Run pending migrations
- [ ] Verify custom_roles table exists
- [ ] Check custom_role_id on account_users
- [ ] Test custom role queries

### WhatsApp Templates CRUD
- [ ] Navigate to WhatsApp Cloud inbox settings
- [ ] Verify "Templates" tab appears
- [ ] Click "Sync Templates" to fetch existing templates
- [ ] Click "Create Template" and verify modal opens
- [ ] Create a simple text template
- [ ] Verify template appears in list after sync
- [ ] Delete a template and verify it's removed
- [ ] Test translations in PT-BR locale

### Evolution WhatsApp Inbox Integration
- [ ] Enable Evolution API in Super Admin settings (EVOLUTION_API_ENABLED, EVOLUTION_API_URL, EVOLUTION_API_KEY)
- [ ] Navigate to Settings > Inboxes > Add Inbox
- [ ] Verify "Evolution WhatsApp" channel appears
- [ ] Create Evolution inbox with unique name
- [ ] Scan QR code with WhatsApp mobile app
- [ ] Verify connection status shows "Connected"
- [ ] Verify phone number appears in inbox settings
- [ ] Send test message and verify delivery
- [ ] Receive message from WhatsApp and verify in Chatwoot
- [ ] Navigate to Evolution settings tab
- [ ] Test Refresh Instance button (phone number updates)
- [ ] Test Disconnect button (phone number clears)
- [ ] Reconnect with different WhatsApp (phone number updates)
- [ ] Delete Evolution inbox (verify instance deleted in Evolution API)
- [ ] Verify WhatsApp icon displays in inbox list
- [ ] Verify "Evolution WhatsApp" name in channel list
- [ ] Verify phone number displays in send message flow
- [ ] Test translations in PT-BR locale

### Contact Preferences Feature
- [ ] Navigate to Settings > Labels
- [ ] Create a new label with "Available for campaigns" checked
- [ ] Edit an existing label and toggle "Available for campaigns"
- [ ] Verify label appears in API response with `available_for_campaigns` field
- [ ] Create a contact with email or phone number
- [ ] Navigate to contact details page
- [ ] Verify "Manage Preferences" button appears next to "Update Contact"
- [ ] Click "Manage Preferences" and verify preference page opens in new tab
- [ ] Use `{{contact.preference_link}}` in a WhatsApp template or message
- [ ] Verify the link generates correctly with JWT token
- [ ] Open preference link in browser
- [ ] Verify full preferences page displays with campaign labels
- [ ] Select/deselect labels and save preferences
- [ ] Verify contact labels updated in Chatwoot
- [ ] Test subscribe link with `?add=<label_id>` parameter
- [ ] Test unsubscribe link with `?remove=<label_id>` parameter
- [ ] Test unsubscribe all with `?unsubscribe_all=true` parameter
- [ ] Verify "Unsubscribe from All" button works on full preferences page
- [ ] Wait 31 days (or manipulate token) and verify expired link shows error
- [ ] Test with deleted contact - verify appropriate error
- [ ] Test with deleted label - verify label skipped gracefully
- [ ] Test translations in PT-BR locale
- [ ] Verify mobile-friendly layout on phone screens
- [ ] Verify dark mode support

---

## 📝 Maintenance Notes

### When Adding New Modifications
1. Update this file immediately
2. Add clear comments in code: `# CommMate: reason for change`
3. Document why the change is needed
4. Note which Chatwoot version it was based on
5. Add to testing checklist

### When Removing Modifications
1. Update this file to remove entry
2. Document in CHANGELOG
3. Test that removal doesn't break anything
4. Update testing checklist

### Version Tracking
- Track which Chatwoot version each modification was made against
- Note when modifications are updated during upgrades
- Document any modifications that were removed/replaced

---

## 🔗 Related Documentation

- `custom/docs/ARCHITECTURE.md` - Architecture guidelines
- `custom/docs/DOWNSTREAM-RELEASE.md` - Upgrade process
- `custom/docs/UPGRADE-PROCEDURE.md` - Detailed upgrade steps
- `custom/docs/MAINTENANCE-CHECKLIST.md` - Maintenance procedures
- `custom/docs/USER-ROLES.md` - Custom roles documentation
- `custom/docs/CONTACT-PREFERENCES.md` - Contact preferences feature (security, API, testing)

---

## 📊 Statistics

- **Total Files Modified:** 59
- **Controllers:** 3 (1 core + 1 Evolution + 1 Preferences)
- **Services:** 4 (Evolution API client, provisioner, send service, preference token)
- **Models/Concerns:** 2 (Evolution inbox concern, Label model)
- **Jobs:** 1 modified (send_reply_job)
- **Views:** 11 (4 core + 1 inbox_slim + 1 preferences layout + 5 preferences pages)
- **Dashboards:** 1
- **Policies:** 1
- **Frontend Components:** 19 (7 Evolution Vue + 7 helper/card + 2 Label forms + 3 Campaign forms)
- **JavaScript/Store:** 9 (4 WhatsApp Templates + 1 chatwootVariables + 1 labels store)
- **Config:** 2
- **Migrations:** 3 (2 roles + 1 labels)
- **Docker:** 1
- **i18n Locale Files:** 4 (EN and PT-BR for inboxMgmt.json + labelsMgmt.json)
- **Custom Locale Files:** 2 (EN and PT-BR custom.yml)
- **New Backend Services:** 2 (WhatsApp Templates CRUD)
- **New Frontend Components:** 5 (WhatsApp Templates UI)
- **Spec Files:** 4 (2 new + 2 modified for preference tests)

**Maintenance Burden:** Low-Medium (~59 files, ~1850 lines)  
**Upgrade Complexity:** Low (most conflicts are trivial)  
**Expected Upgrade Time:** 60-90 minutes

---

**Document Version:** 1.1  
**Last Updated:** January 24, 2026  
**Next Review:** After next Chatwoot upgrade  
**Maintainer:** CommMate Team

---

**This document is the definitive list of all CommMate modifications to Chatwoot core.**  
**Update immediately when adding or removing modifications.**

