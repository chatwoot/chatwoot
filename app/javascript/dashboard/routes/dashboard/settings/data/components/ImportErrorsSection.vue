<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

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
});

defineEmits(['toggle', 'download']);

const { t } = useI18n();

const errors = computed(() => props.dataImport?.import_errors || []);

const headers = computed(() => [
  t('DATA_IMPORTS.DETAIL.ERROR_CODE'),
  t('DATA_IMPORTS.DETAIL.SOURCE_OBJECT'),
  t('DATA_IMPORTS.DETAIL.MESSAGE'),
  t('DATA_IMPORTS.DETAIL.CREATED'),
]);
</script>

<template>
  <ImportLogSection
    :title="$t('DATA_IMPORTS.DETAIL.ERRORS')"
    :count="dataImport.import_errors_count"
    :is-open="isOpen"
    :is-downloading="isDownloading"
    :download-label="$t('DATA_IMPORTS.DETAIL.DOWNLOAD_ERROR_LOGS')"
    :headers="headers"
    :items="errors"
    :empty-message="$t('DATA_IMPORTS.DETAIL.NO_ERRORS')"
    @toggle="$emit('toggle')"
    @download="$emit('download')"
  >
    <template #row="{ items }">
      <BaseTableRow v-for="error in items" :key="error.id" :item="error">
        <template #default>
          <BaseTableCell>
            <span class="text-body-main text-n-slate-12">
              {{ error.error_code }}
            </span>
          </BaseTableCell>
          <BaseTableCell>
            <span class="text-body-main text-n-slate-12">
              {{ sourceObjectLabel(error) }}
            </span>
          </BaseTableCell>
          <BaseTableCell>
            <span class="text-body-main text-n-slate-11">
              {{ error.message || '-' }}
            </span>
          </BaseTableCell>
          <BaseTableCell>
            <span class="whitespace-nowrap text-body-main text-n-slate-11">
              {{ formatDate(error.created_at) }}
            </span>
          </BaseTableCell>
        </template>
      </BaseTableRow>
    </template>
  </ImportLogSection>
</template>
