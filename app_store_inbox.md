# App Store Reviews Inbox Plan

## Goal

Add Apple App Store reviews as a Chatwoot inbox, similar to the Google Play Reviews inbox, so agents can read App Store reviews in Chatwoot and post developer responses from the conversation reply box.

## API Findings

- Use the official App Store Connect API, not public RSS/iTunes review feeds.
- App Store Connect API uses API keys and ES256 JWT bearer tokens, not OAuth user sign-in.
- Required credentials:
  - Issuer ID
  - Key ID
  - `.p8` private key
- JWTs should be short-lived. Apple generally rejects App Store Connect API tokens with expiration more than 20 minutes in the future.
- Reviews can be fetched from:
  - `GET /v1/apps/{id}/customerReviews`
  - `GET /v1/appStoreVersions/{id}/customerReviews`
- Review fields include:
  - `rating`
  - `title`
  - `body`
  - `reviewerNickname`
  - `createdDate`
  - `territory`
  - `response`
- Developer responses can be included with `include=response`.
- Developer replies are created or updated through:
  - `POST /v1/customerReviewResponses`
- A review can have at most one developer response. Posting another response updates/replaces the existing one.
- Apple says responses can take up to 24 hours to appear publicly.
- Required App Store Connect role for responding: Account Holder, Admin, or Customer Support.
- No Apple equivalent of Google Play's 7-day review fetch limit was found. Do not add a 7-day reply window unless real API testing proves one exists.

References:

- https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests
- https://developer.apple.com/documentation/appstoreconnectapi/customer-review-responses
- https://developer.apple.com/documentation/appstoreconnectapi/post-v1-customerreviewresponses
- https://developer.apple.com/documentation/appstoreconnectapi/list_all_customer_reviews_for_an_app_store_version
- https://developer.apple.com/help/app-store-connect/monitor-ratings-and-reviews/respond-to-reviews/

## Product Shape

The App Store inbox should be a new channel type, separate from Google Play:

- Channel name: App Store Reviews
- One inbox per App Store Connect app per Chatwoot account.
- Setup should be credential-form based, not OAuth redirect based.
- Agents should see each review as a conversation.
- Agents should be able to reply once; later replies update the App Store response.
- Existing developer responses from App Store Connect should be mirrored as outgoing messages.
- Review title, body, rating, territory, and reviewer nickname should be visible in the conversation.

## Data Model

Add `channel_app_store`.

Suggested fields:

- `account_id`
- `app_id` - App Store Connect app resource ID
- `bundle_id`
- `app_name`
- `provider_config` - non-secret metadata only, if needed
- `issuer_id`
- `key_id`
- `private_key`
- `last_synced_at`
- timestamps

Indexes:

- unique index on `[:account_id, :app_id]`

Security:

- Treat `.p8` private key as a sensitive credential.
- Prefer explicit encrypted columns for `issuer_id`, `key_id`, and `private_key`.
- Avoid storing the private key inside unencrypted JSONB.
- Follow existing `Chatwoot.encryption_configured?` patterns used by channel credentials.

Model wiring:

- Add `Channel::AppStore`.
- Add `Account#app_store_channels`.
- Add `Inbox#app_store?`.
- Add API serialization for `app_id`, `bundle_id`, `app_name`, and `last_synced_at`.
- Add `SendReplyJob` mapping to `AppStore::SendOnAppStoreService`.

## Backend Services

### `AppStoreConnect::TokenService`

Responsibilities:

- Build an ES256 JWT using the channel credentials.
- Use existing `jwt` gem.
- Parse private key with `OpenSSL::PKey`.
- Set JWT header:
  - `alg: ES256`
  - `kid: key_id`
  - `typ: JWT`
- Set JWT payload:
  - `iss: issuer_id`
  - `iat`
  - `exp`
  - `aud: appstoreconnect-v1`
- Cache token per channel until close to expiry.

### `AppStoreConnect::Client`

Responsibilities:

- Add bearer token auth header.
- Fetch reviews with pagination.
- Fetch included developer responses.
- Post developer responses.
- Raise clear errors for:
  - 401 invalid credentials
  - 403 missing permissions
  - 404 app/review not found
  - 409/422 invalid response payload
  - 429 rate limited
  - 5xx Apple errors

Suggested methods:

