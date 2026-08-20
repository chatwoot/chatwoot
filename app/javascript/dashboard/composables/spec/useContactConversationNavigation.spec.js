import { ref, nextTick } from 'vue';
import { useContactConversationNavigation } from 'dashboard/composables/useContactConversationNavigation';

const mockDispatch = vi.fn();
const currentChat = ref({});
const contactConversationRecords = ref({});

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: mockDispatch }),
  useMapGetter: getter => {
    if (getter === 'getSelectedChat') return currentChat;
    return ref(id => contactConversationRecords.value[id] || []);
  },
}));

vi.mock('dashboard/composables/useConversationRoutePath', () => ({
  useConversationRoutePath: () => ({
    buildConversationPath: id => `/conversations/${id}`,
  }),
}));

describe('useContactConversationNavigation', () => {
  beforeEach(() => {
    mockDispatch.mockClear();
    currentChat.value = {};
    contactConversationRecords.value = {};
  });

  const setConversations = (contactId, conversations) => {
    contactConversationRecords.value = { [contactId]: conversations };
  };

  const openConversation = (contactId, conversationId) => {
    currentChat.value = {
      id: conversationId,
      meta: { sender: { id: contactId } },
    };
  };

  it('resolves the neighbours by conversation start time', () => {
    setConversations(7, [
      { id: 14, created_at: 300 },
      { id: 11, created_at: 100 },
      { id: 13, created_at: 200 },
    ]);
    openConversation(7, 13);

    const { olderConversation, newerConversation } =
      useContactConversationNavigation();

    expect(olderConversation.value.id).toBe(11);
    expect(newerConversation.value.id).toBe(14);
  });

  it('breaks created_at ties by id', () => {
    setConversations(7, [
      { id: 13, created_at: 200 },
      { id: 12, created_at: 200 },
      { id: 14, created_at: 300 },
    ]);
    openConversation(7, 13);

    const { olderConversation, newerConversation } =
      useContactConversationNavigation();

    expect(olderConversation.value.id).toBe(12);
    expect(newerConversation.value.id).toBe(14);
  });

  it('returns no older conversation for the oldest one', () => {
    setConversations(7, [
      { id: 11, created_at: 100 },
      { id: 12, created_at: 200 },
    ]);
    openConversation(7, 11);

    const { olderConversation, newerConversation } =
      useContactConversationNavigation();

    expect(olderConversation.value).toBeNull();
    expect(newerConversation.value.id).toBe(12);
  });

  it('returns no newer conversation for the newest one', () => {
    setConversations(7, [
      { id: 11, created_at: 100 },
      { id: 12, created_at: 200 },
    ]);
    openConversation(7, 12);

    const { olderConversation, newerConversation } =
      useContactConversationNavigation();

    expect(olderConversation.value.id).toBe(11);
    expect(newerConversation.value).toBeNull();
  });

  it('returns no neighbours when the open conversation is not in the list', () => {
    setConversations(7, [
      { id: 11, created_at: 100 },
      { id: 12, created_at: 200 },
    ]);
    openConversation(7, 99);

    const { olderConversation, newerConversation } =
      useContactConversationNavigation();

    expect(olderConversation.value).toBeNull();
    expect(newerConversation.value).toBeNull();
  });

  it('returns no neighbours without a contact', () => {
    const { olderConversation, newerConversation } =
      useContactConversationNavigation();

    expect(olderConversation.value).toBeNull();
    expect(newerConversation.value).toBeNull();
    expect(mockDispatch).not.toHaveBeenCalled();
  });

  it('fetches the contact conversations when the open conversation is unknown', () => {
    openConversation(7, 99);

    useContactConversationNavigation();

    expect(mockDispatch).toHaveBeenCalledWith('contactConversations/get', 7);
  });

  it('does not refetch when the open conversation is already cached', () => {
    setConversations(7, [{ id: 13, created_at: 200 }]);
    openConversation(7, 13);

    useContactConversationNavigation();

    expect(mockDispatch).not.toHaveBeenCalled();
  });

  it('refetches when switching to a conversation the cache cannot place', async () => {
    setConversations(7, [{ id: 13, created_at: 200 }]);
    openConversation(7, 13);

    useContactConversationNavigation();
    expect(mockDispatch).not.toHaveBeenCalled();

    openConversation(7, 99);
    await nextTick();

    expect(mockDispatch).toHaveBeenCalledWith('contactConversations/get', 7);
  });
});
