<script setup>
import { reactive, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import {
  required,
  minLength,
  numeric,
  minValue,
  maxValue,
} from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  labels: useMapGetter('labels/getLabels'),
  inboxes: useMapGetter('inboxes/getAPIInboxes'),
};

const initialState = {
  title: '',
  message: '',
  inboxId: null,
  scheduledAt: null,
  selectedAudience: [],
};

const state = reactive({ ...initialState });

// Delay configuration state
const delayType = ref('none');
const delaySeconds = ref(0);
const delayMin = ref(1);
const delayMax = ref(5);

const rules = {
  title: { required, minLength: minLength(1) },
  message: { required, minLength: minLength(1) },
  inboxId: { required },
  scheduledAt: { required },
  selectedAudience: { required },
};

// Custom validator for delay min/max range
const delayRangeValidator = () => {
  if (delayType.value === 'random') {
    return delayMin.value <= delayMax.value;
  }
  return true;
};

// Dynamic validation rules for delay fields
const delayValidationRules = computed(() => {
  if (delayType.value === 'fixed') {
    return {
      delaySeconds: {
        required,
        numeric,
        minValue: minValue(0),
        maxValue: maxValue(300),
      },
    };
  }
  if (delayType.value === 'random') {
    return {
      delayMin: {
        required,
        numeric,
        minValue: minValue(0),
        maxValue: maxValue(300),
      },
      delayMax: {
        required,
        numeric,
        minValue: minValue(0),
        maxValue: maxValue(300),
        delayRangeValidator,
      },
    };
  }
  return {};
});

const delayState = computed(() => ({
  delaySeconds: delaySeconds.value,
  delayMin: delayMin.value,
  delayMax: delayMax.value,
}));

const v$ = useVuelidate(rules, state);
const v$delay = useVuelidate(delayValidationRules, delayState);

const isCreating = computed(() => formState.uiFlags.value.isCreating);

const currentDateTime = computed(() => {
  // Added to disable the scheduled at field from being set to the current time
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

const mapToOptions = (items, valueKey, labelKey) =>
  items?.map(item => ({
    value: item[valueKey],
    label: item[labelKey],
  })) ?? [];

const audienceList = computed(() =>
  mapToOptions(formState.labels.value, 'id', 'title')
);

const inboxOptions = computed(() =>
  mapToOptions(formState.inboxes.value, 'id', 'name')
);

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.API.CREATE.FORM';
  // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  message: getErrorMessage('message', 'MESSAGE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  scheduledAt: getErrorMessage('scheduledAt', 'SCHEDULED_AT'),
  audience: getErrorMessage('selectedAudience', 'AUDIENCE'),
}));

const isSubmitDisabled = computed(() => v$.value.$invalid);

const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const resetState = () => {
  Object.assign(state, initialState);
  delayType.value = 'none';
  delaySeconds.value = 0;
  delayMin.value = 1;
  delayMax.value = 5;
};

const handleCancel = () => emit('cancel');

const prepareDelayConfiguration = () => {
  if (delayType.value === 'fixed') {
    return {
      type: 'fixed',
      seconds: delaySeconds.value,
    };
  }
  if (delayType.value === 'random') {
    return {
      type: 'random',
      min: delayMin.value,
      max: delayMax.value,
    };
  }
  return {
    type: 'none',
  };
};

