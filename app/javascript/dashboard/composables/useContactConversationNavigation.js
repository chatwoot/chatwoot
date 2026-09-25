import { computed, nextTick, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import wootConstants from 'dashboard/constants/globals';
import { useConversationRoutePath } from './useConversationRoutePath';

// Provided once by the conversation view and injected by the thread and the contact panel.
export const CONTACT_CONVERSATION_NAVIGATION = 'contactConversationNavigation';

export function useContactConversationNavigation() {
  const store = useStore();
  const route = useRoute();
  const router = useRouter();
  const { t } = useI18n();
  const { buildConversationPath } = useConversationRoutePath();

  const currentChat = useMapGetter('getSelectedChat');
  const conversationById = useMapGetter('getConversationById');
  const neighbours = useMapGetter(
    'contactConversations/getConversationNeighbours'
  );
  const appliedContactFilter = useMapGetter('getAppliedContactFilter');
  const filteredConversations = useMapGetter('getFilteredConversations');
  const replyOpenedFor = ref(null);

  const contactId = computed(() => currentChat.value?.meta?.sender?.id);
  // The inbox view has no list to scope, so a filter left behind there means nothing.
  const isReviewingHistory = computed(
    () =>
      !String(route.name || '').startsWith('inbox_view') &&
      appliedContactFilter.value?.id === contactId.value
  );

  // The server returns the open conversation between its neighbours.
  const orderedConversations = computed(() =>
    [...neighbours.value(currentChat.value?.id)].sort(
      (a, b) => a.created_at - b.created_at || a.id - b.id
    )
  );
  const currentIndex = computed(() =>
    orderedConversations.value.findIndex(
      ({ id }) => id === currentChat.value?.id
    )
  );
  const hasHistory = computed(() => orderedConversations.value.length > 1);

  // The history view lists newest first, so its head is the latest conversation.
  const latestConversation = computed(() =>
    isReviewingHistory.value ? (filteredConversations.value[0] ?? null) : null
  );
  // The window decides once loaded; until then the head of the history list stands in.
  const isLatestConversation = computed(() =>
    currentIndex.value >= 0
      ? currentIndex.value === orderedConversations.value.length - 1
      : latestConversation.value?.id === currentChat.value?.id
  );

  // Moving forward is a review move; on a live chat it pulls the agent off the open one.
  const canMoveForward = computed(
    () =>
      isReviewingHistory.value ||
      currentChat.value?.status === wootConstants.STATUS_TYPE.RESOLVED
  );

  const olderConversation = computed(
    () => orderedConversations.value[currentIndex.value - 1] ?? null
  );
  const newerConversation = computed(() =>
    canMoveForward.value && currentIndex.value >= 0
      ? (orderedConversations.value[currentIndex.value + 1] ?? null)
      : null
  );

  const isReplyRevealed = computed(
    () => replyOpenedFor.value === currentChat.value?.id
  );
  const isReadingHistory = computed(
    () =>
      isReviewingHistory.value &&
      !isLatestConversation.value &&
      !isReplyRevealed.value
  );
  const leaveReadingMode = () => {
    replyOpenedFor.value = currentChat.value?.id;
  };

  // `path` is visited first; `conversationId` is the thread kept open once the list is replaced.
  const viewContactHistory = async ({ conversationId = null, path = null }) => {
    const { id, name } = currentChat.value.meta.sender;
    if (path) {
      await router.push(path);
      // Leaving a folder resets the list, which would drop a filter applied before it.
      await nextTick();
    }

    return store
      .dispatch('applyConversationFilters', {
        filters: [
          {
            attribute_key: 'contact_id',
            attribute_model: 'standard',
            filter_operator: 'equal_to',
            query_operator: 'and',
            custom_attribute_type: '',
            values: [{ id, name }],
          },
        ],
        // Match the chronological order of the in-thread navigation.
        sortBy: wootConstants.SORT_BY_TYPE.CREATED_AT_DESC,
      })
      .catch(() => useAlert(t('CHAT_LIST.FETCH_ERROR')))
      .finally(() => {
        // Applying a filter empties the store; refetch the open thread if it was dropped.
        if (conversationId && !conversationById.value(conversationId)) {
          store.dispatch('getConversation', conversationId);
        }
      });
  };

  const openConversation = ({ id }) => {
    const path = buildConversationPath(id, { keepFolderScope: false });
    if (isReviewingHistory.value) return router.push(path);

    return viewContactHistory({ conversationId: id, path });
  };

  watch(
    [contactId, () => currentChat.value?.id],
    ([id, conversationId]) => {
      replyOpenedFor.value = null;
      if (!id || !conversationId) return;

      store.dispatch('contactConversations/getNeighbours', {
        contactId: id,
        conversationId,
      });
    },
    { immediate: true }
  );

  return {
    olderConversation,
    newerConversation,
    hasHistory,
    isReadingHistory,
    isReplyRevealed,
    latestConversation,
    leaveReadingMode,
    openConversation,
    viewContactHistory,
    buildConversationPath,
  };
}
