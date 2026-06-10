<script setup>
import { ref, computed, provide, onMounted, watch } from 'vue';
import {
  useStore,
  useMapGetter,
  useFunctionGetter,
} from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useHaptics } from 'dashboard/composables/useHaptics';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';
import { ASSIGNEE_TYPE_TAB_PERMISSIONS } from 'dashboard/constants/permissions.js';
import {
  getUserPermissions,
  filterItemsByPermission,
} from 'dashboard/helper/permissionsHelper.js';
import { useConversationRequiredAttributes } from 'dashboard/composables/useConversationRequiredAttributes';

import ConversationCard from 'dashboard/components/widgets/conversation/ConversationCard.vue';
import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';
import ChatTypeTabs from 'dashboard/components/widgets/ChatTypeTabs.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';
import MobileConversationHeader from './MobileConversationHeader.vue';
import MobileFilterSheet from './MobileFilterSheet.vue';
import MobileConversationStatusSheet from './MobileConversationStatusSheet.vue';
import MobilePullToRefresh from './MobilePullToRefresh.vue';
import MobileSwipeableRow from './MobileSwipeableRow.vue';

import wootConstants from 'dashboard/constants/globals';

const emit = defineEmits(['openConversation']);
const store = useStore();
const { t } = useI18n();
const { medium, success } = useHaptics();
const { checkMissingAttributes } = useConversationRequiredAttributes();

const swipeOpenRowId = ref(null);
provide('swipeOpenRowId', swipeOpenRowId);

const listRef = ref(null);
const isPullRefreshing = ref(false);
const showFilterSheet = ref(false);
const showStatusSheet = ref(false);
const selectedConversation = ref(null);
const resolveAttributesModalRef = ref(null);

const activeAssigneeTab = ref(wootConstants.ASSIGNEE_TYPE.ME);
const activeStatus = ref(wootConstants.STATUS_TYPE.OPEN);
const activeSortBy = ref(wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC);

const currentUser = useMapGetter('getCurrentUser');
const currentAccountId = useMapGetter('auth/getCurrentAccountId');
const activeInbox = useMapGetter('getSelectedInbox');
const inboxesList = useMapGetter('inboxes/getInboxes');
const conversationStats = useMapGetter('conversationStats/getStats');

const userPermissions = computed(() => {
  return getUserPermissions(currentUser.value, currentAccountId.value);
});

const assigneeTabItems = computed(() => {
  return filterItemsByPermission(
    ASSIGNEE_TYPE_TAB_PERMISSIONS,
    userPermissions.value,
    item => item.permissions
  ).map(({ key, count: countKey }) => ({
    key,
    name: t(`CHAT_LIST.ASSIGNEE_TYPE_TABS.${key}`),
    count: conversationStats.value[countKey] || 0,
  }));
});

const chatLists = useMapGetter('getAllConversations');
const chatListLoadingStatus = useMapGetter('getChatListLoadingStatus');
const getConversationById = useMapGetter('getConversationById');
const currentPage = useFunctionGetter(
  'conversationPage/getCurrentPageFilter',
  activeAssigneeTab
);
const hasCurrentPageEndReached = useFunctionGetter(
  'conversationPage/getHasEndReached',
  activeAssigneeTab
);

const chatListLoading = computed(() => {
  return (
    chatListLoadingStatus.value &&
    !chatLists.value.length &&
    !isPullRefreshing.value
  );
});

const listLoadingMore = computed(() => {
  return (
    chatListLoadingStatus.value &&
    chatLists.value.length > 0 &&
    !isPullRefreshing.value
  );
});

const allConversationsLoaded = computed(
  () => hasCurrentPageEndReached.value && !chatListLoading.value
);

const showInboxName = computed(() => {
  return !activeInbox.value && inboxesList.value.length > 1;
});

const conversationFilters = computed(() => ({
  page: currentPage.value + 1,
  assigneeType: activeAssigneeTab.value,
  status: activeStatus.value,
  sortBy: activeSortBy.value,
}));

const fetchConversations = ({ preserveRecords = false } = {}) => {
  store.dispatch('conversationPage/reset');

  if (!preserveRecords) {
    store.dispatch('emptyAllConversations');
  }

  store.dispatch('setChatListFilters', {
    assigneeType: activeAssigneeTab.value,
    status: activeStatus.value,
    page: 1,
    sortBy: activeSortBy.value,
  });
  return store.dispatch('fetchAllConversations');
};

