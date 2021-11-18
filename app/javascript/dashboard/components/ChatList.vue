l<template>
  <div class="conversations-list-wrap">
    <slot></slot>
    <div class="chat-list__top" :class="{ filter__applied: hasAppliedFilters }">
      <h1 class="page-title text-truncate" :title="pageTitle">
        {{ pageTitle }}
      </h1>

      <div class="filter--actions">
        <chat-filter
          v-if="!hasAppliedFilters"
          @statusFilterChange="updateStatusType"
        />
        <woot-button
          v-else
          variant="clear"
          color-scheme="danger"
          class="btn-clear-filters"
          @click="resetAndFetchData"
        >
          {{ $t('FILTER.CLEAR_BUTTON_LABEL') }}
        </woot-button>
        <woot-button
          v-tooltip.top-end="$t('FILTER.TOOLTIP_LABEL')"
          variant="clear"
          color-scheme="secondary"
          class="btn-filter"
          @click="onToggleAdvanceFiltersModal"
        >
          <i class="icon ion-ios-settings-strong" />
        </woot-button>
      </div>
    </div>

    <chat-type-tabs
      v-if="!hasAppliedFilters"
      :items="assigneeTabItems"
      :active-tab="activeAssigneeTab"
      class="tab--chat-type"
      @chatTabChange="updateAssigneeTab"
    />

    <p v-if="!chatListLoading && !conversationList.length" class="content-box">
      {{ $t('CHAT_LIST.LIST.404') }}
    </p>

    <div ref="activeConversation" class="conversations-list">
      <conversation-card
        v-for="chat in conversationList"
        :key="chat.id"
        :active-label="label"
        :team-id="teamId"
        :chat="chat"
        :show-assignee="showAssigneeInConversationCard"
      />

      <div v-if="chatListLoading" class="text-center">
        <span class="spinner"></span>
      </div>

      <woot-button
        v-if="!hasCurrentPageEndReached && !chatListLoading"
        variant="clear"
        size="expanded"
        @click="loadMoreConversations"
      >
        {{ $t('CHAT_LIST.LOAD_MORE_CONVERSATIONS') }}
      </woot-button>

      <p
        v-if="
          conversationList.length &&
            hasCurrentPageEndReached &&
            !chatListLoading
        "
        class="text-center text-muted end-of-list-text"
      >
        {{ $t('CHAT_LIST.EOF') }}
      </p>
    </div>
    <woot-modal
      :show.sync="showAdvancedFilters"
      :on-close="onToggleAdvanceFiltersModal"
    >
      <conversation-advanced-filter
        v-if="showAdvancedFilters"
        :filter-types="advancedFilterTypes"
        :on-close="onToggleAdvanceFiltersModal"
        @applyFilter="onApplyFilter"
      />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ChatFilter from './widgets/conversation/ChatFilter';
import ConversationAdvancedFilter from './widgets/conversation/ConversationAdvancedFilter';
import ChatTypeTabs from './widgets/ChatTypeTabs';
import ConversationCard from './widgets/conversation/ConversationCard';
import timeMixin from '../mixins/time';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import conversationMixin from '../mixins/conversations';
import wootConstants from '../constants';
import advancedFilterTypes from './widgets/conversation/advancedFilterItems';
import filterQueryGenerator from '../helper/filterQueryGenerator.js';

import {
  hasPressedAltAndJKey,
  hasPressedAltAndKKey,
} from 'shared/helpers/KeyboardHelpers';

