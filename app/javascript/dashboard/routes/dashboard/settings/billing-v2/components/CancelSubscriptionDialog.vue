<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Notice from 'dashboard/components-next/notice/Notice.vue';

defineProps({
  isCanceling: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['cancel']);

const { t } = useI18n();

const dialogRef = ref(null);
const reason = ref('');

const handleCancel = () => {
  emit('cancel', reason.value);
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    width="xl"
    :title="t('BILLING_SETTINGS_V2.CANCEL_MODAL.TITLE')"
    :confirm-button-label="t('BILLING_SETTINGS_V2.CANCEL_MODAL.CONFIRM_CANCEL')"
    :cancel-button-label="
      t('BILLING_SETTINGS_V2.CANCEL_MODAL.KEEP_SUBSCRIPTION')
    "
    :is-loading="isCanceling"
    @confirm="handleCancel"
  >
    <div class="space-y-4">
      <Notice
        color="ruby"
        icon="i-lucide-alert-triangle"
        :title="t('BILLING_SETTINGS_V2.CANCEL_MODAL.WARNING_TITLE')"
        :message="t('BILLING_SETTINGS_V2.CANCEL_MODAL.WARNING_MESSAGE')"
      />

      <TextArea
        v-model="reason"
        :label="t('BILLING_SETTINGS_V2.CANCEL_MODAL.REASON_LABEL')"
        :placeholder="t('BILLING_SETTINGS_V2.CANCEL_MODAL.REASON_PLACEHOLDER')"
        :max-length="1500"
        auto-height
      />

      <div class="flex gap-1.5 items-center">
        <Icon icon="i-lucide-info" class="flex-shrink-0" />
        <p class="text-xs text-n-slate-12">
          {{ t('BILLING_SETTINGS_V2.CANCEL_MODAL.INFO') }}
        </p>
      </div>
    </div>
  </Dialog>
</template>
