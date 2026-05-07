/* eslint-disable no-restricted-globals */
/**
 * Pure helpers for the PWA push notification pipeline.
 *
 * These functions are duplicated verbatim inside `public/sw.js` so the service
 * worker (which cannot import ES modules without the `type: 'module'` flag and
 * a bigger compatibility footprint) stays a single classic script. Vitest
 * exercises this canonical copy; keep both in sync when editing.
 *
 * `self` is the canonical global in service worker contexts and is also
 * available on `window` in browsers; the lint rule is disabled at the file
 * level because every reference here is intentional cross-context code.
 */

export const NOTIFICATION_ACTIONS = Object.freeze({
  REPLY: 'reply',
  MARK_READ: 'mark_read',
  OPEN: 'open',
});

const DEFAULT_VIBRATE_PATTERN = [300, 150, 300, 150, 450];
const DEFAULT_ICON = '/android-icon-192x192.png';
const DEFAULT_BADGE = '/favicon-96x96.png';
const REPLY_PLACEHOLDER_FALLBACK = 'Reply...';

const trimText = value => (typeof value === 'string' ? value.trim() : '');

export const buildNotificationKey = payload => {
  if (!payload) return '';
  return [payload.tag, payload.title, payload.body, payload.url]
    .filter(Boolean)
    .join('::');
};

export const sanitizeReplyText = text => {
  if (typeof text !== 'string') return '';
  // Collapse newlines/whitespace and bound length so pushes never DoS the API.
  return text.replace(/\r/g, '').trim().slice(0, 4000);
};

export const buildReplyPlaceholder = (payload, fallback = 'Reply') => {
  const senderName = trimText(payload?.sender?.name);
  if (!senderName) return `${fallback}…`;
  return `${fallback} ${senderName}…`;
};

export const isReplyAllowed = payload => Boolean(payload?.reply_enabled);

const buildReplyActionDescriptor = (payload, labels) => ({
  action: NOTIFICATION_ACTIONS.REPLY,
  title: labels.reply || 'Reply',
  type: 'text',
  placeholder: buildReplyPlaceholder(payload, labels.replyPlaceholder),
  icon: '/favicon-96x96.png',
});

const buildMarkReadActionDescriptor = labels => ({
  action: NOTIFICATION_ACTIONS.MARK_READ,
  title: labels.markRead || 'Mark as read',
  icon: '/favicon-96x96.png',
});

export const buildNotificationActions = (payload, labels = {}) => {
  if (!isReplyAllowed(payload)) return [];
  return [
    buildReplyActionDescriptor(payload, labels),
    buildMarkReadActionDescriptor(labels),
  ];
};

export const buildNotificationOptions = (payload, labels = {}) => {
  const senderAvatar = trimText(payload?.sender?.avatar_url);
  const icon = senderAvatar || DEFAULT_ICON;

  return {
    body: payload?.body || '',
    tag: payload?.tag,
    icon,
    badge: DEFAULT_BADGE,
    image: senderAvatar || undefined,
    timestamp: payload?.timestamp || Date.now(),
    renotify: false,
    requireInteraction: false,
    silent: false,
    vibrate:
      Array.isArray(payload?.vibrate) && payload.vibrate.length
        ? payload.vibrate
        : DEFAULT_VIBRATE_PATTERN,
    actions: buildNotificationActions(payload, labels),
    data: {
      url: payload?.url,
      account_id: payload?.account_id,
      conversation_id: payload?.conversation_id,
      conversation_uuid: payload?.conversation_uuid,
      notification_id: payload?.notification_id,
      notification_type: payload?.notification_type,
      reply_enabled: isReplyAllowed(payload),
      sender: payload?.sender || null,
      replyPlaceholder: labels.replyPlaceholder || REPLY_PLACEHOLDER_FALLBACK,
    },
  };
};

const resolveOrigin = origin => {
  if (origin) return origin;
  if (typeof self !== 'undefined' && self.location) return self.location.origin;
  return '';
};

export const buildReplyApiUrl = (data, origin) => {
  if (!data?.account_id || !data?.conversation_id) return null;
  return `${resolveOrigin(origin)}/api/v1/accounts/${data.account_id}/conversations/${data.conversation_id}/messages`;
};

export const buildMarkReadApiUrl = (data, origin) => {
  if (!data?.account_id || !data?.notification_id) return null;
  return `${resolveOrigin(origin)}/api/v1/accounts/${data.account_id}/notifications/${data.notification_id}`;
};

export const buildOpenWindowUrl = (data, action, origin) => {
  if (!data?.url) return null;
  const baseOrigin =
    origin ||
    (typeof self !== 'undefined' && self.location ? self.location.origin : '');
  let target;
  try {
    target = new URL(data.url, baseOrigin);
  } catch {
    return null;
  }

  if (action === NOTIFICATION_ACTIONS.REPLY) {
    target.searchParams.set('focus_reply', '1');
  }
  return target.toString();
};

export const buildAuthHeaders = (credentials, extras = {}) => {
  if (!credentials) return null;
  const required = ['accessToken', 'client', 'uid'];
  if (required.some(key => !credentials[key])) return null;

  return {
    'Content-Type': 'application/json',
    'access-token': credentials.accessToken,
    'token-type': credentials.tokenType || 'Bearer',
    client: credentials.client,
    expiry: credentials.expiry || '',
    uid: credentials.uid,
    ...extras,
  };
};

export const buildReplyRequestBody = (replyText, data) => {
  const sanitized = sanitizeReplyText(replyText);
  if (!sanitized) return null;
  return JSON.stringify({
    content: sanitized,
    private: false,
    echo_id: `pwa-reply-${data?.notification_id || ''}-${Date.now()}`,
  });
};
