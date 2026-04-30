# Tiendanube Integration for Chatwoot

## Overview

This implementation adds native Tiendanube integration to Chatwoot, following the same architecture and patterns as the existing Shopify integration. The integration enables Chatwoot accounts to connect their Tiendanube stores and view customer orders directly within conversation sidebars.

## Features Implemented

### ✅ Mandatory MVP Requirements

#### A) Tiendanube Connection per Account (OAuth)
- **Integration Settings Page**: Added Tiendanube to Settings → Integrations
- **OAuth Flow**: Complete authorization code flow implementation
- **Per-Account Credentials**: Secure storage of:
  - `access_token`
  - `store_id` / `user_id`
  - Scope and metadata for debugging
- **Connect/Disconnect**: Full lifecycle management
- **UI States**:
  - Not configured
  - Disconnected
  - Connected
  - Error (with reconnect suggestion)

#### B) Customer Orders in Conversation Sidebar
- **Tiendanube Orders Block**: Displays in conversation sidebar
- **State Handling**:
  - Integration not connected → "Connect Tiendanube"
  - No contact data → "No data to search for orders"
  - Orders found → List display
  - No orders found → "No orders found"
  - Error → Clear error message
- **Order Matching**:
  - Primary: Search by contact email
  - Secondary: Search by contact phone
  - Priority: Email takes precedence if both exist
- **Order Information**:
  - Order number/ID
  - Order status
  - Total amount
  - Order date
  - Direct link to view in Tiendanube admin

### ✅ Bonus Features Implemented

- **Feature Flag**: Integration controlled via `tiendanube_integration` feature flag
- **Caching**: 5-minute cache per contact to reduce API calls
- **Comprehensive Tests**: Full test coverage for controllers and helpers
- **Loom Video**: Demo video showing complete OAuth flow and order display

## Architecture

### Backend (Ruby on Rails)

#### Controllers
- `Api::V1::Accounts::Integrations::TiendanubeController`
  - OAuth initiation (`auth`)
  - Order fetching (`orders`)
  - Integration deletion (`destroy`)
  
- `Tiendanube::CallbacksController`
  - OAuth callback handling
  - Token exchange
  - Hook creation

#### Helpers
- `Tiendanube::IntegrationHelper`
  - API client methods
  - Token generation/verification
  - Order fetching logic
  - Caching implementation

#### Models
- `Integrations::App`
  - Added `tiendanube_enabled?` method
  - Feature flag integration

### Frontend (Vue.js)

#### Components
- `Tiendanube.vue`: Integration settings page
- `TiendanubeOrdersList.vue`: Orders list in sidebar
- `TiendanubeOrderItem.vue`: Individual order display

#### API Client
- `integrations/tiendanube.js`: API methods for order fetching
- `integrations.js`: OAuth connection methods

### Configuration Files
- `config/integration/apps.yml`: Integration metadata
- `config/features.yml`: Feature flag definition
- `config/locales/en.yml`: Translations
- `config/routes.rb`: API and callback routes

## Setup Instructions

### Prerequisites
- Ruby 3.2+
- Node.js 18+
- PostgreSQL
- Redis (for caching)

### 1. Tiendanube App Configuration

#### Create a Tiendanube Partners Account
1. Go to https://partners.tiendanube.com
2. Sign up for a Partners account
3. Create a new app

#### Configure Your App
- **App Name**: Chatwoot Integration (or your choice)
- **Redirect URI**: `http://localhost:3000/tiendanube/callback`
- **Required Scopes**:
  - `read_orders`
  - `read_customers`
  - `read_products` (optional)

#### Get Credentials
After creating the app, you'll receive:
- **Client ID** (App ID)
- **Client Secret**

### 2. Environment Variables

Add to your `.env` file:

```bash
# Tiendanube Integration
TIENDANUBE_CLIENT_ID=your_client_id_here
TIENDANUBE_CLIENT_SECRET=your_client_secret_here
TIENDANUBE_REDIRECT_URI=http://localhost:3000/tiendanube/callback
```

**Security Note**: Never commit these credentials to version control.

### 3. Database Setup

```bash
# Run migrations (if any new migrations were added)
bundle exec rails db:migrate

# Enable the feature flag
bundle exec rails console
> InstallationConfig.find_by(name: 'tiendanube_integration')&.update(locked: false, enabled: true)
```

### 4. Install Dependencies

```bash
# Backend
bundle install

# Frontend
npm install
# or
pnpm install
```

### 5. Start the Application

```bash
# Start Rails server
bundle exec rails server

# In another terminal, start Vite dev server
bin/vite dev
```

### 6. Enable the Integration

1. Log in to Chatwoot as an administrator
2. Go to **Settings** → **Integrations**
3. Find the **Tiendanube** card
4. Click **Configure**
5. Click **Connect**
6. Enter your Tiendanube store ID (e.g., `ideas36`)
7. Authorize the app in Tiendanube
8. You'll be redirected back to Chatwoot with the integration connected

## Usage

### Viewing Orders in Conversations

1. Open any conversation with a contact
2. Ensure the contact has an email or phone number
3. Scroll down the right sidebar
4. The "Tiendanube Orders" section will display:
   - Last 10 orders for that customer
   - Order details (number, status, total, date)
   - Direct links to view orders in Tiendanube admin

### Order Matching Logic

