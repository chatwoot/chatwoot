<script setup>
import { reactive, computed, ref, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { URLPattern } from 'urlpattern-polyfill';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

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
  endPoint: '',
  timeOnPage: 10,
};

const state = reactive({ ...initialState });

const validationRules = {
  title: { required, minLength: minLength(1) },
  message: { required, minLength: minLength(1) },
  inboxId: { required },
  senderId: { required },
  endPoint: {
    required,
    shouldBeAValidURLPattern(value) {
      try {
        // eslint-disable-next-line
        new URLPattern(value);
        return true;
      } catch {
        return false;
      }
    },
    shouldStartWithHTTP(value) {
      if (value) {
        return value.startsWith('https://') || value.startsWith('http://');
      }
      return false;
    },
  },
  timeOnPage: { required },
};

const v$ = useVuelidate(validationRules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);
const isSubmitDisabled = computed(() => v$.value.$invalid);

const inboxOptions = computed(
  () =>
    formState.inboxes.value?.map(({ id, name }) => ({
      value: id,
      label: name,
    })) ?? []
);

const sendersAndBotList = computed(() => [
  { value: 0, label: 'Bot' },
  ...senderList.value.map(({ id, name }) => ({
    value: id,
    label: name,
  })),
]);

const formErrors = computed(() => ({
  title: v$.value.title.$error
    ? t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.TITLE.ERROR')
    : '',
  message: v$.value.message.$error
    ? t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.MESSAGE.ERROR')
    : '',
  inbox: v$.value.inboxId.$error
    ? t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.INBOX.ERROR')
    : '',
  endPoint: v$.value.endPoint.$error
    ? t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.END_POINT.ERROR')
    : '',
  timeOnPage: v$.value.timeOnPage.$error
    ? t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.TIME_ON_PAGE.ERROR')
    : '',
  sender: v$.value.senderId.$error
    ? t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.SENT_BY.ERROR')
    : '',
}));

const handleInboxChange = async inboxId => {
  if (!inboxId) {
    senderList.value = [];
    return;
  }

  try {
    const { data: { payload } = {} } = await store.dispatch(
      'inboxMembers/get',
      { inboxId }
    );
    senderList.value = payload ?? [];
  } catch (error) {
    senderList.value = [];
    const errorMessage =
      error?.response?.message ??
      t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
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
    url: state.endPoint,
    time_on_page: state.timeOnPage,
  },
});

const handleSubmit = async () => {
  const isFormCorrect = await v$.value.$validate();
  if (!isFormCorrect) return;

  emit('submit', prepareCampaignDetails());
};

watch(
  () => state.inboxId,
  newInboxId => {
    handleInboxChange(newInboxId);
  },
  { immediate: true }
);

watch(
  () => props.selectedCampaign,
  newSelectedCampaign => {
    if (props.mode === 'edit' && newSelectedCampaign) {
      const {
        title,
        message,
        inbox: { id: inboxId },
        sender,
        enabled,
        trigger_only_during_business_hours: triggerOnlyDuringBusinessHours,
        trigger_rules: { url: endPoint, time_on_page: timeOnPage },
      } = newSelectedCampaign;
      Object.assign(state, {
        title,
        message,
        inboxId,
        senderId: (sender && sender.id) || 0,
        enabled,
        triggerOnlyDuringBusinessHours,
        endPoint,
        timeOnPage,
      });
    }
  },
  { immediate: true }
);

// Expose the formRef to the parent component
defineExpose({ prepareCampaignDetails, isSubmitDisabled });
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.title"
      :label="t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.TITLE.LABEL')"
      :placeholder="
        t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.TITLE.PLACEHOLDER')
      "
      :message="formErrors.title"
      :message-type="formErrors.title ? 'error' : 'info'"
    />

    <TextArea
      v-model="state.message"
      :label="t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.MESSAGE.LABEL')"
      :placeholder="
        t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.MESSAGE.PLACEHOLDER')
      "
      show-character-count
      :message="formErrors.message"
      :message-type="formErrors.message ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-1">
      <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-11">
        {{ t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="
          t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.INBOX.PLACEHOLDER')
        "
        class="[&>div>button]:dark:bg-slate-900"
      />
      <p
        v-if="formErrors.inbox"
        class="min-w-0 mt-1 mb-0 text-xs truncate text-n-ruby-9"
      >
        {{ formErrors.inbox }}
      </p>
    </div>

    <div class="flex flex-col gap-1">
      <label for="sentBy" class="mb-0.5 text-sm font-medium text-n-slate-11">
        {{ t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.SENT_BY.LABEL') }}
      </label>
      <ComboBox
        id="sentBy"
        v-model="state.senderId"
        :options="sendersAndBotList"
        :has-error="!!formErrors.sender"
        :disabled="!state.inboxId"
        :placeholder="
          t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.SENT_BY.PLACEHOLDER')
        "
        class="[&>div>button]:dark:bg-slate-900"
      />
      <p
        v-if="formErrors.sender"
        class="min-w-0 mt-1 mb-0 text-xs truncate text-n-ruby-9"
      >
        {{ formErrors.sender }}
      </p>
    </div>

    <Input
      v-model="state.endPoint"
      type="url"
      :label="t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.END_POINT.LABEL')"
      :placeholder="
        t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.END_POINT.PLACEHOLDER')
      "
      :message="formErrors.endPoint"
      :message-type="formErrors.endPoint ? 'error' : 'info'"
    />

    <Input
      v-model="state.timeOnPage"
      type="number"
      :label="
        t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.TIME_ON_PAGE.LABEL')
      "
      :placeholder="
        t(
          'CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.TIME_ON_PAGE.PLACEHOLDER'
        )
      "
      :message="formErrors.timeOnPage"
      :message-type="formErrors.timeOnPage ? 'error' : 'info'"
    />

    <fieldset class="flex flex-col gap-2.5">
      <legend class="mb-2.5 text-sm font-medium text-n-slate-11">
        {{
          t(
            'CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.OTHER_PREFERENCES.TITLE'
          )
        }}
      </legend>

      <label class="flex items-center gap-2">
        <input v-model="state.enabled" type="checkbox" />
        <span class="text-sm font-medium text-n-slate-11">
          {{
            t(
              'CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.OTHER_PREFERENCES.ENABLED'
            )
          }}
        </span>
      </label>

      <label class="flex items-center gap-2">
        <input v-model="state.triggerOnlyDuringBusinessHours" type="checkbox" />
        <span class="text-sm font-medium text-n-slate-11">
          {{
            t(
              'CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.OTHER_PREFERENCES.TRIGGER_ONLY_BUSINESS_HOURS'
            )
          }}
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
        :label="t('CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 n-blue-text hover:bg-n-alpha-3"
        @click="emit('cancel')"
      />
      <Button
        type="submit"
        :label="
          t(
            `CAMPAIGN.ONGOING_CAMPAIGNS_PAGE.CREATE.FORM.BUTTONS.${mode.toUpperCase()}`
          )
        "
        class="w-full"
        :is-loading="isCreating"
        :disabled="isCreating"
      />
    </div>
  </form>
</template>
