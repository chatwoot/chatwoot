<script setup>
import { ref, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { helpers } from '@vuelidate/validators';
import { isValidDomain } from '@chatwoot/utils';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'add',
  },
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

const rules = {
  customDomain: {
    isValidDomain: helpers.withMessage(
      () =>
        t(
          'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.FORMAT_ERROR'
        ),
      isValidDomain
    ),
  },
};

const v$ = useVuelidate(rules, formState);

watch(
  () => props.customDomain,
  newVal => {
    formState.customDomain = newVal;
  }
);

const handleDialogConfirm = async () => {
  const isFormCorrect = await v$.value.$validate();
  if (!isFormCorrect) return;

  emit('addCustomDomain', formState.customDomain);
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      t(
        `HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.${props.mode.toUpperCase()}_HEADER`
      )
    "
    :confirm-button-label="
      t(
        `HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.DIALOG.${props.mode.toUpperCase()}_CONFIRM_BUTTON_LABEL`
      )
    "
    @confirm="handleDialogConfirm"
  >
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
      :message="
        v$.customDomain.$error ? v$.customDomain.$errors[0].$message : ''
      "
      :message-type="v$.customDomain.$error ? 'error' : 'info'"
      @blur="v$.customDomain.$touch()"
    />
  </Dialog>
</template>
