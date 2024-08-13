import { ref } from 'vue';
import { describe, it, expect, vi } from 'vitest';
import { useAccount } from '../useAccount';
import { useStoreGetters } from 'dashboard/composables/store';

vi.mock('dashboard/composables/store');

describe('useAccount', () => {
  beforeEach(() => {
    useStoreGetters.mockReturnValue({
      getCurrentAccountId: ref(123),
    });
  });

  it('returns accountId as a computed property', () => {
    const { accountId } = useAccount();
    expect(accountId.value).toBe(123);
  });

  it('generates account-scoped URLs correctly', () => {
    const { accountScopedUrl } = useAccount();
    const result = accountScopedUrl('settings/inbox/new');
    expect(result).toBe('/app/accounts/123/settings/inbox/new');
  });

  it('handles URLs with leading slash', () => {
    const { accountScopedUrl } = useAccount();
    const result = accountScopedUrl('users');
    expect(result).toBe('/app/accounts/123/users');
  });

  it('handles empty URL', () => {
    const { accountScopedUrl } = useAccount();
    const result = accountScopedUrl('');
    expect(result).toBe('/app/accounts/123/');
  });
});
