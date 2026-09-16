import { ref, nextTick } from 'vue';
import { useContactConversationNavigation } from 'dashboard/composables/useContactConversationNavigation';

const mockDispatch = vi.fn();
const currentChat = ref({});
const neighbourRecords = ref({});
const appliedContactFilter = ref(null);

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: mockDispatch }),
  useMapGetter: getter => {
    if (getter === 'getSelectedChat') return currentChat;
    if (getter === 'getAppliedContactFilter') return appliedContactFilter;
    return ref(id => neighbourRecords.value[id] || []);
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
    neighbourRecords.value = {};
    appliedContactFilter.value = null;
  });

  const setNeighbours = (conversationId, conversations) => {
    neighbourRecords.value = { [conversationId]: conversations };
  };

  const openConversation = (contactId, conversationId, status = 'resolved') => {
    currentChat.value = {
      id: conversationId,
      status,
      meta: { sender: { id: contactId } },
    };
  };

  it('orders the window returned for the open conversation', () => {
    setNeighbours(13, [
      { id: 11, created_at: 100 },
      { id: 13, created_at: 200 },
      { id: 14, created_at: 300 },
    ]);
    openConversation(7, 13);

    const { olderConversation, newerConversation } =
      useContactConversationNavigation();

    expect(olderConversation.value.id).toBe(11);
    expect(newerConversation.value.id).toBe(14);
  });

  it('returns no older conversation for the oldest one', () => {
    setNeighbours(11, [
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
    setNeighbours(12, [
      { id: 11, created_at: 100 },
      { id: 12, created_at: 200 },
    ]);
    openConversation(7, 12);

    const { olderConversation, newerConversation } =
      useContactConversationNavigation();

    expect(olderConversation.value.id).toBe(11);
    expect(newerConversation.value).toBeNull();
  });

  it.each(['open', 'pending', 'snoozed'])(
    'keeps the older conversation but hides the newer one while %s',
    status => {
      setNeighbours(13, [
        { id: 11, created_at: 100 },
        { id: 13, created_at: 200 },
        { id: 14, created_at: 300 },
      ]);
      openConversation(7, 13, status);

      const { olderConversation, newerConversation } =
        useContactConversationNavigation();

      expect(olderConversation.value.id).toBe(11);
      expect(newerConversation.value).toBeNull();
    }
  );

  it('shows the newer conversation on a live chat while filtered to the contact', () => {
    setNeighbours(13, [
      { id: 11, created_at: 100 },
      { id: 13, created_at: 200 },
      { id: 14, created_at: 300 },
    ]);
    openConversation(7, 13, 'open');
    appliedContactFilter.value = { id: 7, name: 'Jane Doe' };

    const { olderConversation, newerConversation } =
      useContactConversationNavigation();

    expect(olderConversation.value.id).toBe(11);
    expect(newerConversation.value.id).toBe(14);
  });

  it('returns no neighbours until they are resolved', () => {
    openConversation(7, 13);

    const { olderConversation, newerConversation } =
      useContactConversationNavigation();

    expect(olderConversation.value).toBeNull();
    expect(newerConversation.value).toBeNull();
  });

  it('does not fetch without a contact', () => {
    useContactConversationNavigation();

    expect(mockDispatch).not.toHaveBeenCalled();
  });

  it('fetches the neighbours for the open conversation', () => {
    openConversation(7, 13);

    useContactConversationNavigation();

    expect(mockDispatch).toHaveBeenCalledWith(
      'contactConversations/getNeighbours',
      { contactId: 7, conversationId: 13 }
    );
  });

  it('refetches when the open conversation changes', async () => {
    openConversation(7, 13);
    useContactConversationNavigation();

    openConversation(7, 14);
    await nextTick();

    expect(mockDispatch).toHaveBeenLastCalledWith(
      'contactConversations/getNeighbours',
      { contactId: 7, conversationId: 14 }
    );
  });
});
