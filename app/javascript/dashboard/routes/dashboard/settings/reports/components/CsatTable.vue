<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';

import { messageStamp, dynamicTime } from 'shared/helpers/timeHelper';

import Pagination from 'dashboard/components/table/Pagination.vue';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import ShowMore from 'dashboard/components/widgets/ShowMore.vue';
import CsatContactCell from './CsatContactCell.vue';
import CsatExpandedRow from './CsatExpandedRow.vue';
import CsatEmptyState from './CsatEmptyState.vue';
import CsatTableLoader from './CsatTableLoader.vue';

import { CSAT_RATINGS } from 'shared/constants/messages';

import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
} from '@tanstack/vue-table';

const { pageIndex } = defineProps({
  pageIndex: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['pageChange']);
const { t } = useI18n();
const { isCloudFeatureEnabled, isOnChatwootCloud } = useAccount();
const csatResponses = useMapGetter('csat/getCSATResponses');

const isFeatureEnabled = computed(() =>
  isCloudFeatureEnabled('csat_review_notes')
);
const showExpandableRows = computed(
  () => isFeatureEnabled.value || isOnChatwootCloud.value
);
const metrics = useMapGetter('csat/getMetrics');
const uiFlags = useMapGetter('csat/getUIFlags');

const isLoading = computed(() => uiFlags.value.isFetching);

const expandedRows = ref({});

const toggleRow = id => {
  expandedRows.value = {
    ...expandedRows.value,
    [id]: !expandedRows.value[id],
  };
};

const isRowExpanded = id => !!expandedRows.value[id];

const tableData = computed(() => {
  return csatResponses.value.map(response => ({
    id: response.id,
    contact: response.contact,
    assignedAgent: response.assigned_agent,
    rating: response.rating,
    feedbackText: response.feedback_message || '',
    conversationId: response.conversation_id,
    csatReviewNotes: response.csat_review_notes,
    createdAgo: dynamicTime(response.created_at),
    createdAt: messageStamp(response.created_at, 'LLL d yyyy, h:mm a'),
    _original: response,
  }));
});

const getRatingData = rating => {
  return CSAT_RATINGS.find(r => r.value === rating) || {};
};

const columnHelper = createColumnHelper();

const columns = computed(() => {
  const baseColumns = [
    columnHelper.accessor('contact', {
      header: t('CSAT_REPORTS.TABLE.HEADER.CONTACT_NAME'),
    }),
    columnHelper.accessor('rating', {
      header: t('CSAT_REPORTS.TABLE.HEADER.RATING'),
      size: 120,
    }),
    columnHelper.accessor('feedbackText', {
      header: t('CSAT_REPORTS.TABLE.HEADER.FEEDBACK_TEXT'),
      size: 500,
    }),
    columnHelper.accessor('assignedAgent', {
      header: t('CSAT_REPORTS.TABLE.HEADER.HANDLED_BY'),
      size: 160,
    }),
  ];

  if (showExpandableRows.value) {
    baseColumns.push(
      columnHelper.accessor('actions', {
        header: '',
        size: 50,
      })
    );
  }

  return baseColumns;
});

const paginationParams = computed(() => {
  return {
    pageIndex: pageIndex,
    pageSize: 25,
  };
});

const table = useVueTable({
  get data() {
    return tableData.value;
  },
  get columns() {
    return columns.value;
  },
  manualPagination: true,
  enableSorting: false,
  getCoreRowModel: getCoreRowModel(),
  get rowCount() {
    return metrics.value.totalResponseCount;
  },
  state: {
    get pagination() {
      return paginationParams.value;
    },
  },
  onPaginationChange: updater => {
    const newPagination = updater(paginationParams.value);
    emit('pageChange', newPagination.pageIndex);
  },
});
</script>

<template>
  <div
    class="shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2 overflow-hidden"
  >
    <CsatTableLoader v-if="isLoading" />

    <div v-else-if="tableData.length" class="overflow-x-auto">
      <table class="w-full">
        <thead class="bg-n-solid-2 border-b border-n-container">
          <tr>
            <th
              v-for="header in table.getFlatHeaders()"
              :key="header.id"
              :style="{
                width: header.getSize() ? `${header.getSize()}px` : 'auto',
              }"
              class="text-left py-3 px-5 font-medium text-sm text-n-slate-12"
            >
              {{ header.column.columnDef.header }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-container">
          <template v-for="row in tableData" :key="row.id">
            <tr
              class="group hover:bg-n-slate-2 dark:hover:bg-n-solid-3 transition-colors"
              :class="{
                'bg-n-slate-2 dark:bg-n-solid-3': isRowExpanded(row.id),
                'cursor-pointer': showExpandableRows,
              }"
              @click="showExpandableRows && toggleRow(row.id)"
            >
              <td class="py-4 px-5">
                <CsatContactCell
                  :contact="row.contact"
                  :conversation-id="row.conversationId"
                  :created-ago="row.createdAgo"
                  :created-at="row.createdAt"
                />
              </td>
              <td class="py-4 px-5">
                <div
                  class="inline-flex items-center gap-1.5 px-2 py-1 rounded-lg"
                  :style="{
                    backgroundColor: `${getRatingData(row.rating).color}20`,
                  }"
                >
                  <span class="text-sm font-medium text-n-slate-12 truncate">
                    {{ $t(getRatingData(row.rating).translationKey) }}
                  </span>
                </div>
              </td>
              <td class="py-4 px-5">
                <span
                  v-if="!row.feedbackText"
                  class="text-n-slate-10 italic text-sm"
                >
                  {{ $t('CSAT_REPORTS.NO_FEEDBACK') }}
                </span>
                <div v-else class="text-sm text-n-slate-12">
                  <ShowMore :text="row.feedbackText" :limit="100" />
                </div>
              </td>
              <td class="py-4 px-5">
                <UserAvatarWithName
                  v-if="row.assignedAgent"
                  :user="row.assignedAgent"
                  :size="28"
                />
                <span v-else class="text-n-slate-10 text-sm italic">
                  {{ $t('CSAT_REPORTS.NO_AGENT') }}
                </span>
              </td>
              <td v-if="showExpandableRows" class="py-4 px-5">
                <div
                  class="p-1.5 rounded-md text-n-slate-10 group-hover:text-n-slate-12 transition-colors"
                >
                  <i
                    class="size-4 block transition-transform duration-200"
                    :class="
                      isRowExpanded(row.id)
                        ? 'i-lucide-chevron-up'
                        : 'i-lucide-chevron-down'
                    "
                  />
                </div>
              </td>
            </tr>
            <tr
              v-if="showExpandableRows && isRowExpanded(row.id)"
              class="!border-t-0"
            >
              <td colspan="5" class="p-0 !border-t-0">
                <CsatExpandedRow :response="row._original" />
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>

    <CsatEmptyState
      v-else
      :title="$t('CSAT_REPORTS.NO_RECORDS')"
      :description="$t('CSAT_REPORTS.NO_RECORDS_DESCRIPTION')"
    />

    <div
      v-if="metrics.totalResponseCount"
      class="px-6 py-4 border-t border-n-weak"
    >
      <Pagination :table="table" />
    </div>
  </div>
</template>
