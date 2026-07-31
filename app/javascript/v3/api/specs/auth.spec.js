import wootAPI from '../apiClient';
import { register } from '../auth';

vi.mock('../apiClient', () => ({
  default: {
    post: vi.fn(),
  },
}));

vi.mock('dashboard/store/utils/api', () => ({
  throwErrorMessage: vi.fn(),
  clearLocalStorageOnLogout: vi.fn(),
  parseAPIErrorResponse: vi.fn(),
}));

describe('auth API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('keeps the regular signup payload unchanged', async () => {
    wootAPI.post.mockResolvedValue({ data: { email: 'john@acme.com' } });

    await register({
      email: 'john@acme.com',
      password: 'Password1!',
      hCaptchaClientResponse: 'captcha-token',
    });

    expect(wootAPI.post).toHaveBeenCalledWith('api/v1/accounts.json', {
      account_name: 'Acme',
      user_full_name: 'John',
      email: 'john@acme.com',
      password: 'Password1!',
      h_captcha_client_response: 'captcha-token',
    });
  });

  it('includes the pending install token for Shopify signup', async () => {
    wootAPI.post.mockResolvedValue({ data: { email: 'john@acme.com' } });

    await register({
      email: 'john@acme.com',
      password: 'Password1!',
      hCaptchaClientResponse: 'captcha-token',
      shopifyPendingInstallToken: 'pending-install-token',
    });

    expect(wootAPI.post).toHaveBeenCalledWith(
      'api/v1/accounts.json',
      expect.objectContaining({
        shopify_pending_install_token: 'pending-install-token',
      })
    );
  });
});
