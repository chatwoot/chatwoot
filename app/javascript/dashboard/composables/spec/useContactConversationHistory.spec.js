import { ref, nextTick } from 'vue';
import MessageApi from 'dashboard/api/inbox/message';
import { useContactConversationHistory } from 'dashboard/composables/useContactConversationHistory';

const mockDispatch = vi.fn(() => Promise.resolve());
const currentChat = ref({});
const neighbourRecords = ref({});

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: mockDispatch }),
  useMapGetter: getter => {
    if (getter === 'getSelectedChat') return currentChat;
    return ref(id => neighbourRecords.value[id] || []);
  },
}));

vi.mock('dashboard/api/inbox/message', () => ({
  default: { getPreviousMessages: vi.fn() },
}));

describe('useContactConversationHistory', () => {
  beforeEach(() => {
    mockDispatch.mockClear();
    MessageApi.getPreviousMessages.mockReset();
    currentChat.value = {};
    neighbourRecords.value = {};
  });

  const setNeighbours = (conversationId, conversations) => {
    neighbourRecords.value = {
      ...neighbourRecords.value,
      [conversationId]: conversations,
    };
  };

  const openConversation = (contactId, conversationId) => {
    currentChat.value = {
      id: conversationId,
      meta: { sender: { id: contactId } },
    };
  };

  const buildMessages = (firstId, count) =>
    Array.from({ length: count }, (_, index) => ({ id: firstId + index }));

  const respondWith = (...pages) =>
    pages.forEach(messages =>
      MessageApi.getPreviousMessages.mockResolvedValueOnce({
        data: { payload: messages },
      })
    );

  it('loads the conversation before the open one', async () => {
    setNeighbours(13, [{ id: 11 }, { id: 13 }]);
    openConversation(7, 13);
    respondWith(buildMessages(1, 3));

    const { historySegments, loadMoreHistory } =
      useContactConversationHistory();
    await loadMoreHistory();

    expect(MessageApi.getPreviousMessages).toHaveBeenCalledWith({
      conversationId: 11,
      before: undefined,
    });
    expect(historySegments.value[0].conversation.id).toBe(11);
    expect(historySegments.value[0].messages).toHaveLength(3);
  });

  it('loads the rest of a long conversation before moving to an older one', async () => {
    setNeighbours(13, [{ id: 11 }, { id: 13 }]);
    openConversation(7, 13);
    respondWith(buildMessages(120, 20), buildMessages(115, 5));

    const { historySegments, loadMoreHistory } =
      useContactConversationHistory();
    await loadMoreHistory();
    await loadMoreHistory();

    expect(MessageApi.getPreviousMessages).toHaveBeenLastCalledWith({
      conversationId: 11,
      before: 120,
    });
    expect(historySegments.value).toHaveLength(1);
    expect(historySegments.value[0].messages).toHaveLength(25);
  });

  it('places the conversation before the topmost one above it', async () => {
    setNeighbours(13, [{ id: 11 }, { id: 13 }]);
    setNeighbours(11, [{ id: 9 }, { id: 11 }, { id: 13 }]);
    openConversation(7, 13);
    respondWith(buildMessages(20, 3), buildMessages(10, 3));

    const { historySegments, loadMoreHistory } =
      useContactConversationHistory();
    await loadMoreHistory();
    await loadMoreHistory();

    expect(
      historySegments.value.map(({ conversation }) => conversation.id)
    ).toEqual([9, 11]);
  });

  it('stops at the oldest conversation', async () => {
    setNeighbours(13, [{ id: 13 }, { id: 14 }]);
    openConversation(7, 13);

    const { hasMoreHistory, loadMoreHistory } = useContactConversationHistory();
    await loadMoreHistory();

    expect(hasMoreHistory.value).toBe(false);
    expect(MessageApi.getPreviousMessages).not.toHaveBeenCalled();
  });

  it('does not load without a contact', async () => {
    const { loadMoreHistory } = useContactConversationHistory();
    await loadMoreHistory();

    expect(mockDispatch).not.toHaveBeenCalled();
    expect(MessageApi.getPreviousMessages).not.toHaveBeenCalled();
  });

  it('fetches the neighbours it does not have yet', async () => {
    openConversation(7, 13);

    const { loadMoreHistory } = useContactConversationHistory();
    await loadMoreHistory();

    expect(mockDispatch).toHaveBeenCalledWith(
      'contactConversations/getNeighbours',
      { contactId: 7, conversationId: 13 }
    );
  });

  it('keeps the history retryable when the neighbours fail to load', async () => {
    openConversation(7, 13);

    const { hasHistoryError, hasMoreHistory, loadMoreHistory } =
      useContactConversationHistory();
    await loadMoreHistory();

    expect(hasHistoryError.value).toBe(true);
    expect(hasMoreHistory.value).toBe(true);
  });

  it('flags an error when a page fails to load', async () => {
    setNeighbours(13, [{ id: 11 }, { id: 13 }]);
    openConversation(7, 13);
    MessageApi.getPreviousMessages.mockRejectedValueOnce(new Error('failed'));

    const { hasHistoryError, isHistoryLoading, loadMoreHistory } =
      useContactConversationHistory();
    await loadMoreHistory();

    expect(hasHistoryError.value).toBe(true);
    expect(isHistoryLoading.value).toBe(false);
  });

  it('drops a response that arrives after switching conversations', async () => {
    setNeighbours(13, [{ id: 11 }, { id: 13 }]);
    openConversation(7, 13);
    let resolvePage;
    MessageApi.getPreviousMessages.mockReturnValueOnce(
      new Promise(resolve => {
        resolvePage = resolve;
      })
    );

    const { historySegments, loadMoreHistory } =
      useContactConversationHistory();
    const pending = loadMoreHistory();
    await nextTick();
    openConversation(8, 20);
    await nextTick();
    resolvePage({ data: { payload: buildMessages(1, 3) } });
    await pending;

    expect(historySegments.value).toEqual([]);
  });
});
