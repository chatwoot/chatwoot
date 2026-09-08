<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import MessageReportsAPI from 'dashboard/api/captain/messageReports';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  messageId: { type: [Number, String], required: true },
});

const { t } = useI18n();
const dialogRef = ref(null);
const isLoading = ref(false);

const REPORT_REASONS = [
  'incorrect_information',
  'inappropriate_response',
  'incomplete_response',
  'outdated_information',
  'other',
];

const reasonOptions = computed(() =>
  REPORT_REASONS.map(value => ({
    value,
    label: t(`CONVERSATION.CONTEXT_MENU.REPORT_MESSAGE.REASONS.${value}`),
  }))
);

const form = reactive({ reportReason: '', description: '' });

const isFormInvalid = computed(() => !form.reportReason);

const resetForm = () => {
  form.reportReason = '';
  form.description = '';
};

const open = () => {
  resetForm();
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

const handleConfirm = async () => {
  if (isFormInvalid.value) return;

  isLoading.value = true;
  try {
    await MessageReportsAPI.create({
      message_id: props.messageId,
      report_reason: form.reportReason,
      description: form.description.trim() || null,
    });
    useAlert(t('CONVERSATION.CONTEXT_MENU.REPORT_MESSAGE.SUCCESS'));
    close();
  } catch (error) {
    useAlert(t('CONVERSATION.CONTEXT_MENU.REPORT_MESSAGE.ERROR'));
  } finally {
    isLoading.value = false;
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CONVERSATION.CONTEXT_MENU.REPORT_MESSAGE.TITLE')"
    :description="t('CONVERSATION.CONTEXT_MENU.REPORT_MESSAGE.DESCRIPTION')"
    :confirm-button-label="t('CONVERSATION.CONTEXT_MENU.REPORT_MESSAGE.SUBMIT')"
    :is-loading="isLoading"
    :disable-confirm-button="isFormInvalid"
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-4">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('CONVERSATION.CONTEXT_MENU.REPORT_MESSAGE.PROBLEM_TYPE') }}
        </label>
        <Select
          v-model="form.reportReason"
          class="!w-full [&>select]:w-full"
          :options="reasonOptions"
          :placeholder="
            t(
              'CONVERSATION.CONTEXT_MENU.REPORT_MESSAGE.PROBLEM_TYPE_PLACEHOLDER'
            )
          "
        />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('CONVERSATION.CONTEXT_MENU.REPORT_MESSAGE.DESCRIPTION_LABEL') }}
        </label>
        <TextArea
          v-model="form.description"
          class="w-full"
          :placeholder="
            t(
              'CONVERSATION.CONTEXT_MENU.REPORT_MESSAGE.DESCRIPTION_PLACEHOLDER'
            )
          "
          :max-length="500"
          show-character-count
          auto-height
        />
      </div>
    </div>
  </Dialog>
</template>
