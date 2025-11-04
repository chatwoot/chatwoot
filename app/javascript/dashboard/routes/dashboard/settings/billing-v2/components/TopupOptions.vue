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
  <div
    class="mt-4 grid grid-cols-3 gap-5 p-4 dark:bg-n-solid-1 bg-n-slate-2 rounded-lg"
  >
    <div class="col-span-1">
      <h6 class="text-base font-semibold mb-2">
        {{ t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.TITLE') }}
      </h6>
      <p class="col-span-2 text-n-slate-11">
        {{ t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.DESCRIPTION') }}
      </p>
      <p class="col-span-2 text-n-slate-11">
        {{ t('BILLING_SETTINGS_V2.TOPUP_MODAL.INFO') }}
      </p>
    </div>
    <div class="grid grid-cols-2 col-span-2 gap-3 group">
      <div
        v-for="option in options"
        :key="option.id"
        class="p-4 bg-n-background group-hover:opacity-50 hover:!opacity-100 shadow-sm outline outline-1 outline-n-weak rounded-lg transition-all cursor-pointer"
        @click="openTopupDialog(option)"
      >
        <div class="flex gap-8">
          <div>
            <div class="text-xs tracking-wide">
              {{ $t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.CREDITS') }}
            </div>
            <div class="text-lg font-semibold">
              {{ formatNumber(option.credits) }}
            </div>
          </div>
          <div>
            <div class="text-xs tracking-wide">
              {{ $t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.PRICE') }}
            </div>
            <div class="text-lg font-semibold">
              {{ formatPrice(option.price) }}
            </div>
          </div>
        </div>
        <Button
          class="w-full mt-4"
          sm
          slate
          faded
          @click.stop="openTopupDialog(option)"
        >
          {{ $t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.BUY_NOW') }}
        </Button>
      </div>

      <div v-if="options.length === 0 && !isLoading" class="py-8 text-center">
        <p class="text-sm">
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
  </div>
</template>
