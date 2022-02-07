<template>
  <div class="csat--table-container">
    <ve-table
      max-height="calc(100vh - 35rem)"
      :fixed-header="true"
      :columns="columns"
      :table-data="tableData"
    />
    <div v-show="!tableData.length" class="csat--empty-records">
      {{ $t('CSAT_REPORTS.NO_RECORDS') }}
    </div>
    <div v-if="metrics.totalResponseCount" class="table-pagination">
      <ve-pagination
        :total="metrics.totalResponseCount"
        :page-index="pageIndex"
        :page-size="25"
        :page-size-option="[25]"
        @on-page-number-change="onPageNumberChange"
      />
    </div>
  </div>
</template>
<script>
import { VeTable, VePagination } from 'vue-easytable';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName';
import { CSAT_RATINGS } from 'shared/constants/messages';
import { mapGetters } from 'vuex';
import timeMixin from 'dashboard/mixins/time';

export default {
  components: {
    VeTable,
    VePagination,
  },
  mixins: [timeMixin],
  props: {
    pageIndex: {
      type: Number,
      default: 1,
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'csat/getUIFlags',
      csatResponses: 'csat/getCSATResponses',
      metrics: 'csat/getMetrics',
    }),
    columns() {
      return [
        {
          field: 'contact',
          key: 'contact',
          title: this.$t('CSAT_REPORTS.TABLE.HEADER.CONTACT_NAME'),
          align: 'left',
          width: 200,
          renderBodyCell: ({ row }) => {
            if (row.contact) {
              return <UserAvatarWithName size="24px" user={row.contact} />;
            }
            return '---';
          },
        },
        {
          field: 'assignedAgent',
          key: 'assignedAgent',
          title: this.$t('CSAT_REPORTS.TABLE.HEADER.AGENT_NAME'),
          align: 'left',
          width: 200,
          renderBodyCell: ({ row }) => {
            if (row.assignedAgent) {
              return (
                <UserAvatarWithName size="24px" user={row.assignedAgent} />
              );
            }
            return '---';
          },
        },
        {
          field: 'rating',
          key: 'rating',
          title: this.$t('CSAT_REPORTS.TABLE.HEADER.RATING'),
          align: 'center',
          width: 80,
          renderBodyCell: ({ row }) => {
            const [ratingObject = {}] = CSAT_RATINGS.filter(
              rating => rating.value === row.rating
            );
            return (
              <span class="emoji-response">{ratingObject.emoji || '---'}</span>
            );
          },
        },
        {
          field: 'feedbackText',
          key: 'feedbackText',
          title: this.$t('CSAT_REPORTS.TABLE.HEADER.FEEDBACK_TEXT'),
          align: 'left',
          width: 400,
        },
        {
          field: 'converstionId',
          key: 'converstionId',
          title: '',
          align: 'left',
          width: 100,
          renderBodyCell: ({ row }) => {
            const routerParams = {
              name: 'inbox_conversation',
              params: { conversation_id: row.conversationId },
            };
            return (
              <div class="text-right">
                <router-link to={routerParams}>
                  {`#${row.conversationId}`}
                </router-link>
                <div class="csat--timestamp" v-tooltip={row.createdAt}>
                  {row.createdAgo}
                </div>
              </div>
            );
          },
        },
      ];
    },
    tableData() {
      return this.csatResponses.map(response => ({
        contact: response.contact,
        assignedAgent: response.assigned_agent,
        rating: response.rating,
        feedbackText: response.feedback_message || '---',
        conversationId: response.conversation_id,
        createdAgo: this.dynamicTime(response.created_at),
        createdAt: this.messageStamp(response.created_at, 'LLL d yyyy, h:mm a'),
      }));
    },
  },
  methods: {
    onPageNumberChange(pageIndex) {
      this.$emit('page-change', pageIndex);
    },
  },
};
</script>
<style lang="scss" scoped>
.csat--table-container {
  display: flex;
  flex-direction: column;
  flex: 1;

  .ve-table {
    background: var(--white);

    &::v-deep {
      .ve-table-container {
        border-radius: var(--border-radius-normal);
        border: 1px solid var(--color-border) !important;
      }

      th.ve-table-header-th {
        font-size: var(--font-size-mini) !important;
        padding: var(--space-normal) !important;
      }

      td.ve-table-body-td {
        padding: var(--space-small) var(--space-normal) !important;
      }
    }
  }

  &::v-deep .ve-pagination {
    background-color: transparent;
  }

  &::v-deep .ve-pagination-select {
    display: none;
  }

  .emoji-response {
    font-size: var(--font-size-large);
  }

  .table-pagination {
    margin-top: var(--space-normal);
    text-align: right;
  }
}

.csat--empty-records {
  align-items: center;
  background-color: var(--white);
  border: 1px solid var(--color-border);
  border-top: 0;
  color: var(--b-600);
  display: flex;
  font-size: var(--font-size-small);
  height: 20rem;
  justify-content: center;
  margin-top: -1px;
  width: 100%;
}

.csat--timestamp {
  color: var(--b-400);
  font-size: var(--font-size-small);
}
</style>