const loadMoreConversations = () => {
  if (allConversationsLoaded.value || chatListLoadingStatus.value) return;

  store.dispatch('updateChatListFilters', {
    assigneeType: activeAssigneeTab.value,
    status: activeStatus.value,
    page: currentPage.value + 1,
    sortBy: activeSortBy.value,
  });
  store.dispatch('fetchAllConversations');
};

const onAssigneeTabChange = tab => {
  activeAssigneeTab.value = tab;
  fetchConversations();
};

const onConversationClick = chat => {
  if (swipeOpenRowId.value) {
    swipeOpenRowId.value = null;
    return;
  }
  emit('openConversation', chat.id);
};

const getCurrentContact = chat => {
  const sender = chat.meta?.sender || {};
  if (!sender.id) return sender;

  const contact = store.getters['contacts/getContact'](sender.id);
  return Object.keys(contact).length ? contact : sender;
};

const getAssignee = chat => {
  return chat.meta?.assignee || {};
};

const getInbox = chat => {
  return chat.inbox_id ? store.getters['inboxes/getInbox'](chat.inbox_id) : {};
};

const closeStatusSheet = () => {
  showStatusSheet.value = false;
  selectedConversation.value = null;
};

const toggleConversationStatus = async (
  conversationId,
  status,
  snoozedUntil = null,
  customAttributes = null
) => {
  const payload = {
    conversationId,
    status,
    snoozedUntil,
  };

  if (customAttributes) {
    payload.customAttributes = customAttributes;
  }

  await store.dispatch('toggleStatus', payload);
  if (status === wootConstants.STATUS_TYPE.RESOLVED) {
    success();
  } else {
    medium();
  }
  useAlert(t('CONVERSATION.CHANGE_STATUS'));
};

const openStatusSheet = chat => {
  selectedConversation.value = chat;
  showStatusSheet.value = true;
};

const getSwipeActions = () => {
  return [
    {
      key: 'status',
      icon: 'i-lucide-sliders-horizontal',
      color: 'bg-n-teal-9',
      label: t('MOBILE.SWIPE.STATUS'),
    },
  ];
};

const getLeftSwipeActions = chat => {
  const hasUnread = chat.unread_count > 0;
  return [
    {
      key: hasUnread ? 'markRead' : 'markUnread',
      icon: hasUnread ? 'i-lucide-mail-open' : 'i-lucide-mail',
      color: 'bg-n-blue-9',
      label: hasUnread
        ? t('MOBILE.SWIPE.MARK_READ')
        : t('MOBILE.SWIPE.MARK_UNREAD'),
    },
  ];
};

const onSwipeAction = (chat, actionKey) => {
  medium();
  if (actionKey === 'status') {
    openStatusSheet(chat);
  }
};

const onLeftSwipeAction = async (chat, actionKey) => {
  medium();
  if (actionKey === 'markUnread') {
    try {
      await store.dispatch('markMessagesUnread', { id: chat.id });
      useAlert(t('MOBILE.SWIPE.MARKED_UNREAD'));
    } catch {
      // error already surfaced by the store action
    }
  } else if (actionKey === 'markRead') {
    try {
      const marked = await store.dispatch('markMessagesRead', { id: chat.id });
      if (marked !== false) {
        useAlert(t('MOBILE.SWIPE.MARKED_READ'));
      }
    } catch {
      // error already surfaced by the store action
    }
  }
};

const handleResolveWithAttributes = ({ attributes, context }) => {
  if (!context) return;

  const existingConversation = getConversationById.value(context.id);
  const currentCustomAttributes = existingConversation?.custom_attributes || {};
  const mergedAttributes = { ...currentCustomAttributes, ...attributes };

  toggleConversationStatus(
    context.id,
    wootConstants.STATUS_TYPE.RESOLVED,
    context.snoozedUntil,
    mergedAttributes
  );
};

