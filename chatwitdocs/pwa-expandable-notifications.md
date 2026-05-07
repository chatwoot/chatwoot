# PWA Expandable Notifications (iOS / Android)

## Goal

Bring WhatsApp-style **expandable notifications with inline reply** to the
Chatwit PWA, with first-class support for iPhone (iOS 16.4+ Web Push) and
Chrome/Android (which additionally supports the native inline text input).

When a new message arrives, the user can:

1. **Expand** the notification on the iPhone lock screen (long-press) and read
   the message body, sender name and avatar.
2. Tap the **Reply** action button to either:
   - Type a reply directly inside the notification (Android/Chrome).
   - Open the PWA pre-focused on the reply box (iOS).
3. Tap **Mark as read** to clear the notification without opening the app.

The full PWA is never required to be open for this to work — the service worker
posts the reply via the standard messages API using the user's stored session.

---

## Pieces touched

### Backend — `app/services/notification/push_notification_service.rb`

`push_message` now carries the full conversation/sender context plus a
`reply_enabled` flag and a stable per-conversation `tag`:

```jsonc
{
  "title": "...",
  "body": "John: Hi there",
  "tag": "conversation_<account_id>_<display_id>",
  "url": "...",
  "account_id": 1,
  "conversation_id": 42,
  "conversation_uuid": "abcd-uuid",
  "notification_id": 99,
  "notification_type": "assigned_conversation_new_message",
  "sender": { "name": "John", "avatar_url": "https://..." },
  "reply_enabled": true,
  "timestamp": 1700000000000
}
```

`reply_enabled` is `true` only when the conversation can accept replies
(`Conversation#can_reply?`) AND the notification is one of the new-message
types. SLA notifications, for example, are reply-disabled.

### Service worker — `public/sw.js`

- Builds rich `Notification` options with `actions`, `image` (sender avatar),
  `icon`, `badge`, `body`, `tag`, `data`.
- For repliable conversations adds two action buttons:
  - `reply` — `type: 'text'`, with a placeholder that includes the sender name.
    Chrome/Android renders this as a native inline text input. iOS ignores the
    `type: 'text'` and falls back to the click handler.
  - `mark_read`.
- `notificationclick` handler:
  - `reply` with non-empty `event.reply` → POST to
    `/api/v1/accounts/:id/conversations/:id/messages` using DeviseTokenAuth
    headers stored in IndexedDB. Posts `PWA_REPLY_SENT` to all clients.
  - `reply` with empty text (iOS) → opens the PWA navigated to the conversation
    with `?focus_reply=1` so the input is focused.
  - `mark_read` → PATCH `/api/v1/accounts/:id/notifications/:id`.
  - default → focus or open the existing PWA window.
- Pure helpers are mirrored from
  `app/javascript/shared/helpers/pwaPushNotification.js` (the canonical, tested
  copy).

### Page → SW auth bridge — `app/javascript/dashboard/helper/swAuthBridge.js`

The service worker cannot read the page's `cw_d_session_info` cookie directly
(DeviseTokenAuth requires the headers, not the cookie). On every PWA boot and
on every successful push subscription, the page persists the credentials to
IndexedDB (`chatwit-pwa-auth` / `sessions` / `current`). The SW reads them on
demand.

Stored only — never the user's password — and scoped to the same origin.

### Reply prefill — `MobileChatView.vue` + `MobileReplyBox.vue`

When the URL contains `?focus_reply=1`, `MobileChatView` emits a
`FOCUS_REPLY_BOX` bus event and clears the query param. `MobileReplyBox`
listens for the event and focuses the textarea (with optional prefill text).

---

## Tests

- `spec/services/notification/push_notification_service_spec.rb` — verifies
  the new payload fields (`account_id`, `conversation_id`, `notification_id`,
  `tag`, `timestamp`, `reply_enabled`).
- `app/javascript/shared/helpers/specs/pwaPushNotification.spec.js` — 26
  unit tests covering the pure helper functions.
- `app/javascript/dashboard/helper/specs/swAuthBridge.spec.js` — 7 tests
  covering the IndexedDB round-trip and the cookie → SW sync flow.

Run them with:

```bash
pnpm exec vitest run \
  app/javascript/shared/helpers/specs/pwaPushNotification.spec.js \
  app/javascript/dashboard/helper/specs/swAuthBridge.spec.js
bundle exec rspec spec/services/notification/push_notification_service_spec.rb
```

---

## iOS PWA caveats

- iOS only honors notification actions when the PWA is **installed** to the
  Home Screen (Add to Home Screen → enable Notifications).
- Maximum 2 action buttons are surfaced.
- `type: 'text'` (inline reply input) is **not honored**. We provide a graceful
  fallback that opens the PWA focused on the reply box.
- `image` rendering is best-effort; `icon` is what shows on the lock screen.
- Notifications are delivered via APNs by Apple's relay; payload size is
  enforced (~4 KB). Our payload sits well under that even with the new fields.
