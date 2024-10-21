<script setup>
import { ref, reactive } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  customDomain: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['addCustomDomain']);

const { t } = useI18n();

const dialogRef = ref(null);

const formState = reactive({
  customDomain: props.customDomain,
});

const handleDialogConfirm = () => {
  emit('addCustomDomain', formState.customDomain);
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.HEADER'
      )
    "
    :description="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.DESCRIPTION'
      )
    "
    :confirm-button-label="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.CONFIRM_BUTTON_LABEL'
      )
    "
    @confirm="handleDialogConfirm"
  >
    <template #form>
      <Input
        v-model="formState.customDomain"
        :label="
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.LABEL'
          )
        "
        :placeholder="
          t(
            'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.PLACEHOLDER'
          )
        "
      />
    </template>
  </Dialog>
</template>
