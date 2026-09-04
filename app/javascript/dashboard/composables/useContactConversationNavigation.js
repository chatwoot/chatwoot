import { useMapGetter, useStore } from 'dashboard/composables/store';
import { computed, watch } from 'vue';
import wootConstants from 'dashboard/constants/globals';
import { useConversationRoutePath } from './useConversationRoutePath';

// Resolves the conversations before and after the active one in the contact's history.
export function useContactConversationNavigation() {
  const store = useStore();
  const { buildConversationPath } = useConversationRoutePath();

  const currentChat = useMapGetter('getSelectedChat');
  const contactConversations = useMapGetter(
    'contactConversations/getContactConversation'
  );
  const appliedContactFilter = useMapGetter('getAppliedContactFilter');

  const contactId = computed(() => currentChat.value?.meta?.sender?.id);

  const orderedConversations = computed(() => {
    if (!contactId.value) return [];
    return [...contactConversations.value(contactId.value)].sort(
      (a, b) => a.created_at - b.created_at || a.id - b.id
    );
  });

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

  // Refetch when the cached list cannot place the open conversation.
  watch(
    [contactId, () => currentChat.value?.id],
    ([id, conversationId]) => {
      if (!id || !conversationId) return;

      const isConversationKnown = contactConversations
        .value(id)
        .some(conversation => conversation.id === conversationId);
      if (!isConversationKnown) {
        store.dispatch('contactConversations/get', id);
      }
    },
    { immediate: true }
  );

  return { olderConversation, newerConversation, buildConversationPath };
}
