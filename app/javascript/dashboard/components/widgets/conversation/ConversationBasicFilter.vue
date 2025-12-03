<template>
  <div class="relative flex">
    <woot-button
      v-tooltip.right="$t('CHAT_LIST.SORT_TOOLTIP_LABEL')"
      variant="smooth"
      size="tiny"
      color-scheme="secondary"
      class="selector-button"
      icon="sort-icon"
      @click="toggleDropdown"
    />
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="dropdown-pane dropdown-pane--open mt-1 right-0 basic-filter"
    >
      <div class="items-center flex justify-between last:mt-4">
        <span class="text-slate-800 dark:text-slate-100 text-xs font-medium">{{
          $t('CHAT_LIST.CHAT_SORT.STATUS')
        }}</span>
        <filter-item
          type="status"
          :selected-value="chatStatus"
          :items="chatStatusItems"
          path-prefix="CHAT_LIST.CHAT_STATUS_FILTER_ITEMS"
          @onChangeFilter="onChangeFilter"
        />
      </div>
      <div class="items-center flex justify-between mt-4">
        <span class="text-slate-800 dark:text-slate-100 text-xs font-medium">
          {{ 'Read State' }}
        </span>
        <filter-item
          type="readState"
          :selected-value="conversationReadStatus"
          :items="conversationReadStatusItems"
          @onChangeFilter="onChangeFilter"
        />
      </div>
      <div class="items-center flex justify-between mt-4">
        <span class="text-slate-800 dark:text-slate-100 text-xs font-medium">
          {{ $t('CHAT_LIST.FILTER_AGENT') }}
        </span>
        <filter-item
          type="agent"
          :selected-value="activeAgent"
          :items="agentFilterItems"
          @onChangeFilter="onChangeFilter"
        />
      </div>
      <div class="items-center flex justify-between last:mt-4">
        <span class="text-slate-800 dark:text-slate-100 text-xs font-medium">{{
          $t('CHAT_LIST.CHAT_SORT.ORDER_BY')
        }}</span>
        <filter-item
          type="sort"
          :selected-value="sortFilter"
          :items="chatSortItems"
          path-prefix="CHAT_LIST.SORT_ORDER_ITEMS"
          @onChangeFilter="onChangeFilter"
        />
      </div>
    </div>
  </div>
</template>

<script>
import wootConstants from 'dashboard/constants/globals';
import { mapGetters } from 'vuex';
import FilterItem from './FilterItem.vue';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

export default {
  components: {
    FilterItem,
  },
  mixins: [uiSettingsMixin],
  data() {
    return {
      showActionsDropdown: false,
      chatStatusItems: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS'),
      conversationReadStatusItems: {
        all: {
          TEXT: 'All',
        },
        unread: {
          TEXT: 'Unread',
        },
        read: {
          TEXT: 'Read',
        },
      },
      chatSortItems: this.$t('CHAT_LIST.SORT_ORDER_ITEMS'),
    };
  },
  computed: {
    ...mapGetters({
      chatStatusFilter: 'getChatStatusFilter',
      chatSortFilter: 'getChatSortFilter',
      conversationReadStatusFilter: 'getConversationReadStatusFilter',
      agentFilter: 'getAgentFilter',
      agents: 'agents/getAgents',
    }),
    chatStatus() {
      return this.chatStatusFilter || wootConstants.STATUS_TYPE.OPEN;
    },
    conversationReadStatus() {
      return (
        this.conversationReadStatusFilter ||
        wootConstants.CONVERSATION_READ_STATUS_TYPE.ALL
      );
    },
    sortFilter() {
      return (
        this.chatSortFilter || wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC
      );
    },
    activeAgent() {
      return this.agentFilter || wootConstants.AGENT_FILTER_TYPE.ALL;
    },
    agentFilterItems() {
      const agents = this.agents || [];
      const items = {
        all: { TEXT: this.$t('CHAT_LIST.AGENT_FILTER_ITEMS.all.TEXT') },
        unassigned: {
          TEXT: this.$t('CHAT_LIST.AGENT_FILTER_ITEMS.unassigned.TEXT'),
        },
      };

      agents.forEach(agent => {
        items[agent.id] = {
          TEXT: agent.available_name || agent.name || 'Agent',
        };
      });

      return items;
    },
  },
  methods: {
    onTabChange(value) {
      this.$emit('changeFilter', value);
      this.closeDropdown();
    },
    toggleDropdown() {
      this.showActionsDropdown = !this.showActionsDropdown;
    },
    closeDropdown() {
      this.showActionsDropdown = false;
    },
    onChangeFilter(value, type) {
      this.$emit('changeFilter', value, type);
      this.saveSelectedFilter(type, value);
    },
    saveSelectedFilter(type, value) {
      this.updateUISettings({
        conversations_filter_by: {
          status: type === 'status' ? value : this.chatStatus,
          order_by: type === 'sort' ? value : this.sortFilter,
        },
      });
    },
  },
};
</script>
<style lang="scss" scoped>
.basic-filter {
  @apply w-52 p-4 top-6;
}
</style>
