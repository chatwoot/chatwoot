<template>
  <section class="conversation-page">
    <chat-list
      :conversation-inbox="inboxId"
      :label="label"
      :active-team="activeTeam"
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
  </section>
</template>

<script>
import { mapGetters } from 'vuex';

import ChatList from '../../../components/ChatList';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox';
import Search from './search/Search.vue';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

export default {
  components: {
    ChatList,
    ConversationBox,
    Search,
  },
  mixins: [uiSettingsMixin],
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
    teamId: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      showSearchModal: false,
    };
  },
  computed: {
    ...mapGetters({
      chatList: 'getAllConversations',
      currentChat: 'getSelectedChat',
    }),
    isContactPanelOpen() {
      if (this.currentChat.id) {
        const {
          is_contact_sidebar_open: isContactSidebarOpen,
        } = this.uiSettings;
        return isContactSidebarOpen;
      }
      return false;
    },
    activeTeam() {
      if (this.teamId) {
        return this.$store.getters['teams/getTeam'](this.teamId);
      }
      return {};
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
      this.updateUISettings({
        is_contact_sidebar_open: !this.isContactPanelOpen,
      });
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
<style lang="scss" scoped>
.search--button {
  align-items: center;
  border: 0;
  color: var(--s-400);
  cursor: pointer;
  display: flex;
  font-size: var(--font-size-small);
  font-weight: 400;
  padding: var(--space-normal) var(--space-normal) var(--space-slab);
  text-align: left;
  line-height: var(--font-size-large);

  &:hover {
    .search--icon {
      color: var(--w-500);
    }
  }
}

.search--icon {
  color: var(--s-600);
  font-size: var(--font-size-large);
  padding-right: var(--space-small);
}

.conversation-page {
  display: flex;
  width: 100%;
  height: 100%;
}
</style>
