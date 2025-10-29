<script setup>
import { ref } from 'vue';
import Modal from 'dashboard/components/Modal.vue';
import ButtonV4 from 'next/button/Button.vue';

const props = defineProps({
  isCanceling: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'cancel']);

const show = ref(true);
const reason = ref('');

const handleCancel = () => {
  emit('cancel', reason.value);
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
          {{ $t('BILLING_SETTINGS_V2.CANCEL_MODAL.TITLE') }}
        </h3>
      </div>

      <div class="p-5 space-y-4">
        <!-- Warning -->
        <div class="p-4 bg-r-50 rounded-lg">
          <div class="flex gap-3">
            <span
              class="i-lucide-alert-triangle text-r-700 flex-shrink-0 mt-0.5"
            />
            <div>
              <h4 class="text-sm font-semibold text-r-800">
                {{ $t('BILLING_SETTINGS_V2.CANCEL_MODAL.WARNING_TITLE') }}
              </h4>
              <p class="mt-1 text-sm text-r-700">
                {{ $t('BILLING_SETTINGS_V2.CANCEL_MODAL.WARNING_MESSAGE') }}
              </p>
            </div>
          </div>
        </div>

        <!-- Reason -->
        <div>
          <label class="block mb-2 text-sm font-medium text-n-700">
            {{ $t('BILLING_SETTINGS_V2.CANCEL_MODAL.REASON_LABEL') }}
            <span class="text-n-500">{{
              $t('BILLING_SETTINGS_V2.CANCEL_MODAL.OPTIONAL')
            }}</span>
          </label>
          <textarea
            v-model="reason"
            rows="4"
            class="w-full px-3 py-2 border border-n-weak rounded-lg focus:outline-none focus:ring-2 focus:ring-b-500 resize-none"
            :placeholder="
              $t('BILLING_SETTINGS_V2.CANCEL_MODAL.REASON_PLACEHOLDER')
            "
          />
        </div>

        <!-- Info -->
        <div class="p-3 bg-n-25 rounded-lg">
          <div class="flex gap-2">
            <span class="i-lucide-info text-n-600 flex-shrink-0 mt-0.5" />
            <p class="text-xs text-n-700">
              {{ $t('BILLING_SETTINGS_V2.CANCEL_MODAL.INFO') }}
            </p>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-2 px-5 py-4 border-t border-n-weak">
        <ButtonV4 sm faded slate :disabled="isCanceling" @click="close">
          {{ $t('BILLING_SETTINGS_V2.CANCEL_MODAL.KEEP_SUBSCRIPTION') }}
        </ButtonV4>
        <ButtonV4 sm solid red :is-loading="isCanceling" @click="handleCancel">
          {{ $t('BILLING_SETTINGS_V2.CANCEL_MODAL.CONFIRM_CANCEL') }}
        </ButtonV4>
      </div>
    </div>
  </Modal>
</template>
