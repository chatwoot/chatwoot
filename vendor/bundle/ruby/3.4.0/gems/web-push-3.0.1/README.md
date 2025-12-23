# WebPush

[![Gem Version](https://badge.fury.io/rb/web-push.svg)](https://badge.fury.io/rb/web-push)
![Build Status](https://github.com/pushpad/web-push/workflows/CI/badge.svg)

This gem makes it possible to send push messages to web browsers from Ruby backends using the [Web Push Protocol](https://datatracker.ietf.org/doc/html/rfc8030). It supports [Message Encryption for Web Push](https://datatracker.ietf.org/doc/html/rfc8291) and [VAPID](https://datatracker.ietf.org/doc/html/rfc8292).

**Note**: This is an open source gem for Web Push. If you want to send web push notifications from Ruby using Pushpad, you need to use another gem ([pushpad gem](https://github.com/pushpad/pushpad-ruby)).

## Installation

Add this line to the Gemfile:

```ruby
gem 'web-push'
```

Or install the gem:

```console
$ gem install web-push
```

## Usage

Sending a web push message to a visitor of your website requires a number of steps:

1. In the user's web browser, a `serviceWorker` is installed and activated and its `pushManager` property is subscribed to push events with your VAPID public key, which creates a `subscription` JSON object on the client side.
2. Your server uses the `web-push` gem to send a notification with the `subscription` obtained from the client and an optional payload (the message).
3. Your service worker is set up to receive `'push'` events. To trigger a desktop notification, the user has accepted the prompt to receive notifications from your site.

### Generating VAPID keys

Use `web-push` to generate a VAPID key pair (that has both a `public_key` and `private_key`) and save it on the server side.

```ruby
# One-time, on the server
vapid_key = WebPush.generate_key

# Save these in your application server settings
vapid_key.public_key
vapid_key.private_key

# Or you can save in PEM format if you prefer
vapid_key.to_pem
```

### Installing a service worker

Your application must use JavaScript to register a service worker script at an appropriate scope (root is recommended).

```javascript
navigator.serviceWorker.register('/service-worker.js')
```

### Subscribing to push notifications

The VAPID public key you generated earlier is made available to the client as a `UInt8Array`. To do this, one way would be to expose the urlsafe-decoded bytes from Ruby to JavaScript when rendering the HTML template.

```javascript
window.vapidPublicKey = new Uint8Array(<%= Base64.urlsafe_decode64(ENV['VAPID_PUBLIC_KEY']).bytes %>);
```

Your JavaScript code uses the `pushManager` interface to subscribe to push notifications, passing the VAPID public key to the subscription settings.

```javascript
// When serviceWorker is supported, installed, and activated,
// subscribe the pushManager property with the vapidPublicKey
navigator.serviceWorker.ready.then((serviceWorkerRegistration) => {
  serviceWorkerRegistration.pushManager
  .subscribe({
    userVisibleOnly: true,
    applicationServerKey: window.vapidPublicKey
  });
});
```

### Triggering a web push notification

In order to send web push notifications, the push subscription must be stored in the backend. Get the subscription with `pushManager.getSubscription()` and store it in your database.

Then you can use this gem to send web push messages:

```ruby
WebPush.payload_send(
  message: message,
  endpoint: subscription['endpoint'],
  p256dh: subscription['keys']['p256dh'],
  auth: subscription['keys']['auth'],
  vapid: {
    subject: "mailto:sender@example.com",
    public_key: ENV['VAPID_PUBLIC_KEY'],
    private_key: ENV['VAPID_PRIVATE_KEY']
  },
  ssl_timeout: 5, # optional value for Net::HTTP#ssl_timeout=
  open_timeout: 5, # optional value for Net::HTTP#open_timeout=
  read_timeout: 5 # optional value for Net::HTTP#read_timeout=
)
```

### Receiving the push event

Your `service-worker.js` script should respond to `'push'` events. One action it can take is to trigger desktop notifications by calling `showNotification` on the `registration` property.

```javascript
self.addEventListener('push', (event) => {
  // Get the push message
  var message = event.data;
  // Display a notification
  event.waitUntil(self.registration.showNotification('Example'));
});
```

Before the notifications can be displayed, the user must grant permission for [notifications](https://developer.mozilla.org/en-US/docs/Web/API/notification) in a browser prompt. Use something like this in your JavaScript code:

```javascript
Notification.requestPermission();
```

If everything worked, you should see a desktop notification triggered via web push. Yay!

## API

### With a payload

```ruby
message = {
  title: "Example",
  body: "Hello, world!",
  icon: "https://example.com/icon.png"
}

WebPush.payload_send(
  endpoint: "https://fcm.googleapis.com/gcm/send/eah7hak....",
  message: JSON.generate(message),
  p256dh: "BO/aG9nYXNkZmFkc2ZmZHNmYWRzZmFl...",
  auth: "aW1hcmthcmFpa3V6ZQ==",
  ttl: 600, # optional, ttl in seconds, defaults to 2419200 (4 weeks)
  urgency: 'normal' # optional, it can be very-low, low, normal, high, defaults to normal
)
```

### Without a payload

```ruby
WebPush.payload_send(
  endpoint: "https://fcm.googleapis.com/gcm/send/eah7hak....",
  p256dh: "BO/aG9nYXNkZmFkc2ZmZHNmYWRzZmFl...",
  auth: "aW1hcmthcmFpa3V6ZQ=="
)
```

### With VAPID

VAPID details are given as a hash with `:subject`, `:public_key`, and
`:private_key`. The `:subject` is a contact URI for the application server as either a "mailto:" or an "https:" address. The `:public_key` and `:private_key` should be passed as the base64-encoded values generated with `WebPush.generate_key`.

```ruby
WebPush.payload_send(
  endpoint: "https://fcm.googleapis.com/gcm/send/eah7hak....",
  message: "A message",
  p256dh: "BO/aG9nYXNkZmFkc2ZmZHNmYWRzZmFl...",
  auth: "aW1hcmthcmFpa3V6ZQ==",
  vapid: {
    subject: "mailto:sender@example.com",
    public_key: ENV['VAPID_PUBLIC_KEY'],
    private_key: ENV['VAPID_PRIVATE_KEY']
  }
)
```

### With VAPID in PEM format

This library also supports the PEM format for the VAPID keys:

```ruby
WebPush.payload_send(
  endpoint: "https://fcm.googleapis.com/gcm/send/eah7hak....",
  message: "A message",
  p256dh: "BO/aG9nYXNkZmFkc2ZmZHNmYWRzZmFl...",
  auth: "aW1hcmthcmFpa3V6ZQ==",
  vapid: {
    subject: "mailto:sender@example.com",
    pem: ENV['VAPID_KEYS']
  }
)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pushpad/web-push.

## Credits

This library is a fork of [zaru/webpush](https://github.com/zaru/webpush) actively maintained by [Pushpad](https://pushpad.xyz) with many improvements, bug fixes and frequent updates.
