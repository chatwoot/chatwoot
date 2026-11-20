import Cookies from 'js-cookie';
import { IFrameHelper } from '../sdk/IFrameHelper';
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

describe('$chatwoot.reset', () => {
  let mockIframe;

  beforeEach(() => {
    delete window.$chatwoot;
    delete window.chatwootSettings;
    mockIframe = { src: '' };
    IFrameHelper.getAppFrame = vi.fn().mockReturnValue(mockIframe);
    IFrameHelper.getUrl = vi
      .fn()
      .mockReturnValue(
        'https://app.chatwoot.com/widget?website_token=website-token'
      );
    IFrameHelper.events = {
      toggleBubble: vi.fn(),
    };
    vi.spyOn(Cookies, 'remove').mockImplementation(() => {});
  });

  afterEach(() => {
    delete window.$chatwoot;
    delete window.chatwootSettings;
    vi.restoreAllMocks();
  });

  it('clears conversation and user cookies with default domain when baseDomain is not set', () => {
    window.chatwootSDK.run({
      baseUrl: 'https://app.chatwoot.com',
      websiteToken: 'website-token',
    });

    window.$chatwoot.reset();

    expect(Cookies.remove).toHaveBeenCalledWith('cw_conversation', {
      domain: undefined,
    });
    expect(Cookies.remove).toHaveBeenCalledWith('cw_user_website-token', {
      domain: undefined,
    });
    expect(mockIframe.src).toBe(
      'https://app.chatwoot.com/widget?website_token=website-token'
    );
    expect(window.$chatwoot.resetTriggered).toBe(true);
  });

  it('clears cookies with baseDomain when baseDomain is configured', () => {
    window.chatwootSettings = {
      baseDomain: 'chatwoot.com',
    };

    window.chatwootSDK.run({
      baseUrl: 'https://app.chatwoot.com',
      websiteToken: 'website-token',
    });

    window.$chatwoot.reset();

    expect(Cookies.remove).toHaveBeenCalledWith('cw_conversation', {
      domain: 'chatwoot.com',
    });
    expect(Cookies.remove).toHaveBeenCalledWith('cw_user_website-token', {
      domain: 'chatwoot.com',
    });
  });

  it('toggles bubble if widget is open during reset', () => {
    window.chatwootSDK.run({
      baseUrl: 'https://app.chatwoot.com',
      websiteToken: 'website-token',
    });
    window.$chatwoot.isOpen = true;

    window.$chatwoot.reset();

    expect(IFrameHelper.events.toggleBubble).toHaveBeenCalled();
  });
});
