<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useBranding } from 'shared/composables/useBranding';

import ShopifyBilling from './ShopifyBilling.vue';
import StripeBilling from './Index.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';

const { currentAccount, isCloudFeatureEnabled } = useAccount();
const { replaceInstallationName } = useBranding();

const isAccountLoaded = computed(() => Boolean(currentAccount.value?.id));
const isShopifyBilling = computed(
  () => currentAccount.value?.billing_provider === 'shopify'
);
const isShopifyEnabled = computed(
  () => isAccountLoaded.value && isCloudFeatureEnabled(FEATURE_FLAGS.SHOPIFY)
);
</script>

<template>
  <SettingsLayout
    v-if="!isAccountLoaded"
    is-loading
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
  />
  <ShopifyBilling v-else-if="isShopifyBilling && isShopifyEnabled" />
  <SettingsLayout
    v-else-if="isShopifyBilling"
    no-records-found
    :no-records-message="$t('BILLING_SETTINGS.SHOPIFY.UNAVAILABLE')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('BILLING_SETTINGS.SHOPIFY.TITLE')"
        :description="
          replaceInstallationName($t('BILLING_SETTINGS.SHOPIFY.DESCRIPTION'))
        "
      />
    </template>
  </SettingsLayout>
  <StripeBilling v-else />
</template>
