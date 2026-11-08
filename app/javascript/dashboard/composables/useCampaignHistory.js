import { computed, ref, watch } from 'vue';
import ConversationApi from 'dashboard/api/conversations';
import { useMapGetter } from 'dashboard/composables/store';
import { useConfig } from 'dashboard/composables/useConfig';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

export function useCampaignHistory() {
  const currentChat = useMapGetter('getSelectedChat');
  const allMessagesLoaded = useMapGetter('getAllMessagesLoaded');
  const { isEnterprise } = useConfig();
  const { isCloudFeatureEnabled } = useAccount();
  const { run, abort, isPending } = useAbortableRequest();
  const recipients = ref([]);
  const nextBefore = ref(null);
  const firstMessageId = ref(null);
  const hasLoaded = ref(false);
  const hasError = ref(false);
  const failedRefresh = ref(false);
  let refreshRequested = false;
  // Loaded history per conversation, so switching back reveals the timeline without a spinner.
  const cache = new Map();

  const enabled = computed(
    () =>
      isEnterprise &&
      currentChat.value.meta?.channel === INBOX_TYPES.WHATSAPP &&
      isCloudFeatureEnabled(FEATURE_FLAGS.CAMPAIGNS)
  );
  const oldestMessageTime = computed(
    () => currentChat.value.messages?.[0]?.created_at
  );
  const hasMore = computed(() => !hasLoaded.value || nextBefore.value !== null);
  const hasReachedConversationStart = computed(
    () =>
      allMessagesLoaded.value ||
      (hasLoaded.value &&
        (firstMessageId.value === null ||
          currentChat.value.messages?.some(
            message => message.id === firstMessageId.value
          )))
  );
  const visibleCampaignHistory = computed(() => {
    if (!recipients.value.length) return recipients.value;
    const messageSourceIds = new Set(
      currentChat.value.messages?.map(message => message.source_id)
    );
    return recipients.value.filter(
      recipient =>
        !messageSourceIds.has(recipient.source_id) &&
        (hasReachedConversationStart.value ||
          recipient.sent_at >= oldestMessageTime.value)
    );
  });

  // Cover the loaded chat messages, then let agents load earlier campaigns separately.
  const loadCampaignHistory = async ({
    refresh = failedRefresh.value,
  } = {}) => {
    if (enabled.value && refresh && isPending.value) {
      refreshRequested = true;
      return;
    }
    if (!enabled.value || (!refresh && (isPending.value || !hasMore.value)))
      return;
    hasError.value = false;
    failedRefresh.value = false;
    const conversationId = currentChat.value.id;
    const updatePagination = !refresh || !hasLoaded.value;
    const refreshUntil =
      recipients.value[0]?.sent_at ?? oldestMessageTime.value;
    let before = refresh ? undefined : (nextBefore.value ?? undefined);
    let requestSignal;
    try {
      await run(async signal => {
        requestSignal = signal;
        let oldestFetchedTime;
        let pageMeta;
        const merged = new Map(
          recipients.value.map(recipient => [recipient.id, recipient])
        );
        do {
          // Each page needs the cursor returned by the previous request.
          // eslint-disable-next-line no-await-in-loop
          const { data } = await ConversationApi.getCampaignHistory(
            conversationId,
            {
              before,
              signal,
            }
          );
          if (signal.aborted) return;
          data.payload.forEach(recipient =>
            merged.set(recipient.id, recipient)
          );
          pageMeta = data.meta;
          before = data.meta.next_before;
          oldestFetchedTime = data.payload.at(-1)?.sent_at;
        } while (
          before !== null &&
          oldestFetchedTime >=
            (refresh ? refreshUntil : oldestMessageTime.value)
        );
        // Publish a complete load so failed pages cannot advance retry boundaries.
        recipients.value = [...merged.values()].sort(
          (a, b) => b.sent_at - a.sent_at || b.id - a.id
        );
        if (updatePagination) nextBefore.value = pageMeta.next_before;
        firstMessageId.value = pageMeta.first_message_id;
        hasLoaded.value = true;
        cache.set(conversationId, {
          recipients: recipients.value,
          nextBefore: nextBefore.value,
          firstMessageId: firstMessageId.value,
        });
      });
    } catch (error) {
      hasError.value = true;
      failedRefresh.value = refresh;
    } finally {
      if (refreshRequested && !requestSignal?.aborted) {
        refreshRequested = false;
        await loadCampaignHistory({ refresh: true });
      }
    }
  };

  watch(
    [
      () => currentChat.value.id,
      () => currentChat.value.meta?.sender?.id,
      enabled,
    ],
    ([conversationId], [previousId] = []) => {
      abort();
      refreshRequested = false;
      // Same conversation with a new sender or gate: what was loaded no longer applies.
      if (conversationId === previousId) cache.delete(conversationId);
      const cached = cache.get(conversationId);
      recipients.value = cached?.recipients ?? [];
      nextBefore.value = cached?.nextBefore ?? null;
      firstMessageId.value = cached?.firstMessageId ?? null;
      hasLoaded.value = Boolean(cached);
      hasError.value = false;
      failedRefresh.value = false;
      loadCampaignHistory({ refresh: Boolean(cached) });
    },
    { immediate: true }
  );

  watch(oldestMessageTime, () => {
    if (recipients.value.at(-1)?.sent_at >= oldestMessageTime.value)
      loadCampaignHistory();
  });

  watch(
    () => [currentChat.value.id, currentChat.value.messages?.at(-1)?.id],
    ([conversationId, messageId], [previousConversationId, previousId]) => {
      // A switch already loads the new conversation; only react to messages arriving in this one.
      if (conversationId !== previousConversationId) return;
      if (
        (isPending.value || hasLoaded.value || hasError.value) &&
        messageId > (previousId ?? 0)
      ) {
        loadCampaignHistory({ refresh: true });
      }
    }
  );

  return {
    visibleCampaignHistory,
    isCampaignHistoryLoading: isPending,
    // The timeline waits for the first page so campaigns never pop in between rendered messages.
    isCampaignHistoryReady: computed(
      () => !enabled.value || hasLoaded.value || hasError.value
    ),
    campaignHistoryError: hasError,
    hasMoreCampaignHistory: computed(
      () =>
        enabled.value &&
        hasLoaded.value &&
        hasReachedConversationStart.value &&
        hasMore.value
    ),
    loadCampaignHistory,
  };
}
