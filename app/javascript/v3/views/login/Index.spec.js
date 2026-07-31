import Login from './Index.vue';
import { login } from '../../api/auth';

vi.mock('../../api/auth', () => ({
  login: vi.fn(),
}));

describe('login retries', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('preserves the Shopify pricing redirect after resolving a session limit', async () => {
    login.mockResolvedValue(null);
    const context = {
      email: '',
      credentials: {
        email: 'john@example.com',
        password: 'Password1!',
      },
      ssoAuthToken: '',
      ssoAccountId: '',
      ssoConversationId: '',
      redirectUrl:
        'settings/billing?plan_handle=growth&shop=store.myshopify.com',
      sessionsLimitReached: true,
      limitedSessions: [{ id: 1 }],
      loginApi: { showLoading: false, hasErrored: false },
      handleImpersonation: vi.fn(),
      showAlertMessage: vi.fn(),
      $t: key => key,
    };

    Login.methods.retryLoginWithParams.call(context, {
      revoke_session_id: 1,
    });
    await Promise.resolve();

    expect(login).toHaveBeenCalledWith(
      expect.objectContaining({
        redirectUrl:
          'settings/billing?plan_handle=growth&shop=store.myshopify.com',
        revoke_session_id: 1,
      })
    );
  });
});

describe('SAML login', () => {
  it('carries the Shopify pricing redirect to the SSO route', () => {
    const redirectUrl =
      'settings/billing?plan_handle=growth&shop=store.myshopify.com';

    expect(Login.computed.samlLoginRoute.call({ redirectUrl })).toEqual({
      name: 'sso_login',
      query: { redirect_url: redirectUrl },
    });
  });
});