- `list_reviews(app_id, cursor: nil)`
- `reply_to_review(review_id, response_body)`
- `fetch_app(app_id)` or `validate_app_access(app_id)`

## Import Pipeline

Add jobs:

- `Inboxes::FetchAppStoreReviewInboxesJob`
- `Inboxes::FetchAppStoreReviewsJob`

Polling behavior:

- Scheduled polling similar to Google Play.
- Skip suspended accounts.
- Use `last_synced_at` to avoid excessive polling.
- Page through review results using `links.next`.
- Consider sorting by `-createdDate`.

Add `AppStore::ReviewBuilder`.

Mapping:

- Apple review ID maps to `ContactInbox#source_id`.
- One review maps to one conversation.
- Review edits should be handled idempotently.
- Incoming message source ID can be based on review ID plus `createdDate` or a stable edit/version field if Apple exposes one.
- Existing developer response maps to an outgoing message.
- Developer response message source ID should use Apple response ID if present.

Message content:

- Include star rating.
- Include title.
- Include body.
- Include a compact footer with territory and reviewer nickname when useful.

Message timestamps:

- Use Apple `createdDate` as `created_at` and `updated_at` for imported review messages.
- Do not use import time for review messages.

Metadata:

Store under `content_attributes[:app_store]`:

- `rating`
- `title`
- `territory`
- `reviewer_nickname`
- `created_date`
- `response_state`
- `response_id`

## Reply Pipeline

Add `AppStore::SendOnAppStoreService`.

Behavior:

- Use `conversation.contact_inbox.source_id` as the Apple review ID.
- Call `POST /v1/customerReviewResponses`.
- On success:
  - Update `message.source_id` with Apple response ID if returned.
  - Mark message as sent/delivered through `Messages::StatusUpdateService`.
- On failure:
  - Mark message as failed through `Messages::StatusUpdateService`.
  - Store `external_error`.

Constraints:

- Disable attachments.
- Disable rich-text formatting.
- Confirm Apple's response length limit during implementation. Do not guess a hard cap unless verified.

## Frontend

Add App Store Reviews to inbox creation.

Setup form fields:

- Inbox name
- App Store Connect app ID
- Bundle ID, optional if app ID is enough
- Issuer ID
- Key ID
- Private key `.p8`

Backend should validate credentials before creating the inbox by calling App Store Connect.

Frontend wiring:

- Add `INBOX_TYPES.APP_STORE`.
- Add `isAnAppStoreChannel` / equivalent composable and mixin helpers.
- Add channel icon.
- Add i18n strings in `en.json` only.
- Add channel to inbox list and channel factory.
- Add API client for creating/validating App Store channel.
- Add plain text editor config for `Channel::AppStore`.
- Add reply max length only after Apple limit is confirmed.

Unsupported settings:

- Hide bots.
- Hide business hours.
- Hide CSAT.
- Hide help center.
- Hide channel preferences that do not apply.
- Disable attachments.

## Tests

Backend specs:

- `Channel::AppStore` validations and associations.
- JWT generation with generated EC key.
- Client review pagination.
- Client reply request body.
- Client error handling.
- Inbox creation credential validation.
- Review builder creates contact, conversation, incoming message.
- Review builder idempotency.
- Review builder mirrors existing developer response.
- Send service success and failure.
- Polling job skips suspended accounts.
- Polling job respects sync interval.

Frontend specs:

- Channel detection helper/composable.
- Inbox type icon/readable label.
- Setup form validation.
- Reply box behavior for unsupported attachments/formatting.

## Resolved Open Questions

### App-level reviews vs version-level reviews

Use app-level reviews as the primary fetch path:

- `GET /v1/apps/{id}/customerReviews`

Reasoning:

- Chatwoot inboxes should map to an app, not to a specific App Store version.
- Apple documents app-level customer reviews as the endpoint for getting reviews for a specific app.
- Version-level reviews are still useful for narrower workflows, but they would make inbox setup more complicated and could fragment one app's support queue across several inboxes.

Implementation decision:

- Store the App Store Connect app resource ID on `Channel::AppStore`.
- Fetch app-level reviews by default.
- Keep version-level support out of MVP.
- Add `platform` or `app_store_version_id` later only if real API testing shows app-level reviews mix platforms in a way agents cannot work with.

Still needs real API validation:

