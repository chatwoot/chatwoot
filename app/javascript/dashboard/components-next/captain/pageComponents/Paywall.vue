<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useTrialStatus } from 'dashboard/composables/useTrialStatus';

import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';

const props = defineProps({
  featurePrefix: {
    type: String,
    default: 'CAPTAIN',
  },
});

const router = useRouter();
const currentUser = useMapGetter('getCurrentUser');

const isSuperAdmin = computed(() => {
  return currentUser.value.type === 'SuperAdmin';
});
const { accountId, isOnChatwootCloud } = useAccount();
const { isTrialWithoutCard } = useTrialStatus();
const { te } = useI18n();

// During a trial without a card, the locked features unlock once a card is added, not by upgrading.
const i18nKey = computed(() => {
  if (!isOnChatwootCloud.value) return 'ENTERPRISE_PAYWALL';
  const hasTrialCopy = te(`${props.featurePrefix}.TRIAL_PAYWALL.AVAILABLE_ON`);
  return isTrialWithoutCard.value && hasTrialCopy ? 'TRIAL_PAYWALL' : 'PAYWALL';
});
const openBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};
</script>

<template>
  <div
    class="w-full max-w-5xl mx-auto h-full max-h-[448px] grid place-content-center"
  >
    <BasePaywallModal
      class="mx-auto"
      :feature-prefix="featurePrefix"
      :i18n-key="i18nKey"
      :is-super-admin="isSuperAdmin"
      :is-on-chatwoot-cloud="isOnChatwootCloud"
      @upgrade="openBilling"
    />
  </div>
</template>
