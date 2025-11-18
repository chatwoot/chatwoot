<template>
  <div class="flex flex-col h-full">
    <!-- Header -->
    <div class="border-b border-slate-200 dark:border-slate-700 px-4 py-3">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-medium text-slate-900 dark:text-slate-50">
          {{ $t('SALES_PIPELINE.TITLE') }}
        </h2>
        
        <!-- Filters -->
        <div class="flex items-center space-x-3">
          <div class="flex items-center space-x-2">
            <label class="text-sm font-medium text-slate-700 dark:text-slate-300">
              {{ $t('SALES_PIPELINE.FILTERS.INBOX') }}:
            </label>
            <select
              v-model="filters.inbox_id"
              class="rounded-lg border border-slate-300 dark:border-slate-600 px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-50"
              @change="loadKanbanData"
            >
              <option value="">
                {{ $t('SALES_PIPELINE.FILTERS.ALL_INBOXES') }}
              </option>
              <option
                v-for="inbox in inboxes"
                :key="inbox.id"
                :value="inbox.id"
              >
                {{ inbox.name }}
              </option>
            </select>
          </div>

          <div class="flex items-center space-x-2">
            <label class="text-sm font-medium text-slate-700 dark:text-slate-300">
              {{ $t('SALES_PIPELINE.FILTERS.ASSIGNEE') }}:
            </label>
            <select
              v-model="filters.assignee_id"
              class="rounded-lg border border-slate-300 dark:border-slate-600 px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-50"
              @change="loadKanbanData"
            >
              <option value="">
                {{ $t('SALES_PIPELINE.FILTERS.ALL_AGENTS') }}
              </option>
              <option
                v-for="agent in agents"
                :key="agent.id"
                :value="agent.id"
              >
                {{ agent.name }}
              </option>
            </select>
          </div>

          <button
            class="btn btn--primary"
            @click="loadKanbanData"
            :disabled="uiFlags.isFetching"
          >
            <spinner v-if="uiFlags.isFetching" size="small" />
            {{ $t('SALES_PIPELINE.REFRESH') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Kanban Board -->
    <div class="flex-1 overflow-x-auto">
      <div v-if="uiFlags.isFetching" class="flex items-center justify-center h-64">
        <spinner size="large" />
      </div>

      <div
        v-else-if="stages.length === 0"
        class="flex flex-col items-center justify-center h-64 text-slate-500 dark:text-slate-400"
      >
        <div class="text-lg font-medium mb-2">
          {{ $t('SALES_PIPELINE.NO_STAGES_CONFIGURED') }}
        </div>
        <div class="text-sm">
          {{ $t('SALES_PIPELINE.CONFIGURE_STAGES_FIRST') }}
        </div>
        <router-link
          :to="settingsRoute"
          class="btn btn--primary mt-4"
        >
          {{ $t('SALES_PIPELINE.CONFIGURE_PIPELINE') }}
        </router-link>
      </div>

      <div v-else class="flex h-full p-4 space-x-4">
        <div
          v-for="stage in kanbanData"
          :key="stage.stage_id"
          class="flex-shrink-0 w-80 bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700"
        >
          <!-- Column Header -->
          <div
            class="px-4 py-3 border-b border-slate-200 dark:border-slate-700 rounded-t-lg"
            :style="{ backgroundColor: stage.color + '20', borderColor: stage.color }"
          >
            <div class="flex items-center justify-between">
              <h3 class="font-medium text-slate-900 dark:text-slate-50">
                {{ stage.name }}
              </h3>
              <span
                class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                :style="{ backgroundColor: stage.color + '20', color: stage.color }"
              >
                {{ stage.cards_count }}
              </span>
            </div>
            <div v-if="stage.is_default" class="text-xs text-slate-500 dark:text-slate-400 mt-1">
              {{ $t('SALES_PIPELINE.DEFAULT_STAGE') }}
            </div>
            <div v-else-if="stage.is_closed_won" class="text-xs text-green-600 dark:text-green-400 mt-1">
              {{ $t('SALES_PIPELINE.CLOSED_WON') }}
            </div>
            <div v-else-if="stage.is_closed_lost" class="text-xs text-red-600 dark:text-red-400 mt-1">
              {{ $t('SALES_PIPELINE.CLOSED_LOST') }}
            </div>
          </div>

          <!-- Cards Container -->
          <div class="p-3 space-y-2 min-h-[400px] max-h-[600px] overflow-y-auto">
            <div
              v-for="card in stage.cards"
              :key="card.conversation_id"
              class="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg p-3 cursor-pointer hover:shadow-md transition-shadow"
              @click="openConversation(card.conversation_id)"
            >
              <div class="flex items-start justify-between mb-2">
                <div class="flex items-center space-x-2">
                  <div class="w-6 h-6 rounded-full bg-slate-200 dark:bg-slate-700 flex items-center justify-center">
                    <span class="text-xs font-medium text-slate-600 dark:text-slate-300">
                      {{ card.contact_name.charAt(0).toUpperCase() }}
                    </span>
                  </div>
                  <div>
                    <div class="text-sm font-medium text-slate-900 dark:text-slate-50">
                      {{ card.contact_name }}
                    </div>
                    <div class="text-xs text-slate-500 dark:text-slate-400">
                      {{ card.inbox_name }}
                    </div>
                  </div>
                </div>
                <span
                  class="inline-flex items-center px-2 py-1 rounded text-xs font-medium"
                  :class="getStatusClass(card.status)"
                >
                  {{ getStatusText(card.status) }}
                </span>
              </div>

              <div class="text-sm text-slate-600 dark:text-slate-400 mb-2 line-clamp-2">
                {{ card.last_message_snippet || $t('SALES_PIPELINE.NO_MESSAGES') }}
              </div>

              <div class="flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
                <div>{{ card.assignee_name }}</div>
                <div>{{ timeFormat(card.last_activity_at) }}</div>
              </div>
            </div>

            <div
              v-if="stage.cards.length === 0"
              class="text-center text-slate-400 dark:text-slate-500 text-sm py-8"
            >
              {{ $t('SALES_PIPELINE.NO_CARDS_IN_STAGE') }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import timeMixin from 'dashboard/mixins/time';
import { frontendURL } from 'dashboard/helper/URLHelper';
import FluentIcon from 'shared/components/FluentIcon.vue';
import draggable from 'vuedraggable';

export default {
  name: 'SalesPipelineIndex',
  components: {
    Spinner,
    FluentIcon,
    draggable,
  },
  mixins: [timeMixin],
  data() {
    return {
      filters: {
        inbox_id: '',
        assignee_id: '',
        status: '',
      },
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'salesPipeline/getUIFlags',
      stages: 'salesPipeline/getStages',
      kanbanData: 'salesPipeline/getKanbanData',
      inboxes: 'inboxes/getInboxes',
      agents: 'agents/getAgents',
      currentAccountId: 'getCurrentAccountId',
    }),
    settingsRoute() {
      return frontendURL(`accounts/${this.currentAccountId}/settings/sales-pipeline`);
    },
  },
  mounted() {
    this.loadInitialData();
  },
  methods: {
    async loadInitialData() {
      try {
        await this.$store.dispatch('salesPipeline/fetchSalesPipeline', {
          accountId: this.currentAccountId,
        });
        await this.loadKanbanData();
      } catch (error) {
        this.showErrorMessage(this.$t('SALES_PIPELINE.ERROR.LOAD_FAILED'));
      }
    },

    async loadKanbanData() {
      try {
        await this.$store.dispatch('salesPipeline/fetchKanbanData', {
          accountId: this.currentAccountId,
          filters: this.filters,
        });
      } catch (error) {
        this.showErrorMessage(this.$t('SALES_PIPELINE.ERROR.KANBAN_LOAD_FAILED'));
      }
    },

    openConversation(conversationId) {
      const routeData = this.$router.resolve({
        name: 'conversation_page',
        params: {
          accountId: this.currentAccountId,
          conversationId,
        },
      });
      window.open(routeData.href, '_blank');
    },

    getStatusClass(status) {
      const statusClasses = {
        open: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
        resolved: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
        pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
        snoozed: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
      };
      return statusClasses[status] || 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200';
    },

    getStatusText(status) {
      const statusTexts = {
        open: this.$t('CONVERSATION.STATUS.OPEN'),
        resolved: this.$t('CONVERSATION.STATUS.RESOLVED'),
        pending: this.$t('CONVERSATION.STATUS.PENDING'),
        snoozed: this.$t('CONVERSATION.STATUS.SNOOZED'),
      };
      return statusTexts[status] || status;
    },

    showErrorMessage(message) {
      this.$root.$emit('newToastMessage', {
        message,
        type: 'error',
      });
    },
  },
};
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>