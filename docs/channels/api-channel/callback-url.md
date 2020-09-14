---
path: '/docs/channels/api/callback-url'
title: 'Callback URL and message payload'
---

When a new message is created in the API channel, you will get a POST request to the Callback URL specified while creating the API channel. The payload would look like this.

**Event type**: `message_created`

```json
{
  "id": 0,
  "content": "This is a incoming message from API Channel",
  "created_at": "2020-08-30T15:43:04.000Z",
  "message_type": "incoming",
  "content_type": null,
  "content_attributes": {},
  "source_id": null,
  "sender": {
    "id": 0,
    "name": "contact-name",
    "avatar": "",
    "type": "contact"
  },
  "inbox": {
    "id": 0,
    "name": "API Channel"
  },
  "conversation": {
    "additional_attributes": null,
    "channel": "Channel::Api",
    "id": 0,
    "inbox_id": 0,
    "status": "open",
    "agent_last_seen_at": 0,
    "contact_last_seen_at": 0,
    "timestamp": 0
  },
  "account": {
    "id": 1,
    "name": "API testing"
  },
  "event": "message_created"
}
```
