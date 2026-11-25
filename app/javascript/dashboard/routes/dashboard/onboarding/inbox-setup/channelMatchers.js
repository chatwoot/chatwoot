import { INBOX_TYPES } from 'dashboard/helper/inbox';

// A detected channel maps to a real inbox when they share a channel_type. Gmail
// and Outlook both use Channel::Email, so for email we also match on provider.
// `stub` is a channel's `{ channel_type, provider }` shape (e.g. channel.inbox).

// Returns the matching inbox (not a boolean) so callers can show the connected
// account's real name rather than the detected handle.
export const findConnectedInbox = (inboxes, stub) =>
  inboxes.find(
    inbox =>
      inbox.channel_type === stub?.channel_type &&
      (stub?.channel_type !== INBOX_TYPES.EMAIL ||
        inbox.provider === stub?.provider)
  );

export const isChannelConnected = (inboxes, stub) =>
  Boolean(stub) && Boolean(findConnectedInbox(inboxes, stub));
