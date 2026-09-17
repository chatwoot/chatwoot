<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';
import WhatsAppCampaignAnalyticsContent from './WhatsAppCampaignAnalyticsContent.vue';

const router = useRouter();
const { accountScopedRoute, isOnChatwootCloud } = useAccount();
const { shouldShowPaywall } = usePolicy();
const currentUser = useMapGetter('getCurrentUser');
const canViewAnalytics = computed(
  () => !shouldShowPaywall(FEATURE_FLAGS.CAMPAIGN_ANALYTICS)
);
const isSuperAdmin = computed(() => currentUser.value.type === 'SuperAdmin');
const paywallKey = computed(() =>
  isOnChatwootCloud.value ? 'PAYWALL' : 'ENTERPRISE_PAYWALL'
);
const openBilling = () =>
  router.push(accountScopedRoute('billing_settings_index'));
</script>

<template>
  <WhatsAppCampaignAnalyticsContent v-if="canViewAnalytics" />
  <div v-else class="grid place-content-center w-full h-full min-h-[28rem]">
    <BasePaywallModal
      feature-prefix="CAMPAIGN.WHATSAPP.ANALYTICS"
      :i18n-key="paywallKey"
      :is-on-chatwoot-cloud="isOnChatwootCloud"
      :is-super-admin="isSuperAdmin"
      @upgrade="openBilling"
    />
  </div>
</template>
