import { ref, nextTick } from 'vue';
import { useContactConversationNavigation } from 'dashboard/composables/useContactConversationNavigation';

const mockDispatch = vi.fn(() => Promise.resolve());
const mockPush = vi.fn(() => Promise.resolve());
const currentChat = ref({});
const neighbourRecords = ref({});
const appliedContactFilter = ref(null);
const filteredConversations = ref([]);

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: mockDispatch }),
  useMapGetter: getter => {
    if (getter === 'getSelectedChat') return currentChat;
    if (getter === 'getAppliedContactFilter') return appliedContactFilter;
    if (getter === 'getConversationById') return ref(() => null);
    if (getter === 'getFilteredConversations') return filteredConversations;
    return ref(id => neighbourRecords.value[id] || []);
  },
}));

const route = { name: 'inbox_conversation' };

vi.mock('vue-router', () => ({
  useRoute: () => route,
  useRouter: () => ({ push: mockPush }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('dashboard/composables/useConversationRoutePath', () => ({
  useConversationRoutePath: () => ({
    buildConversationPath: id => `/conversations/${id}`,
  }),
}));

describe('useContactConversationNavigation', () => {
  beforeEach(() => {
    mockDispatch.mockClear();
    mockPush.mockClear();
    currentChat.value = {};
    neighbourRecords.value = {};
    appliedContactFilter.value = null;
    filteredConversations.value = [];
    route.name = 'inbox_conversation';
  });

  const contactFilterCall = () =>
    mockDispatch.mock.calls.find(
      ([action]) => action === 'applyConversationFilters'
    );

  const setNeighbours = (conversationId, conversations) => {
    neighbourRecords.value = { [conversationId]: conversations };
  };

  const openConversation = (contactId, conversationId, status = 'resolved') => {
    currentChat.value = {
      id: conversationId,
      status,
      meta: { sender: { id: contactId, name: 'Jane Doe' } },
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

  it('scopes the list to the contact before opening a neighbour', async () => {
    openConversation(7, 13);

    const { openConversation: open } = useContactConversationNavigation();
    await open({ id: 11 });

    expect(mockPush).toHaveBeenCalledWith('/conversations/11');
    expect(contactFilterCall()[1].filters[0].values).toEqual([
      { id: 7, name: 'Jane Doe' },
    ]);
    expect(mockDispatch).toHaveBeenCalledWith('getConversation', 11);
  });

  it('scopes the list to the contact and keeps the given thread open', async () => {
    openConversation(7, 13);

    const { viewContactHistory } = useContactConversationNavigation();
    await viewContactHistory({ conversationId: 13 });

    expect(mockPush).not.toHaveBeenCalled();
    expect(contactFilterCall()[1].filters[0].values).toEqual([
      { id: 7, name: 'Jane Doe' },
    ]);
    expect(mockDispatch).toHaveBeenCalledWith('getConversation', 13);
  });

  it('visits the given path before scoping the list', async () => {
    openConversation(7, 13);

    const { viewContactHistory } = useContactConversationNavigation();
    await viewContactHistory({ path: '/conversations' });

    expect(mockPush).toHaveBeenCalledWith('/conversations');
    expect(mockDispatch).not.toHaveBeenCalledWith('getConversation', 13);
  });

  it('only navigates when the list is already scoped to the contact', () => {
    openConversation(7, 13);
    appliedContactFilter.value = { id: 7, name: 'Jane Doe' };

    const { openConversation: open } = useContactConversationNavigation();
    open({ id: 11 });

    expect(mockPush).toHaveBeenCalledWith('/conversations/11');
    expect(contactFilterCall()).toBeUndefined();
  });

  it('folds the editor for an older conversation inside the history view', async () => {
    setNeighbours(13, [
      { id: 11, created_at: 100 },
      { id: 13, created_at: 200 },
      { id: 14, created_at: 300 },
    ]);
    openConversation(7, 13, 'open');

    const nav = useContactConversationNavigation();
    expect(nav.isReadingHistory.value).toBe(false);

    appliedContactFilter.value = { id: 7, name: 'Jane Doe' };
    expect(nav.isReadingHistory.value).toBe(true);

    nav.leaveReadingMode();
    expect(nav.isReadingHistory.value).toBe(false);

    openConversation(7, 11);
    await nextTick();
    expect(nav.isReadingHistory.value).toBe(true);

    openConversation(7, 13);
    await nextTick();
    expect(nav.isReadingHistory.value).toBe(true);
  });

  it('keeps the editor on the latest conversation of the history view', () => {
    setNeighbours(14, [
      { id: 13, created_at: 200 },
      { id: 14, created_at: 300 },
    ]);
    openConversation(7, 14);
    appliedContactFilter.value = { id: 7, name: 'Jane Doe' };

    const { isReadingHistory } = useContactConversationNavigation();

    expect(isReadingHistory.value).toBe(false);
  });

  it('ignores a contact filter left behind on the inbox view', () => {
    setNeighbours(13, [
      { id: 11, created_at: 100 },
      { id: 13, created_at: 200 },
      { id: 14, created_at: 300 },
    ]);
    openConversation(7, 13, 'open');
    appliedContactFilter.value = { id: 7, name: 'Jane Doe' };
    route.name = 'inbox_view_conversation';

    const { isReadingHistory, newerConversation, latestConversation } =
      useContactConversationNavigation();

    expect(isReadingHistory.value).toBe(false);
    expect(newerConversation.value).toBeNull();
    expect(latestConversation.value).toBeNull();
  });

  it('keeps the editor when the history list already shows the open one as latest', () => {
    openConversation(7, 20);
    appliedContactFilter.value = { id: 7, name: 'Jane Doe' };
    filteredConversations.value = [{ id: 20 }, { id: 14 }];

    const { isReadingHistory } = useContactConversationNavigation();

    expect(isReadingHistory.value).toBe(false);
  });

  it('keeps reading when the window shows a newer one but the list only holds the open one', () => {
    setNeighbours(13, [
      { id: 11, created_at: 100 },
      { id: 13, created_at: 200 },
      { id: 14, created_at: 300 },
    ]);
    openConversation(7, 13);
    appliedContactFilter.value = { id: 7, name: 'Jane Doe' };
    filteredConversations.value = [{ id: 13 }];

    const { isReadingHistory } = useContactConversationNavigation();

    expect(isReadingHistory.value).toBe(true);
  });

  it('takes the latest conversation from the head of the history list', () => {
    openConversation(7, 13);
    filteredConversations.value = [{ id: 20 }, { id: 14 }, { id: 13 }];

    const { latestConversation } = useContactConversationNavigation();
    expect(latestConversation.value).toBeNull();

    appliedContactFilter.value = { id: 7, name: 'Jane Doe' };
    expect(latestConversation.value.id).toBe(20);
  });
});
