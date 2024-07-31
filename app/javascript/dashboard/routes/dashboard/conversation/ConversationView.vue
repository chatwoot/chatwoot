<template>
  <section class="bg-white conversation-page dark:bg-slate-900">
    <chat-list
      :show-conversation-list="showConversationList"
      :conversation-inbox="inboxId"
      :label="label"
      :team-id="teamId"
      :conversation-type="conversationType"
      :folders-id="foldersId"
      :is-on-expanded-layout="isOnExpandedLayout"
      @conversation-load="onConversationLoad"
    >
      <pop-over-search
        :is-on-expanded-layout="isOnExpandedLayout"
        @toggle-conversation-layout="toggleConversationLayout"
      />
    </chat-list>
    <conversation-box
      v-if="showMessageView"
      :inbox-id="inboxId"
      :is-contact-panel-open="isContactPanelOpen"
      :is-on-expanded-layout="isOnExpandedLayout"
      @contact-panel-toggle="onToggleContactPanel"
    />
    <woot-modal
      :show.sync="showCustomSnoozeModal"
      :on-close="hideCustomSnoozeModal"
    >
      <custom-snooze-modal
        @close="hideCustomSnoozeModal"
        @choose-time="chooseSnoozeTime"
      />
    </woot-modal>
  </section>
</template>

<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { getUnixTime } from 'date-fns';
import ChatList from '../../../components/ChatList.vue';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox.vue';
import PopOverSearch from './search/PopOverSearch.vue';
import CustomSnoozeModal from 'dashboard/components/CustomSnoozeModal.vue';
import wootConstants from 'dashboard/constants/globals';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { CMD_SNOOZE_CONVERSATION } from 'dashboard/routes/dashboard/commands/commandBarBusEvents';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';

export default {
  components: {
    ChatList,
    ConversationBox,
    PopOverSearch,
    CustomSnoozeModal,
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
    teamId: {
      type: String,
      default: '',
    },
    conversationType: {
      type: String,
      default: '',
    },
    foldersId: {
      type: [String, Number],
      default: 0,
    },
  },
  setup() {
    const { uiSettings, updateUISettings } = useUISettings();

    return {
      uiSettings,
      updateUISettings,
    };
  },
  data() {
    return {
      showSearchModal: false,
      showCustomSnoozeModal: false,
    };
  },
  computed: {
    ...mapGetters({
      chatList: 'getAllConversations',
      currentChat: 'getSelectedChat',
      contextMenuChatId: 'getContextMenuChatId',
    }),
    showConversationList() {
      return this.isOnExpandedLayout ? !this.conversationId : true;
    },
    showMessageView() {
      return this.conversationId ? true : !this.isOnExpandedLayout;
    },
    isOnExpandedLayout() {
      const {
        LAYOUT_TYPES: { CONDENSED },
      } = wootConstants;
      const { conversation_display_type: conversationDisplayType = CONDENSED } =
        this.uiSettings;
      return conversationDisplayType !== CONDENSED;
    },
    isContactPanelOpen() {
      if (this.currentChat.id) {
        const { is_contact_sidebar_open: isContactSidebarOpen } =
          this.uiSettings;
        return isContactSidebarOpen;
      }
      return false;
    },
  },
  watch: {
    conversationId() {
      this.fetchConversationIfUnavailable();
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
    this.initialize();
    this.$watch('$store.state.route', () => this.initialize());
    this.$watch('chatList.length', () => {
      this.setActiveChat();
    });
    this.$emitter.on(CMD_SNOOZE_CONVERSATION, this.onCmdSnoozeConversation);
  },
  beforeDestroy() {
    this.$emitter.off(CMD_SNOOZE_CONVERSATION, this.onCmdSnoozeConversation);
  },

  methods: {
    onConversationLoad() {
      this.fetchConversationIfUnavailable();
    },
    initialize() {
      this.$store.dispatch('setActiveInbox', this.inboxId);
      this.setActiveChat();
    },
    toggleConversationLayout() {
      const { LAYOUT_TYPES } = wootConstants;
      const {
        conversation_display_type:
          conversationDisplayType = LAYOUT_TYPES.CONDENSED,
      } = this.uiSettings;
      const newViewType =
        conversationDisplayType === LAYOUT_TYPES.CONDENSED
          ? LAYOUT_TYPES.EXPANDED
          : LAYOUT_TYPES.CONDENSED;
      this.updateUISettings({
        conversation_display_type: newViewType,
        previously_used_conversation_display_type: newViewType,
      });
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
        const selectedConversation = this.findConversation();
        // If conversation doesn't exist or selected conversation is same as the active
        // conversation, don't set active conversation.
        if (
          !selectedConversation ||
          selectedConversation.id === this.currentChat.id
        ) {
          return;
        }
        const { messageId } = this.$route.query;
        this.$store
          .dispatch('setActiveChat', {
            data: selectedConversation,
            after: messageId,
          })
          .then(() => {
            this.$emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
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
    onCmdSnoozeConversation(snoozeType) {
      if (snoozeType === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
        this.showCustomSnoozeModal = true;
      } else {
        this.toggleStatus(
          wootConstants.STATUS_TYPE.SNOOZED,
          findSnoozeTime(snoozeType) || null
        );
      }
    },
    chooseSnoozeTime(customSnoozeTime) {
      this.showCustomSnoozeModal = false;
      if (customSnoozeTime) {
        this.toggleStatus(
          wootConstants.STATUS_TYPE.SNOOZED,
          getUnixTime(customSnoozeTime)
        );
      }
    },
    toggleStatus(status, snoozedUntil) {
      this.$store
        .dispatch('toggleStatus', {
          conversationId: this.currentChat?.id || this.contextMenuChatId,
          status,
          snoozedUntil,
        })
        .then(() => {
          this.$store.dispatch('setContextMenuChatId', null);
          useAlert(this.$t('CONVERSATION.CHANGE_STATUS'));
        });
    },
    hideCustomSnoozeModal() {
      // if we select custom snooze and the custom snooze modal is open
      // Then if the custom snooze modal is closed then set the context menu chat id to null
      this.$store.dispatch('setContextMenuChatId', null);
      this.showCustomSnoozeModal = false;
    },
  },
};
</script>
<style lang="scss" scoped>
.conversation-page {
  display: flex;
  width: 100%;
  height: 100%;
}
</style>
