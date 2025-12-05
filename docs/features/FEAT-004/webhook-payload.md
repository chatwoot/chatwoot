# Webhook Payload Documentation

This document provides comprehensive documentation for the webhook payload structure used by the Go WhatsApp Web
Multidevice application.

## Overview

The webhook system sends HTTP POST requests to configured URLs whenever WhatsApp events occur. Each webhook request
includes event data in JSON format and security headers for verification.

## Security

### HMAC Signature Verification

All webhook requests include an HMAC SHA256 signature for security verification:

- **Header**: `X-Hub-Signature-256`
- **Format**: `sha256={signature}`
- **Algorithm**: HMAC SHA256
- **Default Secret**: `secret` (configurable via `--webhook-secret` or `WHATSAPP_WEBHOOK_SECRET`)

### Verification Example (Node.js)

```javascript
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
    const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(payload, 'utf8')
        .digest('hex');

    const receivedSignature = signature.replace('sha256=', '');
    return crypto.timingSafeEqual(
        Buffer.from(expectedSignature, 'hex'),
        Buffer.from(receivedSignature, 'hex')
    );
}
```

### Verification Example (Python)

```python
import hmac
import hashlib

def verify_webhook_signature(payload, signature, secret):
    expected_signature = hmac.new(
        secret.encode('utf-8'),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    received_signature = signature.replace('sha256=', '')
    return hmac.compare_digest(expected_signature, received_signature)
```

## Common Payload Fields

All webhook payloads share these common fields:

| **Field**   | **Type** | **Description**                                                                                     |
|-------------|----------|-----------------------------------------------------------------------------------------------------|
| `sender_id` | string   | User part of sender JID (phone number, without `@s.whatsapp.net`)                                   |
| `chat_id`   | string   | User part of chat JID                                                                               |
| `from`      | string   | Full JID of the sender (e.g., `628123456789@s.whatsapp.net`)                                        |
| `from_lid`  | string   | (Optional) LID (Lidded ID) of sender when using identity-hidden accounts (e.g., `20036609675500@lid`) |
| `timestamp` | string   | RFC3339 formatted timestamp (e.g., `2023-10-15T10:30:00Z`)                                          |
| `pushname`  | string   | Display name of the sender                                                                          |

## Message Events

### Text Message

```json
{
  "sender_id": "628123456789",
  "chat_id": "628987654321",
  "from": "628123456789@s.whatsapp.net",
  "timestamp": "2023-10-15T10:30:00Z",
  "pushname": "John Doe",
  "message": {
    "text": "Hello, how are you?",
    "id": "3EB0C127D7BACC83D6A1",
    "replied_id": "",
    "quoted_message": ""
  }
}
```

### Reply Message

```json
{
  "sender_id": "628123456789",
  "chat_id": "628987654321",
  "from": "628123456789@s.whatsapp.net",
  "timestamp": "2023-10-15T10:35:00Z",
  "pushname": "John Doe",
  "message": {
    "text": "I'm doing great, thanks!",
    "id": "3EB0C127D7BACC83D6A2",
    "replied_id": "3EB0C127D7BACC83D6A1",
    "quoted_message": "Hello, how are you?"
  }
}
```

### Reaction Message

```json
{
  "sender_id": "628123456789",
  "chat_id": "628987654321",
  "from": "628123456789@s.whatsapp.net",
  "timestamp": "2023-10-15T10:40:00Z",
  "pushname": "John Doe",
  "reaction": {
    "message": "👍",
    "id": "3EB0C127D7BACC83D6A1"
  },
  "message": {
    "text": "",
    "id": "88760C69D1F35FEB239102699AE9XXXX",
    "replied_id": "",
    "quoted_message": ""
  }
}
```

## Receipt Events

Receipt events are triggered when messages receive acknowledgments such as delivery confirmations and read receipts.
These events use the `message.ack` event type and provide information about message status changes.

### Message Delivered

Triggered when a message is successfully delivered to the recipient's device.

