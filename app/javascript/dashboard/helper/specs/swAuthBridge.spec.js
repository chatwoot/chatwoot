import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import Cookies from 'js-cookie';
import {
  PWA_AUTH_DB_NAME,
  buildSessionFromCookie,
  clearSession,
  readSession,
  syncSessionToServiceWorker,
  writeSession,
} from 'dashboard/helper/swAuthBridge';

const SAMPLE_SESSION_COOKIE = JSON.stringify({
  'access-token': 'tok-abc',
  'token-type': 'Bearer',
  client: 'cli-123',
  expiry: '1700000000',
  uid: 'agent@example.com',
});

const setOrigin = origin => {
  Object.defineProperty(window, 'location', {
    configurable: true,
    value: { ...window.location, origin },
  });
};

describe('swAuthBridge', () => {
  beforeEach(async () => {
    Cookies.remove('cw_d_session_info');
    await clearSession();
    setOrigin('https://chat.example');
  });

  afterEach(async () => {
    await clearSession();
    Cookies.remove('cw_d_session_info');
    indexedDB.deleteDatabase(PWA_AUTH_DB_NAME);
  });

  describe('buildSessionFromCookie', () => {
    it('returns null when the auth cookie is missing', () => {
      expect(buildSessionFromCookie()).toBeNull();
    });

    it('returns null when the cookie cannot be parsed', () => {
      Cookies.set('cw_d_session_info', '{not json');
      expect(buildSessionFromCookie()).toBeNull();
    });

    it('extracts credentials and origin from the auth cookie', () => {
      Cookies.set('cw_d_session_info', SAMPLE_SESSION_COOKIE);
      const session = buildSessionFromCookie({
        accountId: 7,
        userId: 12,
      });
      expect(session).toMatchObject({
        accountId: 7,
        userId: 12,
        origin: 'https://chat.example',
        credentials: {
          accessToken: 'tok-abc',
          tokenType: 'Bearer',
          client: 'cli-123',
          uid: 'agent@example.com',
          expiry: '1700000000',
        },
      });
      expect(session.updatedAt).toEqual(expect.any(Number));
    });

    it('returns null when the access token is missing', () => {
      Cookies.set(
        'cw_d_session_info',
        JSON.stringify({ client: 'x', uid: 'y' })
      );
      expect(buildSessionFromCookie()).toBeNull();
    });
  });

  describe('IndexedDB read/write/clear', () => {
    it('round-trips session data through IndexedDB', async () => {
      const payload = { credentials: { accessToken: 'a' }, accountId: 1 };
      const ok = await writeSession(payload);
      expect(ok).toBe(true);

      const stored = await readSession();
      expect(stored).toEqual(payload);

      await clearSession();
      expect(await readSession()).toBeNull();
    });
  });

  describe('syncSessionToServiceWorker', () => {
    it('persists the session and posts a message to the SW controller', async () => {
      Cookies.set('cw_d_session_info', SAMPLE_SESSION_COOKIE);
      const postMessage = vi.fn();
      Object.defineProperty(navigator, 'serviceWorker', {
        configurable: true,
        value: { controller: { postMessage } },
      });

      const ok = await syncSessionToServiceWorker({ accountId: 9 });
      expect(ok).toBe(true);

      const stored = await readSession();
      expect(stored?.credentials?.accessToken).toBe('tok-abc');
      expect(stored?.accountId).toBe(9);
      expect(postMessage).toHaveBeenCalledWith({
        type: 'PWA_AUTH_UPDATED',
        accountId: 9,
      });
    });

    it('returns false and skips IDB write when the auth cookie is absent', async () => {
      const ok = await syncSessionToServiceWorker();
      expect(ok).toBe(false);
      expect(await readSession()).toBeNull();
    });
  });
});
