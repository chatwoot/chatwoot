<script setup>
import { computed, onActivated, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';

import { isWhatsAppComplete } from '@chatwoot/utils';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useAlert, useTrack } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import {
  COMPONENT_TYPES,
  DEFAULT_CATEGORY,
  DEFAULT_LANGUAGE,
  findComponentByType,
  renderTemplatePreview,
} from 'dashboard/helper/templateHelper';
import InboxHealthAPI from 'dashboard/api/inboxHealth';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SectionCard from 'dashboard/components-next/Campaigns/WhatsAppCampaign/SectionCard.vue';
import BasicSettingsFields from 'dashboard/components-next/Campaigns/WhatsAppCampaign/BasicSettingsFields.vue';
import AudienceFields from 'dashboard/components-next/Campaigns/WhatsAppCampaign/AudienceFields.vue';
import TemplateFields from 'dashboard/components-next/Campaigns/WhatsAppCampaign/TemplateFields.vue';
import AccountInformationCard from 'dashboard/components-next/Campaigns/WhatsAppCampaign/AccountInformationCard.vue';
import MessagePreviewCard from 'dashboard/components-next/Campaigns/WhatsAppCampaign/MessagePreviewCard.vue';
import SchedulePopover from 'dashboard/components-next/Campaigns/WhatsAppCampaign/SchedulePopover.vue';

const SECTION_FIELDS = {
  basic: ['title', 'inboxId'],
  audience: ['audienceIds'],
  template: ['templateId', 'processedParams'],
};

const { t, te, locale } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const campaigns = useMapGetter('campaigns/getWhatsAppCampaigns');
const labels = useMapGetter('labels/getLabels');
const whatsAppInboxes = useMapGetter('inboxes/getWhatsAppInboxes');
const whatsAppTemplates = useMapGetter('inboxes/getFilteredWhatsAppTemplates');
const uiFlags = useMapGetter('campaigns/getUIFlags');

const buildState = () => ({
  title: '',
  inboxId: null,
  templateId: null,
  processedParams: {},
  audienceIds: [],
  scheduledAt: '',
});

const snapshot = value => JSON.parse(JSON.stringify(value));

const state = reactive(buildState());
const savedState = ref(buildState());
const hydratedId = ref(null);
const healthData = ref(null);

const campaignId = computed(() => route.params.campaignId);
const isEditMode = computed(() => Boolean(campaignId.value));

const campaign = computed(() =>
  campaigns.value.find(record => String(record.id) === String(campaignId.value))
);

const templatesFor = inboxId => whatsAppTemplates.value(inboxId);

const templates = computed(() => templatesFor(state.inboxId));

const selectedTemplate = computed(
  () => templates.value.find(item => item.id === state.templateId) ?? null
);

