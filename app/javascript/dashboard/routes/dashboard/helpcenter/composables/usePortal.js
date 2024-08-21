import { frontendURL } from 'dashboard/helper/URLHelper';
import allLocales from 'shared/constants/locales.js';
import { useMapGetter } from 'dashboard/composables/store';
import { computed } from 'vue';

/**
 * COmposable to work with portal-related data and URLs.
 *
 * @returns {Object} The portal-related data and utilities.
 */
export const usePortal = () => {
  /**
   * Gets the current account ID.
   * @type {number}
   */
  const accountId = useMapGetter('getCurrentAccountId');

  /**
   * Computes the current portal slug.
   * @type {import('vue').ComputedRef<string>}
   */
  const portalSlug = computed(() => useMapGetter('getCurrentPortalSlug'));

  /**
   * Computes the current locale.
   * @type {import('vue').ComputedRef<string>}
   */
  const locale = computed(() => useMapGetter('getCurrentLocale'));

  /**
   * Generates the URL for an article based on the account ID, portal slug, and locale.
   *
   * @param {number|string} id - The ID of the article.
   * @returns {string} The URL of the article.
   */
  const articleUrl = id => {
    return frontendURL(
      `accounts/${accountId.value}/portals/${portalSlug.value}/${locale.value}/articles/${id}`
    );
  };

  /**
   * Retrieves the locale name using the locale code.
   *
   * @param {string} code - The locale code.
   * @returns {string} The locale name.
   */
  const localeName = code => {
    return allLocales[code];
  };

  return { accountId, portalSlug, locale, articleUrl, localeName };
};
