<script setup>
import { reactive, computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, requiredIf, minLength } from '@vuelidate/validators';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { URLPattern } from 'urlpattern-polyfill';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
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
const store = useStore();

const TRIGGER_ALL_PAGES = 'allPages';
const TRIGGER_SPECIFIC_PAGES = 'specificPages';

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  inboxes: useMapGetter('inboxes/getWebsiteInboxes'),
};

const senderList = ref([]);

const initialState = {
  title: '',
  message: '',
  inboxId: null,
  senderId: 0,
  enabled: true,
  triggerOnlyDuringBusinessHours: false,
  triggerScope: TRIGGER_ALL_PAGES,
  endPoint: '',
  timeOnPage: 10,
};

const state = reactive({ ...initialState });

const isSpecificPages = computed(
  () => state.triggerScope === TRIGGER_SPECIFIC_PAGES
);

const urlValidators = {
  shouldBeAValidURLPattern: value => {
    if (!isSpecificPages.value) return true;
    try {
      // eslint-disable-next-line
      new URLPattern(value);
      return true;
    } catch {
      return false;
    }
  },
  shouldStartWithHTTP: value => {
    if (!isSpecificPages.value) return true;
    return value
      ? value.startsWith('https://') || value.startsWith('http://')
      : false;
  },
};

const validationRules = {
  title: { required, minLength: minLength(1) },
  message: { required, minLength: minLength(1) },
  inboxId: { required },
  senderId: { required },
  endPoint: {
    required: requiredIf(isSpecificPages),
    ...urlValidators,
  },
  timeOnPage: { required },
};

const v$ = useVuelidate(validationRules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);
const isSubmitDisabled = computed(() => v$.value.$invalid);

const mapToOptions = (items, valueKey, labelKey) =>
  items?.map(item => ({
    value: item[valueKey],
    label: item[labelKey],
  })) ?? [];

const inboxOptions = computed(() =>
  mapToOptions(formState.inboxes.value, 'id', 'name')
);

const sendersAndBotList = computed(() => [
  { value: 0, label: t('CAMPAIGN.PROACTIVE.CARD.CAMPAIGN_DETAILS.BOT') },
  ...mapToOptions(senderList.value, 'id', 'name'),
]);

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.PROACTIVE.CREATE.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  message: getErrorMessage('message', 'MESSAGE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  endPoint: getErrorMessage('endPoint', 'END_POINT'),
  timeOnPage: getErrorMessage('timeOnPage', 'TIME_ON_PAGE'),
  sender: getErrorMessage('senderId', 'SENT_BY'),
}));

const resetState = () => Object.assign(state, initialState);

const handleCancel = () => emit('cancel');

const handleTriggerScopeSelect = scope => {
  state.triggerScope = scope;
};

const handleInboxChange = async inboxId => {
  if (!inboxId) {
    senderList.value = [];
    return;
  }

  try {
    const response = await store.dispatch('inboxMembers/get', { inboxId });
    senderList.value = response?.data?.payload ?? [];
  } catch (error) {
    senderList.value = [];
    useAlert(
      error?.response?.message ??
        t('CAMPAIGN.PROACTIVE.CREATE.FORM.API.ERROR_MESSAGE')
    );
  }
};

const prepareCampaignDetails = () => ({
  title: state.title,
  message: state.message,
  inbox_id: state.inboxId,
  sender_id: state.senderId || null,
  enabled: state.enabled,
  trigger_only_during_business_hours: state.triggerOnlyDuringBusinessHours,
  trigger_rules: {
    url: isSpecificPages.value ? state.endPoint : '',
    time_on_page: state.timeOnPage,
  },
});

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

  const {
    title,
    message,
    inbox: { id: inboxId },
    sender,
    enabled,
    trigger_only_during_business_hours: triggerOnlyDuringBusinessHours,
    trigger_rules: { url: endPoint, time_on_page: timeOnPage },
  } = campaign;

  Object.assign(state, {
    title,
    message,
    inboxId,
    senderId: sender?.id ?? 0,
    enabled,
    triggerOnlyDuringBusinessHours,
    triggerScope: endPoint ? TRIGGER_SPECIFIC_PAGES : TRIGGER_ALL_PAGES,
    endPoint: endPoint ?? '',
    timeOnPage,
  });
};

