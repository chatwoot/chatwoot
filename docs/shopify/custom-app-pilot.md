# Account-specific Shopify custom apps

For a small pilot, an operator can connect a customer's custom-distribution Shopify app to an existing Chatwoot account. Each configuration belongs to exactly one account, one app, and one `myshopify.com` store. The customer's existing billing continues; this flow does not create an account or start Shopify billing.

The installation-wide Shopify configuration in Super Admin remains the main Chatwoot app configuration. Accounts without an enabled override continue using it. Custom app client secrets are encrypted using Active Record encryption and are not exposed by account APIs.

## Provision a pilot account

1. Deploy the migration and configure all three `ACTIVE_RECORD_ENCRYPTION_*` keys on the Rails and worker processes. Keep the existing global Shopify client credentials configured; the order reader uses those to initialize the SDK and the connection's own access token for requests.
2. Create a separate Shopify app for the customer's store. Choose **Custom distribution**, restrict installation to that store, and copy Shopify's generated install link. Do not change the public Chatwoot app's distribution method. See [Shopify's distribution instructions](https://shopify.dev/docs/apps/launch/distribution/select-distribution-method).
3. Use an existing account with non-Shopify billing. If it already connects a different Shopify store, disconnect that store first. This pilot retains the existing one-store-per-account limit.
4. Provision the configuration through an operator Rails console. Supply the following environment variables securely to that console process; do not put secrets or signed install links in tickets or shell history.

```ruby
account = Account.find(ENV.fetch('PILOT_ACCOUNT_ID'))
account.enable_features!('shopify_integration')
custom_app = Shopify::CustomApp.create!(
  account: account,
  shop_domain: ENV.fetch('PILOT_SHOP_DOMAIN'),
  client_id: ENV.fetch('PILOT_SHOPIFY_CLIENT_ID'),
  client_secret: ENV.fetch('PILOT_SHOPIFY_CLIENT_SECRET'),
  install_url: ENV.fetch('PILOT_SHOPIFY_INSTALL_URL'),
  enabled: false
)
puts "App URL and redirect URL: #{ENV.fetch('FRONTEND_URL')}#{custom_app.callback_path}"
puts "Webhook URL: #{ENV.fetch('FRONTEND_URL')}#{custom_app.webhook_path}"
```

5. Configure the custom app as non-embedded with the authorization-code flow. Set **both its App URL and allowed redirect URL** to the printed callback URL, and request `read_customers,read_orders,read_fulfillments`. Configure `app/uninstalled` and applicable privacy webhooks to use the printed webhook URL. Release the app version. Production callbacks and webhooks need a public HTTPS origin; do not use a local development URL.
6. Enable the global **Enable Shopify Integration** setting and activate this record with `custom_app.update!(enabled: true)`. The account feature flag and the global flag both still apply.
7. The account administrator opens **Settings → Integrations → Shopify**, enters the configured store domain, and confirms. Chatwoot redirects to the account's generated install link. The merchant approves access in Shopify and returns to that account's integration page.
8. Open a conversation whose contact matches a Shopify customer and verify the order list. Confirm the account's existing billing remains unchanged.

If Shopify expires or regenerates the signed install link, copy a fresh link from its distribution page and update `custom_app.install_url` before retrying. Chatwoot stores the link; it does not generate Shopify signatures.

The app must have the Shopify permissions needed for the customer and order fields being read. Custom distribution does not add permissions automatically. No Partner API token or managed pricing configuration is needed for the custom app.

## Isolation and cleanup

The callback URL identifies the configuration, and the callback must match its store and HMAC secret. OAuth state is single-use and bound to the app. Uninstall invalidates pending authorizations, including authorizations started before a hook exists.

Connections record the custom app ID. Custom webhooks only clean up that app's connection on that account. Global app webhooks skip custom connections. Keep each custom app's webhook URL separate from `/webhooks/shopify`.

The account, store, and client ID cannot be changed on an existing record. Client-secret rotation is supported by updating the existing record. Disabling an override prevents custom OAuth; it does not disconnect an existing token. To revoke a connection, disconnect it in Chatwoot or uninstall it in Shopify.

## Move to the approved public app

1. Disable the override with `custom_app.update!(enabled: false)`, retaining the record and webhook configuration for delayed cleanup events.
2. From the same account, connect the same store again. Chatwoot now uses the global public app. Complete Shopify approval; Chatwoot exchanges a fresh public-app token and replaces the hook's custom-app identity.
3. Verify orders and existing billing before uninstalling the old custom app. A delayed uninstall/redaction for the old app will not remove the replacement public connection.

This is a new authorization, not a token transfer. Changing the global credentials or deleting the custom configuration alone does not migrate an existing connection.
