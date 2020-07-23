<template>
  <div class="columns full-height conv-empty-state">
    <woot-loading-state
      v-if="uiFlags.isFetching || loadingChatList"
      :message="loadingIndicatorMessage"
    />
    <!-- Show empty state images if not loading -->
    <div v-if="!uiFlags.isFetching && !loadingChatList" class="current-chat">
      <!-- No inboxes attached -->
      <div v-if="!inboxesList.length">
        <img src="~dashboard/assets/images/inboxes.svg" alt="No Inboxes" />
        <span v-if="isAdmin">
          {{ $t('CONVERSATION.NO_INBOX_1') }}
          <br />
          <router-link :to="newInboxURL">
            {{ $t('CONVERSATION.CLICK_HERE') }}
          </router-link>
          {{ $t('CONVERSATION.NO_INBOX_2') }}
        </span>
        <span v-if="!isAdmin">
          {{ $t('CONVERSATION.NO_INBOX_AGENT') }}
        </span>
      </div>
      <!-- No conversations available -->
      <div v-else-if="!allConversations.length">
        <img src="~dashboard/assets/images/chat.svg" alt="No Chat" />
        <span>
          {{ $t('CONVERSATION.NO_MESSAGE_1') }}
          <br />
        </span>
      </div>
      <!-- No conversation selected -->
      <div v-else-if="allConversations.length && !currentChat.id">
        <img src="~dashboard/assets/images/chat.svg" alt="No Chat" />
        <span>{{ $t('CONVERSATION.404') }}</span>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import adminMixin from '../../../mixins/isAdmin';
import accountMixin from '../../../mixins/account';

export default {
  mixins: [accountMixin, adminMixin],

  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      allConversations: 'getAllConversations',
      inboxesList: 'inboxes/getInboxes',
      uiFlags: 'inboxes/getUIFlags',
      loadingChatList: 'getChatListLoadingStatus',
    }),
    loadingIndicatorMessage() {
      if (this.uiFlags.isFetching) {
        return this.$t('CONVERSATION.LOADING_INBOXES');
      }
      return this.$t('CONVERSATION.LOADING_CONVERSATIONS');
    },
    newInboxURL() {
      return this.addAccountScoping('settings/inboxes/new');
    },
  },
};
</script>
