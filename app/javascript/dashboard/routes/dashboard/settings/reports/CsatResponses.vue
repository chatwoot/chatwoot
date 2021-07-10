<template>
  <div class="column csat--container">
    <div class="row  csat--metrics-container">
      <div class="medium-2 report-card">
        <h3 class="heading">
          Total responses
        </h3>
        <h4 class="metric">
          {{ metrics.totalResponseCount.toLocaleString() }}
        </h4>
      </div>
      <div class="medium-3 report-card">
        <h3 class="heading">
          Satisfaction score
        </h3>
        <h4 class="metric">
          {{ `${satisfactionScore}%` }}
        </h4>
      </div>
      <div class="medium-7 bar--display">
        <woot-bar
          v-if="metrics.totalResponseCount"
          :collection="chartData"
          :chart-options="chartOptions"
          :height="50"
        />
      </div>
    </div>
    <div class="csat--table-container">
      <ve-table
        id="loading-container"
        max-height="calc(100vh - 30rem)"
        :fixed-header="true"
        :columns="columns"
        :table-data="tableData"
      />
      <div v-if="metrics.totalResponseCount" class="table-pagination">
        <ve-pagination
          :total="metrics.totalResponseCount"
          :page-index="pageIndex"
          page-size="25"
          :page-size-option="[25]"
          @on-page-number-change="onPageNumberChange"
        />
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { VeTable, VePagination } from 'vue-easytable';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName';
import { CSAT_RATINGS } from 'shared/constants/messages';

export default {
  name: 'CsatResponses',
  components: {
    VeTable,
    VePagination,
  },
  data() {
    return {
      pageIndex: 1,
      loadingInstance: null,
    };
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
          title: this.$t('CSAT_REPORTS.TABLE.HEADER.FEEBACK_TEXT'),
          align: 'left',
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
              <router-link to={routerParams}>
                {`#${row.conversationId}`}
              </router-link>
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
      }));
    },
    satisfactionScore() {
      return (
        ((this.metrics.ratingsCount[4] + this.metrics.ratingsCount[5]) /
          this.metrics.totalResponseCount) *
        100
      ).toFixed(2);
    },
    chartOptions() {
      return {
        responsive: true,
        legend: {
          display: false,
        },
        title: {
          display: false,
        },
        scales: {
          xAxes: [
            {
              gridLines: {
                offsetGridLines: false,
              },
              display: false,
              stacked: true,
            },
          ],
          yAxes: [
            {
              gridLines: {
                offsetGridLines: false,
              },
              display: false,
              stacked: true,
            },
          ],
        },
      };
    },
    chartData() {
      return {
        labels: ['Rating'],
        datasets: CSAT_RATINGS.map(rating => ({
          label: rating.emoji,
          data: [
            (
              (this.metrics.ratingsCount[rating.value] /
                this.metrics.totalResponseCount) *
              100
            ).toFixed(2),
          ],
          backgroundColor: rating.color,
        })),
      };
    },
  },
  watch: {},
  destroyed() {},
  mounted() {
    this.$store.dispatch('csat/getMetrics');
    this.getData();
  },
  methods: {
    getData() {
      this.$store.dispatch('csat/get', {
        page: this.pageIndex,
      });
    },
    onPageNumberChange(pageIndex) {
      this.pageIndex = pageIndex;
      this.getData();
    },
  },
};
</script>
<style scoped lang="scss">
.csat--container {
  padding: var(--space-two);
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

.csat--metrics-container {
  background: var(--white);
  margin-bottom: var(--space-two);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  padding: var(--space-normal);
}

.csat--table-container {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.bar--display {
  padding: var(--space-two);
}
.report-card {
  border: 0;

  .metric {
    margin-bottom: 0;
  }
}
</style>
