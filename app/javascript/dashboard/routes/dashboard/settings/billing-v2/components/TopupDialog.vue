<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  option: {
    type: Object,
    required: true,
  },
  isProcessing: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['topup']);

const { t } = useI18n();
const dialogRef = ref(null);

const formatPrice = price => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(price);
};

const formatNumber = num => {
  return new Intl.NumberFormat('en-US').format(num);
};

const handleTopup = () => {
  emit('topup', {
    credits: props.option.credits,
  });
};

const open = () => {
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="sm"
    :title="t('BILLING_SETTINGS_V2.TOPUP_MODAL.TITLE')"
    :description="
      t('BILLING_SETTINGS_V2.TOPUP_MODAL.DESCRIPTION', {
        credits: formatNumber(option.credits),
        price: formatPrice(option.price),
      })
    "
    :confirm-button-label="t('BILLING_SETTINGS_V2.TOPUP_MODAL.CONFIRM')"
    :cancel-button-label="t('BILLING_SETTINGS_V2.TOPUP_MODAL.CANCEL')"
    :is-loading="isProcessing"
    @confirm="handleTopup"
  >
    <div class="space-y-4">
      <div
        class="px-3 py-2 rounded-lg bg-n-slate-2 dark:bg-n-solid-2 space-y-2"
      >
        <div class="flex justify-between items-center">
          <span class="text-sm text-n-slate-11">
            {{ t('BILLING_SETTINGS_V2.TOPUP_MODAL.CREDITS') }}
          </span>
          <span class="text-lg font-bold text-n-slate-12">
            {{ formatNumber(option.credits) }}
          </span>
        </div>
        <div class="flex justify-between items-center">
          <span class="text-sm text-n-slate-11">
            {{ t('BILLING_SETTINGS_V2.TOPUP_MODAL.PRICE') }}
          </span>
          <span class="text-lg font-bold text-n-slate-12">
            {{ formatPrice(option.price) }}
          </span>
        </div>
        <div
          v-if="option.description"
          class="pt-3 border-t border-n-weak text-sm text-n-slate-11"
        >
          {{ option.description }}
        </div>
      </div>
    </div>
  </Dialog>
</template>
