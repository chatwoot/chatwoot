<script setup>
import { useAccount } from 'dashboard/composables/useAccount';
import { useRouter } from 'vue-router';

import Banner from 'dashboard/components-next/banner/Banner.vue';

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
  <Banner
    color="amber"
    :action-label="$t('CAPTAIN.PAYWALL.UPGRADE_NOW')"
    @action="openBilling"
  >
    {{ $t('CAPTAIN.BANNER.DOCUMENTS') }}
  </Banner>
</template>
