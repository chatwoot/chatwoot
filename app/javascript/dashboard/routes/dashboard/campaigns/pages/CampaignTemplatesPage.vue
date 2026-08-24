<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import {
  COMPONENT_TYPES,
  findComponentByType,
} from 'dashboard/helper/templateHelper';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignTemplateCard from 'dashboard/components-next/Campaigns/Pages/CampaignTemplatesPage/CampaignTemplateCard.vue';
import CampaignTemplateDialog from 'dashboard/components-next/Campaigns/Pages/CampaignTemplatesPage/CampaignTemplateDialog.vue';
import SyncedTemplateGroup from 'dashboard/components-next/Campaigns/Pages/CampaignTemplatesPage/SyncedTemplateGroup.vue';

const { t } = useI18n();
const store = useStore();

const SOURCES = {
  OWN: 'own',
  WHATSAPP: 'whatsapp',
  TWILIO: 'twilio',
};

const activeSource = ref(SOURCES.OWN);
const selectedTemplate = ref(null);
const syncingInboxId = ref(null);
const campaignTemplateDialogRef = ref(null);
const confirmDeleteDialogRef = ref(null);

const uiFlags = useMapGetter('campaignTemplates/getUIFlags');
const campaignTemplates = useMapGetter(
  'campaignTemplates/getCampaignTemplates'
);
const whatsAppInboxes = useMapGetter('inboxes/getWhatsAppInboxes');
const twilioInboxes = useMapGetter('inboxes/getTwilioInboxes');
const getFilteredWhatsAppTemplates = useMapGetter(
  'inboxes/getFilteredWhatsAppTemplates'
);

const isFetching = computed(() => uiFlags.value.isFetching);

const sources = computed(() => [
  { key: SOURCES.OWN, label: t('CAMPAIGN.TEMPLATES.SOURCES.OWN') },
  { key: SOURCES.WHATSAPP, label: t('CAMPAIGN.TEMPLATES.SOURCES.WHATSAPP') },
  { key: SOURCES.TWILIO, label: t('CAMPAIGN.TEMPLATES.SOURCES.TWILIO') },
]);

const activeSourceIndex = computed(() =>
  sources.value.findIndex(source => source.key === activeSource.value)
);

const isOwnSource = computed(() => activeSource.value === SOURCES.OWN);

const hasNoOwnTemplates = computed(
  () => campaignTemplates.value.length === 0 && !isFetching.value
);

const whatsAppGroups = computed(() =>
  whatsAppInboxes.value.map(inbox => ({
    id: inbox.id,
    name: inbox.name,
    lastSyncedAt: inbox.message_templates_last_updated,
    templates: getFilteredWhatsAppTemplates.value(inbox.id).map(template => ({
      id: template.id,
      name: template.name,
      language: template.language,
      category: template.category,
      body: findComponentByType(template, COMPONENT_TYPES.BODY)?.text ?? '',
    })),
  }))
);

const twilioGroups = computed(() =>
  twilioInboxes.value.map(inbox => ({
    id: inbox.id,
    name: inbox.name,
    lastSyncedAt: inbox.content_templates_last_updated,
    templates: (inbox.content_templates?.templates ?? []).map(template => ({
      id: template.content_sid,
      name: template.friendly_name,
      language: template.language,
      category: template.status,
      body: template.body,
    })),
  }))
);

const handleCreate = () => {
  selectedTemplate.value = null;
  campaignTemplateDialogRef.value.dialogRef.open();
};

const handleEdit = template => {
  selectedTemplate.value = template;
  campaignTemplateDialogRef.value.dialogRef.open();
};

const handleDelete = template => {
  selectedTemplate.value = template;
  confirmDeleteDialogRef.value.open();
};

