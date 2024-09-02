import { useAccount } from 'dashboard/composables/useAccount';
import { frontendURL } from 'dashboard/helper/URLHelper';
import allLocales from 'shared/constants/locales.js';
import { useRoute } from 'dashboard/composables/route';
import { computed } from 'vue';

/**
 * @typedef {Object} PortalComposable
 * @property {import('vue').ComputedRef<number>} accountId - The current account ID.
 * @property {import('vue').ComputedRef<string>} portalSlug - The slug of the current portal.
 * @property {import('vue').ComputedRef<string>} locale - The current locale code.
 * @property {function(number): string} articleUrl - A function to generate the URL for an article.
 * @property {function(string): string} localeName - A function to get the localized name of a locale.
 */

/**
 * A composable for managing portal-related data and utilities.
 * @returns {PortalComposable} An object containing portal-related properties and functions.
 */
export const usePortal = () => {
  const { accountId } = useAccount();
  const route = useRoute();
  const portalSlug = computed(() => route.params.portalSlug);
  const locale = computed(() => route.params.locale);

  /**
   * Generates the URL for an article.
   * @param {number} id - The ID of the article.
   * @returns {string} The full URL for the article.
   */
  const articleUrl = id => {
    return frontendURL(
      `accounts/${accountId.value}/portals/${portalSlug.value}/${locale.value}/articles/${id}`
    );
  };

  /**
   * Gets the localized name of a locale.
   * @param {string} code - The locale code.
   * @returns {string} The localized name of the locale.
   */
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
};
