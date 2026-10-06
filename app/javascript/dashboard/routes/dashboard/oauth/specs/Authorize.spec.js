import { flushPromises, shallowMount } from '@vue/test-utils';
import Button from 'dashboard/components-next/button/Button.vue';
import oauthAPI from 'dashboard/api/oauth';
import Authorize from '../Authorize.vue';

const OAUTH_QUERY = {
  client_id: 'abc',
  redirect_uri: 'https://chatgpt.com/callback',
  response_type: 'code',
  state: 'xyz',
  code_challenge: 'challenge',
  code_challenge_method: 'S256',
};

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: (key, params) => `${key} ${params?.appName || ''}` }),
}));

vi.mock('vue-router', () => ({
  useRoute: () => ({
    params: { accountId: '7' },
    query: { ...OAUTH_QUERY, account_id: '99', utm_source: 'ad' },
  }),
}));

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ({
    value: { accounts: [{ id: 7, name: 'Acme' }] },
  }),
}));

vi.mock('shared/composables/useBranding', () => ({
  useBranding: () => ({ replaceInstallationName: text => text }),
}));

vi.mock('dashboard/api/oauth', () => ({
  default: {
    getAuthorization: vi.fn(),
    approveAuthorization: vi.fn(),
    denyAuthorization: vi.fn(),
  },
}));

describe('Authorize', () => {
  const mountComponent = async () => {
    const wrapper = shallowMount(Authorize);
    await flushPromises();
    return wrapper;
  };

  beforeEach(() => {
    delete window.location;
    window.location = { assign: vi.fn() };
    oauthAPI.getAuthorization.mockResolvedValue({
      data: {
        client_name: 'ChatGPT',
        scope: 'conversations:read messages:write',
        redirect_uri: 'https://chatgpt.com/callback',
      },
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('loads the request with only the OAuth parameters from the URL', async () => {
    await mountComponent();

    expect(oauthAPI.getAuthorization).toHaveBeenCalledWith(OAUTH_QUERY);
  });

  it('shows the app name and the requested scopes', async () => {
    const wrapper = await mountComponent();

    expect(wrapper.text()).toContain('OAUTH.AUTHORIZE.TITLE ChatGPT');
    expect(wrapper.text()).toContain('OAUTH.SCOPES.CONVERSATIONS_READ');
    expect(wrapper.text()).toContain('OAUTH.SCOPES.MESSAGES_WRITE');
  });

  it('approves for the account in the route and sends the browser to the client', async () => {
    oauthAPI.approveAuthorization.mockResolvedValue({
      data: { redirect_uri: 'https://chatgpt.com/callback?code=123' },
    });
    const wrapper = await mountComponent();

    await wrapper.findAllComponents(Button)[1].trigger('click');
    await flushPromises();

    expect(oauthAPI.approveAuthorization).toHaveBeenCalledWith({
      ...OAUTH_QUERY,
      account_id: 7,
    });
    expect(window.location.assign).toHaveBeenCalledWith(
      'https://chatgpt.com/callback?code=123'
    );
  });

  it('denies and sends the browser to the client', async () => {
    oauthAPI.denyAuthorization.mockResolvedValue({
      data: {
        redirect_uri: 'https://chatgpt.com/callback?error=access_denied',
      },
    });
    const wrapper = await mountComponent();

    await wrapper.findAllComponents(Button)[0].trigger('click');
    await flushPromises();

    expect(oauthAPI.denyAuthorization).toHaveBeenCalledWith(OAUTH_QUERY);
    expect(window.location.assign).toHaveBeenCalledWith(
      'https://chatgpt.com/callback?error=access_denied'
    );
  });

  it('shows an error and no actions when the request is not valid', async () => {
    oauthAPI.getAuthorization.mockRejectedValue({
      response: { data: { error_description: 'Client authentication failed' } },
    });
    const wrapper = await mountComponent();

    expect(wrapper.text()).toContain('OAUTH.AUTHORIZE.ERROR_TITLE');
    expect(wrapper.text()).toContain('Client authentication failed');
    expect(wrapper.findAllComponents(Button)).toHaveLength(0);
  });
});
