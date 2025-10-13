<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, helpers } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedCampaign: {
    type: Object,
    default: () => ({}),
  },
  showActionButtons: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('marketingCampaigns/getUIFlags'),
};

const initialState = {
  title: '',
  description: '',
  source_id: '',
  start_date: '',
  end_date: '',
};

const state = reactive({ ...initialState });

// Validator that only checks minLength if value is not empty
const minLengthIfNotEmpty = value => {
  if (!value || value.trim() === '') return true;
  return value.length >= 1;
};

const validationRules = {
  title: { required, minLength: minLength(1) },
  description: {
    minLengthIfNotEmpty: helpers.withMessage(
      'Description must have at least 1 character',
      minLengthIfNotEmpty
    ),
  },
  source_id: {},
  start_date: { required },
  end_date: { required },
};

const v$ = useVuelidate(validationRules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);
const isSubmitDisabled = computed(() => v$.value.$invalid);

const currentDateTime = computed(() => {
  // Added to disable the scheduled at field from being set to the current time
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.MARKETING.CREATE.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  description: getErrorMessage('description', 'MESSAGE'),
  source_id: getErrorMessage('source_id', 'INBOX'),
  start_date: getErrorMessage('start_date', 'INBOX'),
  end_date: getErrorMessage('end_date', 'INBOX'),
}));

const resetState = () => Object.assign(state, initialState);

const handleCancel = () => emit('cancel');

const prepareCampaignDetails = () => {
  // Convert datetime-local format to ISO 8601 format for API
  const formatDateTimeForAPI = dateTimeString => {
    if (!dateTimeString) return '';
    // datetime-local format: YYYY-MM-DDTHH:MM
    // Create a Date object treating it as local time
    const date = new Date(dateTimeString);
    // Convert to ISO 8601 string (includes timezone)
    return date.toISOString();
  };

  return {
    title: state.title,
    description: state.description,
    source_id: state.source_id,
    start_date: formatDateTimeForAPI(state.start_date),
    end_date: formatDateTimeForAPI(state.end_date),
  };
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  emit('submit', prepareCampaignDetails());
  if (props.mode === 'create') {
    resetState();
    handleCancel();
  }
};

const updateStateFromCampaign = campaign => {
  if (!campaign) return;

  const { title, description, source_id, start_date, end_date } = campaign;

  // Convert Unix timestamp (seconds) to datetime-local format (YYYY-MM-DDTHH:MM)
  const formatTimestampForInput = timestamp => {
    if (!timestamp) return '';
    // API returns Unix timestamp in seconds
    // Create Date object (multiply by 1000 to convert to milliseconds)
    const date = new Date(timestamp * 1000);
    // Convert to ISO string and extract YYYY-MM-DDTHH:MM format
    // toISOString returns UTC, but datetime-local input expects local time
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}`;
  };

  Object.assign(state, {
    title,
    description,
    source_id,
    start_date: formatTimestampForInput(start_date),
    end_date: formatTimestampForInput(end_date),
  });
};

watch(
  () => props.selectedCampaign,
  newCampaign => {
    if (props.mode === 'edit' && newCampaign) {
      updateStateFromCampaign(newCampaign);
    }
  },
  { immediate: true }
);

defineExpose({ prepareCampaignDetails, isSubmitDisabled });
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.title"
      :label="t('CAMPAIGN.MARKETING.CREATE.FORM.TITLE.LABEL')"
      :placeholder="t('CAMPAIGN.MARKETING.CREATE.FORM.TITLE.PLACEHOLDER')"
      :message="formErrors.title"
      :message-type="formErrors.title ? 'error' : 'info'"
    />

    <Editor
      v-model="state.description"
      :label="t('CAMPAIGN.MARKETING.CREATE.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CAMPAIGN.MARKETING.CREATE.FORM.DESCRIPTION.PLACEHOLDER')"
      :message="formErrors.description"
      :message-type="formErrors.description ? 'error' : 'info'"
    />

    <Input
      v-model="state.start_date"
      :label="t('CAMPAIGN.MARKETING.CREATE.FORM.START_DATE.LABEL')"
      type="datetime-local"
      :min="currentDateTime"
      :placeholder="t('CAMPAIGN.MARKETING.CREATE.FORM.START_DATE.PLACEHOLDER')"
      :message="formErrors.startDate"
      :message-type="formErrors.startDate ? 'error' : 'info'"
    />

    <Input
      v-model="state.end_date"
      :label="t('CAMPAIGN.MARKETING.CREATE.FORM.END_DATE.LABEL')"
      type="datetime-local"
      :min="currentDateTime"
      :placeholder="t('CAMPAIGN.MARKETING.CREATE.FORM.END_DATE.PLACEHOLDER')"
      :message="formErrors.endDate"
      :message-type="formErrors.endDate ? 'error' : 'info'"
    />

    <Input
      v-model="state.source_id"
      :label="t('CAMPAIGN.MARKETING.CREATE.FORM.SOURCE_ID.LABEL')"
      :placeholder="t('CAMPAIGN.MARKETING.CREATE.FORM.SOURCE_ID.PLACEHOLDER')"
      :message="formErrors.sourceId"
      :message-type="formErrors.sourceId ? 'error' : 'info'"
    />
    <div
      v-if="showActionButtons"
      class="flex items-center justify-between w-full gap-3"
    >
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('CAMPAIGN.MARKETING.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="
          t(`CAMPAIGN.MARKETING.CREATE.FORM.BUTTONS.${mode.toUpperCase()}`)
        "
        class="w-full"
        :is-loading="isCreating"
        :disabled="isCreating || isSubmitDisabled"
      />
    </div>
  </form>
</template>
