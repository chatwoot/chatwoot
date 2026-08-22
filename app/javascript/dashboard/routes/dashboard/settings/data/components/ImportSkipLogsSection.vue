<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import { BaseTableRow, BaseTableCell } from 'dashboard/components-next/table';
import ImportLogSection from './ImportLogSection.vue';
import { formatDate, sourceObjectLabel } from '../importStatus';

const props = defineProps({
  dataImport: {
    type: Object,
    required: true,
  },
  isOpen: {
    type: Boolean,
    default: false,
  },
  isDownloading: {
    type: Boolean,
    default: false,
  },
  selectedType: {
    type: String,
    default: '',
  },
  isChangingType: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['toggle', 'download', 'changeType']);

const { t } = useI18n();

const skipLogs = computed(() => props.dataImport?.skip_logs || []);

const headers = computed(() => [
  t('DATA_IMPORTS.DETAIL.KIND'),
  t('DATA_IMPORTS.DETAIL.SOURCE_OBJECT'),
  t('DATA_IMPORTS.DETAIL.MESSAGE'),
  t('DATA_IMPORTS.DETAIL.CREATED'),
]);

const typeOptions = computed(() => {
  const counts = props.dataImport?.skip_logs_filters?.counts_by_type || {};
  return [
    {
      value: '',
      label: t('DATA_IMPORTS.DETAIL.ALL_SKIP_LOGS'),
      count: props.dataImport?.skip_logs_count || 0,
    },
    {
      value: 'contact',
      label: t('DATA_IMPORTS.TYPES.CONTACTS'),
      count: counts.contact || 0,
    },
    {
      value: 'conversation',
      label: t('DATA_IMPORTS.TYPES.CONVERSATIONS'),
      count: counts.conversation || 0,
    },
    {
      value: 'message',
      label: t('DATA_IMPORTS.TYPES.MESSAGES'),
      count: counts.message || 0,
    },
  ];
});
</script>

<template>
  <ImportLogSection
    :title="$t('DATA_IMPORTS.DETAIL.SKIP_LOGS')"
    :count="dataImport.skip_logs_count"
    :is-open="isOpen"
    :is-downloading="isDownloading"
    :download-label="$t('DATA_IMPORTS.DETAIL.DOWNLOAD_SKIP_LOGS')"
    :headers="headers"
    :items="skipLogs"
    :empty-message="$t('DATA_IMPORTS.DETAIL.NO_SKIP_LOGS')"
    @toggle="$emit('toggle')"
    @download="$emit('download')"
  >
    <template v-if="dataImport.skip_logs_count" #filters>
      <div class="flex flex-wrap gap-2 border-b border-n-weak px-4 py-3">
        <Button
          v-for="option in typeOptions"
          :key="option.value || 'all'"
          :variant="option.value === selectedType ? 'solid' : 'faded'"
          color="slate"
          size="xs"
          :disabled="!option.count || isChangingType"
          :label="`${option.label} (${option.count})`"
          @click="$emit('changeType', option.value)"
        />
      </div>
    </template>
    <template #row="{ items }">
      <BaseTableRow v-for="skipLog in items" :key="skipLog.id" :item="skipLog">
        <template #default>
          <BaseTableCell>
            <span class="capitalize text-body-main text-n-slate-12">
              {{ skipLog.kind || '-' }}
            </span>
          </BaseTableCell>
          <BaseTableCell>
            <span class="text-body-main text-n-slate-11">
              {{ sourceObjectLabel(skipLog) }}
            </span>
          </BaseTableCell>
          <BaseTableCell>
            <span class="text-body-main text-n-slate-11">
              {{ skipLog.message || '-' }}
            </span>
          </BaseTableCell>
          <BaseTableCell>
            <span class="whitespace-nowrap text-body-main text-n-slate-11">
              {{ formatDate(skipLog.created_at) }}
            </span>
          </BaseTableCell>
        </template>
      </BaseTableRow>
    </template>
  </ImportLogSection>
</template>
