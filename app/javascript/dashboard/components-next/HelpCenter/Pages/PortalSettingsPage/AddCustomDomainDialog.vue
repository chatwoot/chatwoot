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
const emit = defineEmits(['addCustomDomain']);

const store = useStore();

const { t } = useI18n();

const dialogRef = ref(null);
const isValidating = ref(false);
const isDomainValid = ref(null);
const errorMsg = ref(null);

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

const checkDomain = async domain => {
  try {
    const res = await store.dispatch('portals/checkDomain', {
      domain,
    });
    return res;
  } catch (error) {
    this.alertMessage =
      error?.message ||
      t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE_FOR_DOMAIN');
    useAlert(this.alertMessage);
    return null;
  }
};
async function checkDomainInternal(domain) {
  try {
    isValidating.value = true;
    const res = await checkDomain(domain);
    if (res.message === false) {
      errorMsg.value = res.error;
      return;
    }
    isDomainValid.value = res.message;
  } catch (error) {
    isDomainValid.value = false;
  } finally {
    isValidating.value = false;
  }
}

async function onCheckDomainClick() {
  await v$.value.$validate();
  if (state.domain === '' || v$.value.domain.$errors.length > 0) return;
  await checkDomainInternal(state.domain);
}

const handleDialogConfirm = () => {
  if (isDomainValid.value) {
    emit('addCustomDomain', state.domain);
  }
};

const domainError = computed(() => {
  return v$.value.domain.$error ? t('HELP_CENTER.PORTAL.ADD.DOMAIN.ERROR') : '';
});

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
    :disable-confirm-button="isDomainValid != true"
    @confirm="handleDialogConfirm"
  >
    <Input
      v-model="state.domain"
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
      :message="domainError"
      message-type="error"
    />
    <Button
      :disabled="
        state.domain == '' || isValidating || v$.domain.$errors.length > 0
      "
      :is-loading="isValidating"
      @click="onCheckDomainClick"
    >
      {{ t('HELP_CENTER.PORTAL.ADD.DOMAIN.VALIDATE_BUTTON') }}
    </Button>
    <p v-if="errorMsg" class="text-red-500">
      {{ errorMsg }}
    </p>
    <p v-if="isDomainValid === true" class="text-green-500">
      {{ t('HELP_CENTER.PORTAL.ADD.DOMAIN.VALID_MESSAGE') }}
    </p>
  </Dialog>
</template>
