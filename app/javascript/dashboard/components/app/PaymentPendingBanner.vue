<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useEventListener } from '@vueuse/core';
import { useStore } from 'dashboard/composables/store';
import { usePaymentStatus } from 'dashboard/composables/usePaymentStatus';
import Banner from 'dashboard/components-next/banner/Banner.vue';

const router = useRouter();
const store = useStore();
const { t } = useI18n();
const { accountId, isPastDue, canManagePayment, isOnChatwootCloud } =
  usePaymentStatus();

const bannerMessage = computed(() => {
  if (!isOnChatwootCloud.value) {
    return canManagePayment.value
      ? t('GENERAL_SETTINGS.INSTALLATION_PAYMENT_PENDING')
      : t('GENERAL_SETTINGS.INSTALLATION_PAYMENT_PENDING_MEMBER');
  }
  return canManagePayment.value
    ? t('GENERAL_SETTINGS.PAYMENT_PENDING')
    : t('GENERAL_SETTINGS.PAYMENT_PENDING_AGENT');
});

const openBilling = () => {
  if (!canManagePayment.value) return;
  if (!isOnChatwootCloud.value) {
    window.location.assign('/super_admin/settings');
    return;
  }
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};

// Only the recovery direction needs a focus check: the admin returns from the
// billing portal before the webhook lands, and isPastDue stays true until we
// refetch. Becoming past due arrives over the cable, or on reconnect.
useEventListener(window, 'focus', () => {
  if (!isPastDue.value || !accountId.value) return;

  store.dispatch('accounts/get', {
    accountId: accountId.value,
    silent: true,
  });
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Banner
    v-if="isPastDue"
    color="ruby"
    role="alert"
    class="!rounded-none !justify-center flex-wrap shrink-0"
    :action-label="canManagePayment ? t('GENERAL_SETTINGS.OPEN_BILLING') : null"
    @action="openBilling"
  >
    {{ bannerMessage }}
  </Banner>
</template>
