import { unref, watch } from 'vue';
import { useStore } from 'vuex';
import { useDocumentVisibility } from '@vueuse/core';
import { useEmitter } from 'dashboard/composables/emitter';

// Refetches the conversation counts when a socket event asks for it.
// A hidden tab does not refetch. It refetches once when it becomes visible again.
export function useConversationStatsRefetch({ filters, isDisabled }) {
  const store = useStore();
  const documentVisibility = useDocumentVisibility();
  let hasSkippedRefetch = false;

  const refetch = () => {
    if (unref(isDisabled)) return;
    store.dispatch('conversationStats/get', unref(filters));
  };

  useEmitter('fetch_conversation_stats', () => {
    if (documentVisibility.value === 'hidden') {
      hasSkippedRefetch = true;
      return;
    }
    refetch();
  });

  watch(documentVisibility, visibility => {
    if (visibility !== 'visible' || !hasSkippedRefetch) return;

    hasSkippedRefetch = false;
    refetch();
  });
}
