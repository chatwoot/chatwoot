<template>
  <section class="app-content columns">
    <chat-list
      :conversations="conversations"
      :conversation-inbox="inboxId"
      :current-conversation-id="conversationId"
      :current-assignee-type="currentAssigneeType"
      :current-status="currentStatus"
      @fetch="fetchConversations"
    />
    <conversation-box
      :inbox-id="inboxId"
      :is-contact-panel-open="isContactPanelOpen"
      @contactPanelToggle="onToggleContactPanel"
    />
    <contact-panel
      v-if="isContactPanelOpen"
      :conversation-id="conversationId"
      :on-toggle="onToggleContactPanel"
    />
  </section>
</template>

<script>
/* eslint no-console: 0 */
import { mapGetters } from 'vuex';

import ChatList from '../../../components/ChatList';
import ContactPanel from './ContactPanel';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox';

export default {
  components: {
    ChatList,
    ContactPanel,
    ConversationBox,
  },
  props: {
    inboxId: {
      type: [String, Number],
      default: '',
    },
    conversationId: {
      type: [String, Number],
      default: '',
    },
  },
  data() {
    return {
      panelToggleState: false,
    };
  },
  computed: {
    ...mapGetters({
      conversations: 'getCurrentAssigneeConversations',
      currentAssigneeType: 'conversationFilter/getCurrentAssigneeType',
      currentStatus: 'conversationFilter/getCurrentConversationStatus',
    }),
    currentConversation() {
      return this.$store.getters.getConversation(this.conversationId);
    },
    isContactPanelOpen: {
      get() {
        if (this.conversationId) {
          return this.panelToggleState;
        }
        return false;
      },
      set(val) {
        this.panelToggleState = val;
      },
    },

    currentPage() {
      return this.$store.getters['conversationPage/getCurrentPage'](
        this.currentAssigneeType
      );
    },
  },
  watch: {
    inboxId() {
      this.resetAndFetchData();
    },
    currentStatus() {
      this.resetAndFetchData();
    },
    currentAssigneeType() {
      this.fetchConversations();
    },
  },

  mounted() {
    this.$store.dispatch('agents/get');
    this.reInitialize();
    this.resetAndFetchData();
    this.fetchConversation();
    this.$watch('$store.state.route', () => this.reInitialize());
    this.$watch('conversations.length', () => {
      this.fetchConversation();
      this.setActiveChat();
    });
  },

  methods: {
    reInitialize() {
      this.setActiveChat();
      this.setActiveInbox();
    },
    setActiveInbox() {
      this.$store.dispatch('conversationFilter/setActiveInbox', this.inboxId);
    },
    resetAndFetchData() {
      this.$store.dispatch('conversationPage/reset');
      this.$store.dispatch('messages/resetMessages');
      this.$store.dispatch('resetConversations');
      this.fetchConversations();
    },
    fetchConversation() {
      if (!this.conversationId) {
        return;
      }
      if (!this.currentConversation.id) {
        this.$store.dispatch('fetchConversation', this.conversationId);
      }
    },
    fetchConversations() {
      this.$store.dispatch('fetchAllConversations', {
        inboxId: this.inboxId ? this.inboxId : undefined,
        assigneeType: this.currentAssigneeType,
        status: this.currentStatus,
        page: this.currentPage + 1,
      });
    },
    setActiveChat() {
      this.$store.dispatch(
        'conversationFilter/setActiveConversation',
        this.conversationId
      );
    },
    onToggleContactPanel() {
      this.isContactPanelOpen = !this.isContactPanelOpen;
    },
  },
};
</script>
