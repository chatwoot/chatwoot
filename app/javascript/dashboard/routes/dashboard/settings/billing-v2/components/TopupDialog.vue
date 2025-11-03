<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Notice from 'dashboard/components-next/notice/Notice.vue';

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
    :confirm-button-label="t('BILLING_SETTINGS_V2.TOPUP_MODAL.CONFIRM')"
    :cancel-button-label="t('BILLING_SETTINGS_V2.TOPUP_MODAL.CANCEL')"
    :is-loading="isProcessing"
    @confirm="handleTopup"
  >
    <div class="space-y-4">
      <div class="p-4 rounded-lg bg-n-blue-2 dark:bg-n-blue-3 text-center">
        <div class="text-4xl font-bold text-n-blue-11">
          {{ formatNumber(option.credits) }}
        </div>
        <div class="mt-1 text-sm text-n-slate-11">
          {{ t('BILLING_SETTINGS_V2.TOPUP_MODAL.CREDITS') }}
        </div>
      </div>

      <div class="p-4 rounded-lg bg-n-slate-2 dark:bg-n-solid-2 space-y-3">
        <div class="flex justify-between items-center">
          <span class="text-sm text-n-slate-11">
            {{ t('BILLING_SETTINGS_V2.TOPUP_MODAL.PRICE') }}
          </span>
          <span class="text-2xl font-bold text-n-slate-12">
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

      <Notice
        color="teal"
        icon="i-lucide-info"
        :message="t('BILLING_SETTINGS_V2.TOPUP_MODAL.INFO')"
      />
    </div>
  </Dialog>
</template>
