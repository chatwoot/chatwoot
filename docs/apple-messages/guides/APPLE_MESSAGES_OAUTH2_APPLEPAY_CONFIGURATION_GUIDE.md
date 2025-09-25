# Apple Messages for Business - OAuth2 and Apple Pay Configuration Guide

## Overview

This guide provides step-by-step instructions for configuring OAuth2 authentication and Apple Pay payment processing in your Apple Messages for Business channel within Chatwoot.

## OAuth2 Authentication Configuration

### Supported Providers

The Apple Messages for Business integration supports the following OAuth2 providers:

- **Google OAuth2**
- **LinkedIn OAuth2**
- **Facebook OAuth2**

### Configuration Steps

#### 1. Google OAuth2 Setup

1. **Create Google OAuth2 Application**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing project
   - Enable Google+ API and Google OAuth2 API
   - Go to "Credentials" → "Create Credentials" → "OAuth2 Client ID"
   - Choose "Web Application" as application type

2. **Configure Redirect URIs**:
   ```
   https://yourdomain.com/apple_messages_for_business/oauth/callback/google
   ```

3. **Chatwoot Configuration**:
   - Enable "Google Authentication" in channel settings
   - Enter your Google OAuth2 Client ID
   - Enter your Google OAuth2 Client Secret

#### 2. LinkedIn OAuth2 Setup

