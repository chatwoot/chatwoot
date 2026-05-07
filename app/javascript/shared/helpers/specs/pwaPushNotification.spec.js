import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  NOTIFICATION_ACTIONS,
  buildAuthHeaders,
  buildMarkReadApiUrl,
  buildNotificationActions,
  buildNotificationKey,
  buildNotificationOptions,
  buildOpenWindowUrl,
  buildReplyApiUrl,
  buildReplyPlaceholder,
  buildReplyRequestBody,
  isReplyAllowed,
  sanitizeReplyText,
} from 'shared/helpers/pwaPushNotification';

const buildPayload = overrides => ({
  title: 'New message',
  body: 'John: Hi there',
  tag: 'conversation_1_42',
  url: '/app/accounts/1/conversations/42',
  account_id: 1,
  conversation_id: 42,
  conversation_uuid: 'abcd-uuid',
  notification_id: 99,
  notification_type: 'assigned_conversation_new_message',
  reply_enabled: true,
  sender: { name: 'John', avatar_url: 'https://cdn.example/john.jpg' },
  timestamp: 1700000000000,
  ...overrides,
});

const labels = {
  reply: 'Reply',
  markRead: 'Mark as read',
  replyPlaceholder: 'Reply to',
};

describe('pwaPushNotification helpers', () => {
  describe('buildNotificationKey', () => {
    it('joins the identifying fields with double colons', () => {
      expect(buildNotificationKey(buildPayload())).toBe(
        'conversation_1_42::New message::John: Hi there::/app/accounts/1/conversations/42'
      );
    });

    it('skips empty fields', () => {
      expect(
        buildNotificationKey({ title: 'Hi', body: '', tag: '', url: '/a' })
      ).toBe('Hi::/a');
    });

    it('returns empty string for falsy payload', () => {
      expect(buildNotificationKey(null)).toBe('');
    });
  });

  describe('sanitizeReplyText', () => {
    it('trims whitespace and removes carriage returns', () => {
      expect(sanitizeReplyText('  hello\r\nworld  ')).toBe('hello\nworld');
    });

    it('limits length to 4000 chars', () => {
      const long = 'a'.repeat(5000);
      expect(sanitizeReplyText(long)).toHaveLength(4000);
    });

    it('returns empty for non-strings', () => {
      expect(sanitizeReplyText(undefined)).toBe('');
      expect(sanitizeReplyText(null)).toBe('');
      expect(sanitizeReplyText(42)).toBe('');
    });
  });

  describe('buildReplyPlaceholder', () => {
    it('appends the sender name when available', () => {
      expect(buildReplyPlaceholder(buildPayload(), 'Reply to')).toBe(
        'Reply to John…'
      );
    });

    it('falls back to a generic prompt when sender is missing', () => {
      expect(
        buildReplyPlaceholder({ sender: { name: '   ' } }, 'Reply to')
      ).toBe('Reply to…');
      expect(buildReplyPlaceholder({}, 'Reply to')).toBe('Reply to…');
    });
  });

  describe('isReplyAllowed', () => {
    it('returns true only when reply_enabled is truthy', () => {
      expect(isReplyAllowed(buildPayload({ reply_enabled: true }))).toBe(true);
      expect(isReplyAllowed(buildPayload({ reply_enabled: false }))).toBe(
        false
      );
      expect(isReplyAllowed(null)).toBe(false);
    });
  });

  describe('buildNotificationActions', () => {
    it('returns reply + mark_read actions when reply is allowed', () => {
      const actions = buildNotificationActions(buildPayload(), labels);
      expect(actions).toHaveLength(2);
      expect(actions[0]).toMatchObject({
        action: NOTIFICATION_ACTIONS.REPLY,
        type: 'text',
        title: 'Reply',
      });
      expect(actions[0].placeholder).toContain('John');
      expect(actions[1]).toMatchObject({
        action: NOTIFICATION_ACTIONS.MARK_READ,
        title: 'Mark as read',
      });
    });

    it('still returns mark_read when reply is disabled', () => {
      expect(
        buildNotificationActions(buildPayload({ reply_enabled: false }), labels)
      ).toEqual([
        {
          action: NOTIFICATION_ACTIONS.MARK_READ,
          title: 'Mark as read',
          icon: '/favicon-96x96.png',
        },
      ]);
    });

    it('returns no actions when no action context is available', () => {
      expect(
        buildNotificationActions(
          buildPayload({
            reply_enabled: false,
            account_id: null,
            notification_id: null,
          }),
          labels
        )
      ).toEqual([]);
    });
  });

  describe('buildNotificationOptions', () => {
    it('uses sender avatar as icon and image when available', () => {
      const options = buildNotificationOptions(buildPayload(), labels);
      expect(options.icon).toBe('https://cdn.example/john.jpg');
      expect(options.image).toBe('https://cdn.example/john.jpg');
      expect(options.body).toBe('John: Hi there');
      expect(options.tag).toBe('conversation_1_42');
      expect(options.timestamp).toBe(1700000000000);
      expect(options.actions).toHaveLength(2);
    });

    it('falls back to the bundled icon when no avatar is provided', () => {
      const options = buildNotificationOptions(
        buildPayload({ sender: { name: 'John' } }),
        labels
      );
      expect(options.icon).toBe('/android-icon-192x192.png');
      expect(options.image).toBeUndefined();
    });

    it('threads conversation context through to the notification data bag', () => {
      const options = buildNotificationOptions(buildPayload(), labels);
      expect(options.data).toMatchObject({
        url: '/app/accounts/1/conversations/42',
        account_id: 1,
        conversation_id: 42,
        notification_id: 99,
        reply_enabled: true,
      });
    });

    it('uses the default vibrate pattern when none is provided', () => {
      const options = buildNotificationOptions(buildPayload(), labels);
      expect(options.vibrate).toEqual([300, 150, 300, 150, 450]);
    });

    it('respects an explicit vibrate pattern from the payload', () => {
      const options = buildNotificationOptions(
        buildPayload({ vibrate: [100, 50, 100] }),
        labels
      );
      expect(options.vibrate).toEqual([100, 50, 100]);
    });
  });

  describe('buildOpenWindowUrl', () => {
    beforeEach(() => {
      vi.stubGlobal('self', { location: { origin: 'https://chat.example' } });
    });

    it('appends focus_reply when the action is reply', () => {
      const url = buildOpenWindowUrl(
        buildPayload(),
        NOTIFICATION_ACTIONS.REPLY
      );
      expect(url).toContain('focus_reply=1');
    });

    it('keeps the URL unchanged for the open action', () => {
      const url = buildOpenWindowUrl(buildPayload(), NOTIFICATION_ACTIONS.OPEN);
      expect(url).not.toContain('focus_reply');
      expect(url).toContain('/app/accounts/1/conversations/42');
    });

    it('returns null when no url is set', () => {
      expect(
        buildOpenWindowUrl({ ...buildPayload(), url: null }, 'open')
      ).toBeNull();
    });
  });

  describe('buildReplyApiUrl & buildMarkReadApiUrl', () => {
    it('builds the conversation messages endpoint', () => {
      expect(buildReplyApiUrl(buildPayload(), 'https://chat.example')).toBe(
        'https://chat.example/api/v1/accounts/1/conversations/42/messages'
      );
    });

    it('builds the notification update endpoint', () => {
      expect(buildMarkReadApiUrl(buildPayload(), 'https://chat.example')).toBe(
        'https://chat.example/api/v1/accounts/1/notifications/99'
      );
    });

    it('returns null when context is missing', () => {
      expect(buildReplyApiUrl({}, 'https://x')).toBeNull();
      expect(buildMarkReadApiUrl({}, 'https://x')).toBeNull();
    });
  });

  describe('buildAuthHeaders', () => {
    it('returns DeviseTokenAuth headers when credentials are complete', () => {
      const headers = buildAuthHeaders({
        accessToken: 'tok',
        client: 'cli',
        uid: 'me@example.com',
        expiry: '12345',
        tokenType: 'Bearer',
      });
      expect(headers).toMatchObject({
        'Content-Type': 'application/json',
        'access-token': 'tok',
        'token-type': 'Bearer',
        client: 'cli',
        uid: 'me@example.com',
        expiry: '12345',
      });
    });

    it('returns null if any required credential is missing', () => {
      expect(buildAuthHeaders({ accessToken: 'tok' })).toBeNull();
      expect(buildAuthHeaders(null)).toBeNull();
    });
  });

  describe('buildReplyRequestBody', () => {
    it('serializes a JSON body containing the sanitized reply text', () => {
      const body = buildReplyRequestBody('  hello  ', { notification_id: 7 });
      const parsed = JSON.parse(body);
      expect(parsed.content).toBe('hello');
      expect(parsed.private).toBe(false);
      expect(parsed.echo_id).toMatch(/^pwa-reply-7-\d+$/);
    });

    it('returns null for empty replies', () => {
      expect(buildReplyRequestBody('   ', {})).toBeNull();
      expect(buildReplyRequestBody(null, {})).toBeNull();
    });
  });
});