```json
{
  "event": "message.ack",
  "payload": {
    "chat_id": "120363402106XXXXX@g.us",
    "from": "6289685XXXXXX@s.whatsapp.net in 120363402106XXXXX@g.us",
    "ids": [
      "3EB00106E8BE0F407E88EC"
    ],
    "receipt_type": "delivered",
    "receipt_type_description": "means the message was delivered to the device (but the user might not have noticed).",
    "sender_id": "6289685XXXXXX@s.whatsapp.net"
  },
  "timestamp": "2025-07-18T22:44:20Z"
}
```

### Message Read

Triggered when a message is read by the recipient (they opened the chat and saw the message).

```json
{
  "event": "message.ack",
  "payload": {
    "chat_id": "120363402106XXXXX@g.us",
    "from": "6289685XXXXXX@s.whatsapp.net in 120363402106XXXXX@g.us",
    "ids": [
      "3EB00106E8BE0F407E88EC"
    ],
    "receipt_type": "read",
    "receipt_type_description": "the user opened the chat and saw the message.",
    "sender_id": "6289685XXXXXX@s.whatsapp.net"
  },
  "timestamp": "2025-07-18T22:44:44Z"
}
```

### Receipt Event Fields

| **Field**                          | **Type** | **Description**                                                   |
|------------------------------------|----------|-------------------------------------------------------------------|
| `event`                            | string   | Always `"message.ack"` for receipt events                         |
| `payload.chat_id`                  | string   | Chat identifier (group or individual chat)                        |
| `payload.from`                     | string   | Sender information with chat context                              |
| `payload.ids`                      | array    | Array of message IDs that received the acknowledgment             |
| `payload.receipt_type`             | string   | Type of receipt: `"delivered"`, `"read"`, `"sender"`, `"retry"`, `"played"`, `"played_self"`, `"read_self"` |
| `payload.receipt_type_description` | string   | Human-readable description of the receipt type                    |
| `payload.sender_id`                | string   | JID of the message sender                                         |
| `timestamp`                        | string   | RFC3339 formatted timestamp when the receipt was received         |

### Receipt Types Explained

- **`delivered`**: Message was delivered to the device (but the user might not have noticed)
- **`read`**: User opened the chat and saw the message
- **`sender`**: Sent by your other devices when a message you sent is delivered to them
- **`retry`**: Message was delivered to the device, but decrypting the message failed
- **`read_self`**: Current user read a message from a different device, and has read receipts disabled in privacy settings
- **`played`**: View-once media was opened (by recipient or by you on another device)
- **`played_self`**: Current user opened a view-once media message from a different device, and has read receipts disabled

## Group Events

Group events are triggered when group metadata changes, including member join/leave events, admin promotions/demotions, and group settings updates. These events use the `group.participants` event type and provide comprehensive information about group changes.

### Group Member Join

Triggered when users join or are added to a group.

```json
{
  "event": "group.participants",
  "payload": {
    "chat_id": "120363402106XXXXX@g.us",
    "type": "join",
    "jids": [
      "6289685XXXXXX@s.whatsapp.net",
      "6289686YYYYYY@s.whatsapp.net"
    ]
  },
  "timestamp": "2025-07-28T10:30:00Z"
}
```

### Group Member Leave

Triggered when users leave or are removed from a group.

```json
{
  "event": "group.participants",
  "payload": {
    "chat_id": "120363402106XXXXX@g.us",
    "type": "leave",
    "jids": [
      "6289687ZZZZZZ@s.whatsapp.net"
    ]
  },
  "timestamp": "2025-07-28T10:32:00Z"
}
```

### Group Member Promotion

Triggered when users are promoted to admin.

```json
{
  "event": "group.participants",
  "payload": {
    "chat_id": "120363402106XXXXX@g.us",
    "type": "promote",
    "jids": [
      "6289688AAAAAA@s.whatsapp.net"
    ]
  },
  "timestamp": "2025-07-28T10:33:00Z"
}
```

