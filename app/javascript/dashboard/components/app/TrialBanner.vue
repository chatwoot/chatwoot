<script setup>
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAccount } from 'dashboard/composables/useAccount';
import { useBillingStore } from 'dashboard/stores/billing';
import { useI18n } from 'vue-i18n';
import Banner from 'dashboard/components/ui/Banner.vue';

const router = useRouter();
const { isAdmin } = useAdmin();
const { accountId } = useAccount();
const billingStore = useBillingStore();
const { t } = useI18n();

onMounted(() => {
  if (!billingStore.subscription) {
    billingStore.fetch();
  }
});

const trialDaysRemaining = computed(() => {
  const trialEndsAt = billingStore.subscription?.trial_ends_at;
  if (!trialEndsAt) return 0;
  const diff = new Date(trialEndsAt) - new Date();
  return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
});

const shouldShowBanner = computed(() => {
  return billingStore.trialActive && isAdmin.value;
});

const bannerMessage = computed(() => {
  return t('BILLING_SETTINGS.TRIAL_BANNER.MESSAGE', {
    days: trialDaysRemaining.value,
    credits: billingStore.trialCreditsRemaining,
  });
});

const routeToBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Banner
    v-if="shouldShowBanner"
    color-scheme="warning"
    :banner-message="bannerMessage"
    :action-button-label="t('BILLING_SETTINGS.TRIAL_BANNER.ACTION')"
    has-action-button
    @primary-action="routeToBilling"
  />
</template>
