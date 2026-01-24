# Contact Preferences Feature

**Purpose:** Allow contacts to manage their campaign subscription preferences via secure public links  
**Version:** 1.0  
**Last Updated:** January 24, 2026

---

## Overview

The Contact Preferences feature enables contacts to manage their subscription preferences for campaign labels through secure, tokenized URLs. This allows for:

- Public preference management pages (no login required)
- Single-action subscribe/unsubscribe links
- "Unsubscribe from All" functionality
- GDPR-compliant preference management

---

## Security Architecture

### Token Design

The feature uses JWT (JSON Web Tokens) for secure, stateless authentication.

| Property | Value | Purpose |
|----------|-------|---------|
| Algorithm | HS256 (HMAC-SHA256) | Industry-standard symmetric signing |
| Secret | `Rails.application.secret_key_base` | 512-bit server secret |
| Expiry | 30 days | Limits exposure window |
| Scope | Contact-specific | Bound to single contact |

### Token Payload

```json
{
  "contact_id": 123,
  "account_id": 456,
  "exp": 1771887039,
  "iat": 1769295039
}
```

### Security Controls

1. **Cryptographic Signing**
   - Token signature prevents tampering
   - Any modification invalidates the token
   - Impossible to forge without server secret

2. **Contact Isolation**
   - Each token is bound to a specific `contact_id`
   - Controller validates contact belongs to account
   - Cross-contact access is prevented

3. **Account Scoping**
   - Token includes `account_id`
   - Contact lookup scoped: `@account.contacts.find_by(id:)`
   - Cross-account access is prevented

4. **Time-Based Expiry**
   - Tokens expire after 30 days (`EXPIRY_DAYS` constant)
   - Expired tokens show "Link Expired" error
   - Reduces risk from leaked/shared links

5. **Error Handling**
   - Tampered tokens → "Invalid Link"
   - Expired tokens → "Link Expired"
   - Deleted contacts → "Contact Not Found"
   - Suspended accounts → "Account No Longer Available"

### Security Comparison

This implementation follows the same security model used by:
- Mailchimp unsubscribe links
- GitHub notification preferences
- Newsletter management services

---

## API Endpoints

### GET /preferences/:token

Shows the full preferences page or handles single actions.

| Parameter | Type | Description |
|-----------|------|-------------|
| `token` | JWT | Required. Preference token |
| `add` | String | Optional. Label ID or title to subscribe to |
| `remove` | String | Optional. Label ID or title to unsubscribe from |
| `unsubscribe_all` | Boolean | Optional. Unsubscribe from all campaign labels |
| `locale` | String | Optional. Force locale (e.g., `pt_BR`) |

### POST /preferences/:token

Updates preferences from form submission.

| Parameter | Type | Description |
|-----------|------|-------------|
| `token` | JWT | Required. Preference token |
| `labels[]` | Array | Selected label names |
| `unsubscribe_all` | Boolean | If true, removes all campaign labels |

---

## Liquid Variables

The feature adds two Liquid variables for use in templates and campaigns:

### `{{ contact.preference_link }}`

Generates a URL to the full preferences page.

```
https://app.example.com/preferences/eyJhbGciOiJIUzI1NiJ9...
```

### `{{ contact.unsubscribe_all_link }}`

Generates a URL that directly unsubscribes from all labels.

```
https://app.example.com/preferences/eyJhbGciOiJIUzI1NiJ9...?unsubscribe_all=true
```

### Single Action URLs

Append parameters to `preference_link` for single actions:

```
{{ contact.preference_link }}?add=3          # Subscribe to label ID 3
{{ contact.preference_link }}?add=promotions # Subscribe to label by title
{{ contact.preference_link }}?remove=3       # Unsubscribe from label ID 3
```

---

## Database Changes

### Labels Table

```ruby
# Migration: 20260124163545_add_available_for_campaigns_to_labels.rb
add_column :labels, :available_for_campaigns, :boolean, default: false
```

### Label Model

```ruby
# app/models/label.rb
scope :campaign_labels, -> { where(available_for_campaigns: true) }
```

---

## Files Created/Modified

### New Files

| File | Purpose |
|------|---------|
| `app/services/contact_preference_token_service.rb` | JWT token generation/decoding |
| `app/controllers/public/api/v1/preferences_controller.rb` | Public preferences controller |
| `app/views/layouts/preferences.html.erb` | Mobile-friendly layout |
| `app/views/public/api/v1/preferences/show.html.erb` | Full preferences page |
| `app/views/public/api/v1/preferences/subscribe.html.erb` | Subscribe confirmation |
| `app/views/public/api/v1/preferences/unsubscribe.html.erb` | Unsubscribe confirmation |
| `app/views/public/api/v1/preferences/unsubscribe_all.html.erb` | Unsubscribe all confirmation |
| `app/views/public/api/v1/preferences/error.html.erb` | Error pages |
| `spec/services/contact_preference_token_service_spec.rb` | Token service tests |
| `spec/controllers/public/api/v1/preferences_controller_spec.rb` | Controller tests |