const prepareCampaignDetails = () => ({
  title: state.title,
  message: state.message,
  inbox_id: state.inboxId,
  scheduled_at: formatToUTCString(state.scheduledAt),
  audience: state.selectedAudience?.map(id => ({
    id,
    type: 'Label',
  })),
  trigger_rules: {
    delay: prepareDelayConfiguration(),
  },
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  const isDelayValid = await v$delay.value.$validate();

  if (!isFormValid || !isDelayValid) return;

  emit('submit', prepareCampaignDetails());
  resetState();
  handleCancel();
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.title"
      :label="t('CAMPAIGN.API.CREATE.FORM.TITLE.LABEL')"
      :placeholder="t('CAMPAIGN.API.CREATE.FORM.TITLE.PLACEHOLDER')"
      :message="formErrors.title"
      :message-type="formErrors.title ? 'error' : 'info'"
    />

    <TextArea
      v-model="state.message"
      :label="t('CAMPAIGN.API.CREATE.FORM.MESSAGE.LABEL')"
      :placeholder="t('CAMPAIGN.API.CREATE.FORM.MESSAGE.PLACEHOLDER')"
      :max-length="150000"
      show-character-count
      :message="formErrors.message"
      :message-type="formErrors.message ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-1">
      <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.CREATE.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="t('CAMPAIGN.API.CREATE.FORM.INBOX.PLACEHOLDER')"
        :message="formErrors.inbox"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
    </div>

    <div class="flex flex-col gap-1">
      <label for="audience" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.CREATE.FORM.AUDIENCE.LABEL') }}
      </label>
      <TagMultiSelectComboBox
        v-model="state.selectedAudience"
        :options="audienceList"
        :label="t('CAMPAIGN.API.CREATE.FORM.AUDIENCE.LABEL')"
        :placeholder="t('CAMPAIGN.API.CREATE.FORM.AUDIENCE.PLACEHOLDER')"
        :has-error="!!formErrors.audience"
        :message="formErrors.audience"
        class="[&>div>button]:bg-n-alpha-black2"
      />
    </div>

    <Input
      v-model="state.scheduledAt"
      :label="t('CAMPAIGN.API.CREATE.FORM.SCHEDULED_AT.LABEL')"
      type="datetime-local"
      :min="currentDateTime"
      :placeholder="t('CAMPAIGN.API.CREATE.FORM.SCHEDULED_AT.PLACEHOLDER')"
      :message="formErrors.scheduledAt"
      :message-type="formErrors.scheduledAt ? 'error' : 'info'"
    />

    <!-- Message Delay Configuration -->
    <div
      class="flex flex-col gap-3 p-4 border border-n-slate-6 rounded-lg bg-n-alpha-black2"
    >
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.API.CREATE.FORM.DELAY.LABEL') }}
      </label>

      <!-- Radio buttons for delay type -->
      <div class="flex flex-wrap gap-4">
        <label class="flex items-center cursor-pointer">
          <input
            v-model="delayType"
            type="radio"
            value="none"
            class="w-4 h-4 text-n-blue-9 border-n-slate-7 focus:ring-n-blue-9 focus:ring-2"
          />
          <span class="ml-2 text-sm text-n-slate-12">
            {{ t('CAMPAIGN.API.CREATE.FORM.DELAY.NONE') }}
          </span>
        </label>

        <label class="flex items-center cursor-pointer">
          <input
            v-model="delayType"
            type="radio"
            value="fixed"
            class="w-4 h-4 text-n-blue-9 border-n-slate-7 focus:ring-n-blue-9 focus:ring-2"
          />
          <span class="ml-2 text-sm text-n-slate-12">
            {{ t('CAMPAIGN.API.CREATE.FORM.DELAY.FIXED') }}
          </span>
        </label>

        <label class="flex items-center cursor-pointer">
          <input
            v-model="delayType"
            type="radio"
            value="random"
            class="w-4 h-4 text-n-blue-9 border-n-slate-7 focus:ring-n-blue-9 focus:ring-2"
          />
          <span class="ml-2 text-sm text-n-slate-12">
            {{ t('CAMPAIGN.API.CREATE.FORM.DELAY.RANDOM') }}
          </span>
        </label>
      </div>

      <!-- Fixed delay input -->
      <div v-if="delayType === 'fixed'" class="flex flex-col gap-2">
        <Input
          v-model.number="delaySeconds"
          type="number"
          min="0"
          max="300"
          :label="t('CAMPAIGN.API.CREATE.FORM.DELAY.FIXED_SECONDS')"
          :placeholder="t('CAMPAIGN.API.CREATE.FORM.DELAY.FIXED_PLACEHOLDER')"
          :message="
            v$delay.delaySeconds?.$error
              ? t('CAMPAIGN.API.CREATE.FORM.DELAY.ERROR_RANGE')
              : t('CAMPAIGN.API.CREATE.FORM.DELAY.HELP_TEXT')
          "
          :message-type="v$delay.delaySeconds?.$error ? 'error' : 'info'"
        />
      </div>

      <!-- Random delay inputs -->
      <div v-if="delayType === 'random'" class="flex flex-col gap-3">
        <div class="grid grid-cols-2 gap-4">
          <Input
            v-model.number="delayMin"
            type="number"
            min="0"
            max="300"
            :label="t('CAMPAIGN.API.CREATE.FORM.DELAY.MIN_SECONDS')"
            :message="
              v$delay.delayMin?.$error
                ? t('CAMPAIGN.API.CREATE.FORM.DELAY.ERROR_RANGE')
                : ''
            "
            :message-type="v$delay.delayMin?.$error ? 'error' : 'info'"
          />

          <Input
            v-model.number="delayMax"
            type="number"
            min="0"
            max="300"
            :label="t('CAMPAIGN.API.CREATE.FORM.DELAY.MAX_SECONDS')"
            :message="
              v$delay.delayMax?.$error
                ? t('CAMPAIGN.API.CREATE.FORM.DELAY.ERROR_RANGE')
                : ''
            "
            :message-type="v$delay.delayMax?.$error ? 'error' : 'info'"
          />
        </div>

        <p v-if="delayMin > delayMax" class="text-xs text-n-red-9">
          {{ t('CAMPAIGN.API.CREATE.FORM.DELAY.ERROR_MIN_MAX') }}
        </p>

        <p class="text-xs text-n-slate-11">
          {{ t('CAMPAIGN.API.CREATE.FORM.DELAY.RANDOM_HELP_TEXT') }}
        </p>
      </div>
    </div>

    <div class="flex items-center justify-between w-full gap-3">
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('CAMPAIGN.API.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        :label="t('CAMPAIGN.API.CREATE.FORM.BUTTONS.CREATE')"
        class="w-full"
        type="submit"
        :is-loading="isCreating"
        :disabled="isCreating || isSubmitDisabled"
      />
    </div>
  </form>
</template>
