import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import Login from 'v3/views/login/Index.vue';
import { useStore } from 'vuex';

// Mock the global config
const mockGlobalConfig = {
  logo: '/brand-assets/logo.svg',
  logoDark: '/brand-assets/logo_dark.svg',
  installationName: 'Test Company',
  isEnterprise: false,
  disableUserProfileUpdate: false,
};

describe('Login View Branding', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    setActivePinia(createPinia());
    store = useStore();
    
    // Mock the globalConfig getter
    store.getters = {
      'globalConfig/get': mockGlobalConfig,
    };

    // Mock window.chatwootConfig
    window.chatwootConfig = {
      googleOAuthClientId: null,
      signupEnabled: true,
    };

    wrapper = mount(Login, {
      global: {
        plugins: [store],
        mocks: {
          $t: (key) => key,
          $route: { query: {} },
          $router: { replace: vi.fn() },
        },
      },
    });
  });

  it('displays installation name in alt text for logos', () => {
    const lightLogo = wrapper.find('img.dark:hidden');
    const darkLogo = wrapper.find('img.hidden.dark\\:block');
    
    expect(lightLogo.attributes('alt')).toBe('Test Company');
    expect(darkLogo.attributes('alt')).toBe('Test Company');
  });

  it('uses correct logo sources from global config', () => {
    const lightLogo = wrapper.find('img.dark:hidden');
    const darkLogo = wrapper.find('img.hidden.dark\\:block');
    
    expect(lightLogo.attributes('src')).toBe('/brand-assets/logo.svg');
    expect(darkLogo.attributes('src')).toBe('/brand-assets/logo_dark.svg');
  });

  it('applies branding to login title using replaceInstallationName', async () => {
    // Mock the translation to contain "Chatwoot"
    wrapper.vm.$t = (key) => {
      if (key === 'LOGIN.TITLE') return 'Login to Chatwoot';
      return key;
    };

    await wrapper.vm.$nextTick();
    
    const title = wrapper.find('h2');
    // The replaceInstallationName should replace "Chatwoot" with the installation name
    expect(title.text()).toBe('Login to Test Company');
  });

  it('falls back to default when installation name is not set', async () => {
    // Update global config to have empty installation name
    store.getters['globalConfig/get'] = {
      ...mockGlobalConfig,
      installationName: '',
    };

    wrapper.vm.$t = (key) => {
      if (key === 'LOGIN.TITLE') return 'Login to Chatwoot';
      return key;
    };

    await wrapper.vm.$nextTick();
    
    const title = wrapper.find('h2');
    // Should keep original text when no installation name is set
    expect(title.text()).toBe('Login to Chatwoot');
  });
});