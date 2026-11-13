# Instagram API with Unified Login

New Meta apps use Instagram API with Unified Login. Older apps can continue using
Instagram Login. Both create an Instagram inbox in Chatwoot; Unified Login does
not require a Facebook Page.

## Configure the Meta app

1. Create a Meta app owned by a business portfolio and add the Instagram use case.
2. Open **API setup with Unified login** and create a Facebook Login for Business
   configuration with Instagram assets and a system-user access token. Request
   `instagram_basic` and `instagram_manage_messages`. Only include additional
   permissions if your app needs them and has the appropriate access.
3. Register `https://YOUR_CHATWOOT_HOST/instagram/callback` as a redirect URL.
4. Configure Instagram webhooks with callback
   `https://YOUR_CHATWOOT_HOST/webhooks/instagram` and the verification token saved
   in Chatwoot. Enable `messages`, `message_reactions`, and `messaging_seen`.
5. During development, add the test Instagram professional account as an
   **Instagram Tester** under App roles. Accept the invitation in Instagram →
   Apps and websites → Tester Invites. Complete Meta's review and publication
   requirements before connecting customers without app roles.

## Configure Chatwoot

Configure Chatwoot's `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`,
`ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`, and
`ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`, and run database migrations.
These keys enable encrypted storage of temporary provider tokens in Redis.
Then open **Super Admin → Settings → Instagram**:

| Setting | Value |
| --- | --- |
| Login method for new connections | Unified Login |
| Instagram Unified Login Meta App ID | The Meta app ID, not an Instagram app ID |
| Instagram Unified Login Meta App Secret | The Meta app secret |
| Instagram Unified Login Configuration ID | The Facebook Login for Business configuration ID |
| Instagram Verify Token | The same verification token used for the Instagram webhook |
| Instagram API Version | A Graph API version supported by your Meta app |

Keep the original Instagram App ID and Instagram App Secret for existing
Instagram Login integrations. The two app secrets are both accepted for webhook
signature verification. Select the login method to use for new authorizations
only. Existing inboxes reconnect with their stored login method and configuration.
Only the selected method's credentials are shown and saved;
switching methods preserves the other credentials for existing inboxes.
Instagram Login is the default until an administrator selects Unified Login.

From **Settings → Inboxes → Add inbox → Instagram**, continue with Instagram or
Facebook, select the business portfolio and Instagram account, and approve the
permissions. A single shared Instagram account connects automatically. If Meta
returns multiple shared accounts, choose the one to connect. Account selection
expires after ten minutes; start again if it expires.

Chatwoot confirms the account's messaging subscription before creating or
reauthorizing the inbox. Reauthorizing an existing inbox with its current login
method preserves the inbox, name, and conversation history. Switching an existing
inbox between Instagram Login and Unified Login is handled in a separate
follow-up change. An Instagram reauthorization only accepts the Instagram account already linked to that inbox.
If a different account is shared, Chatwoot asks you to reconnect with the original
account instead of creating another inbox. An Instagram account already
connected in a different Chatwoot account cannot be connected
again. When replacing a Facebook Page-linked Instagram inbox, the direct
Instagram inbox takes priority for incoming webhooks; its prior conversations
remain in the Page-linked inbox.

Unified Login tokens use `graph.facebook.com`; Instagram Login tokens continue
using `graph.instagram.com`. Non-expiring system-user tokens have no expiration
date. Finite system-user tokens require reauthorization when they expire; they
are never sent to Instagram's user-token refresh endpoint. Removing the app from
the business portfolio or moving the Instagram account can invalidate a token.

## Rollout and rollback

Apply the additive migration before starting the new web and worker processes.
It marks existing rows as Instagram Login and permits a missing token expiry for
non-expiring system-user tokens. The change adds no data backfill or new index.
Token storage remains an unrestricted string column. Unified Login tokens use
an explicit 20,000-character model limit instead of the default string limit.

Selecting Instagram Login stops new Unified Login authorizations. Existing
Unified Login inboxes still require this code to send messages and receive
profile/story data. Do not roll the code back while Unified Login inboxes are active. Do not roll back the database migration while any inbox
has a null expiration; restoring the previous not-null constraint would fail.

References: [Meta overview](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login/),
[authentication](https://developers.facebook.com/documentation/instagram-platform/instagram-api-with-unified-login/authentication).

## Validation and known gaps

A fresh Meta app was tested with Supastats: inbox creation, incoming messages,
replies, customer profile lookup, and story replies with downloaded images worked.
The local tunnel frontend showed a blank page, so the returned account-selection
URL was completed on localhost. The HTTPS callback itself succeeded.

A sent reply currently appears twice: Meta returns a different message ID in its
send response and echo webhook. This remains open and must be resolved before
release. Instagram reactions are delivered as webhooks but are not processed by
Chatwoot; this is existing behavior. Public setup documentation will be updated
separately.
