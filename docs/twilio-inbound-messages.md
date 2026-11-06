# Twilio inbound message replays

Twilio SMS and WhatsApp callbacks use the message SID as the external message
identifier. Chatwoot accepts `SmsSid` or, when that field is blank, `MessageSid`.
Twilio documents `SmsSid` as a deprecated alias of `MessageSid` in its
[incoming message webhook parameters](https://www.twilio.com/docs/messaging/guides/webhook-request).

If a message with that SID is already stored in the receiving inbox, Chatwoot
skips the callback before updating the contact, selecting or creating a
conversation, or downloading attachments. This also applies when the original
conversation has since been resolved. A SID stored in another inbox does not
suppress delivery, and callbacks without either SID retain their existing
processing behavior.

This check handles replays after a message has been persisted. It does not
serialize concurrent callbacks: two workers can both pass the check before
either saves a message. There is no new lock, deduplication cache or database
constraint, so a failed save does not mark the SID as successfully processed.
This change does not deduplicate Telegram or LINE messages.
