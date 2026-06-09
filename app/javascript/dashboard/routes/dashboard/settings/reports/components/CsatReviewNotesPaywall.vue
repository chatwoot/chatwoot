<script setup>
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';

const router = useRouter();
const currentAccountId = useMapGetter('getCurrentAccountId');

const goToBillingSettings = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: currentAccountId.value },
  });
};
</script>

<template>
  <div class="py-4 px-5 bg-n-background">
    <div class="flex justify-center">
      <BasePaywallModal
        feature-prefix="CSAT_REPORTS.REVIEW_NOTES"
        i18n-key="PAYWALL"
        is-on-chatwoot-cloud
        @upgrade="goToBillingSettings"
      />
    </div>
  </div>
</template>
