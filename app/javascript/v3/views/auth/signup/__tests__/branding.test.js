import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import Signup from 'v3/views/auth/signup/Index.vue';
import { useStore } from 'vuex';

// Mock the global config
const mockGlobalConfig = {
  logo: '/brand-assets/logo.svg',
  logoDark: '/brand-assets/logo_dark.svg',
  installationName: 'Test Company',
  isEnterprise: false,
};

describe('Signup View Branding', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    setActivePinia(createPinia());
    store = useStore();
    
    // Mock the globalConfig getter
    store.getters = {
      'globalConfig/get': mockGlobalConfig,
    };

    wrapper = mount(Signup, {
      global: {
        plugins: [store],
        mocks: {
          $t: (key) => key,
          $route: {},
          $router: {},
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

  it('applies branding to login link using replaceInstallationName', async () => {
    // Mock the translation to contain "Chatwoot"
    wrapper.vm.$t = (key) => {
      if (key === 'LOGIN.TITLE') return 'Login to Chatwoot';
      return key;
    };

    await wrapper.vm.$nextTick();
    
    const loginLink = wrapper.find('a[href="/app/login"]');
    // The replaceInstallationName should replace "Chatwoot" with the installation name
    expect(loginLink.text()).toBe('Login to Test Company');
  });

  it('shows testimonials when installation name is Chatwoot', () => {
    // Set installation name to "Chatwoot" to trigger testimonials
    store.getters['globalConfig/get'] = {
      ...mockGlobalConfig,
      installationName: 'Chatwoot',
    };

    wrapper = mount(Signup, {
      global: {
        plugins: [store],
        mocks: {
          $t: (key) => key,
          $route: {},
          $router: {},
        },
      },
    });

    // Should show testimonials component when installation name is "Chatwoot"
    expect(wrapper.findComponent({ name: 'Testimonials' }).exists()).toBe(true);
  });

  it('hides testimonials when installation name is not Chatwoot', () => {
    // Should not show testimonials component when installation name is not "Chatwoot"
    expect(wrapper.findComponent({ name: 'Testimonials' }).exists()).toBe(false);
  });
});