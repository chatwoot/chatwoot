import Cookies from 'js-cookie';
import { IFrameHelper } from '../sdk/IFrameHelper';
import { storeConfirmedUserHash } from '../sdk/cookieHelpers';
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
      userHash: expect.any(String),
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
      userHash: expect.any(String),
    });
  });
});

describe('$chatwoot.setUser and the user cookie', () => {
  const USER_COOKIE = 'cw_user_website-token';
  const user = { name: 'Pranav', email: 'pranav@example.com' };

  // The widget confirms a call by sending back the hash it received
  const confirmSetUserCall = callNumber => {
    const [, { userHash }] =
      IFrameHelper.sendMessage.mock.calls[callNumber - 1];
    storeConfirmedUserHash(userHash);
  };

  beforeEach(() => {
    delete window.$chatwoot;
    window.chatwootSettings = {};
    window.chatwootSDK.run({
      baseUrl: 'https://app.chatwoot.com',
      websiteToken: 'website-token',
    });
  });

  afterEach(() => {
    Cookies.remove(USER_COOKIE);
    delete window.$chatwoot;
    delete window.chatwootSettings;
  });

  it('does not store the cookie before the widget confirms the call', () => {
    window.$chatwoot.setUser('user-1', user);

    expect(Cookies.get(USER_COOKIE)).toBeUndefined();
  });

  it('sends the user again when the widget did not confirm the first call', () => {
    window.$chatwoot.setUser('user-1', user);
    window.$chatwoot.setUser('user-1', user);

    expect(IFrameHelper.sendMessage).toHaveBeenCalledTimes(2);
  });

  it('skips the call when the widget confirmed the same user', () => {
    window.$chatwoot.setUser('user-1', user);
    confirmSetUserCall(1);
    window.$chatwoot.setUser('user-1', user);

    expect(IFrameHelper.sendMessage).toHaveBeenCalledTimes(1);
  });

  it('sends the user when the confirmed user is a different one', () => {
    window.$chatwoot.setUser('user-1', user);
    confirmSetUserCall(1);
    window.$chatwoot.setUser('user-2', user);

    expect(IFrameHelper.sendMessage).toHaveBeenCalledTimes(2);
  });

  it('ignores a confirmation for an earlier call', () => {
    window.$chatwoot.setUser('user-1', user);
    window.$chatwoot.setUser('user-2', user);
    confirmSetUserCall(1);

    expect(Cookies.get(USER_COOKIE)).toBeUndefined();

    confirmSetUserCall(2);
    window.$chatwoot.setUser('user-2', user);

    expect(IFrameHelper.sendMessage).toHaveBeenCalledTimes(2);
  });
});
