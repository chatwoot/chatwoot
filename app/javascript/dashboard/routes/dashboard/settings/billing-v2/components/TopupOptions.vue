<script setup>
import { ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store.js';
import { useAlert } from 'dashboard/composables';
import Button from 'next/button/Button.vue';
import TopupDialog from './TopupDialog.vue';

defineProps({
  options: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isProcessing: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const store = useStore();

const topupDialogRef = ref(null);
const selectedOption = ref(null);

const formatPrice = price => {
  if (!price) return '$0';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(price);
};

const formatNumber = num => {
  return new Intl.NumberFormat('en-US').format(num);
};

const openTopupDialog = async option => {
  selectedOption.value = option;
  await nextTick();
  topupDialogRef.value?.open();
};

const handleTopup = async data => {
  const result = await store.dispatch('accounts/v2Topup', data);

  if (result.success) {
    topupDialogRef.value?.close();
    setTimeout(async () => {
      await store.dispatch('accounts/fetchCreditsBalance');
    }, 2000);
    useAlert(t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.TOPUP_SUCCESS'));
  } else if (result.error) {
    topupDialogRef.value?.close();

    if (result.error.includes('payment method')) {
      useAlert(t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.NO_PAYMENT_METHOD_ERROR'));
    } else {
      useAlert(result.error);
    }
  }
};
</script>

<template>
  <div class="mt-4">
    <h6 class="text-base font-semibold mb-2">
      {{ t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.TITLE') }}
    </h6>
    <div class="grid gap-3 grid-cols-1 xs:grid-cols-2 xl:grid-cols-4">
      <div
        v-for="option in options"
        :key="option.id"
        class="p-4 -outline-offset-1 outline outline-1 outline-n-weak rounded-lg hover:outline-n-strong hover:shadow-sm transition-all cursor-pointer"
        @click="openTopupDialog(option)"
      >
        <div class="text-center">
          <div class="text-3xl font-bold text-b-800">
            {{ formatNumber(option.credits) }}
          </div>
          <div class="mt-1 text-xs text-n-600 uppercase tracking-wide">
            {{ $t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.CREDITS') }}
          </div>
          <div class="mt-3 text-2xl font-bold text-n-800">
            {{ formatPrice(option.price) }}
          </div>
          <p v-if="option.description" class="mt-2 text-xs text-n-600">
            {{ option.description }}
          </p>
          <Button
            class="w-full mt-4"
            sm
            solid
            blue
            @click.stop="openTopupDialog(option)"
          >
            {{ $t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.BUY_NOW') }}
          </Button>
        </div>
      </div>
    </div>

    <div v-if="options.length === 0 && !isLoading" class="py-8 text-center">
      <p class="text-sm text-n-600">
        {{ $t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.NO_OPTIONS') }}
      </p>
    </div>
  </div>

  <TopupDialog
    v-if="selectedOption"
    ref="topupDialogRef"
    :option="selectedOption"
    :is-processing="isProcessing"
    @topup="handleTopup"
  />
</template>
