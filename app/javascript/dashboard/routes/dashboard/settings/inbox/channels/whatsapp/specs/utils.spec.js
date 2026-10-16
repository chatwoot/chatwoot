import { initializeFacebook } from '../utils';

vi.mock('dashboard/helper/DOMHelpers', () => ({
  loadScript: vi.fn(),
}));

// Mirrors the stub window.FB that connect.facebook.net/en_US/sdk.js installs before the
// real SDK has loaded: init() only stores options and calls are buffered.
const installStubFb = () => {
  window.FB = {
    __buffer: { calls: [], opts: null },
    init: vi.fn(),
  };
};

const installRealFb = () => {
  window.FB = { init: vi.fn(), login: vi.fn() };
};

describe('initializeFacebook', () => {
  afterEach(() => {
    delete window.FB;
    delete window.fbAsyncInit;
  });

  it('waits for fbAsyncInit when only the SDK stub is on the page', async () => {
    installStubFb();
    const stubInit = window.FB.init;
    let resolved = false;

    const promise = initializeFacebook('app-id', 'v22.0').then(() => {
      resolved = true;
    });
    await Promise.resolve();

    expect(resolved).toBe(false);
    expect(stubInit).not.toHaveBeenCalled();

    // The real SDK replaces window.FB, then calls fbAsyncInit.
    installRealFb();
    window.fbAsyncInit();
    await promise;

    expect(resolved).toBe(true);
    expect(window.FB.init).toHaveBeenCalledWith({
      appId: 'app-id',
      autoLogAppEvents: true,
      xfbml: true,
      version: 'v22.0',
    });
  });

  it('waits for fbAsyncInit when window.FB is not defined yet', async () => {
    const promise = initializeFacebook('app-id');
    expect(typeof window.fbAsyncInit).toBe('function');

    installRealFb();
    window.fbAsyncInit();
    await promise;

    expect(window.FB.init).toHaveBeenCalledWith(
      expect.objectContaining({ appId: 'app-id', version: 'v22.0' })
    );
  });

  it('initializes right away when the real SDK is already loaded', async () => {
    installRealFb();

    await initializeFacebook('app-id', 'v23.0');

    expect(window.FB.init).toHaveBeenCalledWith({
      appId: 'app-id',
      autoLogAppEvents: true,
      xfbml: true,
      version: 'v23.0',
    });
  });
});
