<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';

const router = useRouter();
const currentUser = useMapGetter('getCurrentUser');

const isSuperAdmin = computed(() => {
  return currentUser.value.type === 'SuperAdmin';
});
const { accountId, isOnChatwootCloud } = useAccount();

const i18nKey = computed(() =>
  isOnChatwootCloud.value ? 'PAYWALL' : 'ENTERPRISE_PAYWALL'
);
const openBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};
</script>

<template>
  <div
    class="w-full max-w-[60rem] mx-auto h-full max-h-[448px] grid place-content-center"
  >
    <BasePaywallModal
      class="mx-auto"
      feature-prefix="CAPTAIN"
      :i18n-key="i18nKey"
      :is-super-admin="isSuperAdmin"
      :is-on-chatwoot-cloud="isOnChatwootCloud"
      @upgrade="openBilling"
    />
  </div>
</template>
