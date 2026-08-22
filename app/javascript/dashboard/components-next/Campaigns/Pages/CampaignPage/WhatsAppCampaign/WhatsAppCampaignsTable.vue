<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useConfig } from 'dashboard/composables/useConfig';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { messageStamp } from 'shared/helpers/timeHelper';
import {
  campaignAudienceCount,
  campaignDeliveredCount,
} from 'dashboard/helper/campaignDeliveryRate';
import { canShowWhatsAppCampaignAnalytics } from 'dashboard/helper/whatsappCampaignAnalytics';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const props = defineProps({
  campaigns: {
    type: Array,
    required: true,
  },
  emptyMessage: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['showDetail', 'edit', 'delete', 'analytics']);

const EMPTY = '--';

const EDIT_STATUSES = ['draft', 'active'];
const ANALYTICS_STATUSES = ['processing', 'completed'];

const STATUS_LABEL_KEYS = {
  draft: 'CAMPAIGN.WHATSAPP.LIST.STATUS.DRAFT',
  active: 'CAMPAIGN.WHATSAPP.LIST.STATUS.ACTIVE',
  processing: 'CAMPAIGN.WHATSAPP.LIST.STATUS.PROCESSING',
  completed: 'CAMPAIGN.WHATSAPP.LIST.STATUS.COMPLETED',
};

const { t } = useI18n();
const { isEnterprise } = useConfig();

const headers = computed(() => [
  t('CAMPAIGN.WHATSAPP.LIST.COLUMNS.TITLE'),
  t('CAMPAIGN.WHATSAPP.LIST.COLUMNS.STATUS'),
  t('CAMPAIGN.WHATSAPP.LIST.COLUMNS.INBOX'),
  t('CAMPAIGN.WHATSAPP.LIST.COLUMNS.DATE'),
  t('CAMPAIGN.WHATSAPP.LIST.COLUMNS.AUDIENCE'),
  t('CAMPAIGN.WHATSAPP.LIST.COLUMNS.DELIVERED'),
  t('CAMPAIGN.WHATSAPP.LIST.COLUMNS.ACTIONS'),
]);

const statusLabel = status => {
  const key = STATUS_LABEL_KEYS[status];
  return key ? t(key) : status;
};

const statusClass = status => {
  const map = {
    draft: 'bg-n-slate-3 text-n-slate-11',
    active: 'bg-n-teal-3 text-n-teal-11',
    processing: 'bg-n-amber-3 text-n-amber-11',
    completed: 'bg-n-slate-3 text-n-slate-12',
  };
  return map[status] || map.draft;
};

const inboxIcon = inbox => {
  if (!inbox) return '';
  return getInboxIconByType(
    inbox.channel_type,
    inbox.medium,
    'fill',
    inbox.voice_enabled
  );
};

const formatDate = scheduledAt => {
  if (!scheduledAt) return EMPTY;
  return messageStamp(scheduledAt, 'LLL d, h:mm a');
};

const audienceLabel = stats => {
  const count = campaignAudienceCount(stats);
  return count || EMPTY;
};

const deliveredLabel = stats => {
  if (!stats || !campaignAudienceCount(stats)) return EMPTY;
  return campaignDeliveredCount(stats);
};

const showAnalytics = campaign =>
  canShowWhatsAppCampaignAnalytics(campaign, isEnterprise);

const showEdit = campaign => EDIT_STATUSES.includes(campaign.campaign_status);

const handleRowClick = campaign => {
  if (EDIT_STATUSES.includes(campaign.campaign_status)) {
    emit('edit', campaign);
    return;
  }
  if (ANALYTICS_STATUSES.includes(campaign.campaign_status)) {
    emit('showDetail', campaign);
  }
};
</script>

<template>
  <div
    class="w-full overflow-hidden border rounded-xl border-n-weak bg-n-solid-1"
  >
    <div
      class="overflow-x-auto [&_th:first-child]:ps-5 [&_td:first-child]:ps-5 [&_th:last-child]:pe-5 [&_td:last-child]:pe-5 [&_thead]:bg-n-surface-2 [&_thead_th]:py-3 [&_thead_th]:text-xs [&_thead_th]:font-semibold [&_thead_th]:tracking-wide [&_thead_th]:uppercase [&_thead_th]:text-n-slate-11 [&_thead_th]:border-b [&_thead_th]:border-n-weak [&_tbody_tr]:transition-colors [&_tbody_tr:hover]:bg-n-alpha-1"
    >
      <BaseTable
        :headers="headers"
        :items="props.campaigns"
        :no-data-message="emptyMessage"
      >
        <template #row="{ items }">
          <BaseTableRow
            v-for="campaign in items"
            :key="campaign.id"
            :item="campaign"
            class="cursor-pointer"
            @click="handleRowClick(campaign)"
          >
            <BaseTableCell>
              <span
                class="block max-w-xs font-medium truncate text-body-main text-n-slate-12"
              >
                {{ campaign.title }}
              </span>
            </BaseTableCell>
            <BaseTableCell class="whitespace-nowrap">
              <span
                class="inline-flex items-center h-6 px-2 text-xs font-medium rounded-md"
                :class="statusClass(campaign.campaign_status)"
              >
                {{ statusLabel(campaign.campaign_status) }}
              </span>
            </BaseTableCell>
            <BaseTableCell>
              <div
                v-if="campaign.inbox"
                class="flex items-center gap-1.5 max-w-[10rem]"
              >
                <Icon
                  :icon="inboxIcon(campaign.inbox)"
                  class="shrink-0 size-3.5 text-n-slate-12"
                />
                <span class="truncate text-body-main text-n-slate-12">{{
                  campaign.inbox.name
                }}</span>
              </div>
            </BaseTableCell>
            <BaseTableCell class="whitespace-nowrap">
              <span
                class="text-body-main"
                :class="
                  campaign.scheduled_at ? 'text-n-slate-11' : 'text-n-slate-10'
                "
              >
                {{ formatDate(campaign.scheduled_at) }}
              </span>
            </BaseTableCell>
            <BaseTableCell align="end" class="whitespace-nowrap tabular-nums">
              <span
                class="text-body-main"
                :class="
                  campaignAudienceCount(campaign.execution_stats)
                    ? 'text-n-slate-12'
                    : 'text-n-slate-10'
                "
              >
                {{ audienceLabel(campaign.execution_stats) }}
              </span>
            </BaseTableCell>
            <BaseTableCell align="end" class="whitespace-nowrap tabular-nums">
              <span
                class="text-body-main"
                :class="
                  campaignAudienceCount(campaign.execution_stats)
                    ? 'text-n-slate-12'
                    : 'text-n-slate-10'
                "
              >
                {{ deliveredLabel(campaign.execution_stats) }}
              </span>
            </BaseTableCell>
            <BaseTableCell align="end" class="w-28" @click.stop>
              <div class="flex items-center justify-end gap-1">
                <Button
                  v-if="showAnalytics(campaign)"
                  v-tooltip.top="t('CAMPAIGN.WHATSAPP.LIST.VIEW_ANALYTICS')"
                  variant="faded"
                  size="sm"
                  color="blue"
                  icon="i-lucide-chart-no-axes-column"
                  @click="emit('analytics', campaign)"
                />
                <Button
                  v-if="showEdit(campaign)"
                  v-tooltip.top="t('CAMPAIGN.WHATSAPP.LIST.EDIT')"
                  variant="faded"
                  size="sm"
                  color="slate"
                  icon="i-lucide-pencil"
                  @click="emit('edit', campaign)"
                />
                <Button
                  v-tooltip.top="t('CAMPAIGN.WHATSAPP.LIST.DELETE')"
                  variant="faded"
                  size="sm"
                  color="ruby"
                  icon="i-lucide-trash-2"
                  @click="emit('delete', campaign)"
                />
              </div>
            </BaseTableCell>
          </BaseTableRow>
        </template>
      </BaseTable>
    </div>
  </div>
</template>
