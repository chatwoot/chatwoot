# Shopify storefront chat

The public Chatwoot Shopify app uses the theme app embed in `extensions/chatwoot-chat`. Chatwoot Cloud saves the selected Website inbox's public widget token on the Shopify app installation. Shopify renders it into the embed when the merchant enables it on a theme.

## Preview and release

1. Link this directory to the existing public Chatwoot Shopify app with `shopify app config link`. Review the linked app configuration, including any existing extensions, OAuth URLs, scopes, and webhooks, before creating a version.
2. Add `https://app.chatwoot.com` to `[network_access].allowed_sources` in the linked app configuration, preserving existing entries. Verify the required hosts with the [Shopify network access testing preview](https://shopify.dev/docs/apps/build/security/storefront/declare-network-access#test).
3. Preview the app embed on a Shopify development store. Verify the setup in Chatwoot Cloud and confirm the embed works in the theme editor and on the live storefront. Release the tested extension before exposing the setup to public-app merchants.

## Review walkthrough

Install the public app on a development store and connect a Chatwoot workspace. In Chatwoot, open **Settings → Integrations → Shopify**. Under **Storefront chat**, select a Website inbox or create one and add an agent, then save the inbox. Open the Shopify theme editor, enable **Chatwoot chat** under **App embeds**, and save the theme.

Open the storefront in a separate browser session. Send a chat message using the email of a test customer with an order. In Chatwoot, open the conversation, confirm the order appears, and send a reply. Verify the reply in the storefront widget. Turn off the embed and verify that the bubble disappears. Test uninstall and reinstall before recording the English screencast and updating the review instructions in the Partner Dashboard.

For a store with an existing manually installed widget, remove the old snippet when switching to the app embed so the storefront uses the selected inbox.

Shopify's theme editor controls whether the widget is visible. Turn off the embed there before disconnecting a Chatwoot workspace from a store you plan to connect to a different workspace.