### Modified Files

| File | Changes |
|------|---------|
| `app/views/api/v1/models/_contact.json.jbuilder` | Expose `preference_link` in contact API response |
| `app/models/label.rb` | Added `campaign_labels` scope |
| `app/controllers/api/v1/accounts/labels_controller.rb` | Added `available_for_campaigns` to permitted params |
| `app/views/api/v1/accounts/labels/*.json.jbuilder` | Expose `available_for_campaigns` |
| `app/drops/contact_drop.rb` | Added `preference_link` and `unsubscribe_all_link` |
| `config/routes.rb` | Added `/preferences/:token` routes |
| `app/javascript/dashboard/routes/dashboard/settings/labels/AddLabel.vue` | Campaign checkbox |
| `app/javascript/dashboard/routes/dashboard/settings/labels/EditLabel.vue` | Campaign checkbox |
| `app/javascript/dashboard/store/modules/labels.js` | `getCampaignLabels` getter |
| `app/javascript/dashboard/components-next/Contacts/Pages/ContactDetails.vue` | "Manage Preferences" button |
| `app/javascript/dashboard/i18n/locale/en/contact.json` | Translation for MANAGE_PREFERENCES |
| `app/javascript/dashboard/i18n/locale/pt_BR/contact.json` | Translation for MANAGE_PREFERENCES |
| `custom/locales/en_custom.yml` | English translations |
| `custom/locales/pt_BR_custom.yml` | Portuguese translations |

---

## UI Pages

### Contact Details Page (Agent View)

- "Manage Preferences" button next to "Update Contact" button
- Opens the contact's preference page in a new tab
- Only visible if contact has a preference link (always available for contacts in accounts)

### Main Preferences Page

- Lists all campaign-enabled labels with checkboxes
- Shows label description with title in tooltip
- Displays contact identifier (email/phone)
- "Save Preferences" button
- "Unsubscribe from All" button

### Subscribe/Unsubscribe Confirmation

- Success message with label name
- Links to manage preferences or subscribe again

### Unsubscribe All Confirmation

- "We're sad to see you go" message
- Link to manage preferences again

### Error Pages

| Error Type | Title | Description |
|------------|-------|-------------|
| `expired` | Link Expired | Token older than 30 days |
| `invalid` | Invalid Link | Malformed/tampered token |
| `contact_not_found` | Contact Not Found | Contact deleted |
| `account_unavailable` | Account No Longer Available | Account suspended |
| `label_not_found` | Subscription Not Found | Label deleted or not campaign-enabled |

---

## Locale Detection

The preference pages detect locale in this priority:
1. Query parameter (`?locale=pt_BR`)
2. Account locale setting
3. Browser `Accept-Language` header
4. Default (English)

---

## Dark Mode Support

All preference pages support dark mode via:
- CSS media query: `prefers-color-scheme: dark`
- LocalStorage: `localStorage.theme`

---

## Testing

### Unit Tests

```bash
# Run all preference-related tests
bundle exec rspec \
  spec/services/contact_preference_token_service_spec.rb \
  spec/controllers/public/api/v1/preferences_controller_spec.rb \
  spec/drops/contact_drop_spec.rb \
  spec/models/label_spec.rb
```

### Manual Testing URLs

```bash
# Generate test token
bundle exec rails runner "
contact = Contact.first
token = ContactPreferenceTokenService.generate_for_contact(contact)
puts \"http://localhost:3000/preferences/#{token}\"
"
```

---

## Configuration

No additional environment variables required. The feature uses:
- `Rails.application.secret_key_base` for token signing
- Existing Chatwoot domain configuration for URL generation

---

## Potential Future Enhancements

| Enhancement | Benefit | Complexity |
|-------------|---------|------------|
| Token revocation | Invalidate specific tokens | Medium (requires DB) |
| Single-use tokens | One-time preference changes | Medium |
| Rate limiting | Prevent abuse | Low |
| Shorter expiry option | Per-account expiry settings | Low |
| Audit logging | Track preference changes | Low |

---

## Changelog

### v1.0 (January 24, 2026)
- Initial implementation
- JWT-based secure tokens
- Full preferences page with checkboxes
- Single-action subscribe/unsubscribe URLs
- Unsubscribe from all functionality
- Mobile-friendly, dark mode support
- English and Portuguese translations
- Comprehensive unit tests

---

**Maintainer:** CommMate Team  
**Related Docs:** `CORE-MODIFICATIONS.md`

