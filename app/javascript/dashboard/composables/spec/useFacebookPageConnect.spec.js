import { useFacebookPageConnect } from '../useFacebookPageConnect';
import { useMapGetter } from 'dashboard/composables/store';
import ChannelApi from 'dashboard/api/channels';
import { setupFacebookSdk } from 'dashboard/routes/dashboard/settings/inbox/channels/whatsapp/utils';

vi.mock('dashboard/composables/store', () => ({ useMapGetter: vi.fn() }));
vi.mock('dashboard/api/channels', () => ({
  default: { fetchFacebookPages: vi.fn() },
}));
vi.mock(
  'dashboard/routes/dashboard/settings/inbox/channels/whatsapp/utils',
  () => ({ setupFacebookSdk: vi.fn() })
);

const flushPromises = () =>
  new Promise(resolve => {
    setTimeout(resolve, 0);
  });

const createDeferred = () => {
  let resolve;
  let reject;
  const promise = new Promise((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
};

const ACCOUNT_ID = 42;
const PAGES = [
  { id: 'p1', name: 'Page One', access_token: 'page-token-1' },
  { id: 'p2', name: 'Page Two', access_token: 'page-token-2', exists: true },
];

const pagesResponse = {
  data: { data: { page_details: PAGES, user_access_token: 'long-token' } },
};

// FB.login invokes its callback with the given response.
const stubLogin = response => {
  window.FB = { login: vi.fn(callback => callback(response)) };
};

const connected = {
  status: 'connected',
  authResponse: { accessToken: 'user-token' },
};

describe('useFacebookPageConnect', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    window.chatwootConfig = { fbAppId: 'fb-app', fbApiVersion: 'v22.0' };
    useMapGetter.mockReturnValue({ value: ACCOUNT_ID });
    setupFacebookSdk.mockResolvedValue();
    ChannelApi.fetchFacebookPages.mockResolvedValue(pagesResponse);
    stubLogin(connected);
  });

  it('resolves the user token and pages on a connected login', async () => {
    const { loginAndFetchPages } = useFacebookPageConnect();

    await expect(loginAndFetchPages()).resolves.toEqual({
      userAccessToken: 'long-token',
      pages: PAGES,
    });
    expect(setupFacebookSdk).toHaveBeenCalledWith('fb-app', 'v22.0');
    expect(ChannelApi.fetchFacebookPages).toHaveBeenCalledWith(
      'user-token',
      ACCOUNT_ID
    );
    expect(window.FB.login).toHaveBeenCalledWith(expect.any(Function), {
      scope:
        'pages_manage_metadata,business_management,pages_messaging,pages_show_list,pages_read_engagement',
    });
  });

  it('resolves null when the user is not authorized', async () => {
    stubLogin({ status: 'not_authorized' });
    const { loginAndFetchPages } = useFacebookPageConnect();

    await expect(loginAndFetchPages()).resolves.toBeNull();
    expect(ChannelApi.fetchFacebookPages).not.toHaveBeenCalled();
  });

  it('resolves null on an unknown login status', async () => {
    stubLogin({ status: 'unknown' });
    const { loginAndFetchPages } = useFacebookPageConnect();

    await expect(loginAndFetchPages()).resolves.toBeNull();
  });

  it('rejects when fetching pages fails', async () => {
    ChannelApi.fetchFacebookPages.mockRejectedValue(new Error('fetch failed'));
    const { loginAndFetchPages } = useFacebookPageConnect();

    await expect(loginAndFetchPages()).rejects.toThrow('fetch failed');
  });

  it('rejects when the SDK fails to load', async () => {
    const error = new Error('script load failed');
    error.name = 'ScriptLoaderError';
    setupFacebookSdk.mockRejectedValue(error);
    const { loginAndFetchPages } = useFacebookPageConnect();

    await expect(loginAndFetchPages()).rejects.toThrow('script load failed');
  });

  it('ignores a second call while a run is in flight', async () => {
    const pending = createDeferred();
    ChannelApi.fetchFacebookPages.mockReturnValue(pending.promise);

    const { loginAndFetchPages } = useFacebookPageConnect();
    const first = loginAndFetchPages();
    const second = loginAndFetchPages();

    await expect(second).resolves.toBeNull();

    pending.resolve(pagesResponse);
    await first;
    expect(window.FB.login).toHaveBeenCalledTimes(1);
  });

  it('toggles isAuthenticating across a run', async () => {
    const pending = createDeferred();
    ChannelApi.fetchFacebookPages.mockReturnValue(pending.promise);

    const { isAuthenticating, loginAndFetchPages } = useFacebookPageConnect();
    expect(isAuthenticating.value).toBe(false);

    const result = loginAndFetchPages();
    await flushPromises();
    expect(isAuthenticating.value).toBe(true);

    pending.resolve(pagesResponse);
    await result;
    expect(isAuthenticating.value).toBe(false);
  });

  it('preloads the SDK once and reuses it for login', async () => {
    const { preloadSdk, loginAndFetchPages } = useFacebookPageConnect();

    preloadSdk();
    preloadSdk();
    await loginAndFetchPages();

    expect(setupFacebookSdk).toHaveBeenCalledTimes(1);
  });
});
