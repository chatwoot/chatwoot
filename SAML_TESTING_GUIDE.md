# SAML Testing Guide with MockSAML.com

## Prerequisites
- Chatwoot running locally on `http://localhost:3000`
- MockSAML.com account (free tier works)
- A user account in Chatwoot that you'll use for testing

## Step 1: Set Up MockSAML

1. Go to https://mocksaml.com and sign in
2. Click "Create New Configuration"
3. Fill in the configuration:
   - **Configuration Name**: Chatwoot Test
   - **Service Provider Entity ID**: `http://localhost:3000/saml/1` (or use your custom entity ID from SAML settings)
   - **Assertion Consumer Service URL**: `http://localhost:3000/auth/saml/1/callback`
   - **Authentication Method**: Email/Password
   - **Default RelayState**: `/app/dashboard` (optional)

4. In the "Attributes" section, add:
   - **Email Address**: 
     - Name: `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress`
     - Value: Use the email of an existing user in your Chatwoot database
   - **Name**:
     - Name: `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name`
     - Value: The user's full name

5. Save the configuration and note down:
   - The SSO URL (will be like `https://mocksaml.com/api/saml/sso/{config-id}`)
   - Download the certificate from the "Metadata" section

## Step 2: Update Chatwoot SAML Settings

### Using Rails Console:
```ruby
rails console

# Find your account
account = Account.find(1)

# Get or create SAML settings
saml_settings = account.account_saml_settings || account.create_account_saml_settings

# Update with MockSAML values
saml_settings.update!(
  enabled: true,
  sso_url: 'https://mocksaml.com/api/saml/sso/YOUR_CONFIG_ID', # Replace with your MockSAML SSO URL
  certificate: %{-----BEGIN CERTIFICATE-----
PASTE_THE_CERTIFICATE_FROM_MOCKSAML_HERE
-----END CERTIFICATE-----},
  sp_entity_id: 'http://localhost:3000/saml/1', # Must match what you set in MockSAML
  enforced_sso: false
)

# Verify settings
puts saml_settings.certificate_fingerprint
```

### Using API:
```bash
# Update SAML settings via API
curl -X PUT http://localhost:3000/api/v1/accounts/1/saml_settings \
  -H "Content-Type: application/json" \
  -H "api_access_token: YOUR_API_TOKEN" \
  -d '{
    "enabled": true,
    "sso_url": "https://mocksaml.com/api/saml/sso/YOUR_CONFIG_ID",
    "certificate": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----",
    "sp_entity_id": "http://localhost:3000/saml/1"
  }'
```

## Step 3: Test the SAML Flow

### Method 1: Direct Browser Test
1. Open your browser
2. Navigate to: `http://localhost:3000/auth/saml/1`
3. You should be redirected to MockSAML login page
4. Enter the test credentials you configured in MockSAML
5. After successful authentication, you should be redirected to:
   - `http://localhost:3000/app/login?email=USER_EMAIL&sso_auth_token=TOKEN`
6. The frontend should automatically complete the login using the SSO token

### Method 2: API Test
```bash
# 1. Get SAML configuration
curl http://localhost:3000/api/v1/accounts/1/saml/sso

# 2. Initiate SAML flow (in browser)
# Visit: http://localhost:3000/auth/saml/1
```

## Step 4: Verify the Login

1. Check browser developer tools:
   - Network tab should show the SAML flow
   - After redirect, check for `/auth/sign_in` API call with SSO token

2. Check Rails logs:
   ```bash
   tail -f log/development.log | grep -E "OmniauthController|SAML|SSO"
   ```

3. Verify in Rails console:
   ```ruby
   # Check if SSO token was created
   Redis::Alfred.keys("chatwoot:user:*:sso_auth_token:*")
   
   # Check user's last sign in
   User.find_by(email: 'your-test-email@example.com').current_sign_in_at
   ```

## Troubleshooting

### Common Issues:

1. **"SAML not enabled for this account"**
   - Ensure `enabled: true` in SAML settings
   - Verify account ID matches

2. **Redirect to /auth/sign_in without SSO token**
   - Check if SAML response validation failed
   - Verify certificate and fingerprint match
   - Check Rails logs for OmniAuth errors

3. **"User not found" error**
   - Ensure the email in MockSAML matches an existing Chatwoot user
   - Check if `User.find_by(email: 'test@example.com')` returns a user

4. **Certificate validation errors**
   - Make sure you copied the entire certificate including BEGIN/END lines
   - Certificate should not have any extra whitespace

### Debug Commands:

```bash
# Check current SAML settings
rails runner "pp AccountSamlSettings.find_by(account_id: 1)"

# Test metadata endpoint
curl http://localhost:3000/auth/saml/1/metadata

# Check OmniAuth configuration
rails runner "pp Rails.application.config.omniauth"
```

## Next Steps

Once basic login works:
1. Test with multiple users
2. Test logout flow (if implementing SLO)
3. Test with enforced SSO enabled
4. Implement user provisioning for new users
5. Add role mapping from SAML attributes