### Group Member Demotion

Triggered when users are demoted from admin.

```json
{
  "event": "group.participants",
  "payload": {
    "chat_id": "120363402106XXXXX@g.us",
    "type": "demote",
    "jids": [
      "6289689BBBBBB@s.whatsapp.net"
    ]
  },
  "timestamp": "2025-07-28T10:34:00Z"
}
```

### Group Event Fields

| **Field**         | **Type** | **Description**                                              |
|-------------------|----------|--------------------------------------------------------------|
| `event`           | string   | Always `"group.participants"` for group events              |
| `payload.chat_id` | string   | Group identifier (e.g., `"120363402106XXXXX@g.us"`)         |
| `payload.type`    | string   | Action type: `"join"`, `"leave"`, `"promote"`, or `"demote"` |
| `payload.jids`    | array    | Array of user JIDs affected by this action                  |
| `timestamp`       | string   | RFC3339 formatted timestamp when the group event occurred   |

## Media Messages

### Image Message

```json
{
  "sender_id": "628123456789",
  "chat_id": "628123456789",
  "from": "628123456789@s.whatsapp.net",
  "timestamp": "2025-07-13T11:05:51Z",
  "pushname": "John Doe",
  "message": {
    "text": "",
    "id": "********************",
    "replied_id": "",
    "quoted_message": ""
  },
  "image": {
    "media_path": "statics/media/1752404751-ad9e37ac-c658-4fe5-8d25-ba4a3f4d58fd.jpe",
    "mime_type": "image/jpeg",
    "caption": "gijg"
  }
}
```

### Video Message

```json
{
  "sender_id": "628123456789",
  "chat_id": "628123456789",
  "from": "628123456789@s.whatsapp.net",
  "timestamp": "2025-07-13T11:07:24Z",
  "pushname": "Notification System",
  "message": {
    "text": "",
    "id": "********************",
    "replied_id": "",
    "quoted_message": ""
  },
  "video": {
    "media_path": "statics/media/1752404845-b9393cd1-8546-4df9-8a60-ee3276036aba.m4v",
    "mime_type": "video/mp4",
    "caption": "okk"
  }
}
```

### Audio Message

```json
{
  "sender_id": "628123456789",
  "chat_id": "628987654321",
  "from": "628123456789@s.whatsapp.net",
  "timestamp": "2023-10-15T10:55:00Z",
  "pushname": "John Doe",
  "message": {
    "text": "",
    "id": "3EB0C127D7BACC83D6A5",
    "replied_id": "",
    "quoted_message": ""
  },
  "audio": {
    "media_path": "statics/media/1752404905-b9393cd1-8546-4df9-8a60-ee3276036aba.m4v",
    "mime_type": "audio/ogg",
    "caption": "okk"
  }
}
```

### Document Message

```json
{
  "sender_id": "628123456789",
  "chat_id": "628987654321",
  "from": "628123456789@s.whatsapp.net",
  "timestamp": "2023-10-15T11:00:00Z",
  "pushname": "John Doe",
  "message": {
    "text": "",
    "id": "3EB0C127D7BACC83D6A6",
    "replied_id": "",
    "quoted_message": ""
  },
  "document": {
    "media_path": "statics/media/1752404965-b9393cd1-8546-4df9-8a60-ee3276036aba.m4v",
    "mime_type": "application/pdf",
    "caption": "okk"
  }
}
```

### Sticker Message

```json
{
  "chat_id": "628968XXXXXXXX",
  "from": "628968XXXXXXXX@s.whatsapp.net",
  "message": {
    "text": "",
    "id": "446AC2BAF2061B53E24CA526DBDFBD4E",
    "replied_id": "",
    "quoted_message": ""
  },
  "pushname": "Aldino Kemal",
  "sender_id": "628968XXXXXXXX",
  "sticker": {
    "media_path": "statics/media/1752404986-ff2464a6-c54c-4e6c-afde-c4c925ce3573.webp",
    "mime_type": "image/webp",
    "caption": ""
  },
  "timestamp": "2025-07-13T11:09:45Z"
}
```

