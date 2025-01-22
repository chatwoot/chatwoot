<script setup>
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';

import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';

const router = useRouter();
const { accountId } = useAccount();

const openBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};
</script>

<template>
  <div
    class="w-full max-w-[960px] mx-auto h-full max-h-[448px] grid place-content-center"
  >
    <BasePaywallModal
      class="mx-auto"
      feature-prefix="CAPTAIN"
      i18n-key="PAYWALL"
      is-on-chatwoot-cloud
      @upgrade="openBilling"
    />
  </div>
</template>
