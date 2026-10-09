import Cookies from 'js-cookie';
import { IFrameHelper } from '../sdk/IFrameHelper';
import './sdk';

vi.mock('../sdk/IFrameHelper', () => ({
  IFrameHelper: {
    createFrame: vi.fn(),
    getAppFrame: vi.fn(() => ({ src: '' })),
    getUrl: vi.fn(() => 'https://app.chatwoot.com/widget'),
    sendMessage: vi.fn(),
    events: {
      toggleBubble: vi.fn(),
    },
  },
}));

describe('$chatwoot SDK', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    delete window.$chatwoot;
    window.chatwootSettings = {};
    vi.spyOn(Cookies, 'get').mockReturnValue(undefined);
    vi.spyOn(Cookies, 'set').mockImplementation(() => {});
    vi.spyOn(Cookies, 'remove').mockImplementation(() => {});

    window.chatwootSDK.run({
      baseUrl: 'https://app.chatwoot.com',
      websiteToken: 'website-token',
    });
  });

  afterEach(() => {
    delete window.$chatwoot;
    delete window.chatwootSettings;
    vi.restoreAllMocks();
  });

  describe('setUser', () => {
    it('updates the SDK identity synchronously', () => {
      const user = { name: 'Pranav' };

      const result = window.$chatwoot.setUser('first-user', user);

      expect(result).toBeUndefined();
      expect(window.$chatwoot.identifier).toBe('first-user');
      expect(window.$chatwoot.user).toBe(user);
      expect(IFrameHelper.sendMessage).toHaveBeenCalledWith('set-user', {
        identifier: 'first-user',
        user,
      });
    });

    it('keeps the latest identity after consecutive calls', () => {
      const firstUser = { name: 'First user' };
      const secondUser = { name: 'Second user' };

      window.$chatwoot.setUser('first-user', firstUser);
      window.$chatwoot.setUser('second-user', secondUser);

      expect(window.$chatwoot.identifier).toBe('second-user');
      expect(window.$chatwoot.user).toBe(secondUser);
      expect(IFrameHelper.sendMessage).toHaveBeenLastCalledWith('set-user', {
        identifier: 'second-user',
        user: secondUser,
      });
    });
  });

  describe('initial message', () => {
    it('queues the initial message until the widget has loaded', () => {
      window.$chatwoot.setInitialMessage('I need help with invoice 42');

      expect(window.$chatwoot.initialMessage).toBe(
        'I need help with invoice 42'
      );
      expect(IFrameHelper.sendMessage).not.toHaveBeenCalledWith(
        'set-initial-message',
        expect.anything()
      );
    });

    it('sends the initial message to a loaded widget', () => {
      window.$chatwoot.hasLoaded = true;

      window.$chatwoot.setInitialMessage('I need help with invoice 42');

      expect(IFrameHelper.sendMessage).toHaveBeenCalledWith(
        'set-initial-message',
        { initialMessage: 'I need help with invoice 42' }
      );
      expect(window.$chatwoot.initialMessage).toBe('');
    });

    it('accepts an initial message as the second toggle argument', () => {
      window.$chatwoot.hasLoaded = true;

      window.$chatwoot.toggle('open', 'I need help with invoice 42');

      expect(IFrameHelper.sendMessage).toHaveBeenCalledWith(
        'set-initial-message',
        { initialMessage: 'I need help with invoice 42' }
      );
      expect(IFrameHelper.events.toggleBubble).toHaveBeenCalledWith('open');
    });

    it('does not depend on toggle being called with the SDK as this', () => {
      window.$chatwoot.hasLoaded = true;
      const toggle = window.$chatwoot.toggle;

      toggle('open', 'I need help with invoice 42');

      expect(IFrameHelper.sendMessage).toHaveBeenCalledWith(
        'set-initial-message',
        { initialMessage: 'I need help with invoice 42' }
      );
      expect(IFrameHelper.events.toggleBubble).toHaveBeenCalledWith('open');
    });

    it('rejects non-string initial messages', () => {
      expect(() => window.$chatwoot.setInitialMessage({ id: 42 })).toThrow(
        'Initial message should be a string'
      );
    });

    it('clears queued initial messages when resetting the widget', () => {
      window.$chatwoot.setInitialMessage('I need help with invoice 42');

      window.$chatwoot.reset();

      expect(window.$chatwoot.initialMessage).toBe('');
      expect(IFrameHelper.getUrl).toHaveBeenCalledWith({
        baseUrl: 'https://app.chatwoot.com',
        websiteToken: 'website-token',
      });
    });
  });
});
