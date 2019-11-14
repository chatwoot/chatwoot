<template>
  <div :class="conversationClass">
    <div v-if="currentChat.id !== null" class="view-box columns">
      <conversation-header
        :chat="currentChat"
        :is-contact-panel-open="isContactPanelOpen"
        @contactPanelToggle="onToggleContactPanel"
      />
      <ul class="conversation-panel">
        <transition name="slide-up">
          <li>
            <span v-if="shouldShowSpinner" class="spinner message" />
          </li>
        </transition>
        <conversation
          v-for="message in getReadMessages"
          :key="message.id"
          :data="message"
        />
        <li v-show="getUnreadCount != 0" class="unread--toast">
          <span>
            {{ getUnreadCount }} UNREAD MESSAGE{{
              getUnreadCount > 1 ? 'S' : ''
            }}
          </span>
        </li>
        <conversation
          v-for="message in getUnReadMessages"
          :key="message.id"
          :data="message"
        />
      </ul>
      <ReplyBox
        :conversation-id="currentChat.id"
        @scrollToMessage="focusLastMessage"
      />
    </div>
    <!-- No Conversation Selected -->
    <div v-else class="columns full-height conv-empty-state">
      <!-- Loading status -->
      <woot-loading-state
        v-if="fetchingInboxes || loadingChatList"
        :message="loadingIndicatorMessage"
      />
      <!-- Show empty state images if not loading -->
      <div v-if="!fetchingInboxes && !loadingChatList" class="current-chat">
        <!-- No inboxes attached -->
        <div v-if="!inboxesList.length">
          <img src="~dashboard/assets/images/inboxes.svg" alt="No Inboxes" />
          <span v-if="isAdmin()">
            {{ $t('CONVERSATION.NO_INBOX_1') }}
            <br />
            <router-link :to="newInboxURL">
              {{ $t('CONVERSATION.CLICK_HERE') }}
            </router-link>
            {{ $t('CONVERSATION.NO_INBOX_2') }}
          </span>
          <span v-if="!isAdmin()">
            {{ $t('CONVERSATION.NO_INBOX_AGENT') }}
          </span>
        </div>
        <!-- No conversations available -->
        <div v-else-if="!allConversations.length">
          <img src="~dashboard/assets/images/chat.svg" alt="No Chat" />
          <span>
            {{ $t('CONVERSATION.NO_MESSAGE_1') }}
            <br />
            <a :href="linkToMessage" target="_blank">
              {{ $t('CONVERSATION.CLICK_HERE') }}
            </a>
            {{ $t('CONVERSATION.NO_MESSAGE_2') }}
          </span>
        </div>
        <!-- No conversation selected -->
        <div v-else-if="allConversations.length && currentChat.id === null">
          <img src="~dashboard/assets/images/chat.svg" alt="No Chat" />
          <span>{{ $t('CONVERSATION.404') }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* eslint no-console: 0 */
/* eslint no-extra-boolean-cast: 0 */
/* global bus */
import { mapGetters } from 'vuex';

import ConversationHeader from './ConversationHeader';
import ReplyBox from './ReplyBox';
import Conversation from './Conversation';
import conversationMixin from '../../../mixins/conversations';
import adminMixin from '../../../mixins/isAdmin';
import { frontendURL } from '../../../helper/URLHelper';

export default {
  components: {
    ConversationHeader,
    Conversation,
    ReplyBox,
  },

  mixins: [conversationMixin, adminMixin],

  props: {
    inboxId: {
      type: [Number, String],
      required: true,
    },
    isContactPanelOpen: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      isLoadingPrevious: true,
      heightBeforeLoad: null,
      conversationPanel: null,
    };
  },

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      allConversations: 'getAllConversations',
      inboxesList: 'getInboxesList',
      listLoadingStatus: 'getAllMessagesLoaded',
      getUnreadCount: 'getUnreadCount',
      fetchingInboxes: 'getInboxLoadingStatus',
      loadingChatList: 'getChatListLoadingStatus',
    }),
    conversationClass() {
      return `medium-${
        this.isContactPanelOpen ? '5' : '8'
      } columns conversation-wrap`;
    },
    // Loading indicator
    // Returns corresponding loading message
    loadingIndicatorMessage() {
      if (this.fetchingInboxes) {
        return this.$t('CONVERSATION.LOADING_INBOXES');
      }
      return this.$t('CONVERSATION.LOADING_CONVERSATIONS');
    },
    getMessages() {
      const [chat] = this.allConversations.filter(
        c => c.id === this.currentChat.id
      );
      return chat;
    },
    // Get current FB Page ID
    getPageId() {
      let stateInbox;
      if (this.inboxId) {
        const inboxId = Number(this.inboxId);
        [stateInbox] = this.inboxesList.filter(
          inbox => inbox.channel_id === inboxId
        );
      } else {
        [stateInbox] = this.inboxesList;
      }
      return !stateInbox ? 0 : stateInbox.pageId;
    },
    // Get current FB Page ID link
    linkToMessage() {
      return `https://m.me/${this.getPageId}`;
    },
    getReadMessages() {
      const chat = this.getMessages;
      return chat === undefined ? null : this.readMessages(chat);
    },
    getUnReadMessages() {
      const chat = this.getMessages;
      return chat === undefined ? null : this.unReadMessages(chat);
    },
    shouldShowSpinner() {
      return (
        this.getMessages.dataFetched === undefined ||
        (!this.listLoadingStatus && this.isLoadingPrevious)
      );
    },

    newInboxURL() {
      return frontendURL('settings/inboxes/new');
    },

    shouldLoadMoreChats() {
      return !this.listLoadingStatus && !this.isLoadingPrevious;
    },
  },

  created() {
    bus.$on('scrollToMessage', () => {
      this.focusLastMessage();
      this.makeMessagesRead();
    });
  },

  methods: {
    focusLastMessage() {
      setTimeout(() => {
        this.attachListner();
      }, 0);
    },

    onToggleContactPanel() {
      this.$emit('contactPanelToggle');
    },

    attachListner() {
      this.conversationPanel = this.$el.querySelector('.conversation-panel');
      this.heightBeforeLoad =
        this.getUnreadCount === 0
          ? this.conversationPanel.scrollHeight
          : this.$el.querySelector('.conversation-panel .unread--toast')
              .offsetTop - 56;
      this.conversationPanel.scrollTop = this.heightBeforeLoad;
      this.conversationPanel.addEventListener('scroll', this.handleScroll);
      this.isLoadingPrevious = false;
    },

    handleScroll(e) {
      const dataFetchCheck =
        this.getMessages.dataFetched === true && this.shouldLoadMoreChats;
      if (
        e.target.scrollTop < 100 &&
        !this.isLoadingPrevious &&
        dataFetchCheck
      ) {
        this.isLoadingPrevious = true;
        this.$store
          .dispatch('fetchPreviousMessages', {
            conversationId: this.currentChat.id,
            before: this.getMessages.messages[0].id,
          })
          .then(() => {
            this.conversationPanel.scrollTop =
              this.conversationPanel.scrollHeight -
              (this.heightBeforeLoad - this.conversationPanel.scrollTop);
            this.isLoadingPrevious = false;
            this.heightBeforeLoad =
              this.getUnreadCount === 0
                ? this.conversationPanel.scrollHeight
                : this.$el.querySelector('.conversation-panel .unread--toast')
                    .offsetTop - 56;
          });
      }
    },

    makeMessagesRead() {
      if (this.getUnreadCount !== 0 && this.getMessages !== undefined) {
        this.$store.dispatch('markMessagesRead', {
          id: this.currentChat.id,
          lastSeen: this.getMessages.messages.last().created_at,
        });
      }
    },
  },
};
</script>
