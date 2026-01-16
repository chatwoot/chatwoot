<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';

const router = useRouter();

const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');
const currentUser = useMapGetter('getCurrentUser');
const currentAccountId = useMapGetter('getCurrentAccountId');

const isSuperAdmin = computed(() => currentUser.value.type === 'SuperAdmin');

const i18nKey = computed(() =>
  isOnChatwootCloud.value ? 'PAYWALL' : 'ENTERPRISE_PAYWALL'
);

const goToBillingSettings = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: currentAccountId.value },
  });
};
</script>

<template>
  <div class="py-4 px-5 border-t border-n-container bg-n-background">
    <div class="flex justify-center">
      <BasePaywallModal
        feature-prefix="CSAT_REPORTS.REVIEW_NOTES"
        :i18n-key="i18nKey"
        :is-on-chatwoot-cloud="isOnChatwootCloud"
        :is-super-admin="isSuperAdmin"
        @upgrade="goToBillingSettings"
      />
    </div>
  </div>
</template>
