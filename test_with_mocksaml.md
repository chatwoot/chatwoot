# Testing SAML with MockSAML.com

## 1. Verify Your SAML Settings

First, check your current SAML configuration:

```bash
rails console
```

```ruby
settings = AccountSamlSettings.find_by(account_id: 1)
puts "SSO URL: #{settings.sso_url}"
puts "SP Entity ID: #{settings.sp_entity_id_or_default}"
puts "ACS URL: #{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/omniauth/saml/callback?account_id=1"
```

## 2. Update MockSAML Configuration

Go to MockSAML.com and ensure these settings match:
- **SP Entity ID**: Should match `settings.sp_entity_id_or_default`
- **ACS URL**: `http://localhost:3000/omniauth/saml/callback?account_id=1`
- **Name ID Format**: Email Address

## 3. Start the Authentication Flow

### Option A: Browser Test
1. Open your browser
2. Navigate to: `http://localhost:3000/auth/saml?account_id=1`
3. You should be redirected to MockSAML.com
4. Enter any email (use an existing Chatwoot user's email like `john@acme.inc`)
5. Complete authentication at MockSAML
6. You should be redirected back to Chatwoot login page with SSO token

### Option B: Direct Link Test
1. Get the SAML initiation URL:
   ```
   http://localhost:3000/auth/saml?account_id=1
   ```

2. Click or paste this in your browser

## 4. What to Expect

### Success Flow:
1. Browser redirects to MockSAML.com
2. You authenticate at MockSAML
3. MockSAML POST backs to `/omniauth/saml/callback?account_id=1`
4. Chatwoot processes the SAML response
5. You're redirected to: `http://localhost:3000/app/login?email=USER_EMAIL&sso_auth_token=TOKEN`

### If Using ngrok or Public URL:
If you're testing with a public URL (ngrok), update the FRONTEND_URL:
```bash
export FRONTEND_URL=https://your-ngrok-url.ngrok.io
```

## 5. Debugging Tips

### Watch Server Logs:
Look for these log messages:
- `[SAML Setup] Request path:`
- `[SAML Setup] Account ID:`
- `[SAML Setup] Found settings for account`
- `[OmniAuth Callback] Provider: saml`

### Common Issues:

1. **"No fingerprint or certificate on settings"**
   - The account_id isn't being passed properly
   - Check logs for `[SAML Setup] Account ID:`

2. **Redirect to /auth/sign_in instead of /app/login**
   - The SAML response wasn't processed correctly
   - Check if the user exists with that email

3. **404 on callback**
   - The route isn't configured properly
   - Run `rails routes | grep saml` to verify

### Manual SAML Response Test:
If you want to test just the callback with a SAML response from MockSAML:

1. Use browser developer tools to intercept the POST to `/omniauth/saml/callback`
2. Copy the SAMLResponse parameter
3. Use the test script to send it:

```ruby
# save_as: test_saml_callback.rb
require 'net/http'
require 'uri'

saml_response = "PASTE_YOUR_SAML_RESPONSE_HERE"
callback_url = "http://localhost:3000/omniauth/saml/callback?account_id=1"

uri = URI(callback_url)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/x-www-form-urlencoded'
request.body = URI.encode_www_form({
  'SAMLResponse' => saml_response,
  'RelayState' => ''
})

response = http.request(request)
puts "Status: #{response.code}"
puts "Location: #{response['location']}" if response['location']
```

## 6. Test Different Scenarios

### Existing User Login:
- Use email of existing user (e.g., `john@acme.inc`)
- Should redirect with SSO token

### New User (if enabled):
- Use new email address
- Should redirect to password setup page (if account signup is enabled)

### SAML Disabled:
- Disable SAML in settings and try again
- Should show error message