# WooCommerce Integration & E-commerce Product Sidebar

## Overview

This feature adds native WooCommerce integration to Chatwoot and introduces a unified product sidebar for both WooCommerce and Shopify stores. Agents can browse products and send product links directly in conversations.

## Features

### 1. WooCommerce Integration

- Native integration configurable in Settings → Integrations
- Connects to WooCommerce stores via REST API
- Basic Authentication using Consumer Key and Secret
- Support for product catalog browsing

### 2. Product Sidebar

- Unified sidebar for browsing products from connected e-commerce platforms
- Works with both WooCommerce and Shopify integrations
- Search functionality to find products quickly
- One-click product link sharing in conversations
- Displays product information: name, price, SKU, stock status, and thumbnail

## Setup

### WooCommerce Configuration

1. Navigate to **Settings → Integrations** in Chatwoot
2. Find and click on **WooCommerce**
3. Fill in the required information:
   - **Store Name**: A friendly name for your store
   - **Store Base URL**: Your WooCommerce store URL (e.g., `https://mystore.com`)
   - **Consumer Key**: Generated from WooCommerce → Settings → Advanced → REST API
   - **Consumer Secret**: Secret key from WooCommerce REST API settings
   - **API Version**: Optional (defaults to `v3`)
4. Click **Test Connection** to verify the integration
5. Click **Connect** to save the integration

### WooCommerce Requirements

- WooCommerce 3.5+ installed on WordPress 4.4+
- REST API enabled in WooCommerce settings
- **Pretty Permalinks** must be enabled in WordPress (Settings → Permalinks)
  - Choose any option except "Plain"
  - This is required for the `/wp-json/wc/v3/` endpoint to work
- Valid REST API credentials (Consumer Key & Secret)

## Usage

### Accessing the Product Sidebar

1. Open any conversation in the inbox
2. Look for the sidebar toggle buttons on the right side
3. Click the **Store icon** (shopping bag) to open the Products sidebar
4. The sidebar will appear on the right, showing your e-commerce product catalog

### Browsing and Sending Products

1. Use the search bar to find specific products
2. Browse through the product list
3. Each product card shows:
   - Product thumbnail
   - Name and price
   - SKU (if available)
   - Stock status
4. Click **Send link** on any product to share it in the conversation
5. The product URL will be automatically sent as a message

## Technical Architecture

### Backend Structure

```
app/controllers/api/v1/accounts/integrations/
├── woocommerce_controller.rb      # WooCommerce-specific endpoints
└── ecommerce_controller.rb         # Unified e-commerce endpoints

lib/integrations/
├── woocommerce/
│   ├── client.rb                  # WooCommerce API client
│   └── exceptions.rb               # Custom error classes
└── ecommerce/
    ├── base_provider.rb            # Abstract provider interface
    ├── woocommerce_provider.rb     # WooCommerce implementation
    └── shopify_provider.rb         # Shopify implementation
```

### Frontend Structure

```
app/javascript/dashboard/
├── api/integrations/
│   ├── woocommerce.js              # WooCommerce API client
│   └── ecommerce.js                # Unified e-commerce API client
└── components-next/Ecommerce/
    ├── ProductsSidebar.vue         # Main sidebar container
    ├── ProductsList.vue            # Product list with search
    └── ProductItem.vue             # Individual product card
```

### API Endpoints

#### WooCommerce

- `POST /api/v1/accounts/:account_id/integrations/woocommerce/test_connection`
- `GET /api/v1/accounts/:account_id/integrations/woocommerce/products`
- `DELETE /api/v1/accounts/:account_id/integrations/woocommerce`

#### E-commerce (Unified)

- `GET /api/v1/accounts/:account_id/integrations/ecommerce/products`
- `POST /api/v1/accounts/:account_id/integrations/ecommerce/send_product`

## Troubleshooting

### Connection Issues

**"WooCommerce API not found"**
- Ensure WooCommerce is installed and activated
- Enable Pretty Permalinks in WordPress Settings → Permalinks
- Choose any option except "Plain"

**"Authentication failed"**
- Verify Consumer Key and Secret are correct
- Check that the REST API user has sufficient permissions
- Ensure the credentials are active in WooCommerce settings

**"Connection timeout"**
- Verify the Store Base URL is correct
- Check firewall settings aren't blocking requests
- Ensure your server can reach the WooCommerce store

### No Products Showing

- Verify at least one integration (WooCommerce or Shopify) is connected and enabled
- Check that products exist in your store
- Ensure products are published (not draft)
- Try using the search function to find specific products

## Extending the Feature

### Adding New E-commerce Platforms

1. Create a new provider class extending `Integrations::Ecommerce::BaseProvider`
2. Implement `list_products` and `get_product` methods
3. Add the provider to `EcommerceController#provider_for_integration`
4. Create integration configuration in `config/integration/apps.yml`
5. Add necessary controllers, routes, and translations

### Customizing Product Display

Edit `ProductItem.vue` to modify:
- Product card layout
- Information displayed
- Styling and appearance
- Action buttons

## Security Considerations

- WooCommerce credentials are encrypted using Rails' built-in encryption
- API calls use HTTPS with basic authentication
- No sensitive data is stored in frontend state
- All API requests go through authenticated backend endpoints
