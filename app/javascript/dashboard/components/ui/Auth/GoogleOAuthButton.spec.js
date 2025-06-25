import { shallowMount } from '@vue/test-utils';
import GoogleOAuthButton from './GoogleOAuthButton.vue';

function getWrapper(showSeparator, buttonSize) {
  return shallowMount(GoogleOAuthButton, {
    propsData: { showSeparator: showSeparator, buttonSize: buttonSize },
    methods: {
      $t(text) {
        return text;
      },
    },
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

  it('renders the OR separator if showSeparator is true', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.find('.separator').exists()).toBe(true);
  });

  it('does not render the OR separator if showSeparator is false', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.find('.separator').exists()).toBe(false);
  });

  it('generates the correct Google Auth URL', () => {
    const wrapper = getWrapper();
    const googleAuthUrl = new URL(wrapper.vm.getGoogleAuthUrl());

    const params = googleAuthUrl.searchParams;
    expect(googleAuthUrl.origin).toBe('https://accounts.google.com');
    expect(googleAuthUrl.pathname).toBe('/o/oauth2/auth/oauthchooseaccount');
    expect(params.get('client_id')).toBe('clientId');
    expect(params.get('redirect_uri')).toBe(
      'http://localhost:3000/test-callback'
    );
    expect(params.get('response_type')).toBe('code');
    expect(params.get('scope')).toBe('email profile');
  });

  it('responds to buttonSize prop properly', () => {
    let wrapper = getWrapper(true, 'tiny');
    expect(wrapper.find('.button.tiny').exists()).toBe(true);

    wrapper = getWrapper(true, 'small');
    expect(wrapper.find('.button.small').exists()).toBe(true);

    wrapper = getWrapper(true, 'large');
    expect(wrapper.find('.button.large').exists()).toBe(true);

    // should not render either
    wrapper = getWrapper(true, 'default');
    expect(wrapper.find('.button.small').exists()).toBe(false);
    expect(wrapper.find('.button.tiny').exists()).toBe(false);
    expect(wrapper.find('.button.large').exists()).toBe(false);
    expect(wrapper.find('.button').exists()).toBe(true);
  });
});
