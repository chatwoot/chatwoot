import { computed, unref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

/**
 * Company and contact enrichment (Context.dev) need the installation-level API key and,
 * on Cloud, the Business or Enterprise plan.
 * @param {import('vue').Ref<boolean>|boolean} hasIdentity whether the record has
 * enough details to look up (a company domain, or a contact's email, profile or name)
 */
export function useEnrichment(hasIdentity) {
  const globalConfig = useMapGetter('globalConfig/get');
  const { isAdmin } = useAdmin();
  const { shouldShowPaywall } = usePolicy();

  // Shown to admins even without the plan, so clicking it can offer the upgrade.
  const showRefreshButton = computed(
    () =>
      isAdmin.value &&
      globalConfig.value.isCompanyEnrichmentEnabled &&
      Boolean(unref(hasIdentity))
  );

  const requiresUpgrade = computed(() =>
    shouldShowPaywall(FEATURE_FLAGS.COMPANY_ENRICHMENT)
  );

  return { showRefreshButton, requiresUpgrade };
}
