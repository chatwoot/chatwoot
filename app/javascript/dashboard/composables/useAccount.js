import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter } from './store';

/**
 * Composable for account-related operations.
 * @returns {Object} An object containing account-related properties and methods.
 */
export function useAccount() {
  /**
   * Computed property for the current account ID.
   * @type {import('vue').ComputedRef<number>}
   */
  const route = useRoute();
  const getAccountFn = useMapGetter('accounts/getAccount');
  const accountId = computed(() => {
    return Number(route.params.accountId);
  });

  const currentAccount = computed(() => getAccountFn.value(accountId.value));

  /**
   * Generates an account-scoped URL.
   * @param {string} url - The URL to be scoped to the account.
   * @returns {string} The account-scoped URL.
   */
  const accountScopedUrl = url => {
    return `/app/accounts/${accountId.value}/${url}`;
  };

  const accountScopedRoute = (name, params, query) => {
    return {
      name,
      params: { accountId: accountId.value, ...params },
      query: { ...query },
    };
  };

  return {
    accountId,
    route,
    currentAccount,
    accountScopedUrl,
    accountScopedRoute,
  };
}
