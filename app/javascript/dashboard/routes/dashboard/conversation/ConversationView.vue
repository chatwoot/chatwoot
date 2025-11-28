<script setup>
import { computed, watch, onMounted, onBeforeMount } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { onBeforeRouteLeave } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import ChatList from 'dashboard/components/ChatList.vue';
import ConversationBox from 'dashboard/components/widgets/conversation/ConversationBox.vue';
import wootConstants from 'dashboard/constants/globals';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import CmdBarConversationSnooze from 'dashboard/routes/dashboard/commands/CmdBarConversationSnooze.vue';
import { emitter } from 'shared/helpers/mitt';
import SidepanelSwitch from 'dashboard/components-next/Conversation/SidepanelSwitch.vue';
import ConversationSidebar from 'dashboard/components/widgets/conversation/ConversationSidebar.vue';

const props = defineProps({
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
});

const route = useRoute();
const store = useStore();
const { uiSettings } = useUISettings();

const chatList = useMapGetter('getAllConversations');
const currentChat = useMapGetter('getSelectedChat');

const isOnExpandedLayout = computed(() => {
  const {
    LAYOUT_TYPES: { CONDENSED },
  } = wootConstants;
  const { conversation_display_type: conversationDisplayType = CONDENSED } =
    uiSettings.value;
  return conversationDisplayType !== CONDENSED;
});

const showConversationList = computed(() =>
  isOnExpandedLayout.value ? !props.conversationId : true
);

const showMessageView = computed(() =>
  props.conversationId ? true : !isOnExpandedLayout.value
);

const shouldShowSidebar = computed(() => {
  if (!currentChat.value.id) {
    return false;
  }

  const { is_contact_sidebar_open: isContactSidebarOpen } = uiSettings.value;
  return isContactSidebarOpen;
});

const findConversation = () => {
  const conversationId = parseInt(props.conversationId, 10);
  const [chat] = chatList.value.filter(c => c.id === conversationId);
  return chat;
};

const fetchConversationIfUnavailable = () => {
  if (!props.conversationId) {
    return;
  }
  const chat = findConversation();
  if (!chat) {
    store.dispatch('getConversation', props.conversationId);
  }
};

const setActiveChat = () => {
  if (props.conversationId) {
    const selectedConversation = findConversation();
    // If conversation doesn't exist or selected conversation is same as the active
    // conversation, don't set active conversation.
    if (
      !selectedConversation ||
      selectedConversation.id === currentChat.value.id
    ) {
      return;
    }
    const { messageId } = route.query;
    store
      .dispatch('setActiveChat', {
        data: selectedConversation,
        after: messageId,
      })
      .then(() => {
        emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
      });
  } else {
    store.dispatch('clearSelectedState');
  }
};

const initialize = () => {
  store.dispatch('setActiveInbox', props.inboxId);
  setActiveChat();
};

const onConversationLoad = () => {
  fetchConversationIfUnavailable();
};

onBeforeRouteLeave((to, from, next) => {
  // Clear selected state if navigating away from a conversation to a route without a conversationId to prevent stale data issues
  // and resolves timing issues during navigation with conversation view and other screens
  if (props.conversationId) {
    store.dispatch('clearSelectedState');
  }
  next(); // Continue with navigation
});

watch(() => props.conversationId, fetchConversationIfUnavailable);
watch(() => store.state.route, initialize);
watch(() => chatList.value.length, setActiveChat);

onBeforeMount(() => {
  // Clear selected state early if no conversation is selected
  // This prevents child components from accessing stale data
  // and resolves timing issues during navigation
  // with conversation view and other screens
  if (!props.conversationId) {
    store.dispatch('clearSelectedState');
  }
});

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('portals/index');
  initialize();
});
</script>

<template>
  <section class="flex w-full h-full min-w-0">
    <ChatList
      :show-conversation-list="showConversationList"
      :conversation-inbox="inboxId"
      :label="label"
      :team-id="teamId"
      :conversation-type="conversationType"
      :folders-id="foldersId"
      :is-on-expanded-layout="isOnExpandedLayout"
      @conversation-load="onConversationLoad"
    />
    <ConversationBox
      v-if="showMessageView"
      :inbox-id="inboxId"
      :is-on-expanded-layout="isOnExpandedLayout"
    >
      <SidepanelSwitch v-if="currentChat.id" />
    </ConversationBox>
    <ConversationSidebar v-if="shouldShowSidebar" :current-chat="currentChat" />
    <CmdBarConversationSnooze />
  </section>
</template>
