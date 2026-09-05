<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { MUTE_DURATION_VALUES } from 'dashboard/constants/automation';

const emit = defineEmits(['confirm']);

const { t } = useI18n();

const CUSTOM = 'custom';
const PERMANENT = 'permanent';

const dialogRef = ref(null);
const duration = ref(PERMANENT);
const customDate = ref('');

const durationOptions = computed(() => [
  ...MUTE_DURATION_VALUES.filter(({ id }) => id !== PERMANENT).map(
    ({ id, i18nKey }) => ({
      value: id,
      label: t(`CONTACT_PANEL.MUTE_DURATION_DIALOG.DURATIONS.${i18nKey}`),
    })
  ),
  {
    value: CUSTOM,
    label: t('CONTACT_PANEL.MUTE_DURATION_DIALOG.DURATIONS.CUSTOM'),
  },
  {
    value: PERMANENT,
    label: t('CONTACT_PANEL.MUTE_DURATION_DIALOG.DURATIONS.PERMANENT'),
  },
]);

const isCustom = computed(() => duration.value === CUSTOM);

const isCustomDateValid = computed(() => {
  if (!isCustom.value) return true;
  if (!customDate.value) return false;
  return new Date(customDate.value).getTime() > Date.now();
});

// `blocked_until` sent to the API: a preset key, an ISO timestamp, or null for permanent
const blockedUntil = computed(() => {
  if (duration.value === PERMANENT) return null;
  if (isCustom.value) return new Date(customDate.value).toISOString();
  return duration.value;
});

const open = () => {
  duration.value = PERMANENT;
  customDate.value = '';
  dialogRef.value?.open();
};

const handleConfirm = () => {
  if (!isCustomDateValid.value) return;
  emit('confirm', blockedUntil.value);
  dialogRef.value?.close();
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('CONTACT_PANEL.MUTE_DURATION_DIALOG.TITLE')"
    :description="t('CONTACT_PANEL.MUTE_DURATION_DIALOG.DESCRIPTION')"
    :confirm-button-label="t('CONTACT_PANEL.MUTE_DURATION_DIALOG.CONFIRM')"
    :disable-confirm-button="!isCustomDateValid"
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-4">
      <label class="flex flex-col gap-2 text-sm text-n-slate-12">
        {{ t('CONTACT_PANEL.MUTE_DURATION_DIALOG.DURATION_LABEL') }}
        <Select v-model="duration" :options="durationOptions" class="w-full" />
      </label>
      <Input
        v-if="isCustom"
        v-model="customDate"
        type="datetime-local"
        :label="t('CONTACT_PANEL.MUTE_DURATION_DIALOG.CUSTOM_DATE_LABEL')"
        :message-type="customDate && !isCustomDateValid ? 'error' : 'info'"
      />
    </div>
  </Dialog>
</template>
