<script setup>
import { reactive, computed, ref, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, requiredIf, minLength } from '@vuelidate/validators';
import { useDebounceFn } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import {
  BROADCAST_CHANNELS,
  getBroadcastChannel,
  insertVariableAtCursor,
} from 'dashboard/helper/campaignHelper';
import CampaignsAPI from 'dashboard/api/campaigns';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import WhatsAppTemplateParser from 'dashboard/components-next/whatsapp/WhatsAppTemplateParser.vue';
import VariableChips from 'dashboard/components-next/Campaigns/VariableChips.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'create',
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedCampaign: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();

const { SMS: CHANNEL_SMS, WHATSAPP: CHANNEL_WHATSAPP } = BROADCAST_CHANNELS;

const labels = useMapGetter('labels/getLabels');
const smsInboxes = useMapGetter('inboxes/getSMSInboxes');
const whatsAppInboxes = useMapGetter('inboxes/getWhatsAppInboxes');
const campaignTemplates = useMapGetter(
  'campaignTemplates/getCampaignTemplates'
);
const getFilteredWhatsAppTemplates = useMapGetter(
  'inboxes/getFilteredWhatsAppTemplates'
);

const state = reactive({
  channel: CHANNEL_SMS,
  title: '',
  inboxId: null,
  message: '',
  templateId: null,
  campaignTemplateId: null,
  selectedAudience: [],
  scheduledAt: null,
});

const messageRef = ref(null);
const templateParserRef = ref(null);
const pendingCampaignTemplateId = ref(null);
// Bumped to remount the picker so a discarded selection is not left displayed.
const campaignTemplatePickerKey = ref(0);
const audienceCount = ref(null);

const isWhatsApp = computed(() => state.channel === CHANNEL_WHATSAPP);
const isEditMode = computed(() => props.mode === 'edit');

const rules = {
  title: { required, minLength: minLength(1) },
  inboxId: { required },
  message: { required: requiredIf(() => !isWhatsApp.value) },
  templateId: { required: requiredIf(() => isWhatsApp.value) },
  scheduledAt: { required },
  selectedAudience: { required },
};

const v$ = useVuelidate(rules, state);

const isWhatsAppCampaignEnabled = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.WHATSAPP_CAMPAIGNS)
);

const hasSMSInboxes = computed(() => smsInboxes.value.length > 0);
const hasWhatsAppInboxes = computed(
  () => whatsAppInboxes.value.length > 0 && isWhatsAppCampaignEnabled.value
);

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

const audienceList = computed(() => mapToOptions(labels.value, 'id', 'title'));

const inboxOptions = computed(() =>
  mapToOptions(
    isWhatsApp.value ? whatsAppInboxes.value : smsInboxes.value,
    'id',
    'name'
  )
);

const campaignTemplateOptions = computed(() =>
  mapToOptions(campaignTemplates.value, 'id', 'name')
);

const whatsAppTemplateOptions = computed(() => {
  if (!state.inboxId) return [];

  return getFilteredWhatsAppTemplates.value(state.inboxId).map(template => ({
    value: template.id,
    label: `${template.name.replace(/_/g, ' ')} (${template.language || 'en'})`,
    template,
  }));
});

const selectedWhatsAppTemplate = computed(
  () =>
    whatsAppTemplateOptions.value.find(
      option => option.value === state.templateId
    )?.template
);

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.BROADCAST.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  message: getErrorMessage('message', 'MESSAGE'),
  template: getErrorMessage('templateId', 'WHATSAPP_TEMPLATE'),
  scheduledAt: getErrorMessage('scheduledAt', 'SCHEDULED_AT'),
  audience: getErrorMessage('selectedAudience', 'AUDIENCE'),
}));

const hasRequiredTemplateParams = computed(
  () => !isWhatsApp.value || templateParserRef.value?.isFormInvalid === false
);

const isSubmitDisabled = computed(
  () => v$.value.$invalid || !hasRequiredTemplateParams.value
);