const toDateTimeInput = seconds => {
  const date = new Date(seconds * 1000);
  return new Date(date.getTime() - date.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
};

const applyCampaign = record => {
  const {
    name,
    language,
    processed_params: params,
  } = record.template_params ?? {};
  const template = templatesFor(record.inbox.id).find(
    item => item.name === name && item.language === language
  );

  Object.assign(state, {
    title: record.title,
    inboxId: record.inbox.id,
    templateId: template?.id ?? null,
    processedParams: snapshot(params ?? {}),
    audienceIds: (record.audience ?? [])
      .filter(item => item.type === 'Label')
      .map(item => item.id),
    scheduledAt: toDateTimeInput(record.scheduled_at),
  });
  savedState.value = snapshot(state);
};

const resetForm = () => {
  Object.assign(state, buildState());
  savedState.value = buildState();
  hydratedId.value = null;
};

// Campaign and inbox records land at different times, so hydrate once both are
// available and never again for the same campaign, to avoid clobbering edits.
watch(
  [campaign, () => whatsAppInboxes.value.length],
  () => {
    const record = campaign.value;
    if (!record) {
      if (hydratedId.value !== null) resetForm();
      return;
    }
    if (!whatsAppInboxes.value.length || hydratedId.value === record.id) return;
    hydratedId.value = record.id;
    applyCampaign(record);
  },
  { immediate: true }
);

watch(
  () => state.inboxId,
  async inboxId => {
    healthData.value = null;
    if (!inboxId) return;
    try {
      const { data } = await InboxHealthAPI.getHealthStatus(inboxId);
      healthData.value = data;
    } catch {
      healthData.value = null;
    }
  },
  { immediate: true }
);

const messagingTier = computed(() => {
  const tier = healthData.value?.messaging_limit_tier;
  const key = `INBOX_MGMT.ACCOUNT_HEALTH.VALUES.TIERS.${tier}`;
  return tier !== 'UNKNOWN' && te(key) ? t(key) : '';
});

const breadcrumbItems = computed(() => [
  {
    label: t('CAMPAIGN.WHATSAPP.HEADER_TITLE'),
    routeName: 'campaigns_whatsapp_index',
  },
  {
    label: isEditMode.value
      ? campaign.value?.title
      : t('CAMPAIGN.WHATSAPP.FORM.CREATE_TITLE'),
  },
]);

const isTemplateComplete = computed(
  () =>
    !!selectedTemplate.value &&
    isWhatsAppComplete(selectedTemplate.value, state.processedParams)
);

const isValid = computed(
  () =>
    !!state.title &&
    !!state.inboxId &&
    state.audienceIds.length > 0 &&
    isTemplateComplete.value
);

const isSectionDirty = section =>
  SECTION_FIELDS[section].some(
    field =>
      JSON.stringify(state[field]) !== JSON.stringify(savedState.value[field])
  );

const commitSection = section => {
  const saved = snapshot(savedState.value);
  SECTION_FIELDS[section].forEach(field => {
    saved[field] = snapshot(state[field]);
  });
  savedState.value = saved;
};

const audiencePayload = computed(() =>
  state.audienceIds.map(id => ({ id, type: 'Label' }))
);

const templatePayload = computed(() => {
  const template = selectedTemplate.value;
  const bodyText =
    findComponentByType(template, COMPONENT_TYPES.BODY)?.text ?? '';

  return {
    message: renderTemplatePreview(bodyText, state.processedParams.body ?? {}),
    template_params: {
      name: template.name,
      namespace: template.namespace ?? '',
      category: template.category ?? DEFAULT_CATEGORY,
      language: template.language ?? DEFAULT_LANGUAGE,
      processed_params: state.processedParams,
    },
  };
});

const isInboxChanged = computed(
  () => isEditMode.value && state.inboxId !== savedState.value.inboxId
);

const sectionPayloads = {
  basic: () => ({
    title: state.title,
    inbox_id: state.inboxId,
    ...(isInboxChanged.value ? templatePayload.value : {}),
  }),
  audience: () => ({ audience: audiencePayload.value }),
  template: () => templatePayload.value,
};

const scheduleButtonLabel = computed(() => {
  if (!isEditMode.value || !state.scheduledAt)
    return t('CAMPAIGN.WHATSAPP.FORM.SCHEDULE');

  const date = new Intl.DateTimeFormat(locale.value, {
    day: '2-digit',
    month: '2-digit',
    year: '2-digit',
  })
    .formatToParts(new Date(state.scheduledAt))
    .filter(part => part.type !== 'literal')
    .map(part => part.value)
    .join(' / ');

  return t('CAMPAIGN.WHATSAPP.FORM.SCHEDULED_FOR', { date });
});

const isScheduleDirty = computed(
  () => state.scheduledAt !== savedState.value.scheduledAt
);

onActivated(() => {
  if (!isEditMode.value) resetForm();
});

const handleBreadcrumbClick = ({ routeName }) =>
  router.push({ name: routeName });

const handleDiscard = section => {
  SECTION_FIELDS[section].forEach(field => {
    state[field] = snapshot(savedState.value[field]);
  });
};

const handleUpdate = async payload => {
  try {
    await store.dispatch('campaigns/update', {
      id: campaign.value.id,
      ...payload,
    });
    useAlert(t('CAMPAIGN.WHATSAPP.FORM.API.UPDATE_SUCCESS'));
    return true;
  } catch {
    useAlert(t('CAMPAIGN.WHATSAPP.FORM.API.UPDATE_ERROR'));
    return false;
  }
};

// A campaign that does not exist yet has nothing to persist, so saving a
// section only confirms its values until the campaign is scheduled.
const handleSectionSave = async section => {
  const savedTemplateToo = section === 'basic' && isInboxChanged.value;
  if (isEditMode.value && !(await handleUpdate(sectionPayloads[section]())))
    return;
  commitSection(section);
  if (savedTemplateToo) commitSection('template');
};

const handleCreate = async scheduledAt => {
  try {
    await store.dispatch('campaigns/create', {
      title: state.title,
      inbox_id: state.inboxId,
      audience: audiencePayload.value,
      scheduled_at: scheduledAt,
      ...templatePayload.value,
    });
    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.ONE_OFF,
    });
    useAlert(t('CAMPAIGN.WHATSAPP.FORM.API.CREATE_SUCCESS'));
    resetForm();
    router.push({ name: 'campaigns_whatsapp_index' });
  } catch {
    useAlert(t('CAMPAIGN.WHATSAPP.FORM.API.CREATE_ERROR'));
  }
};