const handleConfirmDelete = async () => {
  try {
    await store.dispatch('campaignTemplates/delete', selectedTemplate.value.id);
    useAlert(t('CAMPAIGN.TEMPLATES.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('CAMPAIGN.TEMPLATES.DELETE.API.ERROR_MESSAGE'));
  } finally {
    confirmDeleteDialogRef.value.close();
  }
};

const handleSync = async inboxId => {
  syncingInboxId.value = inboxId;
  try {
    await store.dispatch('inboxes/syncTemplates', inboxId);
    await store.dispatch('inboxes/get');
    useAlert(t('CAMPAIGN.TEMPLATES.SYNCED.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('CAMPAIGN.TEMPLATES.SYNCED.API.ERROR_MESSAGE'));
  } finally {
    syncingInboxId.value = null;
  }
};

onMounted(() => store.dispatch('campaignTemplates/get'));
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.TEMPLATES.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.TEMPLATES.NEW_TEMPLATE')"
    :show-action-button="isOwnSource"
    @click="handleCreate"
  >
    <div class="flex items-center gap-3 pb-4">
      <TabBar
        :tabs="sources"
        :initial-active-tab="activeSourceIndex"
        @tab-changed="activeSource = $event.key"
      />
    </div>

    <template v-if="isOwnSource">
      <div
        v-if="isFetching"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <EmptyStateLayout
        v-else-if="hasNoOwnTemplates"
        :title="t('CAMPAIGN.TEMPLATES.EMPTY_STATE.OWN.TITLE')"
        :subtitle="t('CAMPAIGN.TEMPLATES.EMPTY_STATE.OWN.SUBTITLE')"
        :show-backdrop="false"
      />
      <div v-else class="flex flex-col gap-4">
        <CampaignTemplateCard
          v-for="template in campaignTemplates"
          :key="template.id"
          :name="template.name"
          :body="template.body"
          @edit="handleEdit(template)"
          @delete="handleDelete(template)"
        />
      </div>
    </template>

    <template v-else-if="activeSource === SOURCES.WHATSAPP">
      <EmptyStateLayout
        v-if="whatsAppGroups.length === 0"
        :title="t('CAMPAIGN.TEMPLATES.EMPTY_STATE.SYNCED.TITLE')"
        :subtitle="t('CAMPAIGN.TEMPLATES.EMPTY_STATE.SYNCED.SUBTITLE')"
        :show-backdrop="false"
      />
      <div v-else class="flex flex-col gap-8">
        <SyncedTemplateGroup
          v-for="group in whatsAppGroups"
          :key="group.id"
          :inbox-name="group.name"
          :templates="group.templates"
          :last-synced-at="group.lastSyncedAt"
          :is-syncing="syncingInboxId === group.id"
          @sync="handleSync(group.id)"
        />
      </div>
    </template>

    <template v-else>
      <EmptyStateLayout
        v-if="twilioGroups.length === 0"
        :title="t('CAMPAIGN.TEMPLATES.EMPTY_STATE.SYNCED.TITLE')"
        :subtitle="t('CAMPAIGN.TEMPLATES.EMPTY_STATE.SYNCED.SUBTITLE')"
        :show-backdrop="false"
      />
      <div v-else class="flex flex-col gap-8">
        <SyncedTemplateGroup
          v-for="group in twilioGroups"
          :key="group.id"
          :inbox-name="group.name"
          :templates="group.templates"
          :last-synced-at="group.lastSyncedAt"
          :is-syncing="syncingInboxId === group.id"
          @sync="handleSync(group.id)"
        />
      </div>
    </template>

    <CampaignTemplateDialog
      ref="campaignTemplateDialogRef"
      :selected-template="selectedTemplate"
    />
    <Dialog
      ref="confirmDeleteDialogRef"
      type="alert"
      :title="t('CAMPAIGN.TEMPLATES.DELETE.TITLE')"
      :description="t('CAMPAIGN.TEMPLATES.DELETE.DESCRIPTION')"
      :confirm-button-label="t('CAMPAIGN.TEMPLATES.DELETE.CONFIRM')"
      @confirm="handleConfirmDelete"
    />
  </CampaignLayout>
</template>
