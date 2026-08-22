<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { messageStamp } from 'shared/helpers/timeHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';

const props = defineProps({
  campaign: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['analytics']);

const STATUS_LABEL_KEYS = {
  draft: 'CAMPAIGN.WHATSAPP.LIST.STATUS.DRAFT',
  active: 'CAMPAIGN.WHATSAPP.LIST.STATUS.ACTIVE',
  processing: 'CAMPAIGN.WHATSAPP.LIST.STATUS.PROCESSING',
  completed: 'CAMPAIGN.WHATSAPP.LIST.STATUS.COMPLETED',
};

const EMPTY = '--';

const { t } = useI18n();
const panelRef = ref(null);
const getFilteredWhatsAppTemplates = useMapGetter(
  'inboxes/getFilteredWhatsAppTemplates'
);

const templateParams = computed(() => props.campaign?.template_params || {});

const matchedTemplate = computed(() => {
  const inboxId = props.campaign?.inbox?.id || props.campaign?.inbox_id;
  const name = templateParams.value?.name;
  if (!inboxId || !name) return null;

  const templates = getFilteredWhatsAppTemplates.value(inboxId) || [];
  return templates.find(item => item.name === name) || null;
});

const inboxIcon = computed(() => {
  const inbox = props.campaign?.inbox;
  if (!inbox) return '';
  return getInboxIconByType(
    inbox.channel_type,
    inbox.medium,
    'fill',
    inbox.voice_enabled
  );
});

const statusLabel = computed(() => {
  const status = props.campaign?.campaign_status;
  const key = STATUS_LABEL_KEYS[status];
  return key ? t(key) : EMPTY;
});

const scheduledLabel = computed(() => {
  if (!props.campaign?.scheduled_at) return EMPTY;
  return messageStamp(props.campaign.scheduled_at, 'LLL d, h:mm a');
});

const open = () => panelRef.value?.open();
const close = () => panelRef.value?.close();

defineExpose({ open, close });
</script>

<template>
  <SidePanel
    ref="panelRef"
    width="lg"
    :title="campaign?.title || ''"
    :description="t('CAMPAIGN.WHATSAPP.LIST.DETAIL.DESCRIPTION')"
  >
    <div v-if="campaign" class="flex flex-col gap-6">
      <dl class="grid grid-cols-[7rem_1fr] gap-x-4 gap-y-3 text-sm">
        <dt class="text-n-slate-11">
          {{ t('CAMPAIGN.WHATSAPP.LIST.COLUMNS.STATUS') }}
        </dt>
        <dd class="text-n-slate-12">{{ statusLabel }}</dd>
        <dt class="text-n-slate-11">
          {{ t('CAMPAIGN.WHATSAPP.LIST.COLUMNS.INBOX') }}
        </dt>
        <dd class="flex items-center gap-1.5 text-n-slate-12">
          <Icon v-if="inboxIcon" :icon="inboxIcon" class="size-3.5 shrink-0" />
          <span>{{ campaign.inbox?.name || EMPTY }}</span>
        </dd>
        <dt class="text-n-slate-11">
          {{ t('CAMPAIGN.WHATSAPP.LIST.COLUMNS.DATE') }}
        </dt>
        <dd class="text-n-slate-12">{{ scheduledLabel }}</dd>
      </dl>

      <div class="flex flex-col gap-2">
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ t('CAMPAIGN.WHATSAPP.LIST.DETAIL.TEMPLATE') }}
        </h3>
        <dl class="grid grid-cols-[7rem_1fr] gap-x-4 gap-y-2 text-sm">
          <dt class="text-n-slate-11">
            {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.LABEL') }}
          </dt>
          <dd class="text-n-slate-12">
            {{ templateParams.name || EMPTY }}
          </dd>
          <dt class="text-n-slate-11">
            {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.LANGUAGE') }}
          </dt>
          <dd class="text-n-slate-12">
            {{ templateParams.language || EMPTY }}
          </dd>
          <dt class="text-n-slate-11">
            {{ t('CAMPAIGN.WHATSAPP.CREATE.FORM.TEMPLATE.CATEGORY') }}
          </dt>
          <dd class="text-n-slate-12">
            {{ templateParams.category || matchedTemplate?.category || EMPTY }}
          </dd>
        </dl>
      </div>

      <div class="flex flex-col gap-2">
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ t('CAMPAIGN.WHATSAPP.LIST.DETAIL.MESSAGE') }}
        </h3>
        <p
          class="text-sm whitespace-pre-wrap rounded-xl border border-n-weak bg-n-alpha-1 p-4 text-n-slate-12"
        >
          {{ campaign.message || EMPTY }}
        </p>
      </div>
    </div>

    <template #footer>
      <Button
        class="w-full"
        :label="t('CAMPAIGN.WHATSAPP.LIST.VIEW_ANALYTICS')"
        icon="i-lucide-chart-no-axes-column"
        @click="emit('analytics', campaign)"
      />
    </template>
  </SidePanel>
</template>
