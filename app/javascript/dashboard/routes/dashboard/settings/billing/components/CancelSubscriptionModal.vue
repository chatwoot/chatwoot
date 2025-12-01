<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CancellationFeedbackForm from './CancellationFeedbackForm.vue';

defineProps({
  planName: {
    type: String,
    default: '',
  },
  renewsOn: {
    type: String,
    default: '',
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['confirm', 'close']);

const { t } = useI18n();

const dialogRef = ref(null);
const step = ref('warning'); // 'warning' | 'feedback'

const features = [
  'BILLING_SETTINGS.CANCEL_MODAL.FEATURE_AI_CREDITS',
  'BILLING_SETTINGS.CANCEL_MODAL.FEATURE_TEAM_COLLABORATION',
  'BILLING_SETTINGS.CANCEL_MODAL.FEATURE_PRIORITY_SUPPORT',
];

const handleProceedToFeedback = () => {
  step.value = 'feedback';
};

const handleBack = () => {
  step.value = 'warning';
};

const handleFeedbackSubmit = ({ reason, feedback }) => {
  emit('confirm', { reason, feedback });
};

const handleClose = () => {
  step.value = 'warning';
  emit('close');
};

const open = () => {
  step.value = 'warning';
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
    :title="
      step === 'warning'
        ? t('BILLING_SETTINGS.CANCEL_MODAL.TITLE')
        : t('BILLING_SETTINGS.FEEDBACK_MODAL.TITLE')
    "
    width="lg"
    :show-confirm-button="false"
    :show-cancel-button="false"
    @close="handleClose"
  >
    <!-- Warning Step -->
    <template v-if="step === 'warning'">
      <div class="p-4 border rounded-lg bg-n-ruby-9/5 border-n-ruby-9/20">
        <div class="flex gap-3">
          <span
            class="flex-shrink-0 i-lucide-alert-triangle size-5 text-n-ruby-9"
          />
          <div class="flex flex-col gap-2">
            <p class="text-sm font-medium text-n-ruby-11">
              {{
                t('BILLING_SETTINGS.CANCEL_MODAL.WARNING_TITLE', {
                  plan: planName,
                })
              }}
            </p>
            <p class="text-sm text-n-ruby-11/80">
              {{
                t('BILLING_SETTINGS.CANCEL_MODAL.WARNING_DESCRIPTION', {
                  date: renewsOn,
                })
              }}
            </p>
            <ul class="mt-2 space-y-1">
              <li
                v-for="feature in features"
                :key="feature"
                class="flex items-center gap-2 text-sm text-n-ruby-11"
              >
                <span class="size-1.5 rounded-full bg-n-ruby-9" />
                {{ t(feature) }}
              </li>
            </ul>
          </div>
        </div>
      </div>

      <div class="flex items-center gap-3 mt-6">
        <Button
          variant="faded"
          color="slate"
          :label="t('BILLING_SETTINGS.CANCEL_MODAL.KEEP_SUBSCRIPTION')"
          class="flex-1"
          @click="close"
        />
        <Button
          color="ruby"
          solid
          :label="t('BILLING_SETTINGS.CANCEL_MODAL.CANCEL_SUBSCRIPTION')"
          class="flex-1"
          @click="handleProceedToFeedback"
        />
      </div>
    </template>

    <!-- Feedback Step -->
    <template v-else>
      <CancellationFeedbackForm
        :is-loading="isLoading"
        @submit="handleFeedbackSubmit"
        @back="handleBack"
      />
    </template>
  </Dialog>
</template>