export default {
  components: {
    ChatTypeTabs,
    ConversationCard,
    ChatFilter,
    ConversationAdvancedFilter,
  },
  mixins: [timeMixin, conversationMixin, eventListenerMixins],
  props: {
    conversationInbox: {
      type: [String, Number],
      default: 0,
    },
    teamId: {
      type: [String, Number],
      default: 0,
    },
    label: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      activeAssigneeTab: wootConstants.ASSIGNEE_TYPE.ME,
      activeStatus: wootConstants.STATUS_TYPE.OPEN,
      showAdvancedFilters: false,
      advancedFilterTypes: advancedFilterTypes.map(filter => ({
        ...filter,
        attributeName: this.$t(`FILTER.ATTRIBUTES.${filter.attributeI18nKey}`),
      })),
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      chatLists: 'getAllConversations',
      mineChatsList: 'getMineChats',
      allChatList: 'getAllStatusChats',
      unAssignedChatsList: 'getUnAssignedChats',
      chatListLoading: 'getChatListLoadingStatus',
      currentUserID: 'getCurrentUserID',
      activeInbox: 'getSelectedInbox',
      conversationStats: 'conversationStats/getStats',
      appliedFilters: 'getAppliedFilters',
    }),
    hasAppliedFilters() {
      return this.appliedFilters.length;
    },
    assigneeTabItems() {
      return this.$t('CHAT_LIST.ASSIGNEE_TYPE_TABS').map(item => {
        const count = this.conversationStats[item.COUNT_KEY] || 0;
        return {
          key: item.KEY,
          name: item.NAME,
          count,
        };
      });
    },
    showAssigneeInConversationCard() {
      return this.activeAssigneeTab === wootConstants.ASSIGNEE_TYPE.ALL;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.activeInbox);
    },
    currentPage() {
      return this.$store.getters['conversationPage/getCurrentPageFilter'](
        this.activeAssigneeTab
      );
    },
    currentPageFilterKey() {
      return this.hasAppliedFilters ? 'appliedFilters' : this.activeAssigneeTab;
    },
    currentFiltersPage() {
      return this.$store.getters['conversationPage/getCurrentPageFilter'](
        this.currentPageFilterKey
      );
    },
    hasCurrentPageEndReached() {
      return this.$store.getters['conversationPage/getHasEndReached'](
        this.currentPageFilterKey
      );
    },
    conversationFilters() {
      return {
        inboxId: this.conversationInbox ? this.conversationInbox : undefined,
        assigneeType: this.activeAssigneeTab,
        status: this.activeStatus,
        page: this.currentPage + 1,
        labels: this.label ? [this.label] : undefined,
        teamId: this.teamId ? this.teamId : undefined,
      };
    },
    pageTitle() {
      if (this.inbox.name) {
        return this.inbox.name;
      }
      if (this.activeTeam.name) {
        return this.activeTeam.name;
      }
      if (this.label) {
        return `#${this.label}`;
      }
      return this.$t('CHAT_LIST.TAB_HEADING');
    },
    conversationList() {
      let conversationList = [];
      if (!this.hasAppliedFilters) {
        const filters = this.conversationFilters;
        if (this.activeAssigneeTab === 'me') {
          conversationList = [...this.mineChatsList(filters)];
        } else if (this.activeAssigneeTab === 'unassigned') {
          conversationList = [...this.unAssignedChatsList(filters)];
        } else {
          conversationList = [...this.allChatList(filters)];
        }
      } else {
        conversationList = [...this.chatLists];
      }

      return conversationList;
    },
    activeTeam() {
      if (this.teamId) {
        return this.$store.getters['teams/getTeam'](this.teamId);
      }
      return {};
    },
  },
  watch: {
    activeTeam() {
      this.resetAndFetchData();
    },
    conversationInbox() {
      this.resetAndFetchData();
    },
    label() {
      this.resetAndFetchData();
    },
  },
  mounted() {
    this.$store.dispatch('setChatFilter', this.activeStatus);
    this.resetAndFetchData();

    bus.$on('fetch_conversation_stats', () => {
      this.$store.dispatch('conversationStats/get', this.conversationFilters);
    });
  },
  methods: {
    onApplyFilter(payload) {
      if (this.$route.name !== 'home') {
        this.$router.push({ name: 'home' });
      }
      this.$store.dispatch('conversationPage/reset');
      this.$store.dispatch('emptyAllConversations');
      this.fetchFilteredConversations(payload);
    },
    onToggleAdvanceFiltersModal() {
      this.showAdvancedFilters = !this.showAdvancedFilters;
    },
    getKeyboardListenerParams() {
      const allConversations = this.$refs.activeConversation.querySelectorAll(
        'div.conversations-list div.conversation'
      );
      const activeConversation = this.$refs.activeConversation.querySelector(
        'div.conversations-list div.conversation.active'
      );
      const activeConversationIndex = [...allConversations].indexOf(
        activeConversation
      );
      const lastConversationIndex = allConversations.length - 1;
      return {
        allConversations,
        activeConversation,
        activeConversationIndex,
        lastConversationIndex,
      };
    },
    handleKeyEvents(e) {
      if (hasPressedAltAndJKey(e)) {
        const {
          allConversations,
          activeConversationIndex,
        } = this.getKeyboardListenerParams();
        if (activeConversationIndex === -1) {
          allConversations[0].click();
        }
        if (activeConversationIndex >= 1) {
          allConversations[activeConversationIndex - 1].click();
        }
      }
      if (hasPressedAltAndKKey(e)) {
        const {
          allConversations,
          activeConversationIndex,
          lastConversationIndex,
        } = this.getKeyboardListenerParams();
        if (activeConversationIndex === -1) {
          allConversations[lastConversationIndex].click();
        } else if (activeConversationIndex < lastConversationIndex) {
          allConversations[activeConversationIndex + 1].click();
        }
      }
    },
    resetAndFetchData() {
      this.$store.dispatch('conversationPage/reset');
      this.$store.dispatch('emptyAllConversations');
      this.$store.dispatch('clearConversationFilters');
      this.fetchConversations();
    },
    fetchConversations() {
      this.$store
        .dispatch('fetchAllConversations', this.conversationFilters)
        .then(() => this.$emit('conversation-load'));
    },
    loadMoreConversations() {
      if (!this.hasAppliedFilters) {
        this.fetchConversations();
      } else {
        this.fetchFilteredConversations(this.appliedFilters);
      }
    },
    fetchFilteredConversations(payload) {
      let page = this.currentFiltersPage + 1;
      this.$store
        .dispatch('fetchFilteredConversations', {
          queryData: filterQueryGenerator(payload),
          page,
        })
        .then(() => this.$emit('conversation-load'));
      this.showAdvancedFilters = false;
    },
    updateAssigneeTab(selectedTab) {
      if (this.activeAssigneeTab !== selectedTab) {
        bus.$emit('clearSearchInput');
        this.activeAssigneeTab = selectedTab;
        if (!this.currentPage) {
          this.fetchConversations();
        }
      }
    },
    updateStatusType(index) {
      if (this.activeStatus !== index) {
        this.activeStatus = index;
        this.resetAndFetchData();
      }
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/woot';

.spinner {
  margin-top: var(--space-normal);
  margin-bottom: var(--space-normal);
}

.conversations-list-wrap {
  flex-shrink: 0;
  width: 34rem;

  @include breakpoint(large up) {
    width: 36rem;
  }
  @include breakpoint(xlarge up) {
    width: 35rem;
  }
  @include breakpoint(xxlarge up) {
    width: 38rem;
  }
  @include breakpoint(xxxlarge up) {
    flex-basis: 46rem;
  }
}
.filter--actions {
  display: flex;
  align-items: center;
  .btn-filter {
    cursor: pointer;
    i {
      font-size: var(--font-size-two);
    }
  }
  .btn-clear-filters {
    color: var(--r-500);
    cursor: pointer;
  }
}

.filter__applied {
  padding: var(--space-slab) 0 !important;
  border-bottom: 1px solid var(--color-border);
}
</style>
