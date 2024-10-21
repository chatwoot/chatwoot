import { defineComponent, h } from 'vue';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useAccount } from '../useAccount';
import { useRoute } from 'vue-router';
import { mount } from '@vue/test-utils';

vi.mock('vue-router');

describe('useAccount', () => {
  beforeEach(() => {
    useRoute.mockReturnValue({
      params: {
        accountId: 123,
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

  it('returns accountId as a computed property', async () => {
    const wrapper = mount(createComponent());
    const { accountId } = wrapper.vm;
    expect(accountId).toBe(123);
  });

  it('generates account-scoped URLs correctly', () => {
    const wrapper = mount(createComponent());
    const { accountScopedUrl } = wrapper.vm;
    const result = accountScopedUrl('settings/inbox/new');
    expect(result).toBe('/app/accounts/123/settings/inbox/new');
  });

  it('handles URLs with leading slash', () => {
    const wrapper = mount(createComponent());
    const { accountScopedUrl } = wrapper.vm;
    const result = accountScopedUrl('users');
    expect(result).toBe('/app/accounts/123/users');
  });

  it('handles empty URL', () => {
    const wrapper = mount(createComponent());
    const { accountScopedUrl } = wrapper.vm;
    const result = accountScopedUrl('');
    expect(result).toBe('/app/accounts/123/');
  });
});
