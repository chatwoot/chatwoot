# Email OAuth Provider Configuration Fix

## Problem
Microsoft and Google email provider options were not being enabled even when their OAuth credentials (Azure App ID and Google OAuth Client ID) were configured in the environment variables.

## Root Cause
The Google OAuth Client ID was not being passed from the backend to the frontend's `globalConfig`, causing the Email.vue component to check `window.chatwootConfig` (which may not exist) instead of the proper `globalConfig` store.

## Solution

### 1. Backend Changes

**File**: `app/controllers/dashboard_controller.rb`

Added `GOOGLE_OAUTH_CLIENT_ID` to the `app_config` method so it's available in the frontend:

```ruby
def app_config
  {
    APP_VERSION: Chatwoot.config[:version],
    VAPID_PUBLIC_KEY: VapidService.public_key,
    ENABLE_ACCOUNT_SIGNUP: GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'true'),
    FB_APP_ID: GlobalConfigService.load('FB_APP_ID', ''),
    INSTAGRAM_APP_ID: GlobalConfigService.load('INSTAGRAM_APP_ID', ''),
    FACEBOOK_API_VERSION: GlobalConfigService.load('FACEBOOK_API_VERSION', 'v23.0'),
    WHATSAPP_APP_ID: GlobalConfigService.load('WHATSAPP_APP_ID', ''),
    WHATSAPP_CONFIGURATION_ID: GlobalConfigService.load('WHATSAPP_CONFIGURATION_ID', ''),
    IS_ENTERPRISE: ChatwootApp.enterprise?,
    AZURE_APP_ID: GlobalConfigService.load('AZURE_APP_ID', ''),
    GOOGLE_OAUTH_CLIENT_ID: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', ''), # Added
    GIT_SHA: GIT_HASH
  }
end
```

### 2. Frontend Store Changes

**File**: `app/javascript/shared/store/globalConfig.js`

Added `googleOAuthClientId` to the global config store:

```javascript
const {
  API_CHANNEL_NAME: apiChannelName,
  API_CHANNEL_THUMBNAIL: apiChannelThumbnail,
  APP_VERSION: appVersion,
  AZURE_APP_ID: azureAppId,
  BRAND_NAME: brandName,
  CHATWOOT_INBOX_TOKEN: chatwootInboxToken,
  CREATE_NEW_ACCOUNT_FROM_DASHBOARD: createNewAccountFromDashboard,
  DIRECT_UPLOADS_ENABLED: directUploadsEnabled,
  DISPLAY_MANIFEST: displayManifest,
  GIT_SHA: gitSha,
  GOOGLE_OAUTH_CLIENT_ID: googleOAuthClientId, // Added
  HCAPTCHA_SITE_KEY: hCaptchaSiteKey,
  // ... rest of config
} = window.globalConfig || {};

const state = {
  apiChannelName,
  apiChannelThumbnail,
  appVersion,
  azureAppId,
  brandName,
  chatwootInboxToken,
  deploymentEnv,
  createNewAccountFromDashboard,
  directUploadsEnabled: parseBoolean(directUploadsEnabled),
  disableUserProfileUpdate: parseBoolean(disableUserProfileUpdate),
  displayManifest,
  gitSha,
  googleOAuthClientId, // Added
  hCaptchaSiteKey,
  // ... rest of state
};
```

### 3. Email Component Changes

**File**: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Email.vue`

Updated the Google provider configuration to use `globalConfig` instead of `window.chatwootConfig`:

```javascript
// BEFORE
{
  title: t('INBOX_MGMT.EMAIL_PROVIDERS.GOOGLE.TITLE'),
  description: t('INBOX_MGMT.EMAIL_PROVIDERS.GOOGLE.DESCRIPTION'),
  isEnabled: !!window.chatwootConfig?.googleOAuthClientId, // Unreliable
  key: 'google',
  icon: 'i-woot-gmail',
}

// AFTER
{
  title: t('INBOX_MGMT.EMAIL_PROVIDERS.GOOGLE.TITLE'),
  description: t('INBOX_MGMT.EMAIL_PROVIDERS.GOOGLE.DESCRIPTION'),
  isEnabled: !!globalConfig.value.googleOAuthClientId, // Consistent
  key: 'google',
  icon: 'i-woot-gmail',
}
```

## How It Works Now

### Microsoft Provider
- **Enabled when**: `AZURE_APP_ID` environment variable is set
- **Check**: `globalConfig.value.azureAppId`
- **OAuth Flow**: Uses Microsoft Graph API

### Google Provider
- **Enabled when**: `GOOGLE_OAUTH_CLIENT_ID` environment variable is set
- **Check**: `globalConfig.value.googleOAuthClientId`
- **OAuth Flow**: Uses Google OAuth2 API

### Other Providers
- **Enabled**: Always (default IMAP/SMTP option)
- **Configuration**: Manual email setup with forwarding

## Configuration Steps

### To Enable Microsoft Email Provider:

1. Set environment variable:
   ```bash
   AZURE_APP_ID=your-azure-app-id
   AZURE_APP_SECRET=your-azure-app-secret
   ```

2. Restart the application

3. Navigate to Settings → Inboxes → Add Inbox → Email

4. Microsoft option will be enabled and clickable

### To Enable Google Email Provider:

1. Set environment variables:
   ```bash
   GOOGLE_OAUTH_CLIENT_ID=your-google-client-id
   GOOGLE_OAUTH_CLIENT_SECRET=your-google-client-secret
   ```

2. Restart the application

3. Navigate to Settings → Inboxes → Add Inbox → Email

4. Google option will be enabled and clickable

## Benefits

1. **Consistent Configuration**: All OAuth providers now use the same `globalConfig` pattern
2. **Proper Error Handling**: No more undefined errors from accessing `window.chatwootConfig`
3. **Centralized Management**: All configuration values flow through the same backend → frontend pipeline
4. **Better Maintainability**: Single source of truth for configuration values

## Testing

1. **Without OAuth Credentials**:
   - Only "Other Providers" option should be enabled
   - Microsoft and Google should be visible but disabled

2. **With Azure App ID**:
   - Microsoft option should be enabled and clickable
   - Clicking should start OAuth flow

3. **With Google OAuth Client ID**:
   - Google option should be enabled and clickable
   - Clicking should start OAuth flow

4. **With Both Credentials**:
   - All three options should be enabled
   - Each should work independently

## Files Modified

1. `app/controllers/dashboard_controller.rb` - Added GOOGLE_OAUTH_CLIENT_ID to app_config
2. `app/javascript/shared/store/globalConfig.js` - Added googleOAuthClientId to store
3. `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Email.vue` - Updated to use globalConfig