## Special Message Types

### Contact Message

```json
{
  "chat_id": "6289XXXXXXXXX",
  "contact": {
    "displayName": "3Care",
    "vcard": "BEGIN:VCARD\nVERSION:3.0\nN:;3Care;;;\nFN:3Care\nTEL;type=Mobile:+62 132\nEND:VCARD",
    "contextInfo": {
      "expiration": 7776000,
      "ephemeralSettingTimestamp": 1751808692,
      "disappearingMode": {
        "initiator": 0,
        "trigger": 1,
        "initiatedByMe": true
      }
    }
  },
  "from": "6289XXXXXXXXX@s.whatsapp.net",
  "message": {
    "text": "",
    "id": "56B3DFF4994284634E7AAFEEF6F1A0A2",
    "replied_id": "",
    "quoted_message": ""
  },
  "pushname": "Aldino Kemal",
  "sender_id": "6289XXXXXXXXX",
  "timestamp": "2025-07-13T11:10:19Z"
}
```

### Location Message

```json
{
  "sender_id": "628123456789",
  "chat_id": "628987654321",
  "from": "John Doe",
  "timestamp": "2023-10-15T11:15:00Z",
  "pushname": "John Doe",
  "message": {
    "text": "",
    "id": "3EB0C127D7BACC83D6A9",
    "replied_id": "",
    "quoted_message": ""
  },
  "location": {
    "degreesLatitude": -6.2088,
    "degreesLongitude": 106.8456,
    "name": "Jakarta, Indonesia",
    "address": "Central Jakarta, DKI Jakarta, Indonesia"
  }
}
```

### Live Location Message

**Note**: Live location messages contain the raw WhatsApp protocol structure, sent as-is from the WhatsApp protocol.

```json
{
  "chat_id": "6289XXXXXXXXX",
  "from": "6289XXXXXXXXX@s.whatsapp.net",
  "location": {
    "degreesLatitude": -7.8050297,
    "degreesLongitude": 110.4549165,
    "JPEGThumbnail": "base64_image_thumbnail",
    "contextInfo": {
      "expiration": 7776000,
      "ephemeralSettingTimestamp": 1751808692,
      "disappearingMode": {
        "initiator": 0,
        "trigger": 1,
        "initiatedByMe": true
      }
    }
  },
  "message": {
    "text": "",
    "id": "94D13237B4D7F33EE4A63228BBD79EC0",
    "replied_id": "",
    "quoted_message": ""
  },
  "pushname": "Aldino Kemal",
  "sender_id": "6289685XXXXXX",
  "timestamp": "2025-07-13T11:11:22Z"
}
```

### List Message

List messages contain interactive lists that users can choose from. The WhatsApp list message structure is sent as-is from the WhatsApp protocol.

```json
{
  "sender_id": "628123456789",
  "chat_id": "628987654321",
  "from": "628123456789@s.whatsapp.net",
  "timestamp": "2023-10-15T11:20:00Z",
  "pushname": "John Doe",
  "message": {
    "text": "",
    "id": "3EB0C127D7BACC83D6AA",
    "replied_id": "",
    "quoted_message": ""
  },
  "list": {
    "title": "Choose an option",
    "description": "Please select from the following options",
    "buttonText": "View Options",
    "listType": 1,
    "sections": [
      {
        "title": "Section 1",
        "rows": [
          {
            "title": "Option 1",
            "description": "Description for option 1",
            "rowId": "option_1"
          }
        ]
      }
    ]
  }
}
```

### Order Message

Order messages contain e-commerce order information. The WhatsApp order message structure is sent as-is from the WhatsApp protocol.

