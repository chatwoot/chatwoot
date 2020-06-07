<template>
  <div class="conversations-sidebar medium-4 columns">
    <div class="chat-list__top">
      <h1 class="page-title">
        <woot-sidemenu-icon />
        {{ inbox.name || $t('CHAT_LIST.TAB_HEADING') }}
      </h1>
      <chat-filter
        :active-status="currentStatus"
        @statusFilterChange="updateStatusType"
      />
    </div>

    <chat-type-tabs
      :items="assigneeTabItems"
      :active-tab="currentAssigneeType"
      class="tab--chat-type"
      @chatTabChange="updateAssigneeTab"
    />

    <p v-if="!chatListLoading && !conversations.length" class="content-box">
      {{ $t('CHAT_LIST.LIST.404') }}
    </p>

    <div class="conversations-list">
      <conversation-card
        v-for="chat in conversations"
        :key="chat.id"
        :chat="chat"
        :active-conversation-id="currentConversationId"
        :active-inbox-id="currentInboxId"
      />

      <div v-if="chatListLoading" class="text-center">
        <span class="spinner"></span>
      </div>

      <div
        v-if="!hasCurrentPageEndReached && !chatListLoading"
        class="clear button load-more-conversations"
        @click="fetchMoreConversations"
      >
        {{ $t('CHAT_LIST.LOAD_MORE_CONVERSATIONS') }}
      </div>

      <p
        v-if="
          conversations.length && hasCurrentPageEndReached && !chatListLoading
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
import { mapGetters } from 'vuex';

import ChatFilter from './widgets/conversation/ChatFilter';
import ChatTypeTabs from './widgets/ChatTypeTabs';
import ConversationCard from './widgets/conversation/ConversationCard';
import timeMixin from '../mixins/time';
import conversationMixin from '../mixins/conversations';

export default {
  components: {
    ChatTypeTabs,
    ConversationCard,
    ChatFilter,
  },
  mixins: [timeMixin, conversationMixin],
  props: {
    conversationInbox: {
      type: [String, Number],
      default: '',
    },
    conversations: {
      type: Array,
      default: () => [],
    },
    currentStatus: {
      type: String,
      default: '',
    },
    currentAssigneeType: {
      type: String,
      default: '',
    },
    currentConversationId: {
      type: [String, Number],
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      chatListLoading: 'isConversationListLoading',
      currentInboxId: 'conversationFilter/getCurrentInboxId',
      conversationStats: 'conversationStats/getStats',
    }),
    assigneeTabItems() {
      return this.$t('CHAT_LIST.ASSIGNEE_TYPE_TABS').map(item => ({
        key: item.KEY,
        name: item.NAME,
        count: this.conversationStats[item.COUNT_KEY] || 0,
      }));
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.currentInboxId);
    },
    hasCurrentPageEndReached() {
      return this.$store.getters['conversationPage/getHasEndReached'](
        this.currentAssigneeType
      );
    },
  },

  methods: {
    updateAssigneeTab(assigneeType) {
      if (this.currentAssigneeType !== assigneeType) {
        this.$store.dispatch(
          'conversationFilter/setActiveAssigneeType',
          assigneeType
        );
      }
    },
    updateStatusType(status) {
      if (this.currentStatus !== status) {
        this.$store.dispatch(
          'conversationFilter/setActiveConversationStatus',
          status
        );
      }
    },
    fetchMoreConversations() {
      this.$emit('fetch');
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
