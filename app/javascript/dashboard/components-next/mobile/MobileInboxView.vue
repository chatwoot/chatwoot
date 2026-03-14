<script setup>
import { ref, computed, provide, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useHaptics } from 'dashboard/composables/useHaptics';

import InboxCard from 'dashboard/components-next/Inbox/InboxCard.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';
import MobileInboxHeader from './MobileInboxHeader.vue';
import MobilePullToRefresh from './MobilePullToRefresh.vue';
import MobileSwipeableRow from './MobileSwipeableRow.vue';

import wootConstants from 'dashboard/constants/globals';

const emit = defineEmits(['openConversation']);
const store = useStore();
const { t } = useI18n();
const { medium } = useHaptics();

const swipeOpenRowId = ref(null);
provide('swipeOpenRowId', swipeOpenRowId);

const listRef = ref(null);
const page = ref(1);
const status = ref('');
const type = ref('');
const sortOrder = ref(wootConstants.INBOX_SORT_BY.NEWEST);

const meta = useMapGetter('notifications/getMeta');
const uiFlags = useMapGetter('notifications/getUIFlags');
const records = useMapGetter('notifications/getFilteredNotificationsV4');
const inboxById = useMapGetter('inboxes/getInboxById');

const inboxFilters = computed(() => ({
  page: page.value,
  status: status.value,
  type: type.value,
  sortOrder: sortOrder.value,
}));

const notifications = computed(() => records.value(inboxFilters.value));

const showEndOfList = computed(
  () => uiFlags.value.isAllNotificationsLoaded && !uiFlags.value.isFetching
);

const showEmptyState = computed(
  () => !uiFlags.value.isFetching && !notifications.value.length
);

const stateInbox = inboxId => inboxById.value(inboxId);

const fetchNotifications = () => {
  page.value = 1;
  store.dispatch('notifications/clear');
  store.dispatch('notifications/index', inboxFilters.value);
};

const loadMoreNotifications = () => {
  if (uiFlags.value.isAllNotificationsLoaded) return;
  page.value += 1;
  store.dispatch('notifications/index', {
    page: page.value,
    status: status.value,
    type: type.value,
    sortOrder: sortOrder.value,
  });
};

const inboxSwipeActions = [
  {
    key: 'read',
    icon: 'i-lucide-check',
    color: 'bg-n-blue-9',
    label: t('MOBILE.SWIPE.MARK_READ'),
  },
  {
    key: 'delete',
    icon: 'i-lucide-trash-2',
    color: 'bg-n-ruby-9',
    label: t('MOBILE.SWIPE.DELETE'),
  },
];

const onSwipeAction = (item, actionKey) => {
  medium();
  const { id, primaryActorId, primaryActorType } = item;
  if (actionKey === 'read') {
    store.dispatch('notifications/read', {
      id,
      primaryActorId,
      primaryActorType,
      unreadCount: meta.value.unreadCount,
    });
  } else if (actionKey === 'delete') {
    store.dispatch('notifications/delete', {
      notification: item,
      count: meta.value.count,
      unreadCount: meta.value.unreadCount,
    });
  }
};

const openConversation = notificationItem => {
  const { id, primaryActorId, primaryActorType, primaryActor } =
    notificationItem;
  const conversationId = primaryActor?.id;

  if (!conversationId) {
    useAlert(t('INBOX.NO_CONTENT'));
    return;
  }

  store.dispatch('notifications/read', {
    id,
    primaryActorId,
    primaryActorType,
    unreadCount: meta.value.unreadCount,
  });

  store.dispatch('notifications/unReadCount');
  emit('openConversation', conversationId);
};

const markAllRead = async () => {
  try {
    await store.dispatch('notifications/readAll');
    useAlert(t('INBOX.ALERTS.MARK_ALL_READ'));
    fetchNotifications();
  } catch {
    // error
  }
};

const onRefresh = () => fetchNotifications();

onMounted(() => {
  fetchNotifications();
});
</script>

<template>
  <div class="flex flex-col w-full h-full">
    <MobileInboxHeader @mark-all-read="markAllRead" />
    <MobilePullToRefresh @refresh="onRefresh">
      <div ref="listRef" class="flex-1 overflow-y-auto px-2">
        <div v-if="uiFlags.isFetching && !notifications.length" class="flex items-center justify-center py-8">
          <Spinner class="text-n-brand" />
        </div>
        <div
          v-else-if="showEmptyState"
          class="flex items-center justify-center py-8 text-sm text-n-slate-10"
        >
          {{ t('MOBILE.INBOX.NO_NOTIFICATIONS') }}
        </div>
        <template v-else>
          <MobileSwipeableRow
            v-for="item in notifications"
            :key="item.id"
            :row-id="item.id"
            :actions="inboxSwipeActions"
            class="mb-0.5"
            @action="onSwipeAction(item, $event)"
          >
            <InboxCard
              :inbox-item="item"
              :state-inbox="stateInbox(item.primaryActor?.inboxId)"
              class="rounded-lg"
              @click="openConversation(item)"
            />
          </MobileSwipeableRow>
          <div v-if="uiFlags.isFetching" class="flex justify-center py-4">
            <Spinner class="text-n-brand" />
          </div>
          <IntersectionObserver
            v-if="!showEndOfList && !uiFlags.isFetching"
            :options="{ root: listRef, rootMargin: '100px 0px' }"
            @observed="loadMoreNotifications"
          />
        </template>
      </div>
    </MobilePullToRefresh>
  </div>
</template>
