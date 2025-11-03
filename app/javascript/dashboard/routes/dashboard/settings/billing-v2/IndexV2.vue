<script setup>
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';

import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import CreditsSection from './components/CreditsSection.vue';
import PricingPlans from './components/PricingPlans.vue';
import BillingHeader from '../billing/components/BillingHeader.vue';
import ButtonV4 from 'next/button/Button.vue';

const router = useRouter();
const store = useStore();
const { isOnChatwootCloud, currentAccount } = useAccount();

const uiFlags = useMapGetter('accounts/getUIFlags');
const v2BillingData = useMapGetter('accounts/getV2BillingData');
const v2BillingUIFlags = useMapGetter('accounts/getV2BillingUIFlags');

const isLoading = computed(() => {
  return (
    uiFlags.value.isFetchingItem ||
    v2BillingUIFlags.value.isFetchingGrants ||
    v2BillingUIFlags.value.isFetchingPlans ||
    v2BillingUIFlags.value.isFetchingTopupOptions
  );
});

const canUseTopup = computed(() => {
  const planName = currentAccount.value?.custom_attributes?.plan_name;
  // Block topup if no plan or on Hacker plan
  if (!planName || planName.toLowerCase() === 'hacker') {
    return false;
  }
  return true;
});

const handleInitialLoad = async () => {
  // If self-hosted, redirect to dashboard
  if (!isOnChatwootCloud.value) {
    router.push({ name: 'home' });
    return;
  }

  // Fetch all V2 billing data in parallel
  await Promise.all([
    store.dispatch('accounts/fetchCreditsBalance'),
    store.dispatch('accounts/fetchCreditGrants'),
    store.dispatch('accounts/fetchV2PricingPlans'),
    store.dispatch('accounts/fetchV2TopupOptions'),
    store.dispatch('accounts/subscription'),
  ]);
};

const handleRefresh = () => {
  store.dispatch('accounts/fetchCreditsBalance');
  store.dispatch('accounts/fetchCreditGrants');
  store.dispatch('accounts/fetchV2PricingPlans');
};

const onToggleChatWindow = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

const handleOpenStripeDashboard = async () => {
  await store.dispatch('accounts/checkout');
};

onMounted(handleInitialLoad);
</script>

<template>
  <SettingsLayout :is-loading="isLoading">
    <template #header>
      <BaseSettingsHeader
        :title="$t('BILLING_SETTINGS_V2.TITLE')"
        :description="$t('BILLING_SETTINGS_V2.DESCRIPTION')"
        :link-text="$t('BILLING_SETTINGS_V2.VIEW_PRICING')"
        feature-name="billing-v2"
      >
        <template #actions>
          <ButtonV4
            solid
            blue
            icon="i-lucide-external-link"
            :is-loading="uiFlags.isCheckoutInProcess"
            @click="handleOpenStripeDashboard"
          >
            {{ $t('BILLING_SETTINGS_V2.OPEN_STRIPE_DASHBOARD') }}
          </ButtonV4>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <section class="grid gap-6">
        <!-- Pricing Plans -->
        <PricingPlans
          :plans="v2BillingData.pricingPlans"
          :current-account="currentAccount"
          :is-loading="v2BillingUIFlags.isFetchingPlans"
          :is-subscribing="v2BillingUIFlags.isSubscribeInProcess"
          :is-canceling="v2BillingUIFlags.isCancelInProcess"
        />

        <!-- Credits Section -->
        <CreditsSection
          :balance-data="v2BillingData.creditsBalance"
          :topup-options="v2BillingData.topupOptions"
          :credit-grants="v2BillingData.creditGrants"
          :is-loading-balance="v2BillingUIFlags.isFetchingBalance"
          :is-loading-topup="v2BillingUIFlags.isFetchingTopupOptions"
          :is-loading-grants="v2BillingUIFlags.isFetchingGrants"
          :is-processing-topup="v2BillingUIFlags.isTopupInProcess"
          :can-use-topup="canUseTopup"
          @refresh="handleRefresh"
        />

        <!-- Chat Support -->
        <BillingHeader
          class="px-1 mt-5"
          :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
          :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        >
          <ButtonV4
            sm
            solid
            slate
            icon="i-lucide-life-buoy"
            @click="onToggleChatWindow"
          >
            {{ $t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT') }}
          </ButtonV4>
        </BillingHeader>
      </section>
    </template>
  </SettingsLayout>
</template>
