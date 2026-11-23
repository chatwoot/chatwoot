import { computed, ref, watch } from 'vue';
import MessageApi from 'dashboard/api/inbox/message';
import { useMapGetter, useStore } from 'dashboard/composables/store';

// The messages endpoint returns at most this many per page.
const PAGE_SIZE = 20;

export function useContactConversationHistory() {
  const store = useStore();
  const currentChat = useMapGetter('getSelectedChat');
  const neighbours = useMapGetter(
    'contactConversations/getConversationNeighbours'
  );

  // Oldest first, the order they are shown in above the open thread.
  const segments = ref([]);
  const isLoading = ref(false);
  const hasReachedStart = ref(false);
  const hasError = ref(false);
  // Bumped on every switch so a late response cannot land in another thread.
  let generation = 0;

  const contactId = computed(() => currentChat.value?.meta?.sender?.id);

  const findOlderConversation = async conversation => {
    if (!neighbours.value(conversation.id).length) {
      await store.dispatch('contactConversations/getNeighbours', {
        contactId: contactId.value,
        conversationId: conversation.id,
      });
    }

    // The server returns the conversation between its neighbours, so an empty
    // list means the request failed (the action swallows the error).
    const around = neighbours.value(conversation.id);
    if (!around.length) throw new Error('Neighbours not loaded');
    const index = around.findIndex(({ id }) => id === conversation.id);

    return index > 0 ? around[index - 1] : null;
  };

  const fetchPage = async (conversationId, before) => {
    const { data } = await MessageApi.getPreviousMessages({
      conversationId,
      before,
    });

    return data.payload || [];
  };

  const loadOlderConversation = async run => {
    const anchor = segments.value[0]?.conversation ?? currentChat.value;
    const conversation = await findOlderConversation(anchor);
    if (run !== generation) return;
    if (!conversation) {
      hasReachedStart.value = true;
      return;
    }

    const messages = await fetchPage(conversation.id);
    if (run !== generation) return;
    segments.value = [
      {
        conversation,
        messages,
        hasMore: messages.length >= PAGE_SIZE,
      },
      ...segments.value,
    ];
  };

  const loadEarlierMessages = async (segment, run) => {
    const messages = await fetchPage(
      segment.conversation.id,
      segment.messages[0].id
    );
    if (run !== generation) return;
    segment.messages = [...messages, ...segment.messages];
    segment.hasMore = messages.length >= PAGE_SIZE;
  };

  // Each call loads one page: the rest of the topmost conversation, or the one before it.
  const loadMore = async () => {
    if (isLoading.value || hasReachedStart.value || !contactId.value) return;

    const run = generation;
    isLoading.value = true;
    hasError.value = false;
    try {
      const [topSegment] = segments.value;
      if (topSegment?.hasMore) {
        await loadEarlierMessages(topSegment, run);
      } else {
        await loadOlderConversation(run);
      }
    } catch (error) {
      if (run === generation) hasError.value = true;
    } finally {
      if (run === generation) isLoading.value = false;
    }
  };

  watch([() => currentChat.value?.id, contactId], () => {
    generation += 1;
    segments.value = [];
    isLoading.value = false;
    hasReachedStart.value = false;
    hasError.value = false;
  });

  return {
    historySegments: segments,
    isHistoryLoading: isLoading,
    hasHistoryError: hasError,
    hasMoreHistory: computed(() => !hasReachedStart.value),
    loadMoreHistory: loadMore,
  };
}
