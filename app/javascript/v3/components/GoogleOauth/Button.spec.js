import { shallowMount } from '@vue/test-utils';
import GoogleOAuthButton from './Button.vue';

function getWrapper(props = {}) {
  return shallowMount(GoogleOAuthButton, {
    props,
    mocks: { $t: text => text },
  });
}

describe('GoogleOAuthButton.vue', () => {
  beforeEach(() => {
    window.chatwootConfig = {
      googleOAuthClientId: 'clientId',
      googleOAuthCallbackUrl: 'http://localhost:3000/test-callback',
    };
  });

  afterEach(() => {
    window.chatwootConfig = {};
  });

  it('generates the correct Google Auth URL', () => {
    const wrapper = getWrapper();
    const googleAuthUrl = new URL(wrapper.vm.getGoogleAuthUrl());
    const params = googleAuthUrl.searchParams;
    expect(googleAuthUrl.origin).toBe('https://accounts.google.com');
    expect(googleAuthUrl.pathname).toBe('/o/oauth2/auth');
    expect(params.get('client_id')).toBe('clientId');
    expect(params.get('redirect_uri')).toBe(
      'http://localhost:3000/test-callback'
    );
    expect(params.get('response_type')).toBe('code');
    expect(params.get('scope')).toBe('email profile');
    expect(params.has('state')).toBe(false);
  });

  it('carries the billing redirect through Google OAuth state', () => {
    const redirectUrl =
      'settings/billing?plan_handle=growth&shop=store.myshopify.com';
    const wrapper = getWrapper({ redirectUrl });
    const googleAuthUrl = new URL(wrapper.vm.getGoogleAuthUrl());

    expect(googleAuthUrl.searchParams.get('state')).toBe(redirectUrl);
  });
});
