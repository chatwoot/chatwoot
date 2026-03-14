<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import MobileBottomTabBar from './MobileBottomTabBar.vue';
import MobileInboxView from './MobileInboxView.vue';
import MobileConversationList from './MobileConversationList.vue';
import MobileChatView from './MobileChatView.vue';
import MobileSettingsView from './MobileSettingsView.vue';

const route = useRoute();
const router = useRouter();
const { accountScopedRoute } = useAccount();

const activeTab = ref(1);

const INBOX_ROUTES = [
  'inbox_view',
  'inbox_view_conversation',
];

const SETTINGS_ROUTES = [
  'general_settings_index',
  'settings_inbox_list',
  'agent_list',
];

const activeChatId = computed(() => {
  const id =
    route.params.conversationId ||
    route.params.conversation_id ||
    route.params.id;
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

watch(() => route.name, syncTabFromRoute, { immediate: true });

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
  router.push(
    accountScopedRoute('inbox_conversation', {
      conversation_id: conversationId,
    })
  );
};

const onBack = () => {
  router.back();
};

// iOS PWA standalone: when restored from bfcache, JS event handlers
// may not be re-attached, making the page visually correct but non-interactive.
// Force a reload to re-hydrate the app.
const isStandalone =
  window.matchMedia('(display-mode: standalone)').matches ||
  window.navigator.standalone === true;

const onPageShow = event => {
  if (event.persisted) {
    window.location.reload();
  }
};

onMounted(() => {
  if (isStandalone) {
    window.addEventListener('pageshow', onPageShow);
  }
});

onUnmounted(() => {
  if (isStandalone) {
    window.removeEventListener('pageshow', onPageShow);
  }
});
</script>

<template>
  <div
    class="flex flex-col w-full h-full bg-n-surface-1"
    style="touch-action: manipulation"
  >
    <div
      class="flex-1 overflow-hidden"
      :class="isInChatView ? '' : 'pb-[calc(52px+env(safe-area-inset-bottom))]'"
    >
      <MobileChatView
        v-if="isInChatView"
        :conversation-id="activeChatId"
        @back="onBack"
      />
      <template v-else>
        <MobileInboxView
          v-if="activeTab === 0"
          @open-conversation="onOpenConversation"
        />
        <MobileConversationList
          v-else-if="activeTab === 1"
          @open-conversation="onOpenConversation"
        />
        <MobileSettingsView v-else />
      </template>
    </div>
    <MobileBottomTabBar
      v-if="!isInChatView"
      :active-tab="activeTab"
      @change="onTabChange"
    />
  </div>
</template>
