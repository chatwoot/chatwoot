import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter, useStore } from './store';

/**
 * Composable for account-related operations.
 * @returns {Object} An object containing account-related properties and methods.
 */
export function useAccount() {
  /**
   * Computed property for the current account ID.
   * @type {import('vue').ComputedRef<number>}
   */
  // In the isolated shell (react-components / Web Component context),
  // vue-router is not available. Fall back to the global variable.
  // eslint-disable-next-line no-underscore-dangle
  const isIsolatedShell = !!window.__WOOT_ISOLATED_SHELL__;
  const route = isIsolatedShell ? null : useRoute();

  const store = useStore();
  const getAccountFn = useMapGetter('accounts/getAccount');
  const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');
  const isFeatureEnabledonAccount = useMapGetter(
    'accounts/isFeatureEnabledonAccount'
  );

  const accountId = computed(() => {
    if (isIsolatedShell) {
      // eslint-disable-next-line no-underscore-dangle
      return Number(window.__WOOT_ACCOUNT_ID__);
    }
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

  const isCloudFeatureEnabled = feature => {
    return isFeatureEnabledonAccount.value(currentAccount.value.id, feature);
  };

  const accountScopedRoute = (name, params, query) => {
    return {
      name,
      params: { accountId: accountId.value, ...params },
      query: { ...query },
    };
  };

  const updateAccount = async (data, options) => {
    await store.dispatch('accounts/update', {
      ...data,
      options,
    });
  };

  return {
    accountId,
    route,
    currentAccount,
    accountScopedUrl,
    accountScopedRoute,
    isCloudFeatureEnabled,
    isOnChatwootCloud,
    updateAccount,
  };
}
