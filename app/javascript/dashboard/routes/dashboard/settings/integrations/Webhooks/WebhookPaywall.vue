<script setup>
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';

const router = useRouter();
const accountId = useMapGetter('getCurrentAccountId');

const openBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};
</script>

<template>
  <div class="grid place-content-center w-full h-full max-h-[28rem] mx-auto">
    <BasePaywallModal
      class="mx-auto"
      feature-prefix="INTEGRATION_SETTINGS.WEBHOOK"
      i18n-key="PAYWALL"
      is-on-chatwoot-cloud
      @upgrade="openBilling"
    />
  </div>
</template>
