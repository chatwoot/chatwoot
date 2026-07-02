import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

/**
 * Mirrors the backend quota enforcement (docs/fork/ENTITLEMENTS.md) in the UI.
 * Reads `{ allowed, consumed }` per resource from the account limits endpoint;
 * `allowed: null` means unlimited. The backend stays the source of truth —
 * this only disables create actions and explains why.
 * @param {string} resource - usage_limits key, e.g. 'teams', 'labels'.
 */
export function useQuota(resource) {
  const store = useStore();
  const { t } = useI18n();
  const { currentAccount } = useAccount();

  onMounted(() => store.dispatch('accounts/limits'));

  const quota = computed(() => currentAccount.value?.limits?.[resource]);

  const atQuotaLimit = computed(() => {
    const { allowed, consumed } = quota.value || {};
    return allowed !== null && allowed !== undefined && consumed >= allowed;
  });

  const quotaTitle = computed(() =>
    atQuotaLimit.value
      ? t('QUOTA.LIMIT_REACHED', {
          consumed: quota.value.consumed,
          allowed: quota.value.allowed,
        })
      : undefined
  );

  return { quota, atQuotaLimit, quotaTitle };
}