```json
{
  "sender_id": "628123456789",
  "chat_id": "628987654321",
  "from": "628123456789@s.whatsapp.net",
  "timestamp": "2023-10-15T11:25:00Z",
  "pushname": "John Doe",
  "message": {
    "text": "",
    "id": "3EB0C127D7BACC83D6AB",
    "replied_id": "",
    "quoted_message": ""
  },
  "order": {
    "orderTitle": "Order #12345",
    "itemCount": 2,
    "message": "Thank you for your order!",
    "orderSurface": "CATALOG",
    "sellerJid": "628987654321@s.whatsapp.net"
  }
}
```

## Protocol Messages

### Delete For Me

Triggered when a message is deleted by the sender for themselves only.

```json
{
  "action": "event.delete_for_me",
  "deleted_message_id": "3EB0C127D7BACC83D6A8",
  "sender_id": "6289685XXXXXX",
  "from": "6289685XXXXXX@s.whatsapp.net",
  "chat_id": "6289685XXXXXX@s.whatsapp.net",
  "original_content": "Original message text",
  "original_sender": "6289685XXXXXX@s.whatsapp.net",
  "original_timestamp": "2025-07-13T10:00:00Z",
  "was_from_me": true,
  "original_media_type": "image",
  "original_filename": "photo.jpg",
  "timestamp": "2025-07-13T11:13:30Z"
}
```

**Note**: Fields `original_*` and `was_from_me` are only present if the message was found in the local database.

### Message Revoked

```json
{
  "action": "message_revoked",
  "chat_id": "6289XXXXXXXXX",
  "from": "6289XXXXXXXXX@s.whatsapp.net",
  "message": {
    "text": "",
    "id": "F4062F2BBCB19B7432195AD7080DA4E2",
    "replied_id": "",
    "quoted_message": ""
  },
  "pushname": "Aldino Kemal",
  "revoked_chat": "6289XXXXXXXXX@s.whatsapp.net",
  "revoked_from_me": true,
  "revoked_message_id": "94D13237B4D7F33EE4A63228BBD79EC0",
  "sender_id": "6289XXXXXXXXX",
  "timestamp": "2025-07-13T11:13:30Z"
}
```

### Message Edited

```json
{
  "action": "message_edited",
  "chat_id": "6289XXXXXXXXX",
  "edited_text": "hhhiawww",
  "from": "6289XXXXXXXXX@s.whatsapp.net",
  "message": {
    "text": "hhhiawww",
    "id": "D6271D8223A05B4DA6AE9FE3CD632543",
    "replied_id": "",
    "quoted_message": ""
  },
  "pushname": "Aldino Kemal",
  "sender_id": "6289XXXXXXXXX",
  "timestamp": "2025-07-13T11:14:19Z"
}
```

## Special Flags

### View Once Message

```json
{
  "sender_id": "628123456789",
  "chat_id": "628987654321",
  "from": "John Doe",
  "timestamp": "2023-10-15T11:40:00Z",
  "pushname": "John Doe",
  "message": {
    "text": "",
    "id": "3EB0C127D7BACC83D6B2",
    "replied_id": "",
    "quoted_message": ""
  },
  "image": {
    "media_path": "statics/media/1752405060-b9393cd1-8546-4df9-8a60-ee3276036aba.m4v",
    "mime_type": "image/jpeg",
    "caption": "okk"
  },
  "view_once": true
}
```

### Forwarded Message

```json
{
  "sender_id": "628123456789",
  "chat_id": "628987654321",
  "from": "John Doe",
  "timestamp": "2023-10-15T11:45:00Z",
  "pushname": "John Doe",
  "message": {
    "text": "This is a forwarded message",
    "id": "3EB0C127D7BACC83D6B3",
    "replied_id": "",
    "quoted_message": ""
  },
  "forwarded": true
}
```

## Integration Guide

### Setting Up Webhook Endpoint

1. **Configure webhook URL(s)**:

   ```bash
   ./whatsapp rest --webhook="https://yourapp.com/webhook"
   ```

2. **Set webhook secret**:

   ```bash
   ./whatsapp rest --webhook-secret="your-secret-key"
   ```

