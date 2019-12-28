<template>
  <div class="conversations-sidebar  medium-4 columns">
    <div class="chat-list__top">
      <h1 class="page-title">
        <woot-sidemenu-icon />
        {{ inbox.name || pageTitle }}
      </h1>
      <chat-filter @statusFilterChange="getDataForStatusTab" />
    </div>

    <chat-type-tabs
      :items="assigneeTabItems"
      :active-tab-index="activeAssigneeTab"
      class="tab--chat-type"
      @chatTabChange="getDataForTab"
    />

    <p
      v-if="!chatListLoading && !getChatsForTab(activeStatus).length"
      class="content-box"
    >
      {{ $t('CHAT_LIST.LIST.404') }}
    </p>

    <div v-if="chatListLoading" class="text-center">
      <span class="spinner message"></span>
    </div>

    <transition-group
      name="conversations-list"
      tag="div"
      class="conversations-list"
    >
      <conversation-card
        v-for="chat in getChatsForTab(activeStatus)"
        :key="chat.id"
        :chat="chat"
      />
    </transition-group>
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
import wootConstants from '../constants';

export default {
  components: {
    ChatTypeTabs,
    ConversationCard,
    ChatFilter,
  },
  mixins: [timeMixin, conversationMixin],
  props: ['conversationInbox', 'pageTitle'],
  data() {
    return {
      activeAssigneeTab: 0,
      activeStatus: 0,
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
      convStats: 'getConvTabStats',
    }),
    assigneeTabItems() {
      return this.$t('CHAT_LIST.ASSIGNEE_TYPE_TABS').map((item, index) => ({
        id: index,
        name: item.NAME,
        count: this.convStats[item.KEY] || 0,
      }));
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.activeInbox);
    },
    getToggleStatus() {
      if (this.toggleType) {
        return 'Open';
      }
      return 'Resolved';
    },
  },
  mounted() {
    this.$watch('$store.state.route', () => {
      if (this.$store.state.route.name !== 'inbox_conversation') {
        this.$store.dispatch('emptyAllConversations');
        this.fetchData();
      }
    });

    this.$store.dispatch('emptyAllConversations');
    this.fetchData();
    this.$store.dispatch('agents/get');
  },
  methods: {
    fetchData() {
      if (this.chatLists.length === 0) {
        this.fetchConversations();
      }
    },
    fetchConversations() {
      this.$store.dispatch('fetchAllConversations', {
        inboxId: this.conversationInbox ? this.conversationInbox : undefined,
        assigneeType: this.activeAssigneeTab,
        status: this.activeStatus ? 'resolved' : 'open',
      });
    },
    getDataForTab(index) {
      if (this.activeAssigneeTab !== index) {
        this.activeAssigneeTab = index;
        this.fetchConversations();
      }
    },
    getDataForStatusTab(index) {
      if (this.activeStatus !== index) {
        this.activeStatus = index;
        this.fetchConversations();
      }
    },
    getChatsForTab() {
      let copyList = [];
      if (this.activeAssigneeTab === wootConstants.ASSIGNEE_TYPE_SLUG.MINE) {
        copyList = this.mineChatsList.slice();
      } else if (
        this.activeAssigneeTab === wootConstants.ASSIGNEE_TYPE_SLUG.UNASSIGNED
      ) {
        copyList = this.unAssignedChatsList.slice();
      } else {
        copyList = this.allChatList.slice();
      }
      const sorted = copyList.sort(
        (a, b) =>
          this.lastMessage(b).created_at - this.lastMessage(a).created_at
      );
      return sorted;
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