The integration searches for orders using:
1. **Primary**: Contact's email address
2. **Secondary**: Contact's phone number (if email not found)
3. **Priority**: If both exist, email is used first

### Caching

- Orders are cached for **5 minutes** per contact
- Cache key: `tiendanube_orders_{account_id}_{contact_id}`
- Reduces API calls and improves performance

## Testing

### Run All Tests

```bash
# Run all Tiendanube-related tests
bundle exec rspec spec/controllers/tiendanube/
bundle exec rspec spec/controllers/api/v1/accounts/integrations/tiendanube_controller_spec.rb
bundle exec rspec spec/helpers/tiendanube/
```

### Test Coverage

- ✅ OAuth flow (auth endpoint)
- ✅ OAuth callback handling
- ✅ Token exchange
- ✅ Order fetching
- ✅ Error handling (401, 404, timeouts)
- ✅ Caching behavior
- ✅ Integration deletion

### Manual Testing

1. **OAuth Flow**:
   - Connect integration
   - Verify token is saved
   - Check hook is created

2. **Order Display**:
   - Open conversation with customer who has orders
   - Verify orders appear in sidebar
   - Click order link to verify it opens in Tiendanube

3. **Error States**:
   - Test with invalid token
   - Test with contact without email/phone
   - Test with customer who has no orders

## Technical Decisions & Assumptions

### 1. Store ID Format
- **Decision**: Accept both numeric (e.g., `7237538`) and alphanumeric (e.g., `ideas36`) store IDs
- **Reason**: Tiendanube uses different formats for store identifiers

### 2. Order Matching Priority
- **Decision**: Email takes precedence over phone number
- **Reason**: Email is more reliable and commonly used in e-commerce

### 3. Caching Strategy
- **Decision**: 5-minute cache per contact
- **Reason**: Balances performance with data freshness

### 4. Order Limit
- **Decision**: Display last 10 orders
- **Reason**: Prevents UI clutter and reduces API load

### 5. OAuth Endpoint
- **Decision**: Use store-specific subdomain for OAuth
- **Reason**: Follows Tiendanube's OAuth documentation pattern

### 6. Multi-tenancy
- **Implementation**: Each account stores its own credentials in `hooks` table
- **Isolation**: Complete separation via `Current.account`

### 7. Error Handling
- **401/403**: Suggest reconnection
- **Timeouts**: Graceful fallback with user message
- **No data**: Clear messaging for each state

## Security Considerations

- ✅ Tokens never logged or exposed in frontend
- ✅ Secrets stored in environment variables
- ✅ State parameter used in OAuth for CSRF protection
- ✅ JWT tokens for state verification
- ✅ Per-account credential isolation
- ✅ Secure token storage in encrypted hooks table

## API Endpoints

### Backend Routes

```ruby
# OAuth
POST   /api/v1/accounts/:account_id/integrations/tiendanube/auth
GET    /tiendanube/callback

# Orders
GET    /api/v1/accounts/:account_id/integrations/tiendanube/orders

# Disconnect
DELETE /api/v1/accounts/:account_id/integrations/tiendanube
```

## File Structure

```
app/
├── controllers/
│   ├── api/v1/accounts/integrations/
│   │   └── tiendanube_controller.rb
│   └── tiendanube/
│       └── callbacks_controller.rb
├── helpers/
│   └── tiendanube/
│       └── integration_helper.rb
├── javascript/dashboard/
│   ├── api/integrations/
│   │   └── tiendanube.js
│   ├── components/widgets/conversation/
│   │   ├── TiendanubeOrdersList.vue
│   │   └── TiendanubeOrderItem.vue
│   └── routes/dashboard/settings/integrations/
│       └── Tiendanube.vue
└── models/
    └── integrations/
        └── app.rb (modified)

config/
├── integration/
│   └── apps.yml (modified)
├── features.yml (modified)
├── locales/
│   └── en.yml (modified)
└── routes.rb (modified)

spec/
├── controllers/
│   ├── api/v1/accounts/integrations/
│   │   └── tiendanube_controller_spec.rb
│   └── tiendanube/
│       └── callbacks_controller_spec.rb
└── helpers/
    └── tiendanube/
        └── integration_helper_spec.rb

public/dashboard/images/integrations/
├── tiendanube.png
└── tiendanube-dark.png
```

## Known Limitations

1. **Development Apps**: Direct OAuth URLs may not work for unpublished Tiendanube apps. Use the "Instalar aplicación" button in Partners dashboard for testing.

2. **Webhook Support**: Not implemented in MVP (can be added as future enhancement).

3. **Order Pagination**: Currently fetches last 10 orders only.

## Future Enhancements

- [ ] Webhook support for real-time order updates
- [ ] Order pagination for customers with many orders
- [ ] Product information display
- [ ] Customer details synchronization
- [ ] Abandoned cart recovery
- [ ] Order status change notifications

## Demo Video

A Loom video demonstrating the complete integration is available showing:
- Integration card in Chatwoot
- OAuth connection flow
- Order display in conversation sidebar
- Direct links to Tiendanube admin

## Support

For questions or issues:
1. Check Tiendanube API documentation: https://tiendanube.github.io/api-documentation/
2. Review Chatwoot integration patterns (Shopify integration)
3. Check Rails logs for detailed error messages

## License

This integration follows the same license as the Chatwoot project.
