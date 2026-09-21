<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useEventListener } from '@vueuse/core';
import { useStore } from 'dashboard/composables/store';
import { useTrack } from 'dashboard/composables';
import { usePaymentStatus } from 'dashboard/composables/usePaymentStatus';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import { BILLING_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

const router = useRouter();
const store = useStore();
const { t } = useI18n();
const { accountId, isPastDue, canManagePayment } = usePaymentStatus();

const bannerMessage = computed(() =>
  canManagePayment.value
    ? t('GENERAL_SETTINGS.PAYMENT_PENDING')
    : t('GENERAL_SETTINGS.PAYMENT_PENDING_AGENT')
);

const openBilling = () => {
  if (!canManagePayment.value) return;
  useTrack(BILLING_EVENTS.OPEN_BILLING_FROM_PAST_DUE_BANNER);
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