3. **Multiple webhooks**:

   ```bash
   ./whatsapp rest --webhook="https://app1.com/webhook,https://app2.com/webhook"
   ```

### Webhook Endpoint Implementation (Express.js)

```javascript
const express = require('express');
const crypto = require('crypto');
const app = express();

app.use(express.raw({type: 'application/json'}));

app.post('/webhook', (req, res) => {
    const signature = req.headers['x-hub-signature-256'];
    const payload = req.body;
    const secret = 'your-secret-key';

    // Verify signature
    if (!verifyWebhookSignature(payload, signature, secret)) {
        return res.status(401).send('Unauthorized');
    }

    // Parse and process webhook data
    const data = JSON.parse(payload);
    console.log('Received webhook:', data);

    // Handle different event types
    if (data.event === 'message.ack') {
        console.log(`Message ${data.payload.receipt_type}:`, {
            chat_id: data.payload.chat_id,
            message_ids: data.payload.ids,
            description: data.payload.receipt_type_description
        });
    } else if (data.event === 'group.participants') {
        console.log(`Group ${data.payload.type} event:`, {
            chat_id: data.payload.chat_id,
            type: data.payload.type,
            affected_users: data.payload.jids
        });
        
        // Handle specific group actions
        switch (data.payload.type) {
            case 'join':
                console.log(`${data.payload.jids.length} users joined group ${data.payload.chat_id}`);
                // Auto-greet new members
                data.payload.jids.forEach(jid => {
                    console.log(`Welcome ${jid} to the group!`);
                });
                break;
            case 'leave':
                console.log(`${data.payload.jids.length} users left group ${data.payload.chat_id}`);
                // Update member database
                break;
            case 'promote':
                console.log(`${data.payload.jids.length} users promoted in group ${data.payload.chat_id}`);
                // Notify about new admins
                break;
            case 'demote':
                console.log(`${data.payload.jids.length} users demoted in group ${data.payload.chat_id}`);
                // Handle admin removal
                break;
        }
    } else if (data.action === 'event.delete_for_me') {
        console.log('Message deleted:', data.deleted_message_id);
    } else if (data.action === 'message_revoked') {
        console.log('Message revoked:', data.revoked_message_id);
    } else if (data.message) {
        console.log('New message:', data.message.text);
    }

    res.status(200).send('OK');
});

function verifyWebhookSignature(payload, signature, secret) {
    const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(payload, 'utf8')
        .digest('hex');

    const receivedSignature = signature.replace('sha256=', '');
    return crypto.timingSafeEqual(
        Buffer.from(expectedSignature, 'hex'),
        Buffer.from(receivedSignature, 'hex')
    );
}

app.listen(3001, () => {
    console.log('Webhook server listening on port 3001');
});
```

### Error Handling

The webhook system includes retry logic with exponential backoff:

- **Timeout**: 10 seconds per request
- **Max Attempts**: 5 retries
- **Backoff**: Exponential (1s, 2s, 4s, 8s, 16s)

Ensure your webhook endpoint:

- Responds within 10 seconds
- Returns HTTP 2xx status for successful processing
- Handles duplicate events gracefully
- Validates signatures for security

## Configuration

### Environment Variables

```bash
# Single webhook URL
WHATSAPP_WEBHOOK=https://yourapp.com/webhook

# Multiple webhook URLs (comma-separated)
WHATSAPP_WEBHOOK=https://app1.com/webhook,https://app2.com/webhook

# Webhook secret for HMAC verification
WHATSAPP_WEBHOOK_SECRET=your-super-secret-key
```

### Command Line Flags

```bash
# Single webhook
./whatsapp rest --webhook="https://yourapp.com/webhook"

# Multiple webhooks
./whatsapp rest --webhook="https://app1.com/webhook,https://app2.com/webhook"

# Custom secret
./whatsapp rest --webhook-secret="your-secret-key"
```

## Best Practices

