import wootAPI from '../apiClient';
import { register, verifyPasswordToken } from '../auth';
import { setAuthCredentials } from 'dashboard/store/utils/api';

vi.mock('../apiClient', () => ({
  default: {
    post: vi.fn(),
  },
}));

vi.mock('dashboard/store/utils/api', () => ({
  setAuthCredentials: vi.fn(),
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
  it('returns the authenticated user after email confirmation', async () => {
    const user = { id: 1, accounts: [{ id: 2 }] };
    const response = { data: { data: user } };
    wootAPI.post.mockResolvedValue(response);

    await expect(
      verifyPasswordToken({ confirmationToken: 'confirmation-token' })
    ).resolves.toEqual(user);
    expect(setAuthCredentials).toHaveBeenCalledWith(response);
  });
});
