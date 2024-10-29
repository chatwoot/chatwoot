<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import MultiSelectComboBox from 'dashboard/components-next/combobox/MultiSelectComboBox.vue';

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  labels: useMapGetter('labels/getLabels'),
  inboxes: useMapGetter('inboxes/getSMSInboxes'),
};

const state = reactive({
  title: '',
  message: '',
  inboxId: null,
  scheduledAt: null,
  selectedAudience: [],
});

const rules = {
  title: { required, minLength: minLength(1) },
  message: { required, minLength: minLength(1) },
  inboxId: { required },
  scheduledAt: { required },
  selectedAudience: { required },
};

const v$ = useVuelidate(rules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);

const currentDateTime = computed(() => {
  const now = new Date();
  return new Date(now.getTime() - now.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
});

const audienceList = computed(
  () =>
    formState.labels.value?.map(({ id, title }) => ({
      value: id,
      label: title,
    })) ?? []
);

const inboxOptions = computed(
  () =>
    formState.inboxes.value?.map(({ id, name }) => ({
      value: id,
      label: name,
    })) ?? []
);

const formErrors = computed(() => ({
  title: v$.value.title.$error
    ? t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.TITLE.ERROR')
    : '',
  message: v$.value.message.$error
    ? t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.MESSAGE.ERROR')
    : '',
  inbox: v$.value.inboxId.$error
    ? t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.INBOX.ERROR')
    : '',
  scheduledAt: v$.value.scheduledAt.$error
    ? t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.SCHEDULED_AT.ERROR')
    : '',
  audience: v$.value.selectedAudience.$error
    ? t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.AUDIENCE.ERROR')
    : '',
}));

const isSubmitDisabled = computed(() => v$.value.$invalid);

const formatToUTCString = localDateTime => {
  if (!localDateTime) return null;
  return new Date(localDateTime).toISOString();
};

const resetState = () => {
  state.title = '';
  state.message = '';
  state.inboxId = null;
  state.scheduledAt = null;
  state.selectedAudience = [];
};

const handleCancel = () => emit('cancel');

const handleSubmit = async () => {
  const isFormCorrect = await v$.value.$validate();
  if (!isFormCorrect) return;

  const campaignDetails = {
    title: state.title,
    message: state.message,
    inbox_id: state.inboxId,
    scheduled_at: formatToUTCString(state.scheduledAt),
    audience: state.selectedAudience.map(({ value }) => ({
      id: value,
      type: 'Label',
    })),
  };

  emit('submit', campaignDetails);
  resetState();
  handleCancel();
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <Input
      v-model="state.title"
      :label="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.TITLE.LABEL')"
      :placeholder="
        t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.TITLE.PLACEHOLDER')
      "
      :message="formErrors.title"
      :message-type="formErrors.title ? 'error' : 'info'"
    />

    <TextArea
      v-model="state.message"
      :label="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.MESSAGE.LABEL')"
      :placeholder="
        t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.MESSAGE.PLACEHOLDER')
      "
      show-character-count
      :message="formErrors.message"
      :message-type="formErrors.message ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-1">
      <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-11">
        {{ t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="
          t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.INBOX.PLACEHOLDER')
        "
        class="[&>div>button]:dark:bg-slate-900"
      />
      <p
        v-if="formErrors.inbox"
        class="min-w-0 mt-1 mb-0 text-xs truncate text-n-ruby-9 dark:text-n-ruby-9"
      >
        {{ formErrors.inbox }}
      </p>
    </div>

    <div class="flex flex-col gap-1">
      <label for="audience" class="mb-0.5 text-sm font-medium text-n-slate-11">
        {{ t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.AUDIENCE.LABEL') }}
      </label>
      <MultiSelectComboBox
        v-model="state.selectedAudience"
        :options="audienceList"
        :label="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.AUDIENCE.LABEL')"
        :placeholder="
          t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.AUDIENCE.PLACEHOLDER')
        "
        :has-error="!!formErrors.audience"
      />
      <p
        v-if="formErrors.audience"
        class="min-w-0 mt-1 mb-0 text-xs truncate text-n-ruby-9 dark:text-n-ruby-9"
      >
        {{ formErrors.audience }}
      </p>
    </div>

    <Input
      v-model="state.scheduledAt"
      :label="
        t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.SCHEDULED_AT.LABEL')
      "
      type="datetime-local"
      :min="currentDateTime"
      :placeholder="
        t(
          'CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.SCHEDULED_AT.PLACEHOLDER'
        )
      "
      :message="formErrors.scheduledAt"
      :message-type="formErrors.scheduledAt ? 'error' : 'info'"
    />

    <div class="flex items-center justify-between w-full gap-3">
      <Button
        variant="faded"
        color="slate"
        :label="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        :label="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.CREATE.FORM.BUTTONS.CREATE')"
        class="w-full"
        :is-loading="isCreating"
        :disabled="isCreating || isSubmitDisabled"
        @click="handleSubmit"
      />
    </div>
  </div>
</template>