watch(
  () => state.inboxId,
  newInboxId => {
    if (newInboxId) {
      handleInboxChange(newInboxId);
    }
  },
  { immediate: true }
);

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
  <form class="flex flex-col gap-6" @submit.prevent="handleSubmit">
    <section class="flex flex-col gap-4">
      <h4 class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.PROACTIVE.CREATE.FORM.SECTIONS.MESSAGE') }}
      </h4>

      <Input
        v-model="state.title"
        :label="t('CAMPAIGN.PROACTIVE.CREATE.FORM.TITLE.LABEL')"
        :placeholder="t('CAMPAIGN.PROACTIVE.CREATE.FORM.TITLE.PLACEHOLDER')"
        :message="formErrors.title"
        :message-type="formErrors.title ? 'error' : 'info'"
      />

      <Editor
        v-model="state.message"
        :label="t('CAMPAIGN.PROACTIVE.CREATE.FORM.MESSAGE.LABEL')"
        :placeholder="t('CAMPAIGN.PROACTIVE.CREATE.FORM.MESSAGE.PLACEHOLDER')"
        :message="formErrors.message"
        :message-type="formErrors.message ? 'error' : 'info'"
      />

      <div class="flex flex-col gap-1">
        <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ t('CAMPAIGN.PROACTIVE.CREATE.FORM.INBOX.LABEL') }}
        </label>
        <ComboBox
          id="inbox"
          v-model="state.inboxId"
          :options="inboxOptions"
          :has-error="!!formErrors.inbox"
          :placeholder="t('CAMPAIGN.PROACTIVE.CREATE.FORM.INBOX.PLACEHOLDER')"
          :message="formErrors.inbox"
          class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        />
      </div>

      <div class="flex flex-col gap-1">
        <label for="sentBy" class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ t('CAMPAIGN.PROACTIVE.CREATE.FORM.SENT_BY.LABEL') }}
        </label>
        <ComboBox
          id="sentBy"
          v-model="state.senderId"
          :options="sendersAndBotList"
          :has-error="!!formErrors.sender"
          :disabled="!state.inboxId"
          :placeholder="t('CAMPAIGN.PROACTIVE.CREATE.FORM.SENT_BY.PLACEHOLDER')"
          class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
          :message="formErrors.sender"
        />
      </div>
    </section>

    <section class="flex flex-col gap-4">
      <h4 class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.PROACTIVE.CREATE.FORM.SECTIONS.TRIGGER') }}
      </h4>

      <div class="flex flex-col gap-3">
        <RadioCard
          id="allPages"
          :label="t('CAMPAIGN.PROACTIVE.CREATE.FORM.TRIGGER_SCOPE.ALL.LABEL')"
          :description="
            t('CAMPAIGN.PROACTIVE.CREATE.FORM.TRIGGER_SCOPE.ALL.DESCRIPTION')
          "
          :is-active="!isSpecificPages"
          @select="handleTriggerScopeSelect"
        />
        <RadioCard
          id="specificPages"
          :label="
            t('CAMPAIGN.PROACTIVE.CREATE.FORM.TRIGGER_SCOPE.SPECIFIC.LABEL')
          "
          :description="
            t(
              'CAMPAIGN.PROACTIVE.CREATE.FORM.TRIGGER_SCOPE.SPECIFIC.DESCRIPTION'
            )
          "
          :is-active="isSpecificPages"
          @select="handleTriggerScopeSelect"
        />
      </div>

      <Input
        v-if="isSpecificPages"
        v-model="state.endPoint"
        type="url"
        :label="t('CAMPAIGN.PROACTIVE.CREATE.FORM.END_POINT.LABEL')"
        :placeholder="t('CAMPAIGN.PROACTIVE.CREATE.FORM.END_POINT.PLACEHOLDER')"
        :message="formErrors.endPoint"
        :message-type="formErrors.endPoint ? 'error' : 'info'"
      />

      <Input
        v-model="state.timeOnPage"
        type="number"
        :label="t('CAMPAIGN.PROACTIVE.CREATE.FORM.TIME_ON_PAGE.LABEL')"
        :placeholder="
          t('CAMPAIGN.PROACTIVE.CREATE.FORM.TIME_ON_PAGE.PLACEHOLDER')
        "
        :message="formErrors.timeOnPage"
        :message-type="formErrors.timeOnPage ? 'error' : 'info'"
      />
    </section>

    <fieldset class="flex flex-col gap-2.5">
      <legend class="mb-2.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.PROACTIVE.CREATE.FORM.SECTIONS.ADVANCED') }}
      </legend>

      <label class="flex items-center gap-2">
        <input v-model="state.triggerOnlyDuringBusinessHours" type="checkbox" />
        <span class="text-sm font-medium text-n-slate-12">
          {{
            t(
              'CAMPAIGN.PROACTIVE.CREATE.FORM.OTHER_PREFERENCES.TRIGGER_ONLY_BUSINESS_HOURS'
            )
          }}
        </span>
      </label>

      <label class="flex items-center gap-2">
        <input v-model="state.enabled" type="checkbox" />
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CAMPAIGN.PROACTIVE.CREATE.FORM.OTHER_PREFERENCES.ENABLED') }}
        </span>
      </label>
    </fieldset>

    <div
      v-if="showActionButtons"
      class="flex items-center justify-between w-full gap-3"
    >
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('CAMPAIGN.PROACTIVE.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-11 hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="
          t(`CAMPAIGN.PROACTIVE.CREATE.FORM.BUTTONS.${mode.toUpperCase()}`)
        "
        class="w-full"
        :is-loading="isCreating"
        :disabled="isCreating || isSubmitDisabled"
      />
    </div>
  </form>
</template>
