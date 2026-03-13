<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';

import ConversationCard from 'dashboard/components/widgets/conversation/ConversationCard.vue';
import ChatTypeTabs from 'dashboard/components/widgets/ChatTypeTabs.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';
import MobileConversationHeader from './MobileConversationHeader.vue';
import MobileFilterSheet from './MobileFilterSheet.vue';

import wootConstants from 'dashboard/constants/globals';

const emit = defineEmits(['openConversation']);
const store = useStore();
const route = useRoute();
const { t } = useI18n();
const { uiSettings } = useUISettings();

const listRef = ref(null);
const showFilterSheet = ref(false);

const activeAssigneeTab = ref(wootConstants.ASSIGNEE_TYPE.ME);
const activeStatus = ref(wootConstants.STATUS_TYPE.OPEN);
const activeSortBy = ref(wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC);

const chatLists = useMapGetter('getAllConversations');
const uiFlags = useMapGetter('chatList/getUIFlags');
const currentPage = useMapGetter('chatList/getCurrentPage');
const hasCurrentPageEndReached = useMapGetter(
  'chatList/getHasCurrentPageEndReached'
);

const conversationList = computed(() => chatLists.value);

const chatListLoading = computed(
  () => uiFlags.value.isFetching && !conversationList.value.length
);

const listLoadingMore = computed(
  () => uiFlags.value.isFetching && conversationList.value.length > 0
);

const allConversationsLoaded = computed(
  () => hasCurrentPageEndReached.value && !chatListLoading.value
);

const conversationFilters = computed(() => ({
  page: currentPage.value + 1,
  assigneeType: activeAssigneeTab.value,
  status: activeStatus.value,
  sortBy: activeSortBy.value,
}));

const fetchConversations = () => {
  store.dispatch('chatList/reset');
  store.dispatch('fetchAllConversations', {
    assigneeType: activeAssigneeTab.value,
    status: activeStatus.value,
    page: 1,
    sortBy: activeSortBy.value,
  });
};

const loadMoreConversations = () => {
  if (allConversationsLoaded.value || uiFlags.value.isFetching) return;

  store.dispatch('fetchAllConversations', {
    assigneeType: activeAssigneeTab.value,
    status: activeStatus.value,
    page: currentPage.value + 1,
    sortBy: activeSortBy.value,
  });
};

const onAssigneeTabChange = tab => {
  activeAssigneeTab.value = tab;
  fetchConversations();
};

const onStatusChange = status => {
  activeStatus.value = status;
  fetchConversations();
};

const onConversationClick = chat => {
  emit('openConversation', chat.id);
};

const onFilterApply = filters => {
  if (filters.status) activeStatus.value = filters.status;
  if (filters.assigneeType) activeAssigneeTab.value = filters.assigneeType;
  if (filters.sortBy) activeSortBy.value = filters.sortBy;
  showFilterSheet.value = false;
  fetchConversations();
};

onMounted(() => {
  fetchConversations();
});
</script>

<template>
  <div class="flex flex-col w-full h-full">
    <MobileConversationHeader
      @open-filter="showFilterSheet = true"
    />
    <ChatTypeTabs
      :active-tab="activeAssigneeTab"
      :active-status="activeStatus"
      class="px-2 flex-shrink-0"
      @chatTabChange="onAssigneeTabChange"
    />
    <div
      ref="listRef"
      class="flex-1 overflow-y-auto px-2"
    >
      <div v-if="chatListLoading" class="flex items-center justify-center py-8">
        <Spinner class="text-n-brand" />
      </div>
      <div
        v-else-if="!conversationList.length"
        class="flex items-center justify-center py-8 text-sm text-n-slate-10"
      >
        {{ t('MOBILE.CONVERSATIONS.NO_CONVERSATIONS') }}
      </div>
      <template v-else>
        <ConversationCard
          v-for="chat in conversationList"
          :key="chat.id"
          :chat="chat"
          :show-assignee="activeAssigneeTab === 'all'"
          class="mb-0.5 rounded-lg"
          @click="onConversationClick(chat)"
        />
        <div v-if="listLoadingMore" class="flex justify-center py-4">
          <Spinner class="text-n-brand" />
        </div>
        <IntersectionObserver
          v-if="!allConversationsLoaded && !uiFlags.isFetching"
          :options="{ root: listRef, rootMargin: '100px 0px' }"
          @observed="loadMoreConversations"
        />
      </template>
    </div>
    <MobileFilterSheet
      v-if="showFilterSheet"
      :status="activeStatus"
      :assignee-type="activeAssigneeTab"
      :sort-by="activeSortBy"
      @apply="onFilterApply"
      @close="showFilterSheet = false"
    />
  </div>
</template>
