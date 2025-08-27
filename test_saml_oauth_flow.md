# Testing SAML Authentication Flow

## 1. Start the SAML Authentication Flow

Visit this URL in your browser to initiate SAML authentication:

```
http://localhost:3000/auth/saml?account_id=1
```

This should:
1. Trigger the OmniAuth SAML provider
2. Run the setup phase to load account-specific SAML settings
3. Redirect you to MockSAML.com with the correct parameters

## 2. Complete Authentication at MockSAML

At MockSAML.com:
1. Enter any email address (use an existing Chatwoot user's email)
2. Complete the authentication
3. MockSAML will POST back to: `http://localhost:3000/omniauth/saml/callback`

## 3. Expected Flow

After successful SAML authentication:
1. The `devise_overrides/omniauth_callbacks#omniauth_success` method will be called
2. It will find the user by email
3. Generate an SSO auth token
4. Redirect to the frontend login page with the token: `http://localhost:3000/app/login?email=user@example.com&sso_auth_token=xxx`

## 4. Check Server Logs

Monitor the Rails server logs for:
- "Processing by DeviseOverrides::OmniauthCallbacksController#omniauth_success"
- Any SAML-related errors or warnings

## 5. Debugging

If you encounter issues:

1. **Check if SAML settings are loaded:**
   ```ruby
   rails console
   AccountSamlSettings.find_by(account_id: 1, enabled: true)
   ```

2. **Test the setup phase manually:**
   ```ruby
   # In rails console
   settings = AccountSamlSettings.find_by(account_id: 1)
   puts "SSO URL: #{settings.sso_url}"
   puts "SP Entity ID: #{settings.sp_entity_id_or_default}"
   puts "Certificate present: #{settings.certificate.present?}"
   ```

3. **Enable OmniAuth debug logging:**
   Add this to an initializer:
   ```ruby
   OmniAuth.config.logger = Rails.logger
   OmniAuth.config.logger.level = Logger::DEBUG
   ```

## 6. Alternative Testing with cURL

You can also test the initial redirect:

```bash
curl -v "http://localhost:3000/auth/saml?account_id=1"
```

This should return a 302 redirect to MockSAML.com.