1. **Create LinkedIn Application**:
   - Go to [LinkedIn Developer Portal](https://developer.linkedin.com/)
   - Create a new application
   - Add "Sign In with LinkedIn" product

2. **Configure Redirect URIs**:
   ```
   https://yourdomain.com/apple_messages_for_business/oauth/callback/linkedin
   ```

3. **Chatwoot Configuration**:
   - Enable "LinkedIn Authentication" in channel settings
   - Enter your LinkedIn Client ID
   - Enter your LinkedIn Client Secret

#### 3. Facebook OAuth2 Setup

1. **Create Facebook Application**:
   - Go to [Facebook Developer Portal](https://developers.facebook.com/)
   - Create a new application
   - Add "Facebook Login" product

2. **Configure Redirect URIs**:
   ```
   https://yourdomain.com/apple_messages_for_business/oauth/callback/facebook
   ```

3. **Chatwoot Configuration**:
   - Enable "Facebook Authentication" in channel settings
   - Enter your Facebook App ID
   - Enter your Facebook App Secret

## Apple Pay Configuration

### Prerequisites

Before configuring Apple Pay, ensure you have:

1. **Apple Developer Account** with merchant capabilities
2. **Apple Pay Merchant Certificate** from Apple
3. **Payment Gateway Account** (Stripe, Square, or Braintree)

### Apple Pay Settings

#### Basic Configuration

1. **Enable Apple Pay**: Check the "Enable Apple Pay" checkbox
2. **Merchant Identifier**: Your Apple Pay merchant identifier (e.g., `merchant.com.yourcompany.app`)
3. **Merchant Domain**: Your verified merchant domain (e.g., `yourcompany.com`)
4. **Country Code**: Select your business country
5. **Currency Code**: Select your primary currency
6. **Supported Networks**: Choose supported payment networks (Visa, Mastercard, American Express, Discover)

#### Payment Gateway Configuration

Configure at least one payment processor:

##### Stripe Configuration

1. **Enable Stripe**: Check the "Enable Stripe" checkbox
2. **Publishable Key**: Your Stripe publishable key (`pk_...`)
3. **Secret Key**: Your Stripe secret key (`sk_...`)

**Getting Stripe Keys**:
- Log in to [Stripe Dashboard](https://dashboard.stripe.com/)
- Go to "Developers" → "API Keys"
- Copy your publishable and secret keys

##### Square Configuration

1. **Enable Square**: Check the "Enable Square" checkbox
2. **Application ID**: Your Square application ID
3. **Access Token**: Your Square access token

**Getting Square Credentials**:
- Log in to [Square Developer Dashboard](https://developer.squareup.com/)
- Go to your application
- Copy Application ID and Access Token

##### Braintree Configuration

1. **Enable Braintree**: Check the "Enable Braintree" checkbox
2. **Merchant ID**: Your Braintree merchant ID
3. **Public Key**: Your Braintree public key
4. **Private Key**: Your Braintree private key

**Getting Braintree Credentials**:
- Log in to [Braintree Control Panel](https://sandbox.braintreegateway.com/) (or production)
- Go to "Settings" → "API"
- Copy your merchant ID, public key, and private key

## Security Best Practices

### OAuth2 Security

1. **Use HTTPS**: All redirect URIs must use HTTPS in production
2. **Validate State Parameter**: Always validate the state parameter to prevent CSRF attacks
3. **Secure Storage**: Store client secrets securely using environment variables
4. **Token Rotation**: Implement regular token rotation where supported

### Apple Pay Security

1. **Certificate Management**: Store Apple Pay merchant certificates securely
2. **Key Storage**: Use secure key management for payment processor credentials
3. **PCI Compliance**: Ensure your payment processing meets PCI DSS requirements
4. **Transaction Logging**: Implement secure transaction logging for audit purposes

## Environment Variables

For production deployment, use environment variables instead of storing credentials in the database:

```bash
# OAuth2 Configuration
APPLE_AUTH_GOOGLE_CLIENT_ID=your_google_client_id
APPLE_AUTH_GOOGLE_CLIENT_SECRET=your_google_client_secret
APPLE_AUTH_LINKEDIN_CLIENT_ID=your_linkedin_client_id
APPLE_AUTH_LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret
APPLE_AUTH_FACEBOOK_CLIENT_ID=your_facebook_app_id
APPLE_AUTH_FACEBOOK_CLIENT_SECRET=your_facebook_app_secret

# Apple Pay Configuration
APPLE_PAY_MERCHANT_IDENTIFIER=merchant.com.yourcompany
APPLE_PAY_MERCHANT_CERTIFICATE=your_apple_pay_certificate
APPLE_PAY_MERCHANT_DOMAIN=yourcompany.com

# Payment Gateway Configuration
STRIPE_PUBLISHABLE_KEY=pk_...
STRIPE_SECRET_KEY=sk_...
SQUARE_APPLICATION_ID=your_square_app_id
SQUARE_ACCESS_TOKEN=your_square_access_token
BRAINTREE_MERCHANT_ID=your_braintree_merchant_id
BRAINTREE_PUBLIC_KEY=your_braintree_public_key
BRAINTREE_PRIVATE_KEY=your_braintree_private_key
```

## Testing

### OAuth2 Testing

1. **Test Authentication Flow**:
   - Send authentication request from Apple Messages
   - Verify redirect to OAuth2 provider
   - Confirm successful authentication callback
   - Validate user data extraction

2. **Error Handling Testing**:
   - Test with invalid credentials
   - Test network failure scenarios
   - Verify proper error messages

### Apple Pay Testing

1. **Payment Flow Testing**:
   - Create test payment request
   - Verify Apple Pay sheet displays
   - Test payment authorization
   - Confirm transaction processing

2. **Gateway Testing**:
   - Test each enabled payment processor
   - Verify webhook handling
   - Test refund processing
   - Validate transaction status updates

## Troubleshooting

### Common OAuth2 Issues

1. **Invalid Redirect URI**: Ensure redirect URIs match exactly in provider settings
2. **Scope Issues**: Verify required scopes are configured in OAuth2 applications
3. **Token Expiration**: Implement proper token refresh mechanisms

### Common Apple Pay Issues

1. **Certificate Issues**: Verify Apple Pay merchant certificate is valid and properly formatted
2. **Domain Verification**: Ensure merchant domain is verified with Apple
3. **Payment Network Issues**: Check supported networks match your merchant configuration
4. **Gateway Errors**: Verify payment processor credentials and webhook endpoints

## Support and Documentation

For additional help:

- [Apple Messages for Business Documentation](https://developer.apple.com/documentation/businesschat)
- [Apple Pay Developer Documentation](https://developer.apple.com/apple-pay/)
- [OAuth2 Specification](https://oauth.net/2/)
- [Stripe Documentation](https://stripe.com/docs)
- [Square Documentation](https://developer.squareup.com/)
- [Braintree Documentation](https://developers.braintreepayments.com/)

## Conclusion

With OAuth2 authentication and Apple Pay properly configured, your Apple Messages for Business channel will provide:

- **Seamless User Authentication**: Customers can authenticate using their preferred social accounts
- **Secure Payment Processing**: End-to-end encrypted payment transactions through Apple Pay
- **Multiple Payment Options**: Support for various payment processors and networks
- **Enhanced Customer Experience**: Streamlined authentication and payment flows within Apple Messages

The configuration ensures compliance with Apple's guidelines and security best practices while providing enterprise-grade functionality for customer engagement and commerce.