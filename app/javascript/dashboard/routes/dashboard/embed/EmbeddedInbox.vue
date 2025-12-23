<script>
import { mapGetters } from 'vuex';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAccount } from 'dashboard/composables/useAccount';
import ChatList from '../../../components/ChatList.vue';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox.vue';
import wootConstants from 'dashboard/constants/globals';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import CmdBarConversationSnooze from 'dashboard/routes/dashboard/commands/CmdBarConversationSnooze.vue';
import { emitter } from 'shared/helpers/mitt';
import SidepanelSwitch from 'dashboard/components-next/Conversation/SidepanelSwitch.vue';
import ConversationSidebar from 'dashboard/components/widgets/conversation/ConversationSidebar.vue';

export default {
  name: 'EmbeddedInbox',
  components: {
    ChatList,
    ConversationBox,
    CmdBarConversationSnooze,
    SidepanelSwitch,
    ConversationSidebar,
  },
  beforeRouteLeave(to, from, next) {
    if (this.conversationId) {
      this.$store.dispatch('clearSelectedState');
    }
    next();
  },
  props: {
    inboxId: {
      type: [String, Number],
      default: null,
    },
  },
  setup() {
    const { uiSettings } = useUISettings();
    const { accountId } = useAccount();
    return { uiSettings, accountId };
  },
  data() {
    return {
      showMessageView: false,
      showConversationList: true,
      isOnExpandedLayout: false,
      shouldShowSidebar: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      inboxes: 'inboxes/getInboxes',
    }),
    conversationId() {
      return this.currentChat?.id || 0;
    },
    resolvedInboxId() {
      // Use inbox_id from query params if available, otherwise use prop
      const queryInboxId = this.$route.query.inbox_id;
      if (queryInboxId) {
        return parseInt(queryInboxId, 10);
      }
      return this.inboxId ? parseInt(this.inboxId, 10) : 0;
    },
  },
  watch: {
    currentChat: {
      handler(newChat) {
        this.showMessageView = !!newChat?.id;
      },
      immediate: true,
    },
    resolvedInboxId: {
      handler(newInboxId) {
        if (newInboxId && newInboxId > 0) {
          // Filter to specific inbox if provided
          this.$store.dispatch('inboxes/get', this.accountId);
        }
      },
      immediate: true,
    },
  },
  mounted() {
    emitter.on(BUS_EVENTS.TOGGLE_SIDEBAR, this.toggleSidebar);
    if (this.accountId) {
      this.$store.dispatch('inboxes/get', this.accountId);
    }
  },
  beforeUnmount() {
    emitter.off(BUS_EVENTS.TOGGLE_SIDEBAR, this.toggleSidebar);
  },
  methods: {
    onConversationLoad(conversation) {
      this.showMessageView = !!conversation?.id;
    },
    toggleSidebar() {
      this.shouldShowSidebar = !this.shouldShowSidebar;
    },
  },
};
</script>

<template>
  <section class="flex w-full h-full min-w-0">
    <ChatList
      :show-conversation-list="showConversationList"
      :conversation-inbox="resolvedInboxId"
      :is-on-expanded-layout="isOnExpandedLayout"
      @conversation-load="onConversationLoad"
    />
    <ConversationBox
      v-if="showMessageView"
      :inbox-id="resolvedInboxId"
      :is-on-expanded-layout="isOnExpandedLayout"
    >
      <SidepanelSwitch v-if="currentChat.id" />
    </ConversationBox>
    <ConversationSidebar v-if="shouldShowSidebar" :current-chat="currentChat" />
    <CmdBarConversationSnooze />
  </section>
</template>

