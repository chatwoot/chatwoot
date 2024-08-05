import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { frontendURL } from 'dashboard/helper/URLHelper';
import allLocales from 'shared/constants/locales.js';

/**
 * Composable for handling portal-related computations and methods.
 * @returns {Object} An object containing computed properties and methods for portal management.
 */
export function usePortal() {
  const route = useRoute();
  const store = useStore();

  const accountId = computed(() => store.getters.getCurrentAccountId);
  const portalSlug = computed(() => route.params.portalSlug);
  const locale = computed(() => route.params.locale);

  const articleUrl = id => {
    return frontendURL(
      `accounts/${accountId.value}/portals/${portalSlug.value}/${locale.value}/articles/${id}`
    );
  };

  const localeName = code => {
    return allLocales[code];
  };

  return {
    accountId,
    portalSlug,
    locale,
    articleUrl,
    localeName,
  };
}
