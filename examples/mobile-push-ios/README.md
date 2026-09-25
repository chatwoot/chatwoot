# Website inbox iOS push proof

Local prototype: one native iOS app per Website inbox. This is a push-delivery proof, not a finished SDK. The web widget and native demo use the same inbox and widget customer-session APIs. Browser Web Push is a separate transport and is not added here.

## Admin configuration

Go to **Settings → Inboxes → your Website inbox → Mobile apps**. An account administrator enters:

- App name (notification title).
- Bundle ID matching the signed native app.
- Apple Team ID and APNs Key ID.
- The APNs `.p8` private key.

The private key is encrypted using Active Record encryption; it is never returned by the API. The installation must configure `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`, and `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`. Keep these installation secrets stable and backed up. Losing them makes stored keys unreadable.

A device chooses `development` (APNs sandbox) or `production` (distribution/TestFlight) when registering. A test notification can be sent from each device row. Refresh to see the provider response. **Accepted by APNs does not mean the phone displayed it.** Check the actual notification and tap separately.

Replacing the signing key is supported. Changing Bundle ID while devices exist is rejected; remove the configuration and register devices against the replacement app. Removing configuration deletes its device registrations and delivery history.

## Apple setup

This local demo currently targets the existing test app `chatwoot.ChatwootExampleApp`, team `L7YLMN4634`. Change these Xcode build settings for your own team.

1. In Apple Developer → Certificates, Identifiers & Profiles → Identifiers, enable **Push Notifications** for that explicit App ID. Refresh provisioning profiles after capability changes.
2. Under Keys, create an APNs signing key. Prefer sandbox and a scope limited to this test topic when offered. Download the `.p8` once and retain it securely. Do not put it in the app or source control.
3. Open `PushDemo.xcodeproj` in Xcode. Select your signing team and the same Bundle ID. Run a development build on an iPhone with Developer Mode enabled.
4. The phone must reach your local Rails host. `localhost` on the phone is the phone, not the Mac. Use a reachable development hostname/HTTPS server, or configure LAN access for local testing. The prototype’s Info.plist allows local networking; it does not disable TLS verification.
5. Enter the Website token, inbox ID, and reachable server URL. Connect, send a message, and enable notifications.
6. Upload the key and IDs in Chatwoot’s Mobile apps tab. If notification registration happened before configuration, tap Enable notifications again.
7. Background the app. Send a test notification from Chatwoot, then send an agent reply to its conversation. Confirm both appear and tapping a reply shows the expected conversation ID.

No App Store submission is needed for a development build. Apple references: [App ID registration](https://developer.apple.com/help/account/identifiers/register-an-app-id), [APNs token authentication](https://developer.apple.com/help/account/capabilities/communicate-with-apns-using-authentication-tokens), [registering for APNs](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns).

## Simulator verification without an APNs key

Build with normal simulator signing; disabling signing breaks Keychain access in this demo:

```sh
xcodebuild -project examples/mobile-push-ios/PushDemo.xcodeproj -scheme PushDemo \
  -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/chatwoot-push-demo-build build
xcrun simctl install booted /tmp/chatwoot-push-demo-build/Build/Products/Debug-iphonesimulator/PushDemo.app
xcrun simctl launch booted chatwoot.ChatwootExampleApp
```

Connect to the Website inbox and allow notifications. Set the inbox and conversation IDs in `sample.apns`, background the app, then run:

```sh
xcrun simctl push booted chatwoot.ChatwootExampleApp examples/mobile-push-ios/sample.apns
```

This injection checks notification presentation/tap handling only. It bypasses the backend, APNs authentication, and Apple's network. It is not proof of real delivery.

## API contract

Account-authenticated, admin-only endpoints:

- `GET/PATCH/DELETE /api/v1/accounts/:account_id/inboxes/:inbox_id/mobile_app`
- `POST /api/v1/accounts/:account_id/inboxes/:inbox_id/mobile_app/test_notification`, body `{ "device_id": 123 }`

Obtain the normal widget customer token from `POST /api/v1/widget/config?website_token=...`; retain `website_channel_config.auth_token`. Then use `X-Auth-Token` for:

- `POST /api/v1/widget/mobile_push_devices?website_token=...`, body `{ "device_token": "hex APNs token", "environment": "development", "name": "Test iPhone" }`; returns registration ID.
- `DELETE /api/v1/widget/mobile_push_devices/:id?website_token=...` on logout/reset.

The client uses Keychain for the customer session. A token cannot be moved to another customer session until unregistered. The app retains its session when unregister fails so it can retry. There is no admin API token or APNs credential in the native app.

Agent replies enqueue generic alerts with inbox/conversation identifiers. Private notes and incoming messages do not enqueue alerts. Delivery records deduplicate dispatch for the same message/device. Transient APNs failures are retried; APNs rejection reasons are visible. Expired/invalid tokens stop receiving new pushes until re-registered.

## Prototype limits

- iOS only, one app per Website inbox; Android/FCM comes later.
- Routing is to the exact contact-inbox session that owns the conversation. Cross-device verified-contact fan-out is not implemented.
- All customer-visible outgoing messages qualify; foreground suppression is not implemented. No silent/background synchronization or unread badge counts.
- The demo shows the notification destination ID; the full SDK still needs to authorize and open that exact conversation. Its manual Refresh uses the existing widget latest-conversation endpoint.
- APNs connections are opened per delivery in this proof; production needs connection reuse and operational delivery retention/monitoring.
- Network retries can produce duplicates after an ambiguous provider timeout. No exactly-once delivery promise.
- The proof uses anonymous customer sessions. Verified identity and complete logout/reinstall recovery need SDK integration work.
