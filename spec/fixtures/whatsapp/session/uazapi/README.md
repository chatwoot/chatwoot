# Uazapi capture

Recorded on 19/08/2026 against a live instance, with a throwaway number, a webhook
delivered through a tunnel and 51 events driven by hand: pairing by QR, connecting,
messages in both directions, media, a reaction, an edit, a revoke, receipts, presence, a
group and a disconnect. `webhook/` holds the bodies the provider posted; `rest/` holds
what its endpoints answered.

Everything here is redacted: phone numbers, names, ids, tokens, media URLs, thumbnails
and QR images were replaced with stand-ins, consistently, so a value that was the same
twice in the capture is still the same twice here. Nothing in this directory is a real
credential.

The provider documents none of these shapes, which is why they are committed. What the
translator and the backend are written against is this capture, not a specification, and
a golden body is the only thing that catches the day one of them changes.

## What the capture settled

**Envelopes.** Three shapes, keyed by `EventType`: `connection` carries `instance`,
`messages` carries `message` (plus a large CRM object nothing here reads), and
`messages_update` / `presence` / `groups` carry `event`. Every body also carries `token`,
the instance credential, which is why the controller strips it before the body goes any
further.

**`event_id` exists only on `connection`**, so it cannot be a general deduplication key.

**Ordering.** Nothing in these payloads is monotonic per chat: a message carries
milliseconds, a receipt carries whole seconds in one shape and an ISO string in another,
and presence carries no time at all. That is what decided fazer-ai/chatwoot#373 the way it
was decided: an event whose message is not stored yet waits and is retried, rather than
being ordered against a cursor there is nothing to build.

**Messages.**

- Discriminate on `messageType`. A location is `type: "text"`; a shared contact is
  `type: "media"`.
- Inbound text is `Conversation`, outbound is `ExtendedTextMessage`.
- `sender` alternates between the LID and the phone JID inside one chat for no visible
  reason. `sender_lid` and `sender_pn` are both always there and always right.
- `chatlid` is only sent on incoming messages, so the chat is addressed by `chatid`.
- An edit is an ordinary message with a new id and `edited` naming the original.
- A reaction is `type: "reaction"`, with `reaction` holding the target id and `text` the
  emoji.
- `content.URL` is the encrypted blob on WhatsApp's CDN. `/message/download` is the only
  way to the bytes, and it transcodes: a voice note recorded as `audio/ogg; codecs=opus`
  came back as `audio/mpeg`.
- Our own sends come back with `wasSentByApi: true` and the `track_id` we sent, which is
  why the webhook subscription excludes them.

**Receipts.** `event.Type` is not stable in case (a peer reading answers `Read`, our own
`/message/markread` answers `read`); the top-level `state` was consistent in both.
`FileDownloaded` is the provider's own bookkeeping. `MessageIDs` is a batch and it gets
big: opening a chat produced one event naming 246 messages, most of them from before the
inbox existed, which is why a receipt that matches nothing is not treated as an event that
arrived too early.

**Groups.** A creation carries `Type: "new"` and the whole roster. A membership change
carries no `Type` at all: which of `Join` / `Leave` / `Promote` / `Demote` is populated is
the signal, and each names the same people twice, once by number and once by LID.

**Presence.** Everything captured was our own (`IsFromMe: true`): `/message/presence`
comes back on the webhook naming the peer's chat.

**Endpoints that are not there.** `/instance/logout` and `/group/invitelink` both answer
405, which is why logging out is a disconnect and why `group_invites` is not a declared
capability.
