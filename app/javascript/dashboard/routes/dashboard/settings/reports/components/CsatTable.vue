<script setup>
import { defineEmits, computed, h } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

// [TODO] Instead of converting the values to their reprentation when building the tableData
// We should do the change in the cell
import { messageStamp, dynamicTime } from 'shared/helpers/timeHelper';

// components
import Table from 'dashboard/components/table/Table.vue';
import Pagination from 'dashboard/components/table/Pagination.vue';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import ConversationCell from './ConversationCell.vue';

// constants
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
// const isRTL = useMapGetter('accounts/isRTL');
const csatResponses = useMapGetter('csat/getCSATResponses');
const metrics = useMapGetter('csat/getMetrics');

const tableData = computed(() => {
  return csatResponses.value.map(response => ({
    contact: response.contact,
    assignedAgent: response.assigned_agent,
    rating: response.rating,
    feedbackText: response.feedback_message || '---',
    conversationId: response.conversation_id,
    createdAgo: dynamicTime(response.created_at),
    createdAt: messageStamp(response.created_at, 'LLL d yyyy, h:mm a'),
  }));
});

const defaulSpanRender = cellProps =>
  h(
    'span',
    {
      class: cellProps.getValue() ? '' : 'text-slate-300 dark:text-slate-700',
    },
    cellProps.getValue() ? cellProps.getValue() : '---'
  );

const columnHelper = createColumnHelper();

const columns = [
  columnHelper.accessor('contact', {
    header: t('CSAT_REPORTS.TABLE.HEADER.CONTACT_NAME'),
    width: 200,
    cell: cellProps => {
      const { contact } = cellProps.row.original;
      if (contact) {
        return h(UserAvatarWithName, { user: contact });
      }
      return '--';
    },
  }),
  columnHelper.accessor('assignedAgent', {
    header: t('CSAT_REPORTS.TABLE.HEADER.AGENT_NAME'),
    width: 200,
    cell: cellProps => {
      const { assignedAgent } = cellProps.row.original;
      if (assignedAgent) {
        return h(UserAvatarWithName, { user: assignedAgent });
      }
      return '--';
    },
  }),
  columnHelper.accessor('rating', {
    header: t('CSAT_REPORTS.TABLE.HEADER.RATING'),
    align: 'center',
    width: 80,
    cell: cellProps => {
      const { rating: giveRating } = cellProps.row.original;
      const [ratingObject = {}] = CSAT_RATINGS.filter(
        rating => rating.value === giveRating
      );

      return h(
        'span',
        {
          class: ratingObject.emoji
            ? 'emoji-response text-lg'
            : 'text-slate-300 dark:text-slate-700',
        },
        ratingObject.emoji || '---'
      );
    },
  }),
  columnHelper.accessor('feedbackText', {
    header: t('CSAT_REPORTS.TABLE.HEADER.FEEDBACK_TEXT'),
    width: 400,
    cell: defaulSpanRender,
  }),
  columnHelper.accessor('conversationId', {
    header: '',
    width: 100,
    cell: cellProps => h(ConversationCell, cellProps),
  }),
];

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
  columns,
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
    const newPagintaion = updater(paginationParams.value);
    emit('pageChange', newPagintaion.pageIndex);
  },
});
</script>

<template>
  <div
    class="shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2 px-6 py-5"
  >
    <Table :table="table" class="max-h-[calc(100vh-21.875rem)]" />
    <div
      v-show="!tableData.length"
      class="h-48 flex items-center justify-center text-n-slate-12 text-sm"
    >
      {{ $t('CSAT_REPORTS.NO_RECORDS') }}
    </div>
    <div v-if="metrics.totalResponseCount" class="table-pagination">
      <Pagination class="mt-2" :table="table" />
    </div>
  </div>
</template>
