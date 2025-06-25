import { defineComponent, h } from 'vue';
import { createStore } from 'vuex';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useAccount } from '../useAccount';
import { useRoute } from 'vue-router';
import { mount } from '@vue/test-utils';

const store = createStore({
  modules: {
    auth: {
      namespaced: false,
      getters: {
        getCurrentAccountId: () => 1,
        getCurrentUser: () => ({
          accounts: [
            { id: 1, name: 'Chatwoot', role: 'administrator' },
            { id: 2, name: 'GitX', role: 'agent' },
          ],
        }),
      },
    },
    accounts: {
      namespaced: true,
      getters: {
        getAccount: () => id => ({ id, name: 'Chatwoot' }),
      },
    },
  },
});

const mountParams = {
  global: {
    plugins: [store],
  },
};

vi.mock('vue-router');

describe('useAccount', () => {
  beforeEach(() => {
    useRoute.mockReturnValue({
      params: {
        accountId: '123',
      },
    });
  });

  const createComponent = () =>
    defineComponent({
      setup() {
        return useAccount();
      },
      render() {
        return h('div'); // Dummy render to satisfy mount
      },
    });

  it('returns accountId as a computed property', () => {
    const wrapper = mount(createComponent(), mountParams);
    const { accountId } = wrapper.vm;
    expect(accountId).toBe(123);
  });

  it('generates account-scoped URLs correctly', () => {
    const wrapper = mount(createComponent(), mountParams);
    const { accountScopedUrl } = wrapper.vm;
    const result = accountScopedUrl('settings/inbox/new');
    expect(result).toBe('/app/accounts/123/settings/inbox/new');
  });

  it('handles URLs with leading slash', () => {
    const wrapper = mount(createComponent(), mountParams);
    const { accountScopedUrl } = wrapper.vm;
    const result = accountScopedUrl('users');
    expect(result).toBe('/app/accounts/123/users'); // Ensures no double slashes
  });

  it('handles empty URL', () => {
    const wrapper = mount(createComponent(), mountParams);
    const { accountScopedUrl } = wrapper.vm;
    const result = accountScopedUrl('');
    expect(result).toBe('/app/accounts/123/');
  });

  it('returns current account based on accountId', () => {
    const wrapper = mount(createComponent(), mountParams);
    const { currentAccount } = wrapper.vm;
    expect(currentAccount).toEqual({ id: 123, name: 'Chatwoot' });
  });

  it('returns an account-scoped route', () => {
    const wrapper = mount(createComponent(), mountParams);
    const { accountScopedRoute } = wrapper.vm;
    const result = accountScopedRoute('accountDetail', { userId: 456 }, {});
    expect(result).toEqual({
      name: 'accountDetail',
      params: { accountId: 123, userId: 456 },
      query: {},
    });
  });

  it('returns route with correct params', () => {
    const wrapper = mount(createComponent(), mountParams);
    const { route } = wrapper.vm;
    expect(route.params).toEqual({ accountId: '123' });
  });

  it('handles non-numeric accountId gracefully', async () => {
    useRoute.mockReturnValueOnce({
      params: { accountId: 'abc' },
    });

    const wrapper = mount(createComponent(), mountParams);
    const { accountId } = wrapper.vm;
    expect(accountId).toBeNaN(); // Handles invalid numeric conversion
  });
});
