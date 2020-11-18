<template>
  <section class="app-content columns">
    <chat-list
      :conversation-inbox="inboxId"
      :label="label"
      @conversation-load="onConversationLoad"
    >
      <button class="search--button" @click="onSearch">
        <i class="ion-ios-search-strong search--icon" />
        <div class="text-truncate">
          {{ $t('CONVERSATION.SEARCH_MESSAGES') }}
        </div>
      </button>
      <search
        v-if="showSearchModal"
        :show="showSearchModal"
        :on-close="closeSearch"
      />
    </chat-list>
    <conversation-box
      :inbox-id="inboxId"
      :is-contact-panel-open="isContactPanelOpen"
      @contact-panel-toggle="onToggleContactPanel"
    >
    </conversation-box>
    <contact-panel
      v-if="isContactPanelOpen"
      :conversation-id="conversationId"
      :on-toggle="onToggleContactPanel"
    />
  </section>
</template>

<script>
import { mapGetters } from 'vuex';

import ChatList from '../../../components/ChatList';
import ContactPanel from './ContactPanel';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox';
import Search from './search/Search.vue';

export default {
  components: {
    ChatList,
    ContactPanel,
    ConversationBox,
    Search,
  },
  props: {
    inboxId: {
      type: [String, Number],
      default: 0,
    },
    conversationId: {
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
      panelToggleState: true,
      showSearchModal: false,
    };
  },
  computed: {
    ...mapGetters({
      chatList: 'getAllConversations',
      currentChat: 'getSelectedChat',
    }),
    isContactPanelOpen: {
      get() {
        if (this.currentChat.id) {
          return this.panelToggleState;
        }
        return false;
      },
      set(val) {
        this.panelToggleState = val;
      },
    },
  },

  mounted() {
    this.$store.dispatch('agents/get');
    this.initialize();
    this.$watch('$store.state.route', () => this.initialize());
    this.$watch('chatList.length', () => {
      this.setActiveChat();
    });
  },

  methods: {
    onConversationLoad() {
      this.fetchConversationIfUnavailable();
    },
    initialize() {
      this.$store.dispatch('setActiveInbox', this.inboxId);
      this.setActiveChat();
    },

    fetchConversationIfUnavailable() {
      if (!this.conversationId) {
        return;
      }
      const chat = this.findConversation();
      if (!chat) {
        this.$store.dispatch('getConversation', this.conversationId);
      }
    },
    findConversation() {
      const conversationId = parseInt(this.conversationId, 10);
      const [chat] = this.chatList.filter(c => c.id === conversationId);
      return chat;
    },

    setActiveChat() {
      if (this.conversationId) {
        const chat = this.findConversation();
        if (!chat) {
          return;
        }
        this.$store.dispatch('setActiveChat', chat).then(() => {
          bus.$emit('scrollToMessage');
        });
      } else {
        this.$store.dispatch('clearSelectedState');
      }
    },
    onToggleContactPanel() {
      this.isContactPanelOpen = !this.isContactPanelOpen;
    },
    onSearch() {
      this.showSearchModal = true;
    },
    closeSearch() {
      this.showSearchModal = false;
    },
  },
};
</script>
<style scoped>
.search--button {
  align-items: center;
  border: 0;
  color: var(--s-400);
  cursor: pointer;
  display: flex;
  font-size: var(--font-size-small);
  font-weight: 400;
  padding: var(--space-normal);
  text-align: left;
  line-height: var(--font-size-large);
}

.search--icon {
  color: var(--s-600);
  font-size: var(--font-size-large);
  padding-right: var(--space-small);
}
</style>
