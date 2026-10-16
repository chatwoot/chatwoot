import { useMapGetter, useStore } from 'dashboard/composables/store';
import { computed, watch } from 'vue';
import wootConstants from 'dashboard/constants/globals';
import { useConversationRoutePath } from './useConversationRoutePath';

// Resolves the conversations before and after the active one in the contact's history.
export function useContactConversationNavigation() {
  const store = useStore();
  const { buildConversationPath } = useConversationRoutePath();

  const currentChat = useMapGetter('getSelectedChat');
  const neighbours = useMapGetter(
    'contactConversations/getConversationNeighbours'
  );
  const appliedContactFilter = useMapGetter('getAppliedContactFilter');

  const contactId = computed(() => currentChat.value?.meta?.sender?.id);

  // The server returns the open conversation between its neighbours.
  const orderedConversations = computed(() =>
    [...neighbours.value(currentChat.value?.id)].sort(
      (a, b) => a.created_at - b.created_at || a.id - b.id
    )
  );

  const currentIndex = computed(() =>
    orderedConversations.value.findIndex(
      conversation => conversation.id === currentChat.value?.id
    )
  );

  // Moving forward is a review move; on a live chat it pulls the agent off the open one.
  const canMoveForward = computed(
    () =>
      appliedContactFilter.value?.id === contactId.value ||
      currentChat.value?.status === wootConstants.STATUS_TYPE.RESOLVED
  );

  const olderConversation = computed(() =>
    currentIndex.value > 0
      ? orderedConversations.value[currentIndex.value - 1]
      : null
  );

  const newerConversation = computed(() =>
    canMoveForward.value && currentIndex.value >= 0
      ? (orderedConversations.value[currentIndex.value + 1] ?? null)
      : null
  );

  watch(
    [contactId, () => currentChat.value?.id],
    ([id, conversationId]) => {
      if (!id || !conversationId) return;

      store.dispatch('contactConversations/getNeighbours', {
        contactId: id,
        conversationId,
      });
    },
    { immediate: true }
  );

  return { olderConversation, newerConversation, buildConversationPath };
}
