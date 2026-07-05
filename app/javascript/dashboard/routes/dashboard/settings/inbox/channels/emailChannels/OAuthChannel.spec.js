import { mount, flushPromises } from '@vue/test-utils';
import { describe, it, expect, vi } from 'vitest';

// Stub the network/config layer so onMounted resolves to an unconfigured app and
// the credentials form + guide render without hitting real APIs.
vi.mock('dashboard/api/channel/emailOauthApp', () => ({
  default: {
    get: vi.fn(() =>
      Promise.resolve({
        data: {
          configured: false,
          source: null,
          callback_url: 'https://example.test/callback',
          client_id: '',
          tenant_id: '',
        },
      })
    ),
    update: vi.fn(),
  },
}));
vi.mock('dashboard/api/channel/microsoftClient', () => ({
  default: { generateAuthorization: vi.fn() },
}));
vi.mock('dashboard/api/channel/googleClient', () => ({
  default: { generateAuthorization: vi.fn() },
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

import EmailOauthAppAPI from 'dashboard/api/channel/emailOauthApp';
import OAuthChannel from './OAuthChannel.vue';

const stubs = { SettingsSubPageHeader: true, NextButton: true };

const mountChannel = provider =>
  mount(OAuthChannel, {
    props: {
      provider,
      title: 'Connect',
      description: 'desc',
      submitButtonText: 'Sign in',
      errorMessage: 'error',
    },
    global: { stubs },
  });

describe('OAuthChannel onboarding redesign', () => {
  it('renders a two-column layout with a guide panel', async () => {
    const wrapper = mountChannel('microsoft');
    await flushPromises();

    expect(wrapper.html()).toContain('lg:grid-cols-3');
    const aside = wrapper.find('aside');
    expect(aside.exists()).toBe(true);
    expect(aside.text()).toContain('What this connection does');
    // Guide surfaces the requested scopes for transparency.
    expect(aside.text()).toContain('View the permissions requested');
  });

  it('keeps the credentials form alongside the guide', async () => {
    const wrapper = mountChannel('microsoft');
    await flushPromises();

    expect(wrapper.find('form').exists()).toBe(true);
    expect(wrapper.find('aside').exists()).toBe(true);
  });

  it('shows the Microsoft Graph send capability for the microsoft provider', async () => {
    const wrapper = mountChannel('microsoft');
    await flushPromises();

    const guide = wrapper.find('aside').text();
    expect(guide).toContain('Microsoft Graph');
    expect(guide).not.toContain('Gmail');
  });

  it('shows the Gmail capability for the google provider', async () => {
    const wrapper = mountChannel('google');
    await flushPromises();

    const guide = wrapper.find('aside').text();
    expect(guide).toContain('Gmail');
    expect(guide).not.toContain('Microsoft Graph');
  });

  it('renders only the authorize form (not credentials) when already configured', async () => {
    EmailOauthAppAPI.get.mockResolvedValueOnce({
      data: {
        configured: true,
        source: 'account',
        callback_url: 'https://example.test/callback',
        client_id: 'abc',
        tenant_id: '',
      },
    });

    const wrapper = mountChannel('microsoft');
    await flushPromises();

    // Mutual exclusivity: exactly one form, and the credentials inputs are gone.
    expect(wrapper.findAll('form')).toHaveLength(1);
    expect(wrapper.find('input').exists()).toBe(false);
    // Guide stays visible in the authorize state too.
    expect(wrapper.find('aside').exists()).toBe(true);
  });
});
