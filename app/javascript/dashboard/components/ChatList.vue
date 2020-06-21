<template>
  <div class="conversations-sidebar  medium-4 columns">
    <div class="chat-list__top">
      <h1 class="page-title">
        <woot-sidemenu-icon />
        {{ inbox.name || $t('CHAT_LIST.TAB_HEADING') }}
      </h1>
      <chat-filter @statusFilterChange="updateStatusType" />
    </div>

    <chat-type-tabs
      :items="assigneeTabItems"
      :active-tab="activeAssigneeTab"
      class="tab--chat-type"
      @chatTabChange="updateAssigneeTab"
    />

    <p v-if="!chatListLoading && !getChatsForTab().length" class="content-box">
      {{ $t('CHAT_LIST.LIST.404') }}
    </p>

    <div class="conversations-list">
      <conversation-card
        v-for="chat in getChatsForTab()"
        :key="chat.id"
        :chat="chat"
      />

      <div v-if="chatListLoading" class="text-center">
        <span class="spinner"></span>
      </div>

      <div
        v-if="!hasCurrentPageEndReached && !chatListLoading"
        class="clear button load-more-conversations"
        @click="fetchConversations"
      >
        {{ $t('CHAT_LIST.LOAD_MORE_CONVERSATIONS') }}
      </div>

      <p
        v-if="
          getChatsForTab().length &&
            hasCurrentPageEndReached &&
            !chatListLoading
        "
        class="text-center text-muted end-of-list-text"
      >
        {{ $t('CHAT_LIST.EOF') }}
      </p>
    </div>
  </div>
</template>

<script>
/* eslint-env browser */
/* eslint no-console: 0 */
/* global bus */
import { mapGetters } from 'vuex';

import ChatFilter from './widgets/conversation/ChatFilter';
import ChatTypeTabs from './widgets/ChatTypeTabs';
import ConversationCard from './widgets/conversation/ConversationCard';
import timeMixin from '../mixins/time';
import conversationMixin from '../mixins/conversations';
import wootConstants from '../constants';

export default {
  components: {
    ChatTypeTabs,
    ConversationCard,
    ChatFilter,
  },
  mixins: [timeMixin, conversationMixin],
  props: ['conversationInbox'],
  data() {
    return {
      activeAssigneeTab: wootConstants.ASSIGNEE_TYPE.ME,
      activeStatus: wootConstants.STATUS_TYPE.OPEN,
    };
  },
  computed: {
    ...mapGetters({
      chatLists: 'getAllConversations',
      mineChatsList: 'getMineChats',
      allChatList: 'getAllStatusChats',
      unAssignedChatsList: 'getUnAssignedChats',
      chatListLoading: 'getChatListLoadingStatus',
      currentUserID: 'getCurrentUserID',
      activeInbox: 'getSelectedInbox',
      conversationStats: 'conversationStats/getStats',
    }),
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
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.activeInbox);
    },
    currentPage() {
      return this.$store.getters['conversationPage/getCurrentPage'](
        this.activeAssigneeTab
      );
    },
    hasCurrentPageEndReached() {
      return this.$store.getters['conversationPage/getHasEndReached'](
        this.activeAssigneeTab
      );
    },
    conversationFilters() {
      return {
        inboxId: this.conversationInbox ? this.conversationInbox : undefined,
        assigneeType: this.activeAssigneeTab,
        status: this.activeStatus,
        page: this.currentPage + 1,
      };
    },
  },
  watch: {
    conversationInbox() {
      this.resetAndFetchData();
    },
  },
  mounted() {
    this.$store.dispatch('setChatFilter', this.activeStatus);
    this.resetAndFetchData();
    this.$store.dispatch('agents/get');

    bus.$on('fetch_conversation_stats', () => {
      this.$store.dispatch('conversationStats/get', this.conversationFilters);
    });
  },
  methods: {
    resetAndFetchData() {
      this.$store.dispatch('conversationPage/reset');
      this.$store.dispatch('emptyAllConversations');
      this.fetchConversations();
    },
    fetchConversations() {
      this.$store.dispatch('fetchAllConversations', this.conversationFilters);
    },
    updateAssigneeTab(selectedTab) {
      if (this.activeAssigneeTab !== selectedTab) {
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
    getChatsForTab() {
      let copyList = [];
      if (this.activeAssigneeTab === 'me') {
        copyList = this.mineChatsList.slice();
      } else if (this.activeAssigneeTab === 'unassigned') {
        copyList = this.unAssignedChatsList.slice();
      } else {
        copyList = this.allChatList.slice();
      }
      return copyList;
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';
.spinner {
  margin-top: $space-normal;
  margin-bottom: $space-normal;
}
</style>
