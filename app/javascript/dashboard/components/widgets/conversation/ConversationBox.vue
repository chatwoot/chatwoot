<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import ConversationHeader from './ConversationHeader.vue';
import DashboardAppFrame from '../DashboardApp/Frame.vue';
import EmptyState from './EmptyState/EmptyState.vue';
import MessagesView from './MessagesView.vue';

defineProps({
  inboxId: {
    type: [Number, String],
    default: '',
    required: false,
  },
  isInboxView: {
    type: Boolean,
    default: false,
  },
  isOnExpandedLayout: {
    type: Boolean,
    default: true,
  },
});

const { t } = useI18n();
const store = useStore();

const currentChat = useMapGetter('getSelectedChat');
const dashboardApps = useMapGetter('dashboardApps/getRecords');

const activeIndex = ref(0);

const dashboardAppTabs = computed(() => [
  {
    key: 'messages',
    index: 0,
    name: t('CONVERSATION.DASHBOARD_APP_TAB_MESSAGES'),
  },
  ...dashboardApps.value.map((dashboardApp, index) => ({
    key: `dashboard-${dashboardApp.id}`,
    index: index + 1,
    name: dashboardApp.title,
  })),
]);

const fetchLabels = () => {
  if (!currentChat.value.id) {
    return;
  }
  store.dispatch('conversationLabels/get', currentChat.value.id);
};

const onDashboardAppTabChange = index => {
  activeIndex.value = index;
};

watch(
  () => currentChat.value.inbox_id,
  inboxId => {
    if (inboxId) {
      store.dispatch('inboxAssignableAgents/fetch', [inboxId]);
    }
  },
  { immediate: true }
);

watch(
  () => currentChat.value.id,
  () => {
    fetchLabels();
    activeIndex.value = 0;
  }
);

onMounted(() => {
  fetchLabels();
  store.dispatch('dashboardApps/get');
});
</script>

<template>
  <div
    class="conversation-details-wrap flex flex-col min-w-0 w-full bg-n-surface-1 relative"
    :class="{
      'border-l rtl:border-l-0 rtl:border-r border-n-weak': !isOnExpandedLayout,
    }"
  >
    <ConversationHeader
      v-if="currentChat.id"
      :chat="currentChat"
      :is-on-expanded-view="isOnExpandedLayout"
      :show-back-button="isOnExpandedLayout && !isInboxView"
      :class="{ 'border-b border-n-weak !pb-3': !dashboardApps.length }"
    />
    <woot-tabs
      v-if="dashboardApps.length && currentChat.id"
      :index="activeIndex"
      class="[&>ul]:px-5 h-10"
      @change="onDashboardAppTabChange"
    >
      <woot-tabs-item
        v-for="tab in dashboardAppTabs"
        :key="tab.key"
        :index="tab.index"
        :name="tab.name"
        :show-badge="false"
        is-compact
      />
    </woot-tabs>
    <div v-show="!activeIndex" class="flex h-full min-h-0 m-0">
      <MessagesView
        v-if="currentChat.id"
        :inbox-id="inboxId"
        :is-inbox-view="isInboxView"
      />
      <EmptyState
        v-if="!currentChat.id && !isInboxView"
        :is-on-expanded-layout="isOnExpandedLayout"
      />
      <slot />
    </div>
    <DashboardAppFrame
      v-for="(dashboardApp, index) in dashboardApps"
      v-show="activeIndex - 1 === index"
      :key="currentChat.id + '-' + dashboardApp.id"
      :is-visible="activeIndex - 1 === index"
      :config="dashboardApps[index].content"
      :position="index"
      :current-chat="currentChat"
    />
  </div>
</template>
