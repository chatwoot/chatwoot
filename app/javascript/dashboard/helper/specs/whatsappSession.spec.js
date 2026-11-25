import {
  CAPABILITIES,
  SESSION_PROVIDERS,
  hasCapability,
  inboxCapabilities,
  isSessionProvider,
  isHttpUrl,
} from '../whatsappSession';

describe('whatsappSession', () => {
  describe('isSessionProvider', () => {
    it.each(SESSION_PROVIDERS)('is true for %s', provider => {
      expect(isSessionProvider(provider)).toBe(true);
    });

    it.each(['whatsapp_cloud', 'default', 'twilio', '', undefined])(
      'is false for %s',
      provider => {
        expect(isSessionProvider(provider)).toBe(false);
      }
    );
  });

  describe('inboxCapabilities', () => {
    it('returns the list the server put on the inbox', () => {
      expect(inboxCapabilities({ capabilities: ['edit', 'groups'] })).toEqual([
        'edit',
        'groups',
      ]);
    });

    it('returns an empty list for an inbox that carries none', () => {
      expect(inboxCapabilities({})).toEqual([]);
      expect(inboxCapabilities(null)).toEqual([]);
      expect(inboxCapabilities(undefined)).toEqual([]);
    });
  });

  // The server takes any http(s) URL with a host and decides separately whether a private
  // one is permitted, so the form must not refuse addresses it would have accepted.
  describe('isHttpUrl', () => {
    it('accepts a public address', () => {
      expect(isHttpUrl('https://free.uazapi.com')).toBe(true);
      expect(isHttpUrl('https://api.uazapi.com/v1')).toBe(true);
    });

    // The reason this helper exists: `isValidURL` needs a dot in the host, so it refused
    // the private address an operator who set `SAFE_FETCH_ALLOW_PRIVATE_NETWORK` may enter.
    it('accepts an address on the deployment own network', () => {
      expect(isHttpUrl('http://uazapi:3000')).toBe(true);
      expect(isHttpUrl('http://localhost:3000')).toBe(true);
      expect(isHttpUrl('http://[::1]:3000')).toBe(true);
      expect(isHttpUrl('http://192.168.1.10:3000')).toBe(true);
    });

    it('rejects anything that is not an http address', () => {
      expect(isHttpUrl('ftp://uazapi.com')).toBe(false);
      expect(isHttpUrl('uazapi.com')).toBe(false);
      expect(isHttpUrl('http://')).toBe(false);
      expect(isHttpUrl('')).toBe(false);
      expect(isHttpUrl(undefined)).toBe(false);
    });
  });

  describe('hasCapability', () => {
    const inbox = { capabilities: ['edit', 'reactions'] };

    it('is true for a declared capability', () => {
      expect(hasCapability(inbox, CAPABILITIES.EDIT)).toBe(true);
    });

    it('is false for one the provider did not declare', () => {
      expect(hasCapability(inbox, CAPABILITIES.GROUPS)).toBe(false);
    });

    // A gate on an inbox whose payload carries no capabilities must read false rather
    // than throw: the same components render for every channel type.
    it('is false when the inbox carries no capabilities at all', () => {
      expect(hasCapability({}, CAPABILITIES.EDIT)).toBe(false);
      expect(hasCapability(null, CAPABILITIES.EDIT)).toBe(false);
    });
  });
});
