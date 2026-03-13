<script setup>
import { ref, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useStore } from 'vuex';

import MobileBottomTabBar from './MobileBottomTabBar.vue';
import MobileInboxView from './MobileInboxView.vue';
import MobileConversationList from './MobileConversationList.vue';
import MobileChatView from './MobileChatView.vue';
import MobileSettingsView from './MobileSettingsView.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { accountScopedRoute } = useAccount();

const activeTab = ref(1);

const INBOX_ROUTES = [
  'inbox_view',
  'inbox_view_conversation',
];

const CONVERSATION_ROUTES = [
  'home',
  'inbox_conversation',
  'conversation_through_inbox',
  'conversations_through_label',
  'team_conversations_through_label',
  'conversations_through_folders',
  'conversation_through_mentions',
  'conversation_through_unattended',
  'conversation_through_participating',
];

const SETTINGS_ROUTES = [
  'general_settings_index',
  'settings_inbox_list',
  'agent_list',
];

const activeChatId = computed(() => {
  const id = route.params.conversationId || route.params.id;
  return id ? Number(id) : null;
});

const isInChatView = computed(() => {
  return activeChatId.value !== null && activeChatId.value > 0;
});

const syncTabFromRoute = () => {
  const name = route.name;
  if (INBOX_ROUTES.includes(name)) {
    activeTab.value = 0;
  } else if (SETTINGS_ROUTES.includes(name)) {
    activeTab.value = 2;
  } else {
    activeTab.value = 1;
  }
};

syncTabFromRoute();
watch(() => route.name, syncTabFromRoute);

const onTabChange = tabId => {
  activeTab.value = tabId;
  if (tabId === 0) {
    router.push(accountScopedRoute('inbox_view'));
  } else if (tabId === 1) {
    router.push(accountScopedRoute('home'));
  } else if (tabId === 2) {
    router.push(accountScopedRoute('general_settings_index'));
  }
};

const onOpenConversation = conversationId => {
  router.push({
    name: 'inbox_conversation',
    params: { conversationId },
  });
};

const onBack = () => {
  router.back();
};
</script>

<template>
  <div class="flex flex-col w-full h-full bg-n-surface-1">
    <div class="flex-1 overflow-hidden pb-[calc(52px+env(safe-area-inset-bottom))]">
      <MobileChatView
        v-if="isInChatView"
        :conversation-id="activeChatId"
        @back="onBack"
      />
      <template v-else>
        <MobileInboxView
          v-show="activeTab === 0"
          @open-conversation="onOpenConversation"
        />
        <MobileConversationList
          v-show="activeTab === 1"
          @open-conversation="onOpenConversation"
        />
        <MobileSettingsView v-show="activeTab === 2" />
      </template>
    </div>
    <MobileBottomTabBar
      v-if="!isInChatView"
      :active-tab="activeTab"
      @change="onTabChange"
    />
  </div>
</template>
