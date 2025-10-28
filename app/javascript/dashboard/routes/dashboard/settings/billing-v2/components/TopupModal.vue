<script setup>
import { ref, computed } from 'vue';
import Modal from 'dashboard/components/Modal.vue';
import ButtonV4 from 'next/button/Button.vue';

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

const emit = defineEmits(['close', 'topup']);

const show = ref(true);

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

const close = () => {
  show.value = false;
  emit('close');
};
</script>

<template>
  <Modal v-model:show="show" :on-close="close">
    <div class="flex flex-col h-auto overflow-auto">
      <div class="w-full px-5 py-4 border-b border-n-weak">
        <h3 class="text-lg font-semibold text-n-800">
          {{ $t('BILLING_SETTINGS_V2.TOPUP_MODAL.TITLE') }}
        </h3>
      </div>

      <div class="p-5 space-y-4">
        <!-- Option Info -->
        <div class="p-4 bg-n-25 rounded-lg">
          <h4 class="text-sm font-medium text-n-700 uppercase tracking-wide">
            {{ $t('BILLING_SETTINGS_V2.TOPUP_MODAL.SELECTED_OPTION') }}
          </h4>
          <div class="mt-2 text-center">
            <div class="text-4xl font-bold text-b-800">
              {{ formatNumber(option.credits) }}
            </div>
            <div class="mt-1 text-sm text-n-600">
              {{ $t('BILLING_SETTINGS_V2.TOPUP_MODAL.CREDITS') }}
            </div>
          </div>
        </div>

        <!-- Summary -->
        <div class="p-4 bg-b-50 rounded-lg space-y-2">
          <div class="flex justify-between items-center">
            <span class="text-sm text-n-700">{{
              $t('BILLING_SETTINGS_V2.TOPUP_MODAL.PRICE')
            }}</span>
            <span class="text-2xl font-bold text-b-800">
              {{ formatPrice(option.price) }}
            </span>
          </div>
          <div v-if="option.description" class="pt-2 border-t border-b-200">
            <p class="text-xs text-n-600">
              {{ option.description }}
            </p>
          </div>
        </div>

        <!-- Info -->
        <div class="p-3 bg-g-50 rounded-lg">
          <div class="flex gap-2">
            <span class="i-lucide-info text-g-700 flex-shrink-0 mt-0.5" />
            <p class="text-xs text-g-800">
              {{ $t('BILLING_SETTINGS_V2.TOPUP_MODAL.INFO') }}
            </p>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-2 px-5 py-4 border-t border-n-weak">
        <ButtonV4 sm faded slate :disabled="isProcessing" @click="close">
          {{ $t('BILLING_SETTINGS_V2.TOPUP_MODAL.CANCEL') }}
        </ButtonV4>
        <ButtonV4
          sm
          solid
          blue
          :loading="isProcessing"
          :disabled="isProcessing"
          @click="handleTopup"
        >
          {{ $t('BILLING_SETTINGS_V2.TOPUP_MODAL.CONFIRM') }}
        </ButtonV4>
      </div>
    </div>
  </Modal>
</template>
