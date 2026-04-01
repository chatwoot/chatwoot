<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainInboxes/getUIFlags'),
  inboxes: useMapGetter('inboxes/getInboxes'),
  captainInboxes: useMapGetter('captainInboxes/getRecords'),
};

const initialState = {
  inboxId: null,
};

const state = reactive({ ...initialState });

const validationRules = {
  inboxId: { required },
};

const inboxList = computed(() => {
  const captainInboxIds = formState.captainInboxes.value.map(inbox => inbox.id);

  return formState.inboxes.value
    .filter(inbox => !captainInboxIds.includes(inbox.id))
    .map(inbox => ({
      value: inbox.id,
      label: inbox.name,
    }));
});

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.INBOXES.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  inboxId: getErrorMessage('inboxId', 'INBOX'),
}));

const handleCancel = () => emit('cancel');

const prepareInboxPayload = () => ({
  inboxId: state.inboxId,
  assistantId: props.assistantId,
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareInboxPayload());
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-1">
      <label for="inbox" class="mb-0.5 text-sm font-medium text-on-surface">
        {{ t('CAPTAIN.INBOXES.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxList"
        :has-error="Boolean(formErrors.inboxId)"
        :placeholder="t('CAPTAIN.INBOXES.FORM.INBOX.PLACEHOLDER')"
        :message="formErrors.inboxId"
      />
    </div>

    <div class="flex w-full items-center justify-between gap-3">
      <Button
        type="button"
        faded
        slate
        class="w-full"
        :label="t('CAPTAIN.FORM.CANCEL')"
        @click="handleCancel"
      />
      <Button
        type="submit"
        teal
        class="w-full"
        :label="t('CAPTAIN.FORM.CREATE')"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
