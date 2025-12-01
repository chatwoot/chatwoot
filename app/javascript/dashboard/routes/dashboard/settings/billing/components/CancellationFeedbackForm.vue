<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

defineProps({
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['submit', 'back']);

const { t } = useI18n();

const selectedReason = ref('');
const additionalFeedback = ref('');

const cancellationReasons = [
  {
    key: 'too_expensive',
    label: 'BILLING_SETTINGS.FEEDBACK_MODAL.REASONS.TOO_EXPENSIVE',
  },
  {
    key: 'not_using',
    label: 'BILLING_SETTINGS.FEEDBACK_MODAL.REASONS.NOT_USING',
  },
  {
    key: 'missing_features',
    label: 'BILLING_SETTINGS.FEEDBACK_MODAL.REASONS.MISSING_FEATURES',
  },
  {
    key: 'better_alternative',
    label: 'BILLING_SETTINGS.FEEDBACK_MODAL.REASONS.BETTER_ALTERNATIVE',
  },
  {
    key: 'technical_issues',
    label: 'BILLING_SETTINGS.FEEDBACK_MODAL.REASONS.TECHNICAL_ISSUES',
  },
  { key: 'other', label: 'BILLING_SETTINGS.FEEDBACK_MODAL.REASONS.OTHER' },
];

const handleSubmit = () => {
  emit('submit', {
    reason: selectedReason.value,
    feedback: additionalFeedback.value,
  });
};

const handleBack = () => {
  emit('back');
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <p class="text-sm text-n-slate-11">
      {{ t('BILLING_SETTINGS.FEEDBACK_MODAL.DESCRIPTION') }}
    </p>

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('BILLING_SETTINGS.FEEDBACK_MODAL.REASON_LABEL') }}
      </label>
      <div class="flex flex-col gap-2">
        <label
          v-for="reason in cancellationReasons"
          :key="reason.key"
          class="flex items-center gap-3 p-3 transition-colors border rounded-lg cursor-pointer border-n-weak hover:bg-n-alpha-1"
          :class="{
            'border-n-teal-9 bg-n-teal-9/5': selectedReason === reason.key,
          }"
        >
          <input
            v-model="selectedReason"
            type="radio"
            name="cancellation-reason"
            :value="reason.key"
            class="w-4 h-4 accent-n-teal-9"
          />
          <span class="text-sm text-n-slate-12">{{ t(reason.label) }}</span>
        </label>
      </div>
    </div>

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-11">
        {{ t('BILLING_SETTINGS.FEEDBACK_MODAL.FEEDBACK_LABEL') }}
      </label>
      <textarea
        v-model="additionalFeedback"
        rows="3"
        class="w-full p-3 text-sm transition-colors border rounded-lg resize-none bg-n-alpha-1 border-n-weak text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:border-n-strong"
        :placeholder="t('BILLING_SETTINGS.FEEDBACK_MODAL.FEEDBACK_PLACEHOLDER')"
      />
    </div>

    <div class="flex items-center gap-3 pt-2">
      <button
        type="button"
        class="flex-1 px-4 py-2 text-sm font-medium transition-colors border rounded-lg border-n-weak text-n-slate-12 hover:bg-n-alpha-1"
        :disabled="isLoading"
        @click="handleBack"
      >
        {{ t('BILLING_SETTINGS.FEEDBACK_MODAL.GO_BACK') }}
      </button>
      <button
        type="button"
        class="flex-1 px-4 py-2 text-sm font-medium text-white transition-colors rounded-lg bg-n-slate-9 hover:bg-n-slate-10 disabled:opacity-50"
        :disabled="!selectedReason || isLoading"
        @click="handleSubmit"
      >
        {{ t('BILLING_SETTINGS.FEEDBACK_MODAL.SUBMIT_CANCEL') }}
      </button>
    </div>
  </div>
</template>