1. **Always verify signatures** to ensure webhook authenticity
2. **Handle duplicates** - the same event might be sent multiple times
3. **Process quickly** - respond within 10 seconds to avoid timeouts
4. **Log errors** for debugging webhook integration issues
5. **Use HTTPS** for webhook URLs to ensure secure transmission
6. **Store media files** locally if you need to process them later
7. **Implement proper error handling** for different event types

## Troubleshooting

### Common Issues

1. **Webhook not receiving events**:
    - Check webhook URL is accessible from the internet
    - Verify webhook configuration
    - Check firewall and network settings

2. **Signature verification fails**:
    - Ensure webhook secret matches configuration
    - Use raw request body for signature calculation
    - Check HMAC implementation

3. **Timeouts**:
    - Optimize webhook processing speed
    - Implement asynchronous processing
    - Return response quickly, process in background

4. **Missing media files**:
    - Check media storage path configuration
    - Ensure sufficient disk space
    - Verify file permissions

### Debug Logging

Enable debug mode to see webhook logs:

```bash
./whatsapp rest --debug=true --webhook="https://yourapp.com/webhook"
```

This will show detailed logs of webhook delivery attempts and errors.

## Webhook Event Types Summary

The following table summarizes all webhook event types sent by the system:

| **Category** | **Event/Action** | **Description** | **Key Fields** |
|--------------|------------------|-----------------|----------------|
| **Messages** | (regular) | Text, media, contact, location messages | `message`, `sender_id`, `chat_id`, `from` |
| **Messages** | `live_location` | Live location updates | `live_location` (raw protocol) |
| **Messages** | `list` | Interactive list messages | `list` (raw protocol) |
| **Messages** | `order` | E-commerce order messages | `order` (raw protocol) |
| **Messages** | `reaction` | Message reactions (emoji) | `reaction.message`, `reaction.id` |
| **Messages** | `view_once=true` | View-once media messages | `view_once`, `image`/`video` |
| **Messages** | `forwarded=true` | Forwarded messages | `forwarded` |
| **Receipts** | `event: message.ack` | Message acknowledgments | `payload.receipt_type`, `payload.ids` |
| **Receipts** | `receipt_type: delivered` | Message delivered to device | `payload.ids` |
| **Receipts** | `receipt_type: read` | Message read by user | `payload.ids` |
| **Receipts** | `receipt_type: sender` | Delivered to sender's other devices | `payload.ids` |
| **Receipts** | `receipt_type: retry` | Decryption failed, retry needed | `payload.ids` |
| **Receipts** | `receipt_type: played` | View-once media opened | `payload.ids` |
| **Receipts** | `receipt_type: played_self` | Media opened on another device | `payload.ids` |
| **Receipts** | `receipt_type: read_self` | Read on another device (receipts off) | `payload.ids` |
| **Groups** | `event: group.participants` | Group membership changes | `payload.type`, `payload.jids` |
| **Groups** | `type: join` | Users joined group | `payload.jids`, `payload.chat_id` |
| **Groups** | `type: leave` | Users left group | `payload.jids`, `payload.chat_id` |
| **Groups** | `type: promote` | Users promoted to admin | `payload.jids`, `payload.chat_id` |
| **Groups** | `type: demote` | Users demoted from admin | `payload.jids`, `payload.chat_id` |
| **Protocol** | `action: event.delete_for_me` | Message deleted by sender | `deleted_message_id`, `original_*` |
| **Protocol** | `action: message_revoked` | Message deleted for everyone | `revoked_message_id`, `revoked_from_me` |
| **Protocol** | `action: message_edited` | Message edited by sender | `edited_text`, `message.id` |

### Message Media Types

The following media types are supported in webhook payloads:

- **`image`**: Image messages with optional caption
- **`video`**: Video messages with optional caption
- **`audio`**: Audio messages (including voice notes)
- **`document`**: Document/file messages with optional caption
- **`sticker`**: Sticker messages (static or animated)

Each media type includes:
- `media_path`: Local file path where media is stored
- `mime_type`: MIME type of the media file
- `caption`: Optional caption text (empty string if not present)