const handleSchedule = () =>
  handleCreate(new Date(state.scheduledAt).toISOString());

const handleCancelReschedule = () => {
  state.scheduledAt = savedState.value.scheduledAt;
};

const handleReschedule = async () => {
  const scheduledAt = new Date(state.scheduledAt).toISOString();
  if (await handleUpdate({ scheduled_at: scheduledAt }))
    savedState.value = { ...savedState.value, scheduledAt: state.scheduledAt };
};
</script>

<template>
  <div class="w-full h-full px-6 overflow-y-auto bg-n-surface-1">
    <header
      class="flex items-center justify-between w-full h-20 max-w-5xl gap-3 mx-auto"
    >
      <Breadcrumb :items="breadcrumbItems" @click="handleBreadcrumbClick" />
      <div class="flex items-center gap-2">
        <span v-tooltip.top="t('CAMPAIGN.WHATSAPP.FORM.LIVE_TEST_TOOLTIP')">
          <Button
            variant="faded"
            color="slate"
            size="sm"
            disabled
            :label="t('CAMPAIGN.WHATSAPP.FORM.LIVE_TEST')"
          />
        </span>
        <SchedulePopover
          v-model="state.scheduledAt"
          :button-label="scheduleButtonLabel"
          :confirm-label="t('CAMPAIGN.WHATSAPP.FORM.SCHEDULE_POPOVER.CREATE')"
          :variant="isEditMode ? 'outline' : 'solid'"
          :color="isEditMode ? 'slate' : 'blue'"
          :show-actions="!isEditMode"
          :is-disabled="!isValid"
          :is-loading="uiFlags.isCreating"
          @confirm="handleSchedule"
        />
        <template v-if="isEditMode">
          <Button
            variant="faded"
            color="slate"
            size="sm"
            :label="t('CAMPAIGN.WHATSAPP.FORM.SCHEDULE_POPOVER.CANCEL')"
            :disabled="!isScheduleDirty"
            @click="handleCancelReschedule"
          />
          <Button
            size="sm"
            :label="t('CAMPAIGN.WHATSAPP.FORM.RESCHEDULE')"
            :is-loading="uiFlags.isUpdating"
            :disabled="
              !isScheduleDirty || !state.scheduledAt || uiFlags.isUpdating
            "
            @click="handleReschedule"
          />
        </template>
      </div>
    </header>

    <div
      class="grid items-start w-full max-w-5xl grid-cols-1 gap-6 pb-6 mx-auto lg:grid-cols-[minmax(0,1.25fr)_minmax(0,1fr)]"
    >
      <div class="flex flex-col gap-6">
        <SectionCard
          :title="t('CAMPAIGN.WHATSAPP.FORM.BASIC_SETTINGS.TITLE')"
          :is-dirty="isSectionDirty('basic')"
          :is-saving="uiFlags.isUpdating"
          :is-save-disabled="
            !state.title ||
            !state.inboxId ||
            (isInboxChanged && !isTemplateComplete)
          "
          @discard="handleDiscard('basic')"
          @save="handleSectionSave('basic')"
        >
          <BasicSettingsFields
            v-model:title="state.title"
            v-model:inbox-id="state.inboxId"
            :inboxes="whatsAppInboxes"
          />
        </SectionCard>

        <SectionCard
          :title="t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.TITLE')"
          :is-dirty="isSectionDirty('audience')"
          :is-saving="uiFlags.isUpdating"
          :is-save-disabled="!state.audienceIds.length"
          @discard="handleDiscard('audience')"
          @save="handleSectionSave('audience')"
        >
          <AudienceFields
            v-model="state.audienceIds"
            :labels="labels"
            :messaging-tier="messagingTier"
          />
        </SectionCard>

        <SectionCard
          :title="t('CAMPAIGN.WHATSAPP.FORM.TEMPLATE.TITLE')"
          :is-dirty="isSectionDirty('template')"
          :is-saving="uiFlags.isUpdating"
          :is-save-disabled="!isTemplateComplete"
          @discard="handleDiscard('template')"
          @save="handleSectionSave('template')"
        >
          <TemplateFields
            v-model:template-id="state.templateId"
            v-model:processed-params="state.processedParams"
            :templates="templates"
            :has-inbox="!!state.inboxId"
          />
        </SectionCard>
      </div>

      <div class="flex flex-col gap-6">
        <AccountInformationCard :health-data="healthData" />
        <MessagePreviewCard
          :template="selectedTemplate"
          :processed-params="state.processedParams"
        />
      </div>
    </div>
  </div>
</template>