const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const handleChannelSelect = channel => {
  state.channel = channel;
  state.inboxId = null;
  state.templateId = null;
};

const applyCampaignTemplate = templateId => {
  const template = campaignTemplates.value.find(
    record => record.id === templateId
  );
  if (!template) return;

  state.campaignTemplateId = templateId;
  state.message = template.body;
  pendingCampaignTemplateId.value = null;
};

const handleCampaignTemplateSelect = templateId => {
  if (state.message) {
    pendingCampaignTemplateId.value = templateId;
    return;
  }

  applyCampaignTemplate(templateId);
};

const discardCampaignTemplate = () => {
  pendingCampaignTemplateId.value = null;
  campaignTemplatePickerKey.value += 1;
};

const handleInsertVariable = token => {
  const element = messageRef.value?.textareaRef;
  const { value, cursorPosition } = insertVariableAtCursor(
    element,
    state.message,
    token
  );
  state.message = value;

  nextTick(() => {
    element?.focus();
    element?.setSelectionRange(cursorPosition, cursorPosition);
  });
};

const fetchAudienceCount = useDebounceFn(async labelIds => {
  if (!labelIds.length) {
    audienceCount.value = null;
    return;
  }

  try {
    const { data } = await CampaignsAPI.getAudienceCount(labelIds);
    audienceCount.value = data.count;
  } catch (error) {
    audienceCount.value = null;
  }
}, 400);

const prepareCampaignDetails = () => {
  const details = {
    title: state.title,
    message: state.message,
    inbox_id: state.inboxId,
    scheduled_at: formatToUTCString(state.scheduledAt),
    audience: state.selectedAudience?.map(id => ({
      id,
      type: 'Label',
    })),
  };

  if (!isWhatsApp.value) return details;

  const template = selectedWhatsAppTemplate.value;
  const parserData = templateParserRef.value;

  return {
    ...details,
    message: parserData?.renderedTemplate || '',
    template_params: {
      name: template?.name || '',
      namespace: template?.namespace || '',
      category: template?.category || 'UTILITY',
      language: template?.language || 'en_US',
      processed_params: parserData?.processedParams || {},
    },
  };
};

