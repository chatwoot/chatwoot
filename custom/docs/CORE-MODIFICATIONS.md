# CommMate Core Modifications

**Purpose:** Complete list of all Chatwoot files modified by CommMate  
**Goal:** Quick reference for merge conflict resolution during upgrades  
**Last Updated:** January 11, 2026

---

## 📊 Summary

**Total Modified Files:** 20 files  
**Total Lines Changed:** ~600 lines across all files (including i18n translations)

CommMate maintains minimal modifications to Chatwoot core, focusing on:
- Branding (logo, version display)
- Custom roles functionality
- Campaign permission management
- Version tracking
- WhatsApp Templates CRUD (feat/whatsapp-templates-crud)

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

### Migrations (2 files)

#### 12. db/migrate/20240726220747_add_custom_roles.rb

**Lines Modified:** Entire file (NEW)  
**Reason:** Create custom_roles table and associations  
**Last Modified:** July 26, 2024

**Changes Made:**
- Creates custom_roles table
- Adds custom_role_id to account_users table
- Creates necessary indexes
- Migration is CommMate-specific

**Review on Upgrade:**
- No conflicts expected (CommMate migration)
- Verify migration runs on new Chatwoot versions
- Check for schema compatibility
- Ensure indexes are optimal

**Merge Conflict Strategy:**
- No merge conflicts (new file)
- Run migration after upgrade
- Test custom roles functionality
- Verify database constraints

---

#### 13. db/migrate/20251202140000_add_campaign_manage_to_manager_roles.rb

**Lines Modified:** Entire file (NEW)  
**Reason:** Add campaign_manage permission to existing manager custom roles  
**Last Modified:** December 2, 2024

**Changes Made:**
- Updates existing custom roles with campaign_manage permission
- Data migration for permission upgrade
- Ensures managers have campaign access

**Review on Upgrade:**
- No conflicts expected (CommMate migration)
- May need to run on existing data
- Check if runs idempotently
- Verify permission format

**Merge Conflict Strategy:**
- No merge conflicts (new file)
- Run after custom roles migration
- Test with existing custom roles
- Verify permission is added correctly

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

---

## 📊 Statistics

- **Total Files Modified:** 20
- **Controllers:** 1
- **Views:** 4
- **Dashboards:** 1
- **Policies:** 1
- **JavaScript:** 7 (including 4 for WhatsApp Templates)
- **Config:** 2
- **Migrations:** 2
- **Docker:** 1
- **i18n Locale Files:** 2 (EN and PT-BR inboxMgmt.json)
- **New Backend Services:** 2 (WhatsApp Templates CRUD)
- **New Frontend Components:** 5 (WhatsApp Templates UI)

**Maintenance Burden:** Low (19 files, ~100 lines modified)  
**Upgrade Complexity:** Low (most conflicts are trivial)  
**Expected Upgrade Time:** 45-75 minutes

---

**Document Version:** 1.0  
**Last Updated:** January 11, 2026  
**Next Review:** After next Chatwoot upgrade  
**Maintainer:** CommMate Team

---

**This document is the definitive list of all CommMate modifications to Chatwoot core.**  
**Update immediately when adding or removing modifications.**

