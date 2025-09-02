<template>
  <div class="advanced-search-filters">
    <!-- Search Input -->
    <div class="search-input-container mb-4">
      <div class="relative">
        <fluent-icon 
          icon="search" 
          class="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400"
          size="18"
        />
        <input
          v-model="localParams.query"
          type="text"
          :placeholder="$t('ADVANCED_SEARCH.PLACEHOLDER')"
          class="search-input"
          @keyup.enter="handleSearch"
        />
        <woot-button
          v-if="localParams.query"
          icon="dismiss"
          variant="clear"
          size="small"
          class="absolute right-2 top-1/2 transform -translate-y-1/2"
          @click="clearQuery"
        />
      </div>
    </div>

    <!-- Filter Chips (Active Filters) -->
    <div v-if="activeFilters.length > 0" class="active-filters mb-4">
      <div class="flex items-center gap-2 flex-wrap">
        <span class="text-sm text-slate-600">{{ $t('ADVANCED_SEARCH.ACTIVE_FILTERS') }}:</span>
        <FilterChip
          v-for="filter in activeFilters"
          :key="`${filter.type}-${filter.value}`"
          :type="filter.type"
          :value="filter.value"
          :label="filter.label"
          @remove="removeFilter"
        />
        <woot-button
          size="small"
          variant="clear"
          color-scheme="alert"
          @click="clearAllFilters"
        >
          {{ $t('ADVANCED_SEARCH.CLEAR_ALL') }}
        </woot-button>
      </div>
    </div>

    <!-- Filter Controls -->
    <div class="filter-controls">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <!-- Channel Types -->
        <FilterDropdown
          :label="$t('ADVANCED_SEARCH.FILTERS.CHANNEL_TYPES')"
          :options="channelTypeOptions"
          :selected="localParams.channel_types"
          multiple
          @update="updateFilter('channel_types', $event)"
        />

        <!-- Inboxes -->
        <FilterDropdown
          :label="$t('ADVANCED_SEARCH.FILTERS.INBOXES')"
          :options="inboxOptions"
          :selected="localParams.inbox_ids"
          multiple
          searchable
          @update="updateFilter('inbox_ids', $event)"
        />

        <!-- Agents -->
        <FilterDropdown
          :label="$t('ADVANCED_SEARCH.FILTERS.AGENTS')"
          :options="agentOptions"
          :selected="localParams.agent_ids"
          multiple
          searchable
          @update="updateFilter('agent_ids', $event)"
        />

        <!-- Teams -->
        <FilterDropdown
          :label="$t('ADVANCED_SEARCH.FILTERS.TEAMS')"
          :options="teamOptions"
          :selected="localParams.team_ids"
          multiple
          @update="updateFilter('team_ids', $event)"
        />

        <!-- Status -->
        <FilterDropdown
          :label="$t('ADVANCED_SEARCH.FILTERS.STATUS')"
          :options="statusOptions"
          :selected="localParams.status"
          multiple
          @update="updateFilter('status', $event)"
        />

        <!-- Priority -->
        <FilterDropdown
          :label="$t('ADVANCED_SEARCH.FILTERS.PRIORITY')"
          :options="priorityOptions"
          :selected="localParams.priority"
          multiple
          @update="updateFilter('priority', $event)"
        />
      </div>

      <!-- Advanced Filters Toggle -->
      <div class="mt-4">
        <woot-button
          variant="clear"
          size="small"
          :icon="showAdvanced ? 'chevron-up' : 'chevron-down'"
          @click="showAdvanced = !showAdvanced"
        >
          {{ $t('ADVANCED_SEARCH.ADVANCED_FILTERS') }}
        </woot-button>
      </div>

      <!-- Advanced Filters -->
      <div v-if="showAdvanced" class="advanced-filters mt-4 p-4 bg-slate-50 rounded-lg">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <!-- Labels -->
          <FilterDropdown
            :label="$t('ADVANCED_SEARCH.FILTERS.LABELS')"
            :options="labelOptions"
            :selected="localParams.labels"
            multiple
            searchable
            allow-custom
            @update="updateFilter('labels', $event)"
          />

          <!-- Message Types -->
          <FilterDropdown
            :label="$t('ADVANCED_SEARCH.FILTERS.MESSAGE_TYPES')"
            :options="messageTypeOptions"
            :selected="localParams.message_types"
            multiple
            @update="updateFilter('message_types', $event)"
          />

          <!-- Sentiment -->
          <FilterDropdown
            :label="$t('ADVANCED_SEARCH.FILTERS.SENTIMENT')"
            :options="sentimentOptions"
            :selected="localParams.sentiment"
            multiple
            @update="updateFilter('sentiment', $event)"
          />

          <!-- SLA Status -->
          <FilterDropdown
            :label="$t('ADVANCED_SEARCH.FILTERS.SLA_STATUS')"
            :options="slaStatusOptions"
            :selected="localParams.sla_status"
            multiple
            @update="updateFilter('sla_status', $event)"
          />
        </div>

        <!-- Date Range -->
        <div class="date-range mt-4">
          <label class="block text-sm font-medium mb-2">
            {{ $t('ADVANCED_SEARCH.FILTERS.DATE_RANGE') }}
          </label>
          <div class="flex gap-2">
            <woot-date-picker
              v-model="localParams.date_from"
              :placeholder="$t('ADVANCED_SEARCH.FILTERS.DATE_FROM')"
              @input="emitChange"
            />
            <span class="flex items-center text-slate-400">{{ $t('ADVANCED_SEARCH.TO') }}</span>
            <woot-date-picker
              v-model="localParams.date_to"
              :placeholder="$t('ADVANCED_SEARCH.FILTERS.DATE_TO')"
              @input="emitChange"
            />
          </div>
        </div>

        <!-- Boolean Filters -->
        <div class="boolean-filters mt-4">
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <woot-checkbox
              v-model="localParams.has_attachments"
              @input="emitChange"
            >
              {{ $t('ADVANCED_SEARCH.FILTERS.HAS_ATTACHMENTS') }}
            </woot-checkbox>

            <woot-checkbox
              v-model="localParams.unread_only"
              @input="emitChange"
            >
              {{ $t('ADVANCED_SEARCH.FILTERS.UNREAD_ONLY') }}
            </woot-checkbox>

            <woot-checkbox
              v-model="localParams.assigned_only"
              :disabled="localParams.unassigned_only"
              @input="emitChange"
            >
              {{ $t('ADVANCED_SEARCH.FILTERS.ASSIGNED_ONLY') }}
            </woot-checkbox>

            <woot-checkbox
              v-model="localParams.unassigned_only"
              :disabled="localParams.assigned_only"
              @input="emitChange"
            >
              {{ $t('ADVANCED_SEARCH.FILTERS.UNASSIGNED_ONLY') }}
            </woot-checkbox>
          </div>
        </div>
      </div>
    </div>

    <!-- Action Buttons -->
    <div class="action-buttons mt-6 flex gap-3">
      <woot-button
        color-scheme="primary"
        :disabled="loading || !hasQuery"
        :loading="loading"
        @click="handleSearch"
      >
        {{ $t('ADVANCED_SEARCH.SEARCH') }}
      </woot-button>

      <woot-button
        v-if="hasActiveFilters || localParams.query"
        variant="clear"
        @click="handleClear"
      >
        {{ $t('ADVANCED_SEARCH.CLEAR') }}
      </woot-button>

      <!-- Quick Filters -->
      <div class="quick-filters ml-auto">
        <woot-button
          size="small"
          variant="clear"
          color-scheme="secondary"
          @click="applyQuickFilter('unread')"
        >
          {{ $t('ADVANCED_SEARCH.QUICK_FILTERS.UNREAD') }}
        </woot-button>
        <woot-button
          size="small"
          variant="clear"  
          color-scheme="secondary"
          @click="applyQuickFilter('unassigned')"
        >
          {{ $t('ADVANCED_SEARCH.QUICK_FILTERS.UNASSIGNED') }}
        </woot-button>
        <woot-button
          size="small"
          variant="clear"
          color-scheme="secondary"
          @click="applyQuickFilter('mine')"
        >
          {{ $t('ADVANCED_SEARCH.QUICK_FILTERS.MINE') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import FilterDropdown from './FilterDropdown.vue';
import FilterChip from './FilterChip.vue';

export default {
  name: 'AdvancedSearchFilters',
  components: {
    FilterDropdown,
    FilterChip
  },
  props: {
    value: {
      type: Object,
      default: () => ({})
    },
    loading: {
      type: Boolean,
      default: false
    }
  },
  emits: ['input', 'search', 'clear'],
  data() {
    return {
      showAdvanced: false,
      localParams: { ...this.value }
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      agents: 'agents/getAgents',
      inboxes: 'inboxes/getInboxes', 
      teams: 'teams/getTeams',
      labels: 'labels/getLabels'
    }),

    hasQuery() {
      return this.localParams.query && this.localParams.query.trim().length > 0;
    },

    hasActiveFilters() {
      const filterKeys = [
        'channel_types', 'inbox_ids', 'agent_ids', 'team_ids', 'labels',
        'status', 'priority', 'message_types', 'sentiment', 'sla_status'
      ];
      
      return filterKeys.some(key => 
        Array.isArray(this.localParams[key]) && this.localParams[key].length > 0
      ) || this.localParams.date_from || this.localParams.date_to ||
      this.localParams.has_attachments || this.localParams.unread_only ||
      this.localParams.assigned_only || this.localParams.unassigned_only;
    },

    activeFilters() {
      const filters = [];

      // Array filters
      const arrayFilters = {
        channel_types: 'CHANNEL_TYPES',
        inbox_ids: 'INBOXES', 
        agent_ids: 'AGENTS',
        team_ids: 'TEAMS',
        labels: 'LABELS',
        status: 'STATUS',
        priority: 'PRIORITY',
        message_types: 'MESSAGE_TYPES',
        sentiment: 'SENTIMENT',
        sla_status: 'SLA_STATUS'
      };

      Object.entries(arrayFilters).forEach(([key, labelKey]) => {
        if (Array.isArray(this.localParams[key]) && this.localParams[key].length > 0) {
          this.localParams[key].forEach(value => {
            filters.push({
              type: key,
              value: value,
              label: this.getFilterLabel(key, value)
            });
          });
        }
      });

      // Date filters
      if (this.localParams.date_from) {
        filters.push({
          type: 'date_from',
          value: this.localParams.date_from,
          label: `From: ${this.$d(this.localParams.date_from, 'short')}`
        });
      }

      if (this.localParams.date_to) {
        filters.push({
          type: 'date_to', 
          value: this.localParams.date_to,
          label: `To: ${this.$d(this.localParams.date_to, 'short')}`
        });
      }

      // Boolean filters
      const booleanFilters = {
        has_attachments: 'HAS_ATTACHMENTS',
        unread_only: 'UNREAD_ONLY',
        assigned_only: 'ASSIGNED_ONLY',
        unassigned_only: 'UNASSIGNED_ONLY'
      };

      Object.entries(booleanFilters).forEach(([key, labelKey]) => {
        if (this.localParams[key]) {
          filters.push({
            type: key,
            value: true,
            label: this.$t(`ADVANCED_SEARCH.FILTERS.${labelKey}`)
          });
        }
      });

      return filters;
    },

    // Filter Options
    channelTypeOptions() {
      const types = ['Channel::WebWidget', 'Channel::Email', 'Channel::Api', 'Channel::FacebookPage', 'Channel::TwitterProfile', 'Channel::TwilioSms', 'Channel::Whatsapp', 'Channel::Line', 'Channel::Telegram', 'Channel::Slack'];
      return types.map(type => ({
        value: type.toLowerCase().split('::')[1],
        label: this.$t(`INBOX_MGMT.CHANNELS.${type.split('::')[1].toUpperCase()}`)
      }));
    },

    inboxOptions() {
      return this.inboxes.map(inbox => ({
        value: inbox.id,
        label: inbox.name
      }));
    },

    agentOptions() {
      return this.agents.map(agent => ({
        value: agent.id,
        label: agent.name
      }));
    },

    teamOptions() {
      return this.teams.map(team => ({
        value: team.id,
        label: team.name
      }));
    },

    labelOptions() {
      return this.labels.map(label => ({
        value: label.title,
        label: label.title,
        color: label.color
      }));
    },

    statusOptions() {
      return [
        { value: 'open', label: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.open') },
        { value: 'resolved', label: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.resolved') },
        { value: 'pending', label: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.pending') },
        { value: 'snoozed', label: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.snoozed') }
      ];
    },

    priorityOptions() {
      return [
        { value: 'low', label: this.$t('CONVERSATION.PRIORITY.OPTIONS.LOW') },
        { value: 'medium', label: this.$t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM') },
        { value: 'high', label: this.$t('CONVERSATION.PRIORITY.OPTIONS.HIGH') },
        { value: 'urgent', label: this.$t('CONVERSATION.PRIORITY.OPTIONS.URGENT') }
      ];
    },

    messageTypeOptions() {
      return [
        { value: 'incoming', label: this.$t('ADVANCED_SEARCH.MESSAGE_TYPES.INCOMING') },
        { value: 'outgoing', label: this.$t('ADVANCED_SEARCH.MESSAGE_TYPES.OUTGOING') },
        { value: 'activity', label: this.$t('ADVANCED_SEARCH.MESSAGE_TYPES.ACTIVITY') },
        { value: 'template', label: this.$t('ADVANCED_SEARCH.MESSAGE_TYPES.TEMPLATE') }
      ];
    },

    sentimentOptions() {
      return [
        { value: 'positive', label: this.$t('ADVANCED_SEARCH.SENTIMENT.POSITIVE') },
        { value: 'negative', label: this.$t('ADVANCED_SEARCH.SENTIMENT.NEGATIVE') },
        { value: 'neutral', label: this.$t('ADVANCED_SEARCH.SENTIMENT.NEUTRAL') }
      ];
    },

    slaStatusOptions() {
      return [
        { value: 'active', label: this.$t('SLA.STATUS.ACTIVE') },
        { value: 'hit', label: this.$t('SLA.STATUS.HIT') },
        { value: 'missed', label: this.$t('SLA.STATUS.MISSED') },
        { value: 'active_with_misses', label: this.$t('SLA.STATUS.ACTIVE_WITH_MISSES') }
      ];
    }
  },

  watch: {
    value: {
      handler(newValue) {
        this.localParams = { ...newValue };
      },
      deep: true
    }
  },

  methods: {
    updateFilter(filterType, values) {
      this.localParams[filterType] = values;
      this.emitChange();
    },

    removeFilter(filter) {
      const { type, value } = filter;

      if (Array.isArray(this.localParams[type])) {
        this.localParams[type] = this.localParams[type].filter(v => v !== value);
      } else {
        this.localParams[type] = type.includes('date') ? null : false;
      }

      this.emitChange();
    },

    clearQuery() {
      this.localParams.query = '';
      this.emitChange();
    },

    clearAllFilters() {
      const clearedParams = {
        query: this.localParams.query, // Keep query
        channel_types: [],
        inbox_ids: [],
        agent_ids: [],
        team_ids: [],
        tags: [],
        labels: [],
        status: [],
        priority: [],
        message_types: [],
        sender_types: [],
        sentiment: [],
        sla_status: [],
        date_from: null,
        date_to: null,
        has_attachments: false,
        unread_only: false,
        assigned_only: false,
        unassigned_only: false
      };

      this.localParams = clearedParams;
      this.emitChange();
    },

    applyQuickFilter(type) {
      this.clearAllFilters();

      switch (type) {
        case 'unread':
          this.localParams.unread_only = true;
          break;
        case 'unassigned':
          this.localParams.unassigned_only = true;
          break;
        case 'mine':
          this.localParams.agent_ids = [this.currentUser.id];
          this.localParams.assigned_only = true;
          break;
      }

      this.emitChange();
      this.handleSearch();
    },

    getFilterLabel(filterType, value) {
      // Get human-readable label for filter value
      switch (filterType) {
        case 'inbox_ids':
          const inbox = this.inboxes.find(i => i.id === parseInt(value));
          return inbox ? inbox.name : value;
        case 'agent_ids':
          const agent = this.agents.find(a => a.id === parseInt(value));
          return agent ? agent.name : value;
        case 'team_ids':
          const team = this.teams.find(t => t.id === parseInt(value));
          return team ? team.name : value;
        default:
          return value;
      }
    },

    handleSearch() {
      this.$emit('search');
    },

    handleClear() {
      this.localParams = {
        query: '',
        channel_types: [],
        inbox_ids: [],
        agent_ids: [],
        team_ids: [],
        tags: [],
        labels: [],
        status: [],
        priority: [],
        message_types: [],
        sender_types: [],
        sentiment: [],
        sla_status: [],
        date_from: null,
        date_to: null,
        has_attachments: false,
        unread_only: false,
        assigned_only: false,
        unassigned_only: false
      };
      this.emitChange();
      this.$emit('clear');
    },

    emitChange() {
      this.$emit('input', this.localParams);
    }
  }
};
</script>

<style lang="scss" scoped>
.search-input {
  @apply w-full pl-10 pr-10 py-3 border border-slate-300 rounded-lg;
  @apply focus:ring-2 focus:ring-blue-500 focus:border-blue-500;
  @apply placeholder-slate-400;
}

.advanced-filters {
  border: 1px solid theme('colors.slate.200');
  animation: slideDown 0.2s ease-out;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.filter-controls {
  .quick-filters {
    display: flex;
    gap: 0.5rem;
  }
}
</style>