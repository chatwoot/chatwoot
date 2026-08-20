import { useMapGetter, useStore } from 'dashboard/composables/store';
import { computed, watch } from 'vue';
import { useConversationRoutePath } from './useConversationRoutePath';

// Resolves the conversations that sit immediately before and after the active
// one in the contact's history, ordered by the time each conversation started.
export function useContactConversationNavigation() {
  const store = useStore();
  const { buildConversationPath } = useConversationRoutePath();

  const currentChat = useMapGetter('getSelectedChat');
  const contactConversations = useMapGetter(
    'contactConversations/getContactConversation'
  );

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

  const olderConversation = computed(() =>
    currentIndex.value > 0
      ? orderedConversations.value[currentIndex.value - 1]
      : null
  );

  const newerConversation = computed(() =>
    currentIndex.value < 0
      ? null
      : (orderedConversations.value[currentIndex.value + 1] ?? null)
  );

  // Refetch when the cached list cannot place the open conversation — the
  // contact was never fetched, or the list predates this conversation.
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
