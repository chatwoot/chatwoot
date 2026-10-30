import Cookies from 'js-cookie';
import { IFrameHelper } from '../sdk/IFrameHelper';
import { SDK_SET_BUBBLE_VISIBILITY } from 'shared/constants/sharedFrameEvents';
import './sdk';

vi.mock('../sdk/IFrameHelper', () => ({
  IFrameHelper: {
    createFrame: vi.fn(),
    sendMessage: vi.fn(),
  },
}));

describe('$chatwoot.setUser', () => {
  beforeEach(() => {
    delete window.$chatwoot;
    window.chatwootSettings = {};
    vi.spyOn(Cookies, 'get').mockReturnValue(undefined);
    vi.spyOn(Cookies, 'set').mockImplementation(() => {});

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

describe('$chatwoot.toggleBubbleVisibility', () => {
  beforeEach(() => {
    delete window.$chatwoot;
    window.chatwootSettings = {};
    document
      .querySelectorAll('.woot--bubble-holder, .woot-widget-holder')
      .forEach(element => element.remove());
    IFrameHelper.sendMessage.mockClear();

    window.chatwootSDK.run({
      baseUrl: 'https://app.chatwoot.com',
      websiteToken: 'website-token',
    });
  });

  afterEach(() => {
    delete window.$chatwoot;
    delete window.chatwootSettings;
    vi.clearAllMocks();
  });

  it('handles visibility changes before the widget DOM is mounted', () => {
    expect(document.querySelector('.woot--bubble-holder')).toBeNull();
    expect(document.querySelector('.woot-widget-holder')).toBeNull();

    expect(() => window.$chatwoot.toggleBubbleVisibility('hide')).not.toThrow();
    expect(window.$chatwoot.hideMessageBubble).toBe(true);
    expect(IFrameHelper.sendMessage).toHaveBeenLastCalledWith(
      SDK_SET_BUBBLE_VISIBILITY,
      { hideMessageBubble: true }
    );

    expect(() => window.$chatwoot.toggleBubbleVisibility('show')).not.toThrow();
    expect(window.$chatwoot.hideMessageBubble).toBe(false);
    expect(IFrameHelper.sendMessage).toHaveBeenLastCalledWith(
      SDK_SET_BUBBLE_VISIBILITY,
      { hideMessageBubble: false }
    );
  });
});