const toLocalDateTimeString = unixTimestamp => {
  const date = new Date(unixTimestamp * 1000);
  return new Date(date.getTime() - date.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
};

const updateStateFromCampaign = campaign => {
  const {
    title,
    message,
    inbox,
    audience,
    scheduled_at: scheduledAt,
    template_params: templateParams,
  } = campaign;

  Object.assign(state, {
    channel: getBroadcastChannel(inbox),
    title,
    message,
    inboxId: inbox?.id ?? null,
    selectedAudience: audience?.map(({ id }) => id) ?? [],
    scheduledAt: scheduledAt ? toLocalDateTimeString(scheduledAt) : null,
  });

  if (state.channel === CHANNEL_WHATSAPP && templateParams?.name) {
    state.templateId =
      whatsAppTemplateOptions.value.find(
        option => option.template.name === templateParams.name
      )?.value ?? null;
  }
};

// Seed the state before the watchers are registered so restoring a campaign
// does not look like a user edit.
if (isEditMode.value && props.selectedCampaign) {
  updateStateFromCampaign(props.selectedCampaign);
} else if (!hasSMSInboxes.value && hasWhatsAppInboxes.value) {
  state.channel = CHANNEL_WHATSAPP;
}

watch(
  () => state.selectedAudience,
  labelIds => fetchAudienceCount(labelIds ?? []),
  { immediate: true, deep: true }
);

watch(
  () => state.inboxId,
  () => {
    state.templateId = null;
  }
);

defineExpose({ prepareCampaignDetails, isSubmitDisabled });
</script>

<template>
  <form class="flex flex-col gap-6" @submit.prevent>
    <section class="flex flex-col gap-4">
      <h4 class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.BROADCAST.FORM.SECTIONS.CHANNEL') }}
      </h4>

      <div v-if="!isEditMode" class="flex flex-col gap-3">
        <RadioCard
          v-if="hasSMSInboxes"
          id="sms"
          :label="t('CAMPAIGN.CHANNEL.SMS')"
          :description="t('CAMPAIGN.BROADCAST.FORM.CHANNEL.SMS_DESCRIPTION')"
          :is-active="!isWhatsApp"
          @select="handleChannelSelect"
        />
        <RadioCard
          v-if="hasWhatsAppInboxes"
          id="whatsapp"
          :label="t('CAMPAIGN.CHANNEL.WHATSAPP')"
          :description="
            t('CAMPAIGN.BROADCAST.FORM.CHANNEL.WHATSAPP_DESCRIPTION')
          "
          :is-active="isWhatsApp"
          @select="handleChannelSelect"
        />
        <p
          v-if="!hasSMSInboxes && !hasWhatsAppInboxes"
          class="mb-0 text-sm text-n-slate-11"
        >
          {{ t('CAMPAIGN.BROADCAST.FORM.CHANNEL.NO_INBOX') }}
        </p>
      </div>
      <p v-else class="mb-0 text-sm text-n-slate-11">
        {{
          t('CAMPAIGN.BROADCAST.FORM.CHANNEL.LOCKED', {
            channel: isWhatsApp
              ? t('CAMPAIGN.CHANNEL.WHATSAPP')
              : t('CAMPAIGN.CHANNEL.SMS'),
          })
        }}
      </p>

      <Input
        v-model="state.title"
        :label="t('CAMPAIGN.BROADCAST.FORM.TITLE.LABEL')"
        :placeholder="t('CAMPAIGN.BROADCAST.FORM.TITLE.PLACEHOLDER')"
        :message="formErrors.title"
        :message-type="formErrors.title ? 'error' : 'info'"
      />

      <div class="flex flex-col gap-1">
        <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ t('CAMPAIGN.BROADCAST.FORM.INBOX.LABEL') }}
        </label>
        <ComboBox
          id="inbox"
          v-model="state.inboxId"
          :options="inboxOptions"
          :has-error="!!formErrors.inbox"
          :placeholder="t('CAMPAIGN.BROADCAST.FORM.INBOX.PLACEHOLDER')"
          :message="formErrors.inbox"
          class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        />
      </div>
    </section>

    <section class="flex flex-col gap-4">
      <h4 class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.BROADCAST.FORM.SECTIONS.MESSAGE') }}
      </h4>

      <template v-if="isWhatsApp">
        <div class="flex flex-col gap-1">
          <label
            for="whatsappTemplate"
            class="mb-0.5 text-sm font-medium text-n-slate-12"
          >
            {{ t('CAMPAIGN.BROADCAST.FORM.WHATSAPP_TEMPLATE.LABEL') }}
          </label>
          <ComboBox
            id="whatsappTemplate"
            v-model="state.templateId"
            :options="whatsAppTemplateOptions"
            :has-error="!!formErrors.template"
            :placeholder="
              t('CAMPAIGN.BROADCAST.FORM.WHATSAPP_TEMPLATE.PLACEHOLDER')
            "
            :message="formErrors.template"
            class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
          />
          <p class="mt-1 mb-0 text-xs text-n-slate-11">
            {{ t('CAMPAIGN.BROADCAST.FORM.WHATSAPP_TEMPLATE.INFO') }}
          </p>
        </div>

        <WhatsAppTemplateParser
          v-if="selectedWhatsAppTemplate"
          ref="templateParserRef"
          :template="selectedWhatsAppTemplate"
        />
      </template>

      <template v-else>
        <div class="flex flex-col gap-1">
          <label
            for="campaignTemplate"
            class="mb-0.5 text-sm font-medium text-n-slate-12"
          >
            {{ t('CAMPAIGN.BROADCAST.FORM.CAMPAIGN_TEMPLATE.LABEL') }}
          </label>
          <ComboBox
            id="campaignTemplate"
            :key="campaignTemplatePickerKey"
            :model-value="state.campaignTemplateId"
            :options="campaignTemplateOptions"
            :placeholder="
              t('CAMPAIGN.BROADCAST.FORM.CAMPAIGN_TEMPLATE.PLACEHOLDER')
            "
            :empty-state="
              t('CAMPAIGN.BROADCAST.FORM.CAMPAIGN_TEMPLATE.EMPTY_STATE')
            "
            class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
            @update:model-value="handleCampaignTemplateSelect"
          />
        </div>

        <div
          v-if="pendingCampaignTemplateId"
          class="flex flex-col gap-2 p-3 rounded-lg bg-n-amber-2"
        >
          <p class="mb-0 text-sm text-n-amber-11">
            {{
              t('CAMPAIGN.BROADCAST.FORM.CAMPAIGN_TEMPLATE.OVERWRITE_WARNING')
            }}
          </p>
          <div class="flex gap-2">
            <Button
              size="sm"
              type="button"
              :label="
                t('CAMPAIGN.BROADCAST.FORM.CAMPAIGN_TEMPLATE.OVERWRITE_CONFIRM')
              "
              @click="applyCampaignTemplate(pendingCampaignTemplateId)"
            />
            <Button
              size="sm"
              type="button"
              variant="faded"
              color="slate"
              :label="
                t('CAMPAIGN.BROADCAST.FORM.CAMPAIGN_TEMPLATE.OVERWRITE_CANCEL')
              "
              @click="discardCampaignTemplate"
            />
          </div>
        </div>

        <TextArea
          ref="messageRef"
          v-model="state.message"
          :label="t('CAMPAIGN.BROADCAST.FORM.MESSAGE.LABEL')"
          :placeholder="t('CAMPAIGN.BROADCAST.FORM.MESSAGE.PLACEHOLDER')"
          show-character-count
          :message="formErrors.message"
          :message-type="formErrors.message ? 'error' : 'info'"
        />

        <VariableChips @insert="handleInsertVariable" />
      </template>
    </section>

    <section class="flex flex-col gap-4">
      <h4 class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.BROADCAST.FORM.SECTIONS.AUDIENCE') }}
      </h4>

      <div class="flex flex-col gap-1">
        <label
          for="audience"
          class="mb-0.5 text-sm font-medium text-n-slate-12"
        >
          {{ t('CAMPAIGN.BROADCAST.FORM.AUDIENCE.LABEL') }}
        </label>
        <TagMultiSelectComboBox
          v-model="state.selectedAudience"
          :options="audienceList"
          :label="t('CAMPAIGN.BROADCAST.FORM.AUDIENCE.LABEL')"
          :placeholder="t('CAMPAIGN.BROADCAST.FORM.AUDIENCE.PLACEHOLDER')"
          :has-error="!!formErrors.audience"
          :message="formErrors.audience"
          class="[&>div>button]:bg-n-alpha-black2"
        />
        <p
          v-if="audienceCount !== null"
          class="mt-1 mb-0 text-xs text-n-slate-11"
        >
          {{
            t('CAMPAIGN.BROADCAST.FORM.AUDIENCE.ESTIMATED_REACH', {
              count: audienceCount,
            })
          }}
        </p>
      </div>
    </section>

    <section class="flex flex-col gap-4">
      <h4 class="text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.BROADCAST.FORM.SECTIONS.SCHEDULE') }}
      </h4>

      <Input
        v-model="state.scheduledAt"
        :label="t('CAMPAIGN.BROADCAST.FORM.SCHEDULED_AT.LABEL')"
        type="datetime-local"
        :min="currentDateTime"
        :placeholder="t('CAMPAIGN.BROADCAST.FORM.SCHEDULED_AT.PLACEHOLDER')"
        :message="formErrors.scheduledAt"
        :message-type="formErrors.scheduledAt ? 'error' : 'info'"
      />
    </section>
  </form>
</template>
