<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Modal from 'dashboard/components/Modal.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'success']);

const { t } = useI18n();
const store = useStore();

const isOpen = ref(props.show);
const selectedReason = ref('');
const customReason = ref('');
const isSubmitting = ref(false);

// Watch for prop changes
import { watch } from 'vue';
watch(
  () => props.show,
  newVal => {
    isOpen.value = newVal;
    // Reset form when modal opens
    if (newVal) {
      selectedReason.value = '';
      customReason.value = '';
    }
  }
);

// Predefined close reasons
const closeReasons = computed(() => [
  { value: 'resolved_success', label: t('CLOSE_REASON.RESOLVED_SUCCESS') },
  {
    value: 'resolved_compensation',
    label: t('CLOSE_REASON.RESOLVED_COMPENSATION'),
  },
  { value: 'partially_resolved', label: t('CLOSE_REASON.PARTIALLY_RESOLVED') },
  { value: 'waiting_client', label: t('CLOSE_REASON.WAITING_CLIENT') },
  { value: 'escalated', label: t('CLOSE_REASON.ESCALATED') },
  { value: 'conflict', label: t('CLOSE_REASON.CONFLICT') },
  { value: 'custom', label: t('CLOSE_REASON.CUSTOM') },
]);

const canSubmit = computed(() => {
  // Need a reason to submit
  if (selectedReason.value === 'custom') {
    return customReason.value.trim().length > 0;
  }
  return selectedReason.value !== '';
});

const closeModal = () => {
  isOpen.value = false;
  emit('close');
};

const submitReason = async () => {
  if (!canSubmit.value) return;

  isSubmitting.value = true;

  try {
    // Prepare the reason value
    let reasonValue = selectedReason.value;
    let customReasonText = null;

    // If custom reason is selected, save the text to custom_attributes
    if (selectedReason.value === 'custom') {
      customReasonText = customReason.value;
    }

    // Update conversation with resolution reason
    await store.dispatch('toggleStatus', {
      conversationId: props.conversationId,
      status: 'resolved',
      resolutionReason: reasonValue === 'custom' ? null : reasonValue,
    });

    // If custom reason, save it to custom_attributes
    if (customReasonText) {
      await store.dispatch('updateCustomAttributes', {
        conversationId: props.conversationId,
        customAttributes: {
          custom_resolution_reason: customReasonText,
          resolved_at: new Date().toISOString(),
        },
      });
    }

    useAlert(t('CLOSE_REASON.SUCCESS_MESSAGE'));
    emit('success', { reason: reasonValue, customReason: customReasonText });
    closeModal();
  } catch (error) {
    useAlert(t('CLOSE_REASON.ERROR_MESSAGE'));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <Modal v-model:show="isOpen" :on-close="closeModal" @close="closeModal">
    <div class="flex flex-col">
      <!-- Header -->
      <div class="p-4 border-b border-n-slate-5">
        <h1 class="text-n-slate-12 text-lg font-semibold">
          {{ $t('CLOSE_REASON.TITLE') }}
        </h1>
      </div>

      <!-- Body -->
      <div class="flex flex-col gap-4 p-4">
        <!-- Reason selector -->
        <div class="flex flex-col gap-2">
          <!-- Predefined reasons -->
          <div class="flex flex-col gap-2 max-h-64 overflow-y-auto">
            <label
              v-for="reason in closeReasons"
              :key="reason.value"
              class="flex items-center gap-2 p-2 rounded-lg cursor-pointer hover:bg-n-slate-3 transition-colors"
              :class="{ 'bg-n-slate-3': selectedReason === reason.value }"
            >
              <input
                v-model="selectedReason"
                type="radio"
                :value="reason.value"
                class="text-blue-600"
              />
              <span class="text-sm">{{ reason.label }}</span>
            </label>
          </div>

          <!-- Custom reason input -->
          <div v-if="selectedReason === 'custom'" class="mt-2">
            <textarea
              v-model="customReason"
              :placeholder="$t('CLOSE_REASON.CUSTOM_PLACEHOLDER')"
              class="w-full p-2 border border-n-slate-5 rounded-lg resize-none"
              rows="3"
            />
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex justify-end gap-2 p-4 border-t border-n-slate-5">
        <Button
          faded
          slate
          :label="$t('CLOSE_REASON.CANCEL')"
          @click="closeModal"
        />
        <Button
          :label="$t('CLOSE_REASON.SAVE')"
          :is-loading="isSubmitting"
          :disabled="!canSubmit"
          @click="submitReason"
        />
      </div>
    </div>
  </Modal>
</template>

<style scoped>
.max-h-64 {
  max-height: 16rem;
}
</style>
