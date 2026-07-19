<script setup>
import { computed, onMounted, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useWindowSize } from '@vueuse/core';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import ChatRoomList from 'dashboard/components-next/InternalChats/ChatRoomList.vue';
import ChatThread from 'dashboard/components-next/InternalChats/ChatThread.vue';
import ChatEmptyState from 'dashboard/components-next/InternalChats/ChatEmptyState.vue';

const props = defineProps({
  conversationId: { type: [String, Number], default: 0 },
});

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();
const { accountScopedRoute } = useAccount();
const { width: windowWidth } = useWindowSize();

const accountId = computed(() => Number(route.params.accountId) || 0);
const isMobile = computed(() => windowWidth.value < 768);

const rooms = useMapGetter('internalChats/getRooms');
const uiFlags = useMapGetter('internalChats/getUIFlags');
const currentUserId = useMapGetter('getCurrentUserID');
const currentUser = useMapGetter('getCurrentUser');

const selectedId = computed(() => Number(props.conversationId) || 0);

const selectedRoom = computed(() =>
  rooms.value.find(room => room.id === selectedId.value)
);

const messages = computed(() =>
  store.getters['internalChats/getMessagesByRoomId'](selectedId.value)
);

const hasMore = computed(() =>
  store.getters['internalChats/getHasMoreByRoomId'](selectedId.value)
);

const showRoomList = computed(() => !isMobile.value || !selectedId.value);

const showThread = computed(
  () => Boolean(selectedRoom.value) && (!isMobile.value || selectedId.value)
);

const openRoom = roomId => {
  router.push(
    accountScopedRoute('internal_chats_show', { conversationId: roomId })
  );
};

const goToIndex = () => {
  router.push(accountScopedRoute('internal_chats_index'));
};

const loadMessages = async () => {
  if (!selectedId.value) return;
  await store.dispatch('internalChats/fetchMessages', {
    conversationId: selectedId.value,
  });
};

const loadOlder = beforeId =>
  store.dispatch('internalChats/fetchMessages', {
    conversationId: selectedId.value,
    beforeId,
  });

const sendMessage = async content => {
  try {
    await store.dispatch('internalChats/sendMessage', {
      conversationId: selectedId.value,
      content,
      currentUserId: currentUserId.value,
      currentUser: currentUser.value,
    });
  } catch (error) {
    useAlert(error?.response?.data?.error || t('INTERNAL_CHATS.ERRORS.SEND'));
  }
};

const onRetryMessage = message => {
  store.dispatch('internalChats/retryMessage', {
    conversationId: selectedId.value,
    message,
    currentUserId: currentUserId.value,
    currentUser: currentUser.value,
  });
};

const onDraftChange = () => {
  // Drafts are persisted by ChatThread in localStorage.
  // This hook is here in case future store-level coordination is needed.
};

const onNoRoomsAction = () => {
  router.push(accountScopedRoute('settings_teams_list'));
};

// Desktop: open first room so the pane isn't empty. Mobile keeps the list first.
const autoSelectFirstRoom = roomsList => {
  if (isMobile.value) return;
  if (selectedId.value) return;
  if (!Array.isArray(roomsList) || !roomsList.length) return;
  router.replace(
    accountScopedRoute('internal_chats_show', {
      conversationId: roomsList[0].id,
    })
  );
};

onMounted(async () => {
  const data = await store.dispatch('internalChats/fetchRooms');
  autoSelectFirstRoom(data);
  await loadMessages();
});

watch(selectedId, () => {
  loadMessages();
});
</script>

<template>
  <section
    class="flex h-full min-h-0 w-full min-w-0 overflow-hidden bg-n-surface-1"
  >
    <ChatRoomList
      v-if="showRoomList"
      :rooms="rooms"
      :selected-id="selectedId"
      :is-fetching="uiFlags.isFetching"
      @select="openRoom"
    />

    <ChatThread
      v-if="showThread"
      :room="selectedRoom"
      :messages="messages"
      :has-more="hasMore"
      :is-fetching-messages="uiFlags.isFetchingMessages"
      :is-creating="uiFlags.isCreating"
      :show-back="isMobile"
      :account-id="accountId"
      :load-older="loadOlder"
      @send="sendMessage"
      @back="goToIndex"
      @draft-change="onDraftChange"
      @retry-message="onRetryMessage"
    />

    <ChatEmptyState
      v-else-if="!uiFlags.isFetching && !rooms.length"
      variant="no_rooms"
      @action="onNoRoomsAction"
    />

    <ChatEmptyState v-else-if="!isMobile && !selectedRoom" variant="select" />
  </section>
</template>
