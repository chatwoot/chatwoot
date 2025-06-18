<script setup>
import { ref, reactive, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { isDomain } from 'shared/helpers/Validators';
import { useVuelidate } from '@vuelidate/core';
import { useStore } from 'dashboard/composables/store.js';
import { useAlert } from 'dashboard/composables';

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
const emit = defineEmits(['removeCustomDomain']);

const store = useStore();

const { t } = useI18n();

const dialogRef = ref(null);
const errorMsg = ref(null);

const removeDomain = async () => {
  try {
    const res = await store.dispatch('portals/removeDomain', {
      initialCustomDomain: props.customDomain,
    });
    emit('removeCustomDomain');
    var alertMessage = t(
      `HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.REMOVE_CONFIRMATION`,
      { domain: props.customDomain }
    );
    useAlert(alertMessage);
    return res;
  } catch (error) {
    var alertMessage =
      error?.message ||
      t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_DOMAIN');
    useAlert(alertMessage);
    return null;
  }
};

const state = reactive({
  domain: props.customDomain,
});

watch(
  () => props.customDomain,
  newVal => {
    state.domain = newVal;
  }
);

const rules = {
  domain: { isDomain },
};

const v$ = useVuelidate(rules, state);

watch(
  () => state.domain,
  async () => {
    isDomainValid.value = null;
    errorMsg.value = null;
    await v$.value.$validate();
  }
);

const handleDialogConfirm = () => {
  removeDomain();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="
      t(
        `HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.REMOVE_DIALOG.HEADER`,
        {
          domain: customDomain,
        }
      )
    "
    :confirm-button-label="
      t(
        `HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.CUSTOM_DOMAIN.REMOVE_DIALOG.CONFIRM_BUTTON_LABEL`
      )
    "
    @confirm="handleDialogConfirm"
  >
  </Dialog>
</template>