const onStatusSelect = async status => {
  const currentConversation = selectedConversation.value;

  closeStatusSheet();

  if (!currentConversation) return;

  if (status === wootConstants.STATUS_TYPE.PENDING) {
    await toggleConversationStatus(currentConversation.id, status);
    return;
  }

  if (status === wootConstants.STATUS_TYPE.SNOOZED) {
    await toggleConversationStatus(
      currentConversation.id,
      status,
      findSnoozeTime(wootConstants.SNOOZE_OPTIONS.UNTIL_NEXT_REPLY) || null
    );
    return;
  }

  if (status === wootConstants.STATUS_TYPE.RESOLVED) {
    const latestConversation =
      getConversationById.value(currentConversation.id) || currentConversation;
    const currentCustomAttributes = latestConversation.custom_attributes || {};
    const { hasMissing, missing } = checkMissingAttributes(
      currentCustomAttributes
    );

    if (hasMissing) {
      resolveAttributesModalRef.value?.open(missing, currentCustomAttributes, {
        id: latestConversation.id,
        snoozedUntil: latestConversation.snoozed_until,
      });
      return;
    }

    await toggleConversationStatus(latestConversation.id, status);
  }
};

const onRefreshStart = () => {
  isPullRefreshing.value = true;
};

const onRefreshEnd = () => {
  isPullRefreshing.value = false;
};

const onRefresh = () => fetchConversations({ preserveRecords: true });

const onFilterApply = filters => {
  if (filters.status) activeStatus.value = filters.status;
  if (filters.assigneeType) activeAssigneeTab.value = filters.assigneeType;
  if (filters.sortBy) activeSortBy.value = filters.sortBy;
  showFilterSheet.value = false;
  fetchConversations();
};

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('setChatListFilters', conversationFilters.value);
  fetchConversations();
  store.dispatch('conversationStats/get', conversationFilters.value);
});

watch(conversationFilters, newFilters => {
  store.dispatch('updateChatListFilters', newFilters);
  store.dispatch('conversationStats/get', newFilters);
});
</script>

<template>
  <div class="flex flex-col w-full h-full">
    <MobileConversationHeader @open-filter="showFilterSheet = true" />
    <ChatTypeTabs
      :items="assigneeTabItems"
      :active-tab="activeAssigneeTab"
      class="px-2 flex-shrink-0"
      @chat-tab-change="onAssigneeTabChange"
    />
    <MobilePullToRefresh
      :refresh-action="onRefresh"
      @refresh-start="onRefreshStart"
      @refresh-end="onRefreshEnd"
    >
      <div
        ref="listRef"
        data-mobile-pull-scroll
        class="flex-1 overflow-y-auto overscroll-y-contain px-2"
      >
        <div
          v-if="chatListLoading"
          class="flex items-center justify-center py-8"
        >
          <Spinner class="text-n-brand" />
        </div>
        <div
          v-else-if="!chatLists.length"
          class="flex items-center justify-center py-8 text-sm text-n-slate-10"
        >
          {{ t('MOBILE.CONVERSATIONS.NO_CONVERSATIONS') }}
        </div>
        <template v-else>
          <MobileSwipeableRow
            v-for="chat in chatLists"
            :key="chat.id"
            :row-id="chat.id"
            :actions="getSwipeActions(chat)"
            :left-actions="getLeftSwipeActions(chat)"
            class="mb-0.5"
            @action="onSwipeAction(chat, $event)"
            @left-action="onLeftSwipeAction(chat, $event)"
          >
            <ConversationCard
              :chat="chat"
              :current-contact="getCurrentContact(chat)"
              :assignee="getAssignee(chat)"
              :inbox="getInbox(chat)"
              :show-assignee="
                activeAssigneeTab === wootConstants.ASSIGNEE_TYPE.ALL
              "
              :show-inbox-name="showInboxName"
              class="rounded-lg"
              @click="onConversationClick(chat)"
            />
          </MobileSwipeableRow>
          <div v-if="listLoadingMore" class="flex justify-center py-4">
            <Spinner class="text-n-brand" />
          </div>
          <IntersectionObserver
            v-if="!allConversationsLoaded && !chatListLoadingStatus"
            :options="{ root: listRef, rootMargin: '100px 0px' }"
            @observed="loadMoreConversations"
          />
        </template>
      </div>
    </MobilePullToRefresh>
    <MobileFilterSheet
      v-if="showFilterSheet"
      :status="activeStatus"
      :assignee-type="activeAssigneeTab"
      :sort-by="activeSortBy"
      @apply="onFilterApply"
      @close="showFilterSheet = false"
    />
    <MobileConversationStatusSheet
      :open="showStatusSheet"
      @close="closeStatusSheet"
      @select="onStatusSelect"
    />
    <ConversationResolveAttributesModal
      ref="resolveAttributesModalRef"
      @submit="handleResolveWithAttributes"
    />
  </div>
</template>