- Confirm whether app-level reviews include all platforms and all versions for a multi-platform app.
- Confirm whether app-level review payload includes enough context to identify platform/version. The documented review attributes include `rating`, `title`, `body`, `reviewerNickname`, `createdDate`, and `territory`, but not platform/version.

### Response payload shape

Use JSON:API format for `POST /v1/customerReviewResponses`.

Request body:

```json
{
  "data": {
    "type": "customerReviewResponses",
    "attributes": {
      "responseBody": "Thanks for the feedback."
    },
    "relationships": {
      "review": {
        "data": {
          "type": "customerReviews",
          "id": "CUSTOMER_REVIEW_ID"
        }
      }
    }
  }
}
```

Expected successful response:

- HTTP `201 Created`.
- Response resource type: `customerReviewResponses`.
- Response fields can include:
  - `responseBody`
  - `lastModifiedDate`
  - `state`
  - `review`

Implementation decision:

- Use the returned customer review response ID as outgoing message `source_id`.
- Store `state` and `lastModifiedDate` in `content_attributes[:app_store]` when present.

### Review edits and idempotency

Apple's documented `CustomerReview.Attributes` include `createdDate`, but not an update timestamp for the customer review itself.

Implementation decision:

- Use the Apple review ID as the stable incoming message source ID.
- Create one incoming message per review.
- If a fetched review with the same ID has changed title/body/rating, update the existing message content and metadata instead of creating a new message.
- Do not append edit history in MVP because the API docs do not expose a review edit timestamp.

Still needs real API validation:

- Confirm how Apple represents a reviewer editing an existing review in API responses.
- Confirm whether edited reviews preserve the same review ID.

### Response body length

No official customer review response length limit was found in the App Store Connect API docs checked.

Implementation decision:

- Do not hardcode a special App Store response length limit in MVP.
- Use Chatwoot's general reply validation on the frontend.
- Let Apple return `409` or `422` for invalid response payloads and surface the error through `external_error`.

Still needs real API validation:

- Check whether App Store Connect applies a hidden maximum length for `responseBody`.

### Rate limits and retries

Apple documents rate limits through the `X-Rate-Limit` response header.

Header shape:

```text
user-hour-lim:3500;user-hour-rem:500;
```

Behavior:

- Limits apply to requests using the same API key.
- The window is a rolling hour.
- Exceeding the limit returns HTTP `429` with `RATE_LIMIT_EXCEEDED`.

Implementation decision:

- Parse and log `X-Rate-Limit` headers in the client.
- On `429`, do not mark the inbox broken.
- Re-enqueue the fetch job later with backoff.
- Keep polling conservative, similar to Google Play, and page with `limit=200`.

### Inbox scope for multiple platforms and versions

Implementation decision:

- MVP scope is one inbox per App Store Connect app resource ID per Chatwoot account.
- Do not create separate inboxes by platform or app version.
- Store `platform` only if we can reliably derive it during setup or fetch.

Reasoning:

- This matches the way agents think about supporting one app.
- It avoids forcing customers to know App Store version resource IDs.
- It keeps parity with Google Play's one-app-per-inbox model.

Still needs real API validation:

- Confirm if app-level reviews for multi-platform apps are agent-friendly without platform separation.

## Remaining Risks

- Credential storage must be handled carefully because `.p8` private keys are highly sensitive.
- Apple responses can remain pending for up to 24 hours, so Chatwoot send status and public App Store visibility are not the same.
- A real App Store Connect app and API key are required before finalizing response-length handling, review-edit behavior, and multi-platform behavior.

## Suggested Implementation Order

1. Add model, migration, associations, and inbox serialization.
2. Add JWT token service and low-level App Store Connect client.
3. Add backend channel creation/validation endpoint.
4. Add review fetch job and review builder.
5. Add send service and `SendReplyJob` mapping.
6. Add frontend inbox setup and channel helpers.
7. Add settings/reply-box restrictions.
8. Add specs.
9. Manually verify with a real App Store Connect app and API key.
10. Revisit shared abstractions with Google Play after both integrations work.

## Potential Shared Abstraction Later

After Google Play and App Store are both implemented, consider extracting shared store-review behavior:

- Store review polling orchestration.
- Review-to-conversation builder conventions.
- Reply status handling.
- Unsupported inbox settings.
- Plain-text reply channel behavior.

Do not extract this upfront. Let both implementations settle first.
