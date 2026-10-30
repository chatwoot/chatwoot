import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';

const FREE_CLOUD_PLAN = 'hacker';

export function useTranslationPlan() {
  const { currentAccount, isOnChatwootCloud } = useAccount();
  const { isEnterprise, enterprisePlanName } = useConfig();

  const needsUpgrade = computed(
    () =>
      isOnChatwootCloud.value &&
      currentAccount.value?.custom_attributes?.plan_name?.toLowerCase() ===
        FREE_CLOUD_PLAN
  );

  const isAvailable = computed(() => {
    if (isOnChatwootCloud.value) return !needsUpgrade.value;
    return isEnterprise && enterprisePlanName !== 'community';
  });

  return { isAvailable, needsUpgrade };
}
