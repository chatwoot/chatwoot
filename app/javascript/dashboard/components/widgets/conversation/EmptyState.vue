<template>
  <div :class="emptyClassName">
    <woot-loading-state
      v-if="uiFlags.isFetching || loadingChatList"
      :message="loadingIndicatorMessage"
    />
    <!-- No inboxes attached -->
    <div
      v-if="!inboxesList.length && !uiFlags.isFetching && !loadingChatList"
      class="clearfix"
    >
      <onboarding-view v-if="isAdmin" />
      <div v-else class="flex flex-col items-center justify-center h-full">
        <div class="flex flex-col items-center justify-center h-full">
          <img
            class="m-4 w-[6.25rem]"
            src="~dashboard/assets/images/inboxes.svg"
            alt="No Inboxes"
          />
          <span
            class="text-sm text-slate-800 dark:text-slate-200 font-medium text-center"
          >
            {{ $t('CONVERSATION.NO_INBOX_AGENT') }}
          </span>
        </div>
      </div>
    </div>
    <!-- Show empty state images if not loading -->
    <div
      v-else-if="!uiFlags.isFetching && !loadingChatList"
      class="flex flex-col items-center justify-center h-full"
    >
      <!-- No conversations available -->
      <div
        v-if="!allConversations.length"
        class="flex flex-col items-center justify-center h-full"
      >
        <img
          class="m-4 w-[6.25rem]"
          src="~dashboard/assets/images/chat.svg"
          alt="No Chat"
        />
        <span
          class="text-sm text-slate-800 dark:text-slate-200 font-medium text-center"
        >
          {{ $t('CONVERSATION.NO_MESSAGE_1') }}
          <br />
        </span>
      </div>
      <!-- No conversation selected -->
      <div
        v-else-if="allConversations.length && !currentChat.id"
        class="flex flex-col items-center justify-center h-full"
      >
        <img
          class="m-4 w-28"
          src="~dashboard/assets/images/no-chat.svg"
          alt="No Chat"
        />
        <span
          class="text-sm text-slate-800 dark:text-slate-200 font-medium text-center"
        >
          {{ conversationMissingMessage }}
        </span>
        <!-- Cmd bar, keyboard shortcuts, and more -->
        <div class="flex flex-col gap-2 mt-9">
          <div
            v-for="keyShortcut in keyShortcuts"
            :key="keyShortcut.key"
            class="flex gap-2 items-center"
          >
            <div class="flex gap-2 items-center">
              <hotkey
                custom-class="h-6 w-8 text-sm font-medium text-slate-700 dark:text-slate-100 bg-slate-100 dark:bg-slate-700 border-b-2 border-slate-300 dark:border-slate-500"
              >
                ⌘
              </hotkey>
              <hotkey
                custom-class="h-6 w-8 text-sm font-medium text-slate-700 dark:text-slate-100 bg-slate-100 dark:bg-slate-700 border-b-2 border-slate-300 dark:border-slate-500"
              >
                {{ keyShortcut.key }}
              </hotkey>
            </div>
            <span
              class="text-sm text-slate-700 dark:text-slate-300 font-medium text-center"
            >
              {{ keyShortcut.description }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import adminMixin from '../../../mixins/isAdmin';
import accountMixin from '../../../mixins/account';
import OnboardingView from './OnboardingView';
import Hotkey from 'dashboard/components/base/Hotkey';

export default {
  components: {
    OnboardingView,
    Hotkey,
  },
  mixins: [accountMixin, adminMixin],
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      keyShortcuts: [
        {
          key: 'K',
          description: this.$t('CONVERSATION.EMPTY_STATE.CMD_BAR'),
        },
        {
          key: '/',
          description: this.$t('CONVERSATION.EMPTY_STATE.KEYBOARD_SHORTCUTS'),
        },
      ],
    };
  },
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
    conversationMissingMessage() {
      if (!this.isOnExpandedLayout) {
        return this.$t('CONVERSATION.SELECT_A_CONVERSATION');
      }
      return this.$t('CONVERSATION.404');
    },
    newInboxURL() {
      return this.addAccountScoping('settings/inboxes/new');
    },
    emptyClassName() {
      if (
        !this.inboxesList.length &&
        !this.uiFlags.isFetching &&
        !this.loadingChatList &&
        this.isAdmin
      ) {
        return 'h-full overflow-auto';
      }
      return 'flex-1 min-w-0 px-0 flex flex-col items-center justify-center h-full';
    },
  },
};
</script>
