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
  it('renders a form-narrow, guide-dominant layout (not the old 3-col grid)', async () => {
    const wrapper = mountChannel('microsoft');
    await flushPromises();

    // The rejected layout used lg:grid-cols-3 with the form at col-span-2 (form-dominant).
    expect(wrapper.html()).not.toContain('lg:grid-cols-3');
    // Form is a fixed narrow column; the guide takes the remaining width.
    expect(wrapper.html()).toContain('lg:w-[340px]');
    const aside = wrapper.find('aside');
    expect(aside.exists()).toBe(true);
    expect(aside.classes()).toContain('lg:flex-1');
  });

  it('keeps the credentials form alongside the guide', async () => {
    const wrapper = mountChannel('microsoft');
    await flushPromises();

    expect(wrapper.find('form').exists()).toBe(true);
    expect(wrapper.find('aside').exists()).toBe(true);
  });

  it('surfaces calendar as a required capability and setup step', async () => {
    const wrapper = mountChannel('microsoft');
    await flushPromises();

    const guide = wrapper.find('aside').text();
    expect(guide).toContain('Calendar');
    // GUIDE_BADGE_REQUIRED (capability) + GUIDE_BADGE_MANDATORY (setup step).
    expect(guide).toContain('Required');
    expect(guide).toContain('Mandatory');
  });

  it('includes clickable documentation links in the guide', async () => {
    const wrapper = mountChannel('microsoft');
    await flushPromises();

    const links = wrapper.find('aside').findAll('a[target="_blank"]');
    // App registration link + calendar setup link + docs link.
    expect(links.length).toBeGreaterThanOrEqual(3);
    const hrefs = links.map(a => a.attributes('href'));
    expect(hrefs.some(h => h.includes('portal.azure.com'))).toBe(true);
    expect(hrefs.some(h => h.includes('learn.microsoft.com'))).toBe(true);
  });

  it('adapts send capability and app link for the microsoft provider', async () => {
    const wrapper = mountChannel('microsoft');
    await flushPromises();

    const aside = wrapper.find('aside');
    expect(aside.text()).toContain('Microsoft Graph');
    expect(aside.text()).not.toContain('Gmail');
    expect(aside.html()).toContain('portal.azure.com');
  });

  it('adapts send capability and app link for the google provider', async () => {
    const wrapper = mountChannel('google');
    await flushPromises();

    const aside = wrapper.find('aside');
    expect(aside.text()).toContain('Gmail');
    expect(aside.text()).not.toContain('Microsoft Graph');
    expect(aside.html()).toContain('console.cloud.google.com');
